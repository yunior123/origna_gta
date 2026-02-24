"""
Product Management Handlers
- Product CRUD operations
- Algolia indexing (Firestore triggers)
- Image upload to Cloudflare R2
- Product deletion with validation
- Rating submission
"""

import logging
import re
import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import boto3
import requests
from botocore.config import Config
from firebase_functions import firestore_fn, https_fn

from config import (
    APP_SECRETS_PARAM,
    R2Config,
    get_geoapify_api_key,
    get_r2_credentials,
)
from schema_constants import (
    AppConfig,
    CategoryIds,
    Collections,
    DeliveryTypeValues,
    EmailConfig,
    Fields,
    OrderStatusValues,
    ProductApprovalStatusValues,
    ProductLifecycleStatusValues,
    ProductStatusValues,
    UserRoleValues,
    WarehouseTypeValues,
)
from services.algolia_service import delete_product as algolia_delete_product
from services.algolia_service import index_product, partial_update_product as algolia_partial_update
from utils.function_options import DEFAULT_OPTIONS, FIRESTORE_TRIGGER_OPTIONS
from utils.helpers import create_success_response

logger = logging.getLogger(__name__)

# Constants
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100
CDN_BASE_URL = "https://cdn.origna.ca"

# SECURITY FIX #6: Magic bytes for image format validation
# Prevents serving non-image files via CDN even if MIME type is spoofed
IMAGE_MAGIC_BYTES = {
    b"\xff\xd8\xff": "image/jpeg",  # JPEG
    b"\x89PNG\r\n\x1a\n": "image/png",  # PNG
    b"RIFF": "image/webp",  # WebP (RIFF container)
    b"GIF87a": "image/gif",  # GIF87a
    b"GIF89a": "image/gif",  # GIF89a
}
MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB absolute max

_db = None
_firestore = None


def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db, _firestore
    if _db is None:
        from firebase_admin import firestore as fs

        _firestore = fs
        _db = fs.client()
    return _db


def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore.SERVER_TIMESTAMP


def _generate_product_slug(title: str) -> str:
    """Generate a URL-safe slug: {title-slug}-{4 random hex chars}.
    Collisions checked by caller — retry with new suffix if needed.
    """
    base = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:40]
    suffix = secrets.token_hex(2)  # 4 hex chars
    return f"{base}-{suffix}"


# CORS is configured in DEFAULT_OPTIONS via function_options.py


@https_fn.on_call(secrets=[APP_SECRETS_PARAM])
def upload_product_images(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Generates presigned URLs for uploading product images to Cloudflare R2.

    Security:
    - Authenticated users only
    - Max 5 images per request
    - 10MB file size limit
    - 1-hour URL expiration

    Request data:
        fileNames: List of file names (e.g., ["image1.jpg", "image2.png"])
        contentTypes: List of MIME types (e.g., ["image/jpeg", "image/png"])

    Returns:
        {
            uploadUrls: [{uploadUrl, publicUrl, fileName}],
            success: True
        }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # SECURITY: Verify seller onboarding is complete before allowing uploads
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_data = user_doc.to_dict()
    if user_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError("permission-denied", "Your account is suspended")
    if UserRoleValues.SELLER not in user_data.get(Fields.ROLES, []) and UserRoleValues.ADMIN not in user_data.get(
        Fields.ROLES, []
    ):
        raise https_fn.HttpsError("permission-denied", "Seller role required")
    if not user_data.get(Fields.ONBOARDING_COMPLETED, False) and UserRoleValues.ADMIN not in user_data.get(
        Fields.ROLES, []
    ):
        raise https_fn.HttpsError("failed-precondition", "Please complete seller onboarding before uploading products")

    # AUDIT FIX: Rate limit image uploads
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="upload_images", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    data = req.data
    file_names_raw = data.get("fileNames", [])
    content_types = data.get("contentTypes", [])

    # Import validation functions
    from utils.helpers import sanitize_path

    if not file_names_raw or len(file_names_raw) == 0:
        raise https_fn.HttpsError("invalid-argument", "No files specified")

    if len(file_names_raw) > 5:
        raise https_fn.HttpsError("invalid-argument", "Maximum 5 images allowed")

    if len(file_names_raw) != len(content_types):
        raise https_fn.HttpsError("invalid-argument", "File names and content types count mismatch")

    # SECURITY: Validate MIME types against whitelist (prevent non-image uploads to CDN)
    ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
    for ct in content_types:
        if ct not in ALLOWED_MIME_TYPES:
            raise https_fn.HttpsError(
                "invalid-argument", f"Invalid content type '{ct}'. Allowed: {', '.join(sorted(ALLOWED_MIME_TYPES))}"
            )

    # Sanitize file names to prevent path traversal
    file_names = [sanitize_path(fn) for fn in file_names_raw]

    # SECURITY: Validate file extensions against whitelist
    ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}
    for fn in file_names:
        ext = fn.rsplit(".", 1)[-1].lower() if "." in fn else ""
        if ext not in ALLOWED_EXTENSIONS:
            raise https_fn.HttpsError(
                "invalid-argument", f"Invalid file extension '.{ext}'. Allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
            )

    # Get R2 credentials based on environment
    r2_creds = get_r2_credentials()
    r2_access_key = r2_creds.get("access_key")
    r2_secret_key = r2_creds.get("secret_key")
    r2_account_id = r2_creds.get("account_id")

    if not all([r2_access_key, r2_secret_key, r2_account_id]):
        raise https_fn.HttpsError("failed-precondition", "R2 credentials not configured")

    # Initialize R2 client (S3-compatible)
    s3_client = boto3.client(
        "s3",
        endpoint_url=f"https://{r2_account_id}.r2.cloudflarestorage.com",
        aws_access_key_id=r2_access_key,
        aws_secret_access_key=r2_secret_key,
        config=Config(signature_version="s3v4"),
        region_name="auto",
    )

    bucket_name = R2Config.BUCKET_NAME
    upload_urls = []

    try:
        for file_name, content_type in zip(file_names, content_types, strict=False):
            # Generate unique key with environment-aware path
            file_extension = file_name.split(".")[-1]
            unique_key = R2Config.get_image_path("products", f"{uuid.uuid4()}.{file_extension}")

            # Generate presigned URL for upload
            # NOTE: ContentLength removed — it enforces EXACT size, not max.
            # Size limit enforced by Cloudflare R2 bucket-level configuration.
            presigned_url = s3_client.generate_presigned_url(
                "put_object",
                Params={
                    "Bucket": bucket_name,
                    "Key": unique_key,
                    "ContentType": content_type,
                    # SECURITY: Force inline display — prevents download-triggered XSS
                    "ContentDisposition": "inline",
                },
                ExpiresIn=3600,  # 1 hour
            )

            public_url = f"{CDN_BASE_URL}/{unique_key}"

            upload_urls.append(
                {"uploadUrl": presigned_url, "publicUrl": public_url, "fileName": file_name, "key": unique_key}
            )

        return create_success_response({"uploadUrls": upload_urls})

    except Exception as e:
        logger.error(f"ERROR: Failed to generate upload URLs: {e}")
        raise https_fn.HttpsError("internal", "Failed to generate upload URLs. Please try again.") from e


@https_fn.on_call(secrets=[APP_SECRETS_PARAM])
def upload_review_images(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Generates presigned URLs for uploading review images to Cloudflare R2.

    Available to all authenticated users (buyers as well as sellers).
    Max 3 images per request.

    Request data:
        fileNames: List of file names
        contentTypes: List of MIME types

    Returns:
        { uploadUrls: [{uploadUrl, publicUrl, fileName}], success: True }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # Photo reviews are a premium-only feature
    _user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not _user_doc.exists or not _user_doc.to_dict().get(Fields.IS_PREMIUM, False):
        raise https_fn.HttpsError(
            "permission-denied", "Photo reviews are a premium feature. Upgrade to add photos to your reviews."
        )

    from utils.helpers import sanitize_path

    data = req.data
    file_names_raw = data.get("fileNames", [])
    content_types = data.get("contentTypes", [])

    if not file_names_raw:
        raise https_fn.HttpsError("invalid-argument", "No files specified")
    if len(file_names_raw) > 3:
        raise https_fn.HttpsError("invalid-argument", "Maximum 3 review images allowed")
    if len(file_names_raw) != len(content_types):
        raise https_fn.HttpsError("invalid-argument", "File names and content types count mismatch")

    ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
    for ct in content_types:
        if ct not in ALLOWED_MIME_TYPES:
            raise https_fn.HttpsError("invalid-argument", f"Invalid content type '{ct}'")

    file_names = [sanitize_path(fn) for fn in file_names_raw]
    ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}
    for fn in file_names:
        ext = fn.rsplit(".", 1)[-1].lower() if "." in fn else ""
        if ext not in ALLOWED_EXTENSIONS:
            raise https_fn.HttpsError("invalid-argument", f"Invalid file extension '.{ext}'")

    r2_creds = get_r2_credentials()
    r2_access_key = r2_creds.get("access_key")
    r2_secret_key = r2_creds.get("secret_key")
    r2_account_id = r2_creds.get("account_id")

    if not all([r2_access_key, r2_secret_key, r2_account_id]):
        raise https_fn.HttpsError("failed-precondition", "R2 credentials not configured")

    s3_client = boto3.client(
        "s3",
        endpoint_url=f"https://{r2_account_id}.r2.cloudflarestorage.com",
        aws_access_key_id=r2_access_key,
        aws_secret_access_key=r2_secret_key,
        config=Config(signature_version="s3v4"),
        region_name="auto",
    )

    bucket_name = R2Config.BUCKET_NAME
    upload_urls = []

    try:
        for file_name, content_type in zip(file_names, content_types, strict=False):
            file_extension = file_name.split(".")[-1]
            unique_key = R2Config.get_image_path("reviews", f"{user_id}/{uuid.uuid4()}.{file_extension}")
            presigned_url = s3_client.generate_presigned_url(
                "put_object",
                Params={
                    "Bucket": bucket_name,
                    "Key": unique_key,
                    "ContentType": content_type,
                    "ContentDisposition": "inline",
                },
                ExpiresIn=3600,
            )
            public_url = f"{CDN_BASE_URL}/{unique_key}"
            upload_urls.append(
                {"uploadUrl": presigned_url, "publicUrl": public_url, "fileName": file_name, "key": unique_key}
            )

        return create_success_response({"uploadUrls": upload_urls})

    except Exception as e:
        logger.error(f"ERROR: Failed to generate review upload URLs: {e}")
        raise https_fn.HttpsError("internal", "Failed to generate upload URLs. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def delete_product(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Soft deletes a product (sets isActive = False).

    Security:
    - Only product owner or admin can delete
    - Cannot delete if there are pending orders
    - Product remains in database for order history

    Request data:
        productId: Document ID of product to delete

    Returns:
        {success: True, message: "Product deleted"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    product_id = req.data.get(Fields.PRODUCT_ID)

    # Rate limit: 10/min — prevent mass-deletion abuse
    from services.rate_limiter import RateLimiter as _RL

    _limiter = _RL(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="delete_product", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_doc = product_ref.get()

    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")

    product_data = product_doc.to_dict()

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    is_owner = product_data[Fields.SELLER_ID] == user_id

    if not (is_admin or is_owner):
        raise https_fn.HttpsError("permission-denied", "Only product owner or admin can delete")

    # Check for pending orders
    # NOTE: Firestore can't filter on nested array map fields with array_contains.
    # Use sellerIds (denormalized on orders) to find related orders for this seller,
    # then check if any contain this productId in items.
    pending_orders_query = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.SELLER_IDS, "array_contains", user_id)
        .where(
            Fields.ORDER_STATUS,
            "in",
            [
                OrderStatusValues.PENDING,
                OrderStatusValues.CONFIRMED,
                OrderStatusValues.PROCESSING,
                OrderStatusValues.SHIPPED,
            ],
        )
        .limit(20)
    )

    pending_orders = []
    for order_doc in pending_orders_query.stream():
        order_data_check = order_doc.to_dict()
        for item in order_data_check.get(Fields.ITEMS, []):
            if item.get(Fields.PRODUCT_ID) == product_id:
                pending_orders.append(order_doc)
                break

    if pending_orders:
        raise https_fn.HttpsError(
            "failed-precondition", "Cannot delete product with pending orders. Please wait for orders to complete."
        )

    # Soft delete
    product_ref.update({Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ARCHIVED, Fields.DELETED_AT: get_server_timestamp(), Fields.DELETED_BY: user_id})

    # Remove from Algolia index
    try:
        algolia_delete_product(product_id)
    except Exception as e:
        logger.error(f"Failed to delete from Algolia: {str(e)}")

    # Clean up stock_notification subscriptions for this product
    try:
        subs = list(get_db().collection(Collections.STOCK_NOTIFICATIONS).where(Fields.PRODUCT_ID, "==", product_id).limit(200).stream())
        batch = get_db().batch()
        for sub in subs:
            batch.delete(sub.reference)
        if subs:
            batch.commit()
    except Exception as e:
        logger.error(f"Failed to cleanup stock_notifications for deleted product {product_id}: {e}")

    # Clean up favorites entries across all users for this product
    try:
        fav_refs = list(
            get_db().collection_group(Collections.FAVORITES).where(Fields.PRODUCT_ID, "==", product_id).limit(500).stream()
        )
        if fav_refs:
            batch = get_db().batch()
            for fav in fav_refs:
                batch.delete(fav.reference)
            batch.commit()
            logger.info(f"Cleaned up {len(fav_refs)} favorites for deleted product {product_id}")
    except Exception as e:
        logger.error(f"Failed to cleanup favorites for deleted product {product_id}: {e}")

    return create_success_response({"message": "Product deleted successfully"})


@https_fn.on_call(**DEFAULT_OPTIONS)
def submit_product_rating(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Submits a product rating after order delivery.

    Security:
    - User must have purchased and received the product
    - One rating per user per product
    - Rating: 1-5 stars

    Request data:
        productId: Product to rate
        orderId: Order ID (for verification)
        rating: 1-5
        review: Optional text review
        reviewImageUrls: Optional list of CDN image URLs (max 3)

    Returns:
        {success: True, newRating: 4.5, ratingCount: 120}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # AUDIT FIX: Rate limit rating submissions
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="submit_rating", max_requests=5, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils.helpers import sanitized_text

    product_id = data.get(Fields.PRODUCT_ID)
    order_id = data.get(Fields.ORDER_ID)
    rating = data.get(Fields.RATING)
    review_raw = data.get(Fields.REVIEW, "")
    review_image_urls_raw = data.get(Fields.REVIEW_IMAGE_URLS, [])

    # Sanitize review text to prevent XSS
    review = sanitized_text(review_raw)[:1000] if review_raw else ""  # Max 1000 chars

    # TASK 06: Validate reviewImageUrls — max 3, must be from CDN, premium only
    if review_image_urls_raw:
        if not isinstance(review_image_urls_raw, list):
            raise https_fn.HttpsError("invalid-argument", "reviewImageUrls must be a list")
        if len(review_image_urls_raw) > 3:
            raise https_fn.HttpsError("invalid-argument", "Maximum 3 review images allowed")
        # Photo reviews require premium — verify before accepting URLs
        _user_doc = get_db().collection(Collections.USERS).document(user_id).get()
        if not _user_doc.exists or not _user_doc.to_dict().get(Fields.IS_PREMIUM, False):
            raise https_fn.HttpsError(
                "permission-denied", "Photo reviews are a premium feature. Upgrade to add photos to your reviews."
            )
        for url in review_image_urls_raw:
            if not isinstance(url, str) or not url.startswith(CDN_BASE_URL):
                raise https_fn.HttpsError("invalid-argument", "Review images must be uploaded to the platform CDN")
    review_image_urls: list[str] = [str(u) for u in review_image_urls_raw] if review_image_urls_raw else []

    if not product_id or not order_id or rating is None:
        raise https_fn.HttpsError("invalid-argument", "productId, orderId, and rating required")

    # Validate rating is numeric and in valid range
    if not isinstance(rating, (int, float)) or rating < 1 or rating > 5:
        raise https_fn.HttpsError("invalid-argument", "Rating must be between 1 and 5")

    # Verify user purchased this product
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    if order_data.get(Fields.USER_ID) != user_id:
        raise https_fn.HttpsError("permission-denied", "This is not your order")

    # Block sellers from rating their own product
    rated_item = next((item for item in order_data.get(Fields.ITEMS, []) if item.get(Fields.PRODUCT_ID) == product_id), None)
    if rated_item and rated_item.get(Fields.SELLER_ID) == user_id:
        raise https_fn.HttpsError("permission-denied", "Sellers cannot rate their own products")

    if order_data[Fields.ORDER_STATUS] not in {OrderStatusValues.DELIVERED, OrderStatusValues.DISPUTED}:
        raise https_fn.HttpsError("failed-precondition", "Can only rate delivered orders")

    # Check if product is in order
    product_in_order = any(item[Fields.PRODUCT_ID] == product_id for item in order_data[Fields.ITEMS])

    if not product_in_order:
        raise https_fn.HttpsError("invalid-argument", "Product not in this order")

    # Build rating doc (pre-assembled — written atomically inside transaction below)
    rating_doc: dict = {
        Fields.PRODUCT_ID: product_id,
        Fields.USER_ID: user_id,
        Fields.ORDER_ID: order_id,
        Fields.RATING: rating,
        Fields.REVIEW: review,
        Fields.CREATED_AT: get_server_timestamp(),
        Fields.HELPFUL_COUNT: 0,
        # Votes are tracked in review_votes/{userId} subcollection (not an array)
    }
    if review_image_urls:
        rating_doc[Fields.REVIEW_IMAGE_URLS] = review_image_urls

    # Atomically: check for duplicate, write the rating doc AND update the product average in one transaction.
    # Moving the duplicate check inside the transaction prevents race conditions.
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    new_rating_ref = get_db().collection(Collections.PRODUCT_RATINGS).document()  # Pre-generate doc ref
    _txn_error: dict = {}

    def update_rating_transaction(transaction):
        # Duplicate guard inside transaction (prevents race condition)
        existing = list(
            get_db()
            .collection(Collections.PRODUCT_RATINGS)
            .where(Fields.ORDER_ID, "==", order_id)
            .limit(1)
            .stream()
        )
        if existing:
            _txn_error["err"] = https_fn.HttpsError("already-exists", "This order has already been rated")
            return None, None

        product_doc = product_ref.get(transaction=transaction)
        if not product_doc.exists:
            return None, None

        product_data = product_doc.to_dict()
        current_rating = product_data.get(Fields.RATING, 0)
        rating_count = product_data.get(Fields.RATING_COUNT, 0)

        # Calculate new average atomically
        total_rating = current_rating * rating_count
        new_rating_count = rating_count + 1
        new_average = (total_rating + rating) / new_rating_count

        transaction.create(new_rating_ref, rating_doc)
        transaction.update(product_ref, {Fields.RATING: new_average, Fields.RATING_COUNT: new_rating_count})
        return new_average, new_rating_count

    # Ensure _firestore is initialized before using transactional decorator
    if _firestore is None:
        from firebase_admin import firestore as _fs
        globals()["_firestore"] = _fs
    txn_fn = _firestore.transactional(update_rating_transaction)
    transaction = get_db().transaction()
    new_average, new_rating_count = txn_fn(transaction)

    if "err" in _txn_error:
        raise _txn_error["err"]

    if new_average is not None:
        # Sync updated rating to Algolia so sort-by-rating returns correct results
        algolia_partial_update(product_id, {Fields.RATING: new_average, Fields.RATING_COUNT: new_rating_count})
        return create_success_response({"newRating": new_average, Fields.RATING_COUNT: new_rating_count})

    raise https_fn.HttpsError("not-found", "Product not found")


def validate_image_magic_bytes(image_url: str) -> bool:
    """
    SECURITY FIX #6: Validate uploaded image by checking magic bytes.
    Downloads first 16 bytes and verifies against known image signatures.
    Returns True if valid image, False if malicious/invalid.
    """
    try:
        resp = requests.get(image_url, stream=True, timeout=5)
        if resp.status_code != 200:
            logger.warning(f"⚠️ Image validation failed: HTTP {resp.status_code} for {image_url}")
            return False

        # Read only first 16 bytes for magic byte check
        header_bytes = resp.raw.read(16)
        resp.close()

        if not header_bytes:
            return False

        for magic, _mime in IMAGE_MAGIC_BYTES.items():
            if header_bytes[: len(magic)] == magic:
                return True

        logger.warning(f"⚠️ SECURITY: Image {image_url} has invalid magic bytes: {header_bytes[:8].hex()}")
        return False
    except Exception as e:
        logger.warning(f"⚠️ Image validation error for {image_url}: {type(e).__name__}")
        # Fail open for CDN timeout issues; rely on MIME type validation
        return True


def _verify_address_with_geoapify(
    product_id: str,
    lat: float,
    lon: float,
    street: str,
    city: str,
    postal_code: str,
    country: str,
) -> tuple[bool, str]:
    """
    SECURITY: Verify seller address coordinates via Geoapify reverse geocoding.

    Returns:
        (is_valid, reason) — bool indicates if address is valid, reason is error message

    Validation rules:
    - Address MUST be verified via Geoapify for non-digital products
    - Coordinates must match declared city/postal/country (fuzzy matching)
    - If unverified or fake address detected → product is REJECTED
    """
    geo_key = get_geoapify_api_key()
    if not geo_key:
        # In production, we MUST have Geoapify key. Fail closed.
        return False, "Address verification service not configured"

    try:
        url = f"https://api.geoapify.com/v1/geocode/reverse?lat={lat}&lon={lon}&apiKey={geo_key}"
        response = requests.get(url, timeout=AppConfig.GEOAPIFY_TIMEOUT_SECONDS)
        if response.status_code != 200:
            return False, f"Address verification failed (HTTP {response.status_code})"

        data = response.json()
        features = data.get("features", [])
        if not features:
            return (False, f"Address verification returned no results — coordinates ({lat}, {lon}) may be invalid")

        props = features[0].get("properties", {})
        geo_city = (props.get("city") or props.get("town") or props.get("village") or "").lower()
        geo_postal = (props.get("postcode") or "").replace(" ", "").replace("-", "").upper()
        geo_country = (props.get("country_code") or "").upper()

        declared_city = city.lower().strip()
        declared_postal = postal_code.replace(" ", "").replace("-", "").upper()
        declared_country = country.upper().strip()

        # Check country match (CA vs CA)
        country_match = geo_country == declared_country[:2].upper() if declared_country else False

        # Check city match (fuzzy — first 3 chars)
        city_match = (
            geo_city[:3] == declared_city[:3]
            if len(geo_city) >= 3 and len(declared_city) >= 3
            else geo_city == declared_city
        )

        # Check postal code match (first 3 chars = Forward Sortation Area)
        postal_match = (
            geo_postal[:3] == declared_postal[:3]
            if len(geo_postal) >= 3 and len(declared_postal) >= 3
            else False  # Strict: postal code must be provided and match
        )

        if not country_match:
            return False, f"Country mismatch: declared {declared_country} vs verified {geo_country}"

        if not city_match:
            return False, f"City mismatch: declared {declared_city} vs verified {geo_city}"

        if not postal_match:
            return False, f"Postal code mismatch: declared {declared_postal} vs verified {geo_postal}"

        logger.info(f"✅ Address verified for product {product_id}: {geo_city}, {geo_postal}")
        return True, ""

    except requests.Timeout:
        return False, "Address verification timeout — please try again"
    except Exception as e:
        return False, f"Address verification error: {type(e).__name__}"


def _geocode_warehouse_address(address: dict) -> dict:
    """Forward-geocode a warehouse address via Geoapify, injecting lat/lon into the dict.
    Fail-open: logs warning, returns original address on failure.
    """
    geo_key = get_geoapify_api_key()
    if not geo_key:
        logger.warning("Geoapify key not configured — skipping warehouse geocoding")
        return address

    parts = [
        address.get(Fields.STREET, ""),
        address.get(Fields.CITY, ""),
        address.get(Fields.POSTAL_CODE, ""),
        address.get(Fields.COUNTRY, ""),
    ]
    query = ", ".join(p for p in parts if p).strip()
    if not query:
        return address

    try:
        url = f"https://api.geoapify.com/v1/geocode/search?text={query}&apiKey={geo_key}&limit=1"
        response = requests.get(url, timeout=AppConfig.GEOAPIFY_TIMEOUT_SECONDS)
        if response.status_code != 200:
            logger.warning(f"Warehouse geocode HTTP {response.status_code} for: {query}")
            return address

        data = response.json()
        features = data.get("features", [])
        if not features:
            logger.warning(f"Warehouse geocode no results for: {query}")
            return address

        coords = features[0].get("geometry", {}).get("coordinates", [])
        if len(coords) >= 2:
            address[Fields.LONGITUDE] = coords[0]
            address[Fields.LATITUDE] = coords[1]
            logger.info(f"Warehouse geocoded: {query} → ({coords[1]}, {coords[0]})")
        return address
    except requests.Timeout:
        logger.warning(f"Warehouse geocode timeout for: {query}")
        return address
    except Exception as e:
        logger.warning(f"Warehouse geocode error: {type(e).__name__}: {e}")
        return address


def _derive_ship_from_fields(seller_id: str, product_data: dict) -> dict:
    """Derive shipFrom* fields from warehouse addresses or seller address.
    Returns dict with shipFromCity, shipFromProvince, shipFromCountry, shipFromCountries.
    """
    if product_data.get(Fields.IS_DIGITAL, False):
        return {}

    warehouse_ids = product_data.get(Fields.WAREHOUSE_IDS) or []
    if not warehouse_ids:
        # Individual seller — use sellerAddress
        addr = product_data.get(Fields.SELLER_ADDRESS) or {}
        result = {}
        if addr.get(Fields.CITY):
            result[Fields.SHIP_FROM_CITY] = addr[Fields.CITY]
        if addr.get(Fields.STATE):
            result[Fields.SHIP_FROM_PROVINCE] = addr[Fields.STATE]
        if addr.get(Fields.COUNTRY):
            result[Fields.SHIP_FROM_COUNTRY] = addr[Fields.COUNTRY]
            result[Fields.SHIP_FROM_COUNTRIES] = [addr[Fields.COUNTRY]]
        return result

    # Warehouse seller — batch-read warehouse docs
    wh_refs = [
        get_db()
        .collection(Collections.USERS)
        .document(seller_id)
        .collection(Collections.WAREHOUSES)
        .document(wh_id)
        for wh_id in warehouse_ids[:20]  # Cap reads
    ]
    wh_docs = get_db().get_all(wh_refs)

    countries = set()
    primary_addr = None
    for doc in wh_docs:
        if not doc.exists:
            continue
        wh_data = doc.to_dict() or {}
        addr = wh_data.get("address") or {}
        country = addr.get(Fields.COUNTRY)
        if country:
            countries.add(country)
        # Use default warehouse as primary, otherwise first
        if wh_data.get("isDefault", False) or primary_addr is None:
            primary_addr = addr

    result = {}
    if primary_addr:
        if primary_addr.get(Fields.CITY):
            result[Fields.SHIP_FROM_CITY] = primary_addr[Fields.CITY]
        if primary_addr.get(Fields.STATE):
            result[Fields.SHIP_FROM_PROVINCE] = primary_addr[Fields.STATE]
        if primary_addr.get(Fields.COUNTRY):
            result[Fields.SHIP_FROM_COUNTRY] = primary_addr[Fields.COUNTRY]
    if countries:
        result[Fields.SHIP_FROM_COUNTRIES] = sorted(countries)
    return result




@firestore_fn.on_document_created(document="products/{productId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_product_created(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Indexes product to Algolia when created.
    Also validates product data consistency and fixes known issues.
    """
    product_id = event.params[Fields.PRODUCT_ID]
    product_data = event.data.to_dict()

    if not product_data:
        logger.info(f"No data for product {product_id}")
        return

    # NOTE: Do NOT skip validation based on lifecycleStatus. All newly created
    # products (draft, under_review, etc.) must pass validation before approval.
    # Algolia indexing only happens after admin approval via admin_approve_product.

    # ── SECURITY: SERVER-SIDE VALIDATION (products written from Flutter) ──
    from utils.helpers import sanitized_text

    # CRITICAL: Check if seller is suspended — deactivate product immediately
    seller_id = product_data.get(Fields.SELLER_ID)
    if seller_id:
        seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
        if seller_doc.exists:
            seller_data = seller_doc.to_dict()
            if seller_data.get(Fields.SUSPENDED, False):
                logger.info(f"SECURITY: Product {product_id} from suspended seller {seller_id} — deactivating")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                        Fields.DEACTIVATION_REASON: "Seller is suspended",
                    }
                )
                return

    # CRITICAL: Enforce sellerSku uniqueness per seller
    # sellerId + sellerSku must be unique in the products collection
    seller_sku = product_data.get(Fields.SELLER_SKU)
    if seller_sku and seller_id:
        existing = (
            get_db()
            .collection(Collections.PRODUCTS)
            .where(Fields.SELLER_ID, "==", seller_id)
            .where(Fields.SELLER_SKU, "==", seller_sku)
            .where(Fields.LIFECYCLE_STATUS, "!=", ProductLifecycleStatusValues.ARCHIVED)
            .limit(2)
            .get()
        )
        # If more than one document matches (including this new one), it's a duplicate
        duplicate_ids = [doc.id for doc in existing if doc.id != product_id]
        if duplicate_ids:
            logger.warning(
                f"SECURITY: Duplicate sellerSku '{seller_sku}' for seller {seller_id} — "
                f"existing product(s): {duplicate_ids} — deactivating new product {product_id}"
            )
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                    Fields.DEACTIVATION_REASON: f"Duplicate sellerSku: '{seller_sku}' already exists for this seller",
                }
            )
            return

    # CRITICAL: Validate price > 0 and <= 100000 CAD
    price = product_data.get(Fields.PRICE)
    if price is None or not isinstance(price, (int, float)) or price <= 0 or price > 100000:
        logger.info(f"SECURITY: Product {product_id} has invalid price ({price}) — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                Fields.DEACTIVATION_REASON: f"Invalid price: {price}",
            }
        )
        return

    # CRITICAL: Validate stock quantity >= 0
    stock = product_data.get(Fields.STOCK_QUANTITY, 0)
    if not isinstance(stock, (int, float)) or stock < 0:
        logger.info(f"SECURITY: Product {product_id} has invalid stock ({stock}) — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                Fields.DEACTIVATION_REASON: f"Invalid stock: {stock}",
            }
        )
        return

    # Seller address validation — verify address exists via Geoapify geocoding
    # Skip if product uses warehouse IDs (warehouses are validated at creation time)
    warehouse_ids = product_data.get(Fields.WAREHOUSE_IDS) or []
    seller_address = product_data.get(Fields.SELLER_ADDRESS) or {}
    is_digital = product_data.get(Fields.IS_DIGITAL, False)

    if not is_digital and not warehouse_ids:
        country = seller_address.get(Fields.COUNTRY) or ""
        if not country:
            logger.info(f"SECURITY: Product {product_id} has empty seller country — deactivating")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                    Fields.DEACTIVATION_REASON: "Missing seller country",
                }
            )
            return

        # SECURITY: Validate address coordinates via Geoapify reverse geocoding
        seller_lat = seller_address.get(Fields.LATITUDE)
        seller_lon = seller_address.get(Fields.LONGITUDE)
        seller_street = seller_address.get(Fields.STREET, "")
        seller_city = seller_address.get(Fields.CITY, "")
        seller_postal = seller_address.get(Fields.POSTAL_CODE, "")

        if seller_lat is None or seller_lon is None:
            logger.info(
                f"SECURITY: Product {product_id} missing lat/lng — address not verified via Geoapify — REJECTING"
            )
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                    Fields.DEACTIVATION_REASON: "Address not verified via Geoapify (missing coordinates)",
                }
            )
            return
        else:
            is_valid, error_reason = _verify_address_with_geoapify(
                product_id,
                seller_lat,
                seller_lon,
                seller_street,
                seller_city,
                seller_postal,
                country,
            )
            if not is_valid:
                logger.info(f"SECURITY: Product {product_id} failed address verification: {error_reason} — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                        Fields.DEACTIVATION_REASON: f"Address verification failed: {error_reason}",
                    }
                )
                return

    # CRITICAL: Sanitize text fields to prevent stored XSS
    xss_patches: dict = {}
    name = product_data.get(Fields.NAME, "")
    description = product_data.get(Fields.DESCRIPTION, "")

    # CRITICAL: Validate categoryId against allowed categories
    category_id = product_data.get(Fields.CATEGORY_ID)
    if category_id is not None and (
        not isinstance(category_id, (int, float))
        or int(category_id) < CategoryIds.MIN
        or int(category_id) > CategoryIds.MAX
    ):
        logger.info(f"SECURITY: Product {product_id} has invalid categoryId ({category_id}) — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                Fields.DEACTIVATION_REASON: f"Invalid categoryId: {category_id}",
            }
        )
        return
    sanitized_name = sanitized_text(name)
    sanitized_desc = sanitized_text(description)
    if sanitized_name != name:
        xss_patches[Fields.NAME] = sanitized_name
        logger.info(f"SECURITY: Sanitized XSS in product {product_id} name")
    if sanitized_desc != description:
        xss_patches[Fields.DESCRIPTION] = sanitized_desc
        logger.info(f"SECURITY: Sanitized XSS in product {product_id} description")
    if xss_patches:
        get_db().collection(Collections.PRODUCTS).document(product_id).update(xss_patches)
        product_data.update(xss_patches)

    # ── DATA CONSISTENCY VALIDATION ──────────────────────────────────
    patches = {}

    # Derive priceCents from price (server-side, authoritative)
    price_val = product_data.get(Fields.PRICE)
    if isinstance(price_val, (int, float)) and price_val > 0:
        patches[Fields.PRICE_CENTS] = round(price_val * 100)

    # Slug generation: assign on creation if missing (unique, URL-safe sharing URL)
    if not product_data.get(Fields.SLUG):
        product_name = product_data.get(Fields.NAME, "product")
        slug_candidate = None
        for _ in range(5):
            candidate = _generate_product_slug(product_name)
            existing = get_db().collection(Collections.PRODUCTS).where(Fields.SLUG, "==", candidate).limit(1).get()
            if not existing:
                slug_candidate = candidate
                break
        if not slug_candidate:
            # Fallback: use doc ID suffix (guaranteed unique)
            slug_candidate = f"product-{product_id[-8:]}"
        patches[Fields.SLUG] = slug_candidate
        logger.info(f"Slug assigned to product {product_id}: {slug_candidate}")

    # Bug #1: Digital products MUST have freeShipping=true
    is_digital = product_data.get(Fields.IS_DIGITAL, False)
    if is_digital and not product_data.get(Fields.FREE_SHIPPING, False):
        patches[Fields.FREE_SHIPPING] = True
        logger.info(f"FIX: Product {product_id} is digital but freeShipping=false → patching to true")

    # Bug #2: Local-only products should have a pickup delivery option
    is_local_only = product_data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False)
    delivery_options = product_data.get(Fields.DELIVERY_OPTIONS, [])
    if is_local_only and not any(
        opt.get(Fields.TYPE) == DeliveryTypeValues.PICKUP for opt in delivery_options if isinstance(opt, dict)
    ):
        pickup_option = {
            Fields.TYPE: DeliveryTypeValues.PICKUP,
            Fields.DESCRIPTION: "Local Pickup",
            Fields.ESTIMATED_DAYS: 0,
            Fields.COST: 0.0,
        }
        patches[Fields.DELIVERY_OPTIONS] = [pickup_option] + delivery_options
        logger.info(f"FIX: Product {product_id} is local-only but missing pickup option → patching")

    # Bug #4: Physical products with no delivery options (and not local-only) → add standard
    if not is_digital and not is_local_only and not delivery_options:
        standard_option = {
            Fields.TYPE: DeliveryTypeValues.STANDARD,
            Fields.DESCRIPTION: "Standard Delivery",
            Fields.ESTIMATED_DAYS: 5,
            Fields.COST: 0.0,
        }
        patches[Fields.DELIVERY_OPTIONS] = [standard_option]
        logger.info(f"FIX: Product {product_id} has no delivery options → adding standard")

    # Derive shipFrom* fields from warehouse addresses or seller address
    seller_id = product_data.get(Fields.SELLER_ID)
    warehouse_ids = product_data.get(Fields.WAREHOUSE_IDS) or []
    if seller_id and (warehouse_ids or product_data.get(Fields.SELLER_ADDRESS)):
        try:
            ship_from = _derive_ship_from_fields(seller_id, product_data)
            if ship_from:
                patches.update(ship_from)
        except Exception as e:
            logger.error(f"Failed to derive shipFrom fields for {product_id}: {e}")

    # Apply patches if any
    if patches:
        try:
            get_db().collection(Collections.PRODUCTS).document(product_id).update(patches)
            logger.info(f"Applied {len(patches)} fix(es) to product {product_id}")
            # Update local copy for indexing
            product_data.update(patches)
        except Exception as e:
            logger.error(f"WARNING: Failed to apply patches to product {product_id}: {str(e)}")

    # FOOD SAFETY: Perishable products should have local delivery or same-day option
    is_perishable = product_data.get(Fields.IS_PERISHABLE, False)

    # SECURITY FIX #6: Validate image magic bytes for uploaded product images
    # Check each image URL to ensure it's a real image (not a malicious file)
    image_urls = product_data.get(Fields.IMAGE_URLS, [])
    for img_url in image_urls:
        if isinstance(img_url, str) and img_url.startswith(CDN_BASE_URL) and not validate_image_magic_bytes(img_url):
            logger.warning(f"SECURITY: Product {product_id} has invalid image — deactivating: {img_url[:80]}")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.DRAFT,
                    Fields.DEACTIVATION_REASON: "Image validation failed (invalid file type)",
                }
            )
            return

    if is_perishable:
        delivery_options = product_data.get(Fields.DELIVERY_OPTIONS, [])
        has_local_or_same_day = (
            any(
                opt.get(Fields.TYPE)
                in (
                    DeliveryTypeValues.LOCAL_DELIVERY,
                    DeliveryTypeValues.SAME_DAY,
                    DeliveryTypeValues.PICKUP,
                )
                or opt.get(Fields.ESTIMATED_DAYS, 99) <= 1
                for opt in delivery_options
            )
            if delivery_options
            else product_data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False)
        )

        if not has_local_or_same_day:
            logger.warning(f"WARNING: Perishable product {product_id} should have local/same-day delivery")

    # ── DIGITAL URL VALIDATION: HTTPS-only enforcement ──
    if is_digital:
        bad_urls = []
        book_source_url = product_data.get(Fields.BOOK_SOURCE_URL)
        if book_source_url and not book_source_url.startswith("https://"):
            bad_urls.append("bookSourceUrl")
        digital_builds = product_data.get(Fields.DIGITAL_BUILDS) or {}
        for platform, url in digital_builds.items():
            if url and not url.startswith("https://"):
                bad_urls.append(f"digitalBuilds.{platform}")
        if bad_urls:
            logger.warning(f"SECURITY: Product {product_id} has non-HTTPS digital URL(s): {bad_urls} — deactivating")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.REJECTED,
                    Fields.DEACTIVATION_REASON: f"Digital download URLs must use HTTPS: {', '.join(bad_urls)}",
                    Fields.APPROVAL_REJECTION_REASON: f"Download URLs must use HTTPS: {', '.join(bad_urls)}",
                }
            )
            return

    # ── ADMIN APPROVAL GATE: All products land in under_review ──
    # Products are NOT indexed to Algolia until an admin explicitly approves them.
    # The admin_approve_product callable sets lifecycleStatus=active and triggers indexing.
    try:
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.UNDER_REVIEW,
            }
        )
        logger.info(f"Product {product_id} set to under_review — awaiting admin approval")
    except Exception as e:
        logger.error(f"Failed to set approval status for {product_id}: {e}")

    # ── NOTIFY ALL ADMINS ──
    try:
        _notify_admins_new_product(product_id, product_data)
    except Exception as e:
        logger.error(f"Failed to notify admins of new product {product_id}: {e}")


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────


def _notify_admins_new_product(product_id: str, product_data: dict) -> None:
    """Email all admin users when a product is submitted for review."""
    from services.email_service import send_email

    product_name = product_data.get(Fields.NAME, "Unknown Product")
    seller_id = product_data.get(Fields.SELLER_ID, "unknown")
    is_digital = product_data.get(Fields.IS_DIGITAL, False)
    digital_type = product_data.get(Fields.DIGITAL_TYPE, "")
    price = product_data.get(Fields.PRICE, 0)
    product_type_label = f"Digital ({digital_type})" if is_digital else "Physical"

    # Fetch all admin users
    admin_docs = (
        get_db().collection(Collections.USERS).where(Fields.ROLES, "array-contains", UserRoleValues.ADMIN).get()
    )

    subject = f"[Origna] New Product Pending Review: {product_name}"
    for admin_doc in admin_docs:
        admin_data = admin_doc.to_dict() or {}
        admin_email = admin_data.get(Fields.EMAIL)
        if not admin_email:
            continue
        html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #5B30F6;">New Product Pending Review</h2>
  <table style="width:100%; border-collapse:collapse;">
    <tr><td style="padding:6px 0; color:#666; width:140px;">Product Name</td><td style="font-weight:bold;">{product_name}</td></tr>
    <tr><td style="padding:6px 0; color:#666;">Product ID</td><td><code>{product_id}</code></td></tr>
    <tr><td style="padding:6px 0; color:#666;">Seller ID</td><td><code>{seller_id}</code></td></tr>
    <tr><td style="padding:6px 0; color:#666;">Type</td><td>{product_type_label}</td></tr>
    <tr><td style="padding:6px 0; color:#666;">Price</td><td>CAD ${price:.2f}</td></tr>
  </table>
  <p style="margin-top:20px;">
    <a href="https://orignagta.ca/admin" style="background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;">
      Review in Admin Panel
    </a>
  </p>
  <p style="color:#999; font-size:12px; margin-top:20px;">Origna Ventures Inc. — {EmailConfig.PHYSICAL_ADDRESS}</p>
</div>"""
        send_email(admin_email, subject, html)
        logger.info(f"Admin notification sent to {admin_email} for product {product_id}")


def _send_product_approval_email(seller_email: str, product_name: str, product_id: str) -> None:
    """Notify seller that their product has been approved and is now live."""
    from services.email_service import send_email

    html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #22C55E;">🎉 Your Product is Live!</h2>
  <p>Good news! Your product <strong>{product_name}</strong> has been reviewed and approved by our team.</p>
  <p>It is now visible to buyers on Origna GTA.</p>
  <table style="width:100%; border-collapse:collapse; margin:16px 0;">
    <tr><td style="padding:6px 0; color:#666; width:140px;">Product</td><td style="font-weight:bold;">{product_name}</td></tr>
    <tr><td style="padding:6px 0; color:#666;">Status</td><td style="color:#22C55E; font-weight:bold;">✅ Approved &amp; Live</td></tr>
  </table>
  <p>Thank you for selling on Origna GTA!</p>
  <p style="color:#999; font-size:12px; margin-top:20px;">Origna Ventures Inc. — {EmailConfig.PHYSICAL_ADDRESS}</p>
</div>"""
    send_email(seller_email, f"✅ Your product is live: {product_name}", html)


def _send_product_rejection_email(seller_email: str, product_name: str, reason: str) -> None:
    """Notify seller that their product has been rejected with the reason."""
    from services.email_service import send_email

    html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #EF4444;">Product Review Update</h2>
  <p>Unfortunately, your product <strong>{product_name}</strong> could not be approved at this time.</p>
  <table style="width:100%; border-collapse:collapse; margin:16px 0;">
    <tr><td style="padding:6px 0; color:#666; width:140px;">Product</td><td style="font-weight:bold;">{product_name}</td></tr>
    <tr><td style="padding:6px 0; color:#666;">Status</td><td style="color:#EF4444; font-weight:bold;">❌ Rejected</td></tr>
    <tr><td style="padding:6px 0; color:#666; vertical-align:top;">Reason</td><td>{reason}</td></tr>
  </table>
  <p>You can edit your product to address the issue and resubmit it for review.</p>
  <p>If you have questions, contact us at <a href="mailto:{EmailConfig.SUPPORT_EMAIL}">{EmailConfig.SUPPORT_EMAIL}</a>.</p>
  <p style="color:#999; font-size:12px; margin-top:20px;">Origna Ventures Inc. — {EmailConfig.PHYSICAL_ADDRESS}</p>
</div>"""
    send_email(seller_email, f"Product review update: {product_name}", html)


def _notify_premium_users_new_product(product_data: dict, product_id: str) -> None:
    """Send FCM push to premium users with notifyNewProducts=True (max 500)."""
    try:
        from firebase_admin import messaging
    except ImportError:
        logger.warning("firebase_admin.messaging not available")
        return

    users_query = (
        get_db()
        .collection(Collections.USERS)
        .where(Fields.IS_PREMIUM, "==", True)
        .where(Fields.NOTIFY_NEW_PRODUCTS, "==", True)
        .limit(500)
        .stream()
    )

    tokens = []
    for user in users_query:
        token = (user.to_dict() or {}).get(Fields.FCM_TOKEN)
        if token:
            tokens.append(token)

    if not tokens:
        return

    product_name = product_data.get(Fields.NAME, "New Product")
    images = product_data.get(Fields.IMAGE_URLS) or []
    image_url = images[0] if images else None

    notification_kwargs: dict = {
        "title": "🛍️ New Product on Origna",
        "body": f"{product_name} just went live!",
    }
    if image_url:
        notification_kwargs["image"] = image_url

    msg = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(**notification_kwargs),
        data={"type": "new_product", "productId": product_id, "screen": f"/product/{product_id}"},
    )
    response = messaging.send_each_for_multicast(msg)
    logger.info(f"New product FCM sent: {response.success_count} ok, {response.failure_count} failed")


# ─────────────────────────────────────────────────────────────────────────────
# ADMIN CALLABLES
# ─────────────────────────────────────────────────────────────────────────────


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_approve_product(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Admin-only: Approve a product. Sets approvalStatus=approved, isActive=True,
    and indexes it to Algolia so buyers can discover it.

    Request data:
        productId: str

    Returns:
        {success: True, message: "Product approved"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_data = user_doc.to_dict() or {}
    if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    product_id = req.data.get(Fields.PRODUCT_ID)
    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_doc = product_ref.get()
    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")

    product_data = product_doc.to_dict() or {}

    # Validate digital URLs via HEAD request before approving
    is_digital = product_data.get(Fields.IS_DIGITAL, False)
    if is_digital:
        dead_urls = _check_digital_url_reachability(product_id, product_data)
        if dead_urls:
            seller_email = _get_seller_email(product_data.get(Fields.SELLER_ID))
            reason = f"Download URL(s) unreachable: {', '.join(dead_urls)}"
            product_ref.update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.REJECTED,
                    Fields.APPROVAL_REJECTION_REASON: reason,
                }
            )
            if seller_email:
                _send_product_rejection_email(seller_email, product_data.get(Fields.NAME, ""), reason)
            return create_success_response(
                {"approved": False, "rejected": True, "reason": reason},
                message=f"Product auto-rejected: {reason}",
            )

    # Approve — set lifecycleStatus=active atomically
    product_ref.update(
        {
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            Fields.APPROVAL_REJECTION_REASON: None,
        }
    )

    # Index to Algolia now that it's approved
    try:
        product_data.update(
            {
                "id": product_id,
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
            }
        )
        index_product(product_id, product_data)
        logger.info(f"Product {product_id} indexed to Algolia after admin approval")
    except Exception as e:
        logger.error(f"Algolia indexing failed after approval for {product_id}: {e}")

    # Email seller
    seller_email = _get_seller_email(product_data.get(Fields.SELLER_ID))
    if seller_email:
        try:
            _send_product_approval_email(seller_email, product_data.get(Fields.NAME, ""), product_id)
        except Exception as e:
            logger.error(f"Failed to send approval email for {product_id}: {e}")

    logger.info(f"Admin {user_id} approved product {product_id}")

    # Notify premium users who opted in for new product alerts
    try:
        _notify_premium_users_new_product(product_data, product_id)
    except Exception as e:
        logger.error(f"Failed to send new product FCM for {product_id}: {e}")

    return create_success_response({}, message="Product approved and now live")


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_reject_product(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Admin-only: Reject a product with a mandatory reason.
    Sets approvalStatus=rejected, isActive=False, stores reason, emails seller.

    Request data:
        productId: str
        reason: str  — mandatory rejection reason shown to seller

    Returns:
        {success: True, message: "Product rejected"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_data = user_doc.to_dict() or {}
    if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    product_id = req.data.get(Fields.PRODUCT_ID)
    reason = (req.data.get("reason") or "").strip()
    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")
    if not reason:
        raise https_fn.HttpsError("invalid-argument", "reason required for rejection")
    if len(reason) > 1000:
        raise https_fn.HttpsError("invalid-argument", "reason must be ≤ 1000 characters")

    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_doc = product_ref.get()
    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")

    product_data = product_doc.to_dict() or {}
    product_name = product_data.get(Fields.NAME, "")

    product_ref.update(
        {
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.REJECTED,
            Fields.APPROVAL_REJECTION_REASON: reason,
        }
    )

    # Remove from Algolia if it was previously approved
    import contextlib

    with contextlib.suppress(Exception):
        algolia_delete_product(product_id)

    # Email seller
    seller_email = _get_seller_email(product_data.get(Fields.SELLER_ID))
    if seller_email:
        try:
            _send_product_rejection_email(seller_email, product_name, reason)
        except Exception as e:
            logger.error(f"Failed to send rejection email for {product_id}: {e}")

    logger.info(f"Admin {user_id} rejected product {product_id}: {reason}")
    return create_success_response({}, message="Product rejected")


def _get_seller_email(seller_id: str | None) -> str | None:
    """Fetch seller email from Firestore users collection."""
    if not seller_id:
        return None
    try:
        doc = get_db().collection(Collections.USERS).document(seller_id).get()
        return (doc.to_dict() or {}).get(Fields.EMAIL)
    except Exception:
        return None


def _check_digital_url_reachability(product_id: str, product_data: dict) -> list[str]:
    """HEAD-check all digital download URLs. Returns list of unreachable URL labels."""
    dead = []
    urls_to_check: list[tuple[str, str]] = []

    book_url = product_data.get(Fields.BOOK_SOURCE_URL)
    if book_url:
        urls_to_check.append(("bookSourceUrl", book_url))

    builds = product_data.get(Fields.DIGITAL_BUILDS) or {}
    for platform, url in builds.items():
        if url:
            urls_to_check.append((f"digitalBuilds.{platform}", url))

    for label, url in urls_to_check:
        try:
            resp = requests.head(url, timeout=10, allow_redirects=True, headers={"User-Agent": "OrignaBot/1.0"})
            if resp.status_code >= 400:
                logger.warning(f"Digital URL check: {label} returned {resp.status_code} for product {product_id}")
                dead.append(label)
        except requests.exceptions.RequestException as e:
            logger.warning(f"Digital URL check: {label} unreachable for product {product_id}: {e}")
            dead.append(label)

    return dead


@firestore_fn.on_document_updated(document="products/{productId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_product_updated(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Updates product in Algolia when modified.
    """
    product_id = event.params[Fields.PRODUCT_ID]
    product_data = event.data.after.to_dict()
    before_data = event.data.before.to_dict() if event.data.before else {}

    if not product_data:
        logger.info(f"No data for product {product_id}")
        return

    # If product is not active, delete from index
    if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
        try:
            algolia_delete_product(product_id)
            logger.info(f"Product {product_id} removed from Algolia (inactive)")
        except Exception as e:
            logger.error(f"Failed to delete from Algolia: {str(e)}")
        return

    # ── SKIP RE-VALIDATION FOR NON-SECURITY-RELEVANT UPDATES ──
    # When create_checkout_session or stock-restore updates stockQuantity, or when only
    # metadata fields change, we must NOT re-validate address/geocoding — this would
    # deactivate products that were already validated at creation time.
    _SKIP_VALIDATION_FIELDS = {
        Fields.STOCK_QUANTITY,
        Fields.UPDATED_AT,
        Fields.STOCK_RESTORED,
        Fields.LIFECYCLE_STATUS,
        Fields.DEACTIVATION_REASON,
        Fields.APPROVAL_REJECTION_REASON,
    }
    _address_changed = False
    if before_data:
        changed_fields = {
            key
            for key in set(list(product_data.keys()) + list(before_data.keys()))
            if product_data.get(key) != before_data.get(key)
        }

        # ── RESUBMIT: Seller edited a rejected product — reset to under_review ──
        _SELLER_EDITABLE_FIELDS = {
            Fields.NAME,
            Fields.DESCRIPTION,
            Fields.PRICE,
            Fields.IMAGE_URLS,
            Fields.CATEGORY_ID,
            Fields.KEYWORDS,
            Fields.DIGITAL_BUILDS,
            Fields.BOOK_SOURCE_URL,
            Fields.STOCK_QUANTITY,
            Fields.DIGITAL_TYPE,
        }
        before_lifecycle = before_data.get(Fields.LIFECYCLE_STATUS)
        after_lifecycle = product_data.get(Fields.LIFECYCLE_STATUS)
        if (
            before_lifecycle == ProductLifecycleStatusValues.REJECTED
            and after_lifecycle == ProductLifecycleStatusValues.REJECTED
            and changed_fields & _SELLER_EDITABLE_FIELDS
        ):
            logger.info(f"Product {product_id}: rejected product edited by seller — resetting to under_review")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.UNDER_REVIEW,
                    Fields.APPROVAL_REJECTION_REASON: None,
                }
            )
            # Notify admins of the resubmission
            try:
                _notify_admins_new_product(product_id, product_data)
            except Exception as e:
                logger.error(f"Failed to notify admins of resubmission for {product_id}: {e}")
            return

        if changed_fields and changed_fields.issubset(_SKIP_VALIDATION_FIELDS):
            # Non-security-relevant update — re-index if active
            is_active = product_data.get(Fields.LIFECYCLE_STATUS) == ProductLifecycleStatusValues.ACTIVE
            if is_active:
                try:
                    product_data["id"] = product_id
                    # Use partial update for stock/status-only changes to avoid rewriting all fields
                    stock_only_fields = {Fields.STOCK_QUANTITY, Fields.LIFECYCLE_STATUS, Fields.UPDATED_AT}
                    if changed_fields.issubset(stock_only_fields):
                        partial_fields = {k: product_data[k] for k in changed_fields if k in product_data and k != Fields.UPDATED_AT}
                        if partial_fields:
                            algolia_partial_update(product_id, partial_fields)
                    else:
                        index_product(product_id, product_data)
                except Exception as e:
                    logger.error(f"Failed to index product {product_id} after metadata update: {str(e)}")

            # TASK 07: Fire back-in-stock notifications when stockQuantity 0→>0
            try:
                _fire_back_in_stock_notifications(product_id, before_data, product_data)
            except Exception as e:
                logger.error(f"Back-in-stock notification error for {product_id}: {e}")

            # N-06: Track price history even on metadata-only updates
            try:
                _track_price_history(product_id, before_data, product_data)
            except Exception as e:
                logger.error(f"Price history tracking error for {product_id}: {e}")

            return
        # Track whether address changed — skip geocoding if it didn't
        _address_changed = before_data.get(Fields.SELLER_ADDRESS) != product_data.get(Fields.SELLER_ADDRESS)

    # ── SERVER-SIDE VALIDATION on update (same as on_product_created) ──
    from utils.helpers import sanitized_text

    # CRITICAL: Check if seller is suspended — deactivate product immediately
    seller_id = product_data.get(Fields.SELLER_ID)
    if seller_id:
        seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
        if seller_doc.exists:
            seller_data = seller_doc.to_dict()
            if seller_data.get(Fields.SUSPENDED, False):
                logger.info(f"SECURITY: Product {product_id} from suspended seller {seller_id} — deactivating")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                        Fields.DEACTIVATION_REASON: "Seller is suspended",
                    }
                )
                return

    # Validate price > 0 and <= 100000 CAD
    price = product_data.get(Fields.PRICE)
    if price is not None and (not isinstance(price, (int, float)) or price <= 0 or price > 100000):
        logger.info(f"SECURITY: Product {product_id} updated with invalid price ({price}) — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
            }
        )
        return

    # Validate compareAtPrice > price to prevent fraudulent discount display
    compare_at_price = product_data.get(Fields.COMPARE_AT_PRICE)
    if compare_at_price is not None and price is not None:
        if not isinstance(compare_at_price, (int, float)) or compare_at_price <= price:
            logger.info(
                f"SECURITY: Product {product_id} updated with invalid compareAtPrice ({compare_at_price}) <= price ({price}) — deactivating"
            )
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                }
            )
            return

    # Validate stock quantity >= 0
    stock = product_data.get(Fields.STOCK_QUANTITY, 0)
    if not isinstance(stock, (int, float)) or stock < 0:
        logger.info(f"SECURITY: Product {product_id} updated with invalid stock ({stock}) — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
            }
        )
        return

    # Seller address validation — skip for warehouse products and digital products
    warehouse_ids = product_data.get(Fields.WAREHOUSE_IDS) or []
    is_digital = product_data.get(Fields.IS_DIGITAL, False)

    if not is_digital and not warehouse_ids:
        seller_address = product_data.get(Fields.SELLER_ADDRESS, {})
        country = seller_address.get(Fields.COUNTRY) or ""
        if not country:
            logger.info(f"SECURITY: Product {product_id} updated with empty seller country — deactivating")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                }
            )
            return

        # SECURITY: Validate address coordinates on updates — only if address actually changed
        if _address_changed:
            seller_lat = seller_address.get(Fields.LATITUDE)
            seller_lon = seller_address.get(Fields.LONGITUDE)
            seller_street = seller_address.get(Fields.STREET, "")
            seller_city = seller_address.get(Fields.CITY, "")
            seller_postal = seller_address.get(Fields.POSTAL_CODE, "")

            if seller_lat is None or seller_lon is None:
                logger.info(f"SECURITY: Product {product_id} updated with missing coordinates — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                        Fields.DEACTIVATION_REASON: "Address not verified via Geoapify (missing coordinates)",
                    }
                )
                return

            is_valid, error_reason = _verify_address_with_geoapify(
                product_id,
                seller_lat,
                seller_lon,
                seller_street,
                seller_city,
                seller_postal,
                country,
            )
            if not is_valid:
                logger.info(f"SECURITY: Product {product_id} updated with invalid address: {error_reason} — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                        Fields.DEACTIVATION_REASON: f"Address verification failed: {error_reason}",
                    }
                )
                return

    # Sanitize text fields to prevent stored XSS
    xss_patches = {}
    name = product_data.get(Fields.NAME, "")
    description = product_data.get(Fields.DESCRIPTION, "")
    sanitized_name = sanitized_text(name)
    sanitized_desc = sanitized_text(description)
    if sanitized_name != name:
        xss_patches[Fields.NAME] = sanitized_name
    if sanitized_desc != description:
        xss_patches[Fields.DESCRIPTION] = sanitized_desc
    if xss_patches:
        get_db().collection(Collections.PRODUCTS).document(product_id).update(xss_patches)
        product_data.update(xss_patches)

    # Re-derive shipFrom* fields when warehouseIds changed or shipFromCountry missing (backfill)
    update_wh_ids = product_data.get(Fields.WAREHOUSE_IDS) or []
    update_seller_id = product_data.get(Fields.SELLER_ID)
    ship_from_needed = (
        before_data
        and (
            before_data.get(Fields.WAREHOUSE_IDS) != update_wh_ids
            or not product_data.get(Fields.SHIP_FROM_COUNTRY)
        )
    )
    if ship_from_needed and update_seller_id:
        try:
            ship_from = _derive_ship_from_fields(update_seller_id, product_data)
            if ship_from:
                get_db().collection(Collections.PRODUCTS).document(product_id).update(ship_from)
                product_data.update(ship_from)
        except Exception as e:
            logger.error(f"Failed to derive shipFrom fields on update for {product_id}: {e}")

    # N-06: Track price history on full-validation path
    try:
        _track_price_history(product_id, before_data, product_data)
    except Exception as e:
        logger.error(f"Price history tracking error for {product_id}: {e}")

    # Fire back-in-stock notifications unconditionally (covers full-validation path too)
    try:
        _fire_back_in_stock_notifications(product_id, before_data, product_data)
    except Exception as e:
        logger.error(f"Back-in-stock notification error for {product_id}: {e}")

    try:
        product_data["id"] = product_id
        # Only index if product is active — prevents bypassing the approval gate
        if product_data.get(Fields.LIFECYCLE_STATUS) == ProductLifecycleStatusValues.ACTIVE:
            index_product(product_id, product_data)
            logger.info(f"Product {product_id} updated in Algolia")
        else:
            logger.info(f"Product {product_id} not indexed — lifecycleStatus={product_data.get(Fields.LIFECYCLE_STATUS)}")
    except Exception as e:
        logger.error(f"Failed to update product {product_id} in Algolia: {str(e)}")


@firestore_fn.on_document_deleted(document="products/{productId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_product_deleted(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Removes product from Algolia and cleans up stock_notifications when deleted.
    """
    product_id = event.params[Fields.PRODUCT_ID]

    try:
        algolia_delete_product(product_id)
        logger.info(f"Product {product_id} deleted from Algolia")
    except Exception as e:
        logger.error(f"Failed to delete product {product_id} from Algolia: {str(e)}")

    try:
        subs = list(get_db().collection(Collections.STOCK_NOTIFICATIONS).where(Fields.PRODUCT_ID, "==", product_id).limit(200).stream())
        batch = get_db().batch()
        for sub in subs:
            batch.delete(sub.reference)
        if subs:
            batch.commit()
        logger.info(f"Cleaned up {len(subs)} stock_notifications for deleted product {product_id}")
    except Exception as e:
        logger.error(f"Failed to cleanup stock_notifications for hard-deleted product {product_id}: {e}")

    try:
        fav_refs = list(
            get_db().collection_group(Collections.FAVORITES).where(Fields.PRODUCT_ID, "==", product_id).limit(500).stream()
        )
        if fav_refs:
            batch = get_db().batch()
            for fav in fav_refs:
                batch.delete(fav.reference)
            batch.commit()
            logger.info(f"Cleaned up {len(fav_refs)} favorites for hard-deleted product {product_id}")
    except Exception as e:
        logger.error(f"Failed to cleanup favorites for hard-deleted product {product_id}: {e}")


@https_fn.on_call(**DEFAULT_OPTIONS)
def configure_algolia(req: https_fn.CallableRequest) -> dict:
    """
    One-time setup: Configures Algolia index settings.
    Admin only.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # Check admin role
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()

    if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin only")

    # AUDIT FIX: Rate limit admin endpoint
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="configure_algolia", max_requests=3, window_minutes=60
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    try:
        from services.algolia_service import configure_algolia_index

        configure_algolia_index()
        return create_success_response({"message": "Algolia index configured"})
    except Exception as e:
        logger.error(f"ERROR: Algolia configuration failed: {e}")
        raise https_fn.HttpsError("internal", "Failed to configure Algolia. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_products_paginated(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Récupère les produits avec pagination (lazy loading).

    Request data:
        limit: Nombre de produits (défaut: 20, max: 100)
        startAfter: Document ID pour commencer après (cursor)
        category: Filtrer par catégorie (optionnel)
        sellerId: Filtrer par vendeur (optionnel)
        isActive: Filtrer par statut actif (défaut: True)
        orderBy: Champ de tri (défaut: 'createdAt')
        orderDirection: Direction du tri ('asc' ou 'desc', défaut: 'desc')

    Returns:
        {
            products: [...],
            nextCursor: 'doc_id' ou null,
            hasMore: boolean,
            totalFetched: number
        }
    """
    # AUDIT FIX: Rate limit read endpoint to prevent scraping
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())

    if req.auth:
        allowed, msg = _limiter.check_rate_limit(
            identifier=req.auth.uid, action="get_products", max_requests=30, window_minutes=1, fail_closed=False
        )
        if not allowed:
            raise https_fn.HttpsError("resource-exhausted", msg)
    else:
        # IP-based rate limiting for unauthenticated requests (anti-scraping)
        client_ip = (req.raw_request.headers.get("X-Forwarded-For", "") or "").split(",")[0].strip()
        if client_ip:
            allowed, msg = _limiter.check_rate_limit(
                identifier=f"ip:{client_ip}",
                action="get_products",
                max_requests=15,
                window_minutes=1,
                fail_closed=False,
            )
            if not allowed:
                raise https_fn.HttpsError("resource-exhausted", msg)

    data = req.data or {}

    # Paramètres de pagination
    limit = min(data.get("limit", DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE)
    start_after_id = data.get("startAfter")
    category = data.get("category")
    seller_id = data.get(Fields.SELLER_ID)
    order_by = data.get("orderBy", Fields.CREATED_AT)
    order_direction = data.get("orderDirection", "desc")

    # SECURITY FIX #14: Force lifecycleStatus=active for public API — only admins can list non-active products
    # Prevents client-side bypass where inactive products are exposed
    is_admin = False
    if req.auth:
        user_doc = get_db().collection(Collections.USERS).document(req.auth.uid).get()
        if user_doc.exists:
            roles = user_doc.to_dict().get(Fields.ROLES, [])
            is_admin = UserRoleValues.ADMIN in roles

    # Admins can optionally filter by lifecycleStatus; public always gets active only
    lifecycle_filter = ProductLifecycleStatusValues.ACTIVE
    if is_admin:
        requested = data.get(Fields.LIFECYCLE_STATUS)
        if requested and requested in ProductLifecycleStatusValues.ALL:
            lifecycle_filter = requested

    # Validation
    if order_by not in [Fields.CREATED_AT, Fields.PRICE, Fields.RATING, Fields.RATING_COUNT, Fields.NAME]:
        raise https_fn.HttpsError("invalid-argument", "Invalid orderBy field")

    if order_direction not in ["asc", "desc"]:
        raise https_fn.HttpsError("invalid-argument", "orderDirection must be asc or desc")

    try:
        # Construction de la requête de base
        query = get_db().collection(Collections.PRODUCTS)

        # Filtres
        if lifecycle_filter is not None:
            query = query.where(Fields.LIFECYCLE_STATUS, "==", lifecycle_filter)

        if category:
            query = query.where(Fields.CATEGORY_ID, "==", category)

        if seller_id:
            query = query.where(Fields.SELLER_ID, "==", seller_id)

        # Tri
        if order_direction == "desc":
            query = query.order_by(order_by, direction="DESCENDING")
        else:
            query = query.order_by(order_by, direction="ASCENDING")

        # Cursor pour pagination
        if start_after_id:
            start_doc = get_db().collection(Collections.PRODUCTS).document(start_after_id).get()
            if start_doc.exists:
                query = query.start_after(start_doc)

        # Limiter avec +1 pour détecter s'il y a plus de résultats
        query = query.limit(limit + 1)

        # Exécution lazy
        docs = list(query.stream())

        # Vérifier s'il y a plus de résultats
        has_more = len(docs) > limit

        # Limiter au nombre demandé
        if has_more:
            docs = docs[:limit]

        # Formatter les produits
        products = []
        for doc in docs:
            product_data = doc.to_dict()
            product_data["id"] = doc.id
            products.append(product_data)

        # Cursor pour la prochaine page
        next_cursor = docs[-1].id if has_more and docs else None

        return create_success_response(
            {"products": products, "nextCursor": next_cursor, "hasMore": has_more, "totalFetched": len(products)}
        )

    except Exception as e:
        logger.error(f"ERROR: Failed to fetch products: {e}")
        raise https_fn.HttpsError("internal", "Failed to fetch products. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_seller_products_paginated(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Récupère les produits d'un vendeur avec pagination.
    Authentification requise pour voir ses propres produits.

    Request data:
        sellerId: ID du vendeur (optionnel si connecté)
        limit: Nombre de produits (défaut: 20, max: 100)
        startAfter: Document ID cursor
        includeInactive: Inclure produits inactifs (owner/admin only)

    Returns:
        {
            products: [...],
            nextCursor: 'doc_id' ou null,
            hasMore: boolean,
            totalFetched: number
        }
    """
    # AUDIT FIX: Rate limit read endpoint to prevent scraping
    if req.auth:
        from services.rate_limiter import RateLimiter

        _limiter = RateLimiter(get_db())
        allowed, msg = _limiter.check_rate_limit(
            identifier=req.auth.uid, action="get_seller_products", max_requests=30, window_minutes=1, fail_closed=False
        )
        if not allowed:
            raise https_fn.HttpsError("resource-exhausted", msg)

    data = req.data or {}

    seller_id = data.get(Fields.SELLER_ID)
    limit = min(data.get("limit", DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE)
    start_after_id = data.get("startAfter")
    include_inactive = data.get("includeInactive", False)

    # Si pas de sellerId, utiliser l'utilisateur connecté
    if not seller_id:
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "User must be authenticated")
        seller_id = req.auth.uid

    # Vérifier les permissions pour includeInactive
    if include_inactive:
        if not req.auth:
            raise https_fn.HttpsError("permission-denied", "Authentication required to view inactive products")

        user_id = req.auth.uid

        # Vérifier que c'est le propriétaire ou un admin
        if user_id != seller_id:
            user_ref = get_db().collection(Collections.USERS).document(user_id)
            user_doc = user_ref.get()

            if not user_doc.exists:
                raise https_fn.HttpsError("not-found", "User not found")

            user_data = user_doc.to_dict()
            if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
                raise https_fn.HttpsError("permission-denied", "Only owner or admin can view inactive products")

    try:
        # Construction de la requête
        query = get_db().collection(Collections.PRODUCTS).where(Fields.SELLER_ID, "==", seller_id)

        # Filtrer par statut si nécessaire
        if not include_inactive:
            query = query.where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.ACTIVE)

        # Tri par date de création (plus récent en premier)
        query = query.order_by(Fields.CREATED_AT, direction="DESCENDING")

        # Cursor
        if start_after_id:
            start_doc = get_db().collection(Collections.PRODUCTS).document(start_after_id).get()
            if start_doc.exists:
                query = query.start_after(start_doc)

        # Limite avec +1 pour hasMore
        query = query.limit(limit + 1)

        # Exécution lazy
        docs = list(query.stream())

        has_more = len(docs) > limit
        if has_more:
            docs = docs[:limit]

        # Formatter
        products = []
        for doc in docs:
            product_data = doc.to_dict()
            product_data["id"] = doc.id
            products.append(product_data)

        next_cursor = docs[-1].id if has_more and docs else None

        return create_success_response(
            {"products": products, "nextCursor": next_cursor, "hasMore": has_more, "totalFetched": len(products)}
        )

    except Exception as e:
        logger.error(f"ERROR: Failed to fetch seller products: {e}")
        raise https_fn.HttpsError("internal", "Failed to fetch seller products. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_product_ratings_paginated(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Récupère les ratings d'un produit avec pagination (lazy loading).

    Request data:
        productId: ID du produit (requis)
        limit: Nombre de ratings (défaut: 10, max: 50)
        startAfter: Document ID cursor
        minRating: Filtrer par rating minimum (1-5)

    Returns:
        {
            ratings: [...],
            nextCursor: 'doc_id' ou null,
            hasMore: boolean,
            totalFetched: number
        }
    """
    # AUDIT FIX: Rate limit read endpoint to prevent scraping
    if req.auth:
        from services.rate_limiter import RateLimiter

        _limiter = RateLimiter(get_db())
        allowed, msg = _limiter.check_rate_limit(
            identifier=req.auth.uid, action="get_product_ratings", max_requests=30, window_minutes=1, fail_closed=False
        )
        if not allowed:
            raise https_fn.HttpsError("resource-exhausted", msg)

    data = req.data or {}

    product_id = data.get(Fields.PRODUCT_ID)
    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    limit = min(data.get("limit", 10), 50)
    start_after_id = data.get("startAfter")
    min_rating = data.get("minRating")

    # Validation
    if min_rating is not None and (not isinstance(min_rating, (int, float)) or min_rating < 1 or min_rating > 5):
        raise https_fn.HttpsError("invalid-argument", "minRating must be between 1 and 5")

    try:
        # Construction de la requête
        query = get_db().collection(Collections.PRODUCT_RATINGS).where(Fields.PRODUCT_ID, "==", product_id)

        # Filtrer par rating minimum
        if min_rating is not None:
            query = query.where(Fields.RATING, ">=", min_rating)

        # Tri par date (plus récent en premier)
        query = query.order_by(Fields.CREATED_AT, direction="DESCENDING")

        # Cursor
        if start_after_id:
            start_doc = get_db().collection(Collections.PRODUCT_RATINGS).document(start_after_id).get()
            if start_doc.exists:
                query = query.start_after(start_doc)

        # Limite avec +1
        query = query.limit(limit + 1)

        # Exécution lazy
        docs = list(query.stream())

        has_more = len(docs) > limit
        if has_more:
            docs = docs[:limit]

        # Formatter avec informations utilisateur (batch read pour éviter N+1)
        ratings = []
        rating_data_list = []
        user_ids_to_fetch = set()

        # Préparer les données et collecter les user IDs uniques
        for doc in docs:
            rating_data = doc.to_dict()
            rating_data["id"] = doc.id
            rating_data_list.append(rating_data)

            user_id = rating_data.get(Fields.USER_ID)
            if user_id:
                user_ids_to_fetch.add(user_id)

        # Batch read des utilisateurs (max 10 à la fois pour getAll)
        user_data_map = {}
        if user_ids_to_fetch:
            user_ids_list = list(user_ids_to_fetch)
            # Firestore getAll limite à 10 documents
            for i in range(0, len(user_ids_list), 10):
                batch_user_ids = user_ids_list[i : i + 10]
                user_refs = [get_db().collection(Collections.USERS).document(uid) for uid in batch_user_ids]
                user_docs = get_db().get_all(user_refs)

                for user_doc in user_docs:
                    if user_doc.exists:
                        user_data_map[user_doc.id] = user_doc.to_dict()

        # Enrichir les ratings avec les données utilisateur
        for rating_data in rating_data_list:
            user_id = rating_data.get(Fields.USER_ID)
            if user_id and user_id in user_data_map:
                user_data = user_data_map[user_id]
                rating_data["userName"] = user_data.get(Fields.NAME, "Anonymous").split()[0] if user_data.get(Fields.NAME) else "Anonymous"
                # userAvatar intentionally omitted — privacy: avatars not exposed to other users

            ratings.append(rating_data)

        next_cursor = docs[-1].id if has_more and docs else None

        return create_success_response(
            {Fields.RATINGS: ratings, "nextCursor": next_cursor, "hasMore": has_more, "totalFetched": len(ratings)}
        )

    except Exception as e:
        logger.error(f"ERROR: Failed to fetch ratings: {e}")
        raise https_fn.HttpsError("internal", "Failed to fetch ratings. Please try again.") from e


# =============================================================================
# WAREHOUSE CRUD — Seller shipping location management
# =============================================================================


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_warehouse(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Create a warehouse for the authenticated seller.
    Path: users/{sellerId}/warehouses/{warehouseId}
    """
    try:
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "Authentication required")

        seller_id = req.auth.uid
        data = req.data or {}

        label = (data.get("label") or "").strip()
        if not label or len(label) > 100:
            raise https_fn.HttpsError("invalid-argument", "label must be 1–100 characters")

        w_type = data.get("type", WarehouseTypeValues.WAREHOUSE)
        if w_type not in WarehouseTypeValues.ALL:
            raise https_fn.HttpsError("invalid-argument", f"type must be one of: {WarehouseTypeValues.ALL}")

        address = data.get("address")
        if not isinstance(address, dict) or not address.get(Fields.CITY):
            raise https_fn.HttpsError("invalid-argument", "address must include at least a city")

        # Geocode warehouse address to get lat/lon
        address = _geocode_warehouse_address(address)

        is_default = bool(data.get("isDefault", False))

        # If setting as default, clear any existing default
        if is_default:
            _clear_default_warehouse(seller_id)

        warehouse_doc = (
            get_db().collection(Collections.USERS).document(seller_id).collection(Collections.WAREHOUSES).document()
        )
        warehouse_doc.set(
            {
                "label": label,
                "type": w_type,
                "address": address,
                "isDefault": is_default,
                "createdAt": get_server_timestamp(),
            }
        )

        logger.info(f"Warehouse {warehouse_doc.id} created for seller {seller_id}")
        return create_success_response({"warehouseId": warehouse_doc.id})

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"Failed to create warehouse: {e}")
        raise https_fn.HttpsError("internal", "Failed to create warehouse") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_warehouse(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Update a warehouse label, type, address, or default status."""
    try:
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "Authentication required")

        seller_id = req.auth.uid
        data = req.data or {}

        warehouse_id = data.get("warehouseId", "").strip()
        if not warehouse_id:
            raise https_fn.HttpsError("invalid-argument", "warehouseId is required")

        # Verify ownership
        wh_ref = (
            get_db()
            .collection(Collections.USERS)
            .document(seller_id)
            .collection(Collections.WAREHOUSES)
            .document(warehouse_id)
        )
        wh_doc = wh_ref.get()
        if not wh_doc.exists:
            raise https_fn.HttpsError("not-found", "Warehouse not found")

        patches: dict = {}
        if "label" in data:
            label = data["label"].strip()
            if not label or len(label) > 100:
                raise https_fn.HttpsError("invalid-argument", "label must be 1–100 characters")
            patches["label"] = label

        if "type" in data:
            if data["type"] not in WarehouseTypeValues.ALL:
                raise https_fn.HttpsError("invalid-argument", f"type must be one of: {WarehouseTypeValues.ALL}")
            patches["type"] = data["type"]

        if "address" in data:
            if not isinstance(data["address"], dict) or not data["address"].get(Fields.CITY):
                raise https_fn.HttpsError("invalid-argument", "address must include at least a city")
            patches["address"] = _geocode_warehouse_address(data["address"])

        if "isDefault" in data:
            patches["isDefault"] = bool(data["isDefault"])
            if patches["isDefault"]:
                _clear_default_warehouse(seller_id, exclude_id=warehouse_id)

        if not patches:
            raise https_fn.HttpsError("invalid-argument", "No valid fields to update")

        wh_ref.update(patches)
        logger.info(f"Warehouse {warehouse_id} updated for seller {seller_id}: {list(patches.keys())}")
        return create_success_response({"warehouseId": warehouse_id})

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"Failed to update warehouse: {e}")
        raise https_fn.HttpsError("internal", "Failed to update warehouse") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def delete_warehouse(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Delete a warehouse. Blocked if any product still has stock in this warehouse
    or if in-flight orders reference it."""
    try:
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "Authentication required")

        seller_id = req.auth.uid
        data = req.data or {}

        warehouse_id = data.get("warehouseId", "").strip()
        if not warehouse_id:
            raise https_fn.HttpsError("invalid-argument", "warehouseId is required")

        wh_ref = (
            get_db()
            .collection(Collections.USERS)
            .document(seller_id)
            .collection(Collections.WAREHOUSES)
            .document(warehouse_id)
        )
        if not wh_ref.get().exists:
            raise https_fn.HttpsError("not-found", "Warehouse not found")

        # GUARD 1: Block if any product has stock > 0 in this warehouse
        products_with_wh = (
            get_db()
            .collection(Collections.PRODUCTS)
            .where(Fields.SELLER_ID, "==", seller_id)
            .where(Fields.WAREHOUSE_IDS, "array_contains", warehouse_id)
            .limit(50)
            .get()
        )
        for pdoc in products_with_wh:
            pdata = pdoc.to_dict() or {}
            # Check inventoryLevels subcollection for stock
            inv_doc = (
                get_db()
                .collection(Collections.PRODUCTS)
                .document(pdoc.id)
                .collection(Collections.INVENTORY_LEVELS)
                .document(warehouse_id)
                .get()
            )
            wh_stock = inv_doc.to_dict().get(Fields.AVAILABLE_QUANTITY, 0) if inv_doc.exists else 0
            if wh_stock > 0:
                raise https_fn.HttpsError(
                    "failed-precondition",
                    f"Cannot delete warehouse: product '{pdata.get(Fields.NAME, pdoc.id)}' still has {wh_stock} units in stock. Move or sell stock first.",
                )

        # GUARD 2: Block if in-flight orders reference this warehouse
        active_statuses = [
            OrderStatusValues.PENDING,
            OrderStatusValues.CONFIRMED,
            OrderStatusValues.PROCESSING,
            OrderStatusValues.SHIPPED,
        ]
        recent_orders = (
            get_db()
            .collection(Collections.ORDERS)
            .where(Fields.SELLER_IDS, "array_contains", seller_id)
            .where(Fields.ORDER_STATUS, "in", active_statuses)
            .limit(100)
            .get()
        )
        for odoc in recent_orders:
            odata = odoc.to_dict() or {}
            for oitem in odata.get(Fields.ITEMS, []):
                if oitem.get(Fields.FULFILLMENT_WAREHOUSE_ID) == warehouse_id:
                    raise https_fn.HttpsError(
                        "failed-precondition",
                        f"Cannot delete warehouse: order {odoc.id} has an in-flight item fulfilled from this warehouse.",
                    )

        # Delete the warehouse doc
        wh_ref.delete()

        # Cleanup: remove warehouse reference from products + delete inventoryLevels subdoc
        cleanup_batch = get_db().batch()
        count = 0
        for pdoc in products_with_wh:
            pdata = pdoc.to_dict() or {}
            p_ref = get_db().collection(Collections.PRODUCTS).document(pdoc.id)
            current_wh_ids = list(pdata.get(Fields.WAREHOUSE_IDS) or [])
            if warehouse_id in current_wh_ids:
                current_wh_ids.remove(warehouse_id)

            product_patch = {
                Fields.WAREHOUSE_IDS: current_wh_ids,
            }
            cleanup_batch.update(p_ref, product_patch)

            # Delete inventoryLevels/{warehouseId} subdoc
            inv_ref = p_ref.collection(Collections.INVENTORY_LEVELS).document(warehouse_id)
            cleanup_batch.delete(inv_ref)

            count += 1
            if count >= 450:
                cleanup_batch.commit()
                cleanup_batch = get_db().batch()
                count = 0

        if count > 0:
            cleanup_batch.commit()

        # Re-derive shipFrom* fields for affected products
        for pdoc in products_with_wh:
            try:
                pdata = pdoc.to_dict() or {}
                ship_from = _derive_ship_from_fields(seller_id, pdata)
                if ship_from:
                    get_db().collection(Collections.PRODUCTS).document(pdoc.id).update(ship_from)
            except Exception as e:
                logger.error(f"Failed to re-derive shipFrom for {pdoc.id}: {e}")

        logger.info(f"Warehouse {warehouse_id} deleted for seller {seller_id} (cleaned {len(products_with_wh)} products)")
        return create_success_response({"warehouseId": warehouse_id})

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"Failed to delete warehouse: {e}")
        raise https_fn.HttpsError("internal", "Failed to delete warehouse") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_seller_warehouses(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Return all warehouses for the authenticated seller, ordered by default first."""
    try:
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "Authentication required")

        seller_id = req.auth.uid
        docs = (
            get_db()
            .collection(Collections.USERS)
            .document(seller_id)
            .collection(Collections.WAREHOUSES)
            .order_by("isDefault", direction="DESCENDING")
            .order_by("createdAt", direction="ASCENDING")
            .get()
        )

        warehouses = []
        for doc in docs:
            d = doc.to_dict() or {}
            d["warehouseId"] = doc.id
            # Serialize timestamps
            created_at = d.get("createdAt")
            if hasattr(created_at, "isoformat"):
                d["createdAt"] = created_at.isoformat()
            warehouses.append(d)

        return create_success_response({"warehouses": warehouses})

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"Failed to fetch warehouses: {e}")
        raise https_fn.HttpsError("internal", "Failed to fetch warehouses") from e


def _clear_default_warehouse(seller_id: str, exclude_id: str | None = None) -> None:
    """Remove isDefault=True from all warehouses of a seller (except exclude_id)."""
    docs = (
        get_db()
        .collection(Collections.USERS)
        .document(seller_id)
        .collection(Collections.WAREHOUSES)
        .where("isDefault", "==", True)
        .get()
    )
    for doc in docs:
        if exclude_id and doc.id == exclude_id:
            continue
        doc.reference.update({"isDefault": False})


# ================================================================
# TASK 07 — BACK-IN-STOCK NOTIFICATIONS
# ================================================================


def _fire_back_in_stock_notifications(product_id: str, before_data: dict, after_data: dict) -> None:
    """Send back-in-stock emails to subscribers when stockQuantity transitions 0 → >0."""

    before_stock = before_data.get(Fields.STOCK_QUANTITY, 0)
    after_stock = after_data.get(Fields.STOCK_QUANTITY, 0)
    has_variants = after_data.get(Fields.HAS_VARIANTS, False)

    # For non-variant products: check top-level stock transition.
    # For variant products: we fire per-variant notifications when variants change.
    if not has_variants:
        if before_stock > 0 or after_stock <= 0:
            return
        if after_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
            return

    from services.email_service import send_email

    product_name = after_data.get(Fields.NAME, "A product you wanted")
    now_utc = datetime.now(UTC)

    if has_variants:
        # variants is a list[dict] — key by variantId for before/after comparison.
        before_variants_raw = before_data.get(Fields.VARIANTS) or []
        after_variants_raw = after_data.get(Fields.VARIANTS) or []
        before_by_id: dict[str, dict] = {
            v.get(Fields.VARIANT_ID, ""): v for v in before_variants_raw if isinstance(v, dict)
        }
        after_by_id: dict[str, dict] = {
            v.get(Fields.VARIANT_ID, ""): v for v in after_variants_raw if isinstance(v, dict)
        }
        restocked_keys: list[str] = [
            vk
            for vk, vdata in after_by_id.items()
            if (before_by_id.get(vk) or {}).get(Fields.STOCK_QUANTITY, 0) == 0
            and (vdata or {}).get(Fields.STOCK_QUANTITY, 0) > 0
            and vk
        ]
        if not restocked_keys:
            return
        if after_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
            return

        for variant_key in restocked_keys:
            subscriptions = (
                get_db()
                .collection(Collections.STOCK_NOTIFICATIONS)
                .where(Fields.PRODUCT_ID, "==", product_id)
                .where(Fields.VARIANT_KEY, "==", variant_key)
                .where(Fields.NOTIFIED_AT, "==", None)
                .limit(200)
                .stream()
            )
            variant_url = f"https://orignagta.ca/products/{product_id}?variant={variant_key}"
            for sub_doc in subscriptions:
                sub_data = sub_doc.to_dict() or {}
                email = sub_data.get(Fields.EMAIL)
                if not email:
                    continue
                subject = f"🎉 Back in stock: {product_name} — Origna"
                html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #5B30F6;">It's back! 🎉</h2>
  <p><strong>{product_name}</strong> (the variant you wanted) is back in stock on Origna.</p>
  <p style="margin-top:20px;">
    <a href="{variant_url}"
       style="background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;">
      Shop now
    </a>
  </p>
  <p style="color:#999; font-size:12px; margin-top:24px;">
    You requested this notification. If you no longer want back-in-stock emails,
    visit your <a href="https://orignagta.ca/settings/notifications" style="color:#999;">notification settings</a>.<br>
    Origna Ventures Inc.
  </p>
</div>"""
                try:
                    send_email(email, subject, html)
                    sub_doc.reference.update({Fields.NOTIFIED_AT: now_utc})
                except Exception as e:
                    logger.error(f"Failed to send back-in-stock email for sub {sub_doc.id}: {e}")
        return

    # Non-variant product: fire for subscribers without a variantKey.
    subscriptions = (
        get_db()
        .collection(Collections.STOCK_NOTIFICATIONS)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.NOTIFIED_AT, "==", None)
        .limit(200)
        .stream()
    )

    for sub_doc in subscriptions:
        sub_data = sub_doc.to_dict() or {}
        email = sub_data.get(Fields.EMAIL)
        if not email:
            continue
        subject = f"🎉 Back in stock: {product_name} — Origna"
        html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #5B30F6;">It's back! 🎉</h2>
  <p><strong>{product_name}</strong> is back in stock on Origna.</p>
  <p style="margin-top:20px;">
    <a href="https://orignagta.ca/products/{product_id}"
       style="background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;">
      Shop now
    </a>
  </p>
  <p style="color:#999; font-size:12px; margin-top:24px;">
    You requested this notification. If you no longer want back-in-stock emails,
    visit your <a href="https://orignagta.ca/settings/notifications" style="color:#999;">notification settings</a>.<br>
    Origna Ventures Inc.
  </p>
</div>"""
        try:
            send_email(email, subject, html)
            sub_doc.reference.update({Fields.NOTIFIED_AT: now_utc})
        except Exception as e:
            logger.error(f"Failed to send back-in-stock email for sub {sub_doc.id}: {e}")


@https_fn.on_call(**DEFAULT_OPTIONS)
def subscribe_stock_notification(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    TASK 07: Subscribe to back-in-stock notification for a product.

    Request data:
        productId: Product to watch

    Idempotent — re-subscribing after being notified creates a new subscription.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    product_id = data.get(Fields.PRODUCT_ID)
    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    # Verify product exists and is actually out of stock
    product_doc = get_db().collection(Collections.PRODUCTS).document(product_id).get()
    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")
    product_data = product_doc.to_dict() or {}

    # When a variantKey is provided, check that specific variant's stock instead
    # of top-level stockQuantity, which would be > 0 if other variants are in stock.
    variant_key = data.get(Fields.VARIANT_KEY)
    if variant_key and product_data.get(Fields.HAS_VARIANTS):
        variants = product_data.get(Fields.VARIANTS) or {}
        variant_data = variants.get(variant_key) or {}
        if variant_data.get(Fields.STOCK_QUANTITY, 0) > 0:
            raise https_fn.HttpsError("failed-precondition", "Variant is already in stock")
    elif product_data.get(Fields.STOCK_QUANTITY, 0) > 0:
        raise https_fn.HttpsError("failed-precondition", "Product is already in stock")

    # Fetch buyer email
    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_email = (user_doc.to_dict() or {}).get(Fields.EMAIL)
    if not user_email:
        raise https_fn.HttpsError("failed-precondition", "Account has no email")

    # Idempotency: skip if active subscription already exists for same product+variant
    existing_query = (
        get_db()
        .collection(Collections.STOCK_NOTIFICATIONS)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.USER_ID, "==", user_id)
        .where(Fields.NOTIFIED_AT, "==", None)
    )
    if variant_key:
        existing_query = existing_query.where(Fields.VARIANT_KEY, "==", variant_key)
    if list(existing_query.limit(1).stream()):
        return create_success_response({"alreadySubscribed": True})

    doc: dict[str, Any] = {
        Fields.PRODUCT_ID: product_id,
        Fields.USER_ID: user_id,
        Fields.EMAIL: user_email,
        Fields.NAME: product_data.get(Fields.NAME, ""),
        Fields.NOTIFIED_AT: None,
        Fields.CREATED_AT: get_server_timestamp(),
    }
    if variant_key:
        doc[Fields.VARIANT_KEY] = variant_key
    get_db().collection(Collections.STOCK_NOTIFICATIONS).add(doc)
    return create_success_response({"subscribed": True})


@https_fn.on_call(**DEFAULT_OPTIONS)
def unsubscribe_stock_notification(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    TASK 07: Unsubscribe from back-in-stock notification.

    Request data:
        productId: Product to stop watching
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    product_id = data.get(Fields.PRODUCT_ID)
    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    subscriptions = list(
        get_db()
        .collection(Collections.STOCK_NOTIFICATIONS)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.USER_ID, "==", user_id)
        .where(Fields.NOTIFIED_AT, "==", None)
        .limit(5)
        .stream()
    )
    for sub in subscriptions:
        sub.reference.delete()

    return create_success_response({"unsubscribed": True})


# ================================================================
# TASK 09 — PRODUCT Q&A
# ================================================================


@https_fn.on_call(**DEFAULT_OPTIONS)
def ask_product_question(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    TASK 09: Buyer submits a question about a product.

    Request data:
        productId: Product ID
        question: Question text (10-500 chars)
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # Premium gate must be enforced backend-side (authoritative subscriptions/{uid}).
    from utils.premium_check import is_premium_authoritative

    db = get_db()
    if not is_premium_authoritative(req.auth.uid, db=db):
        raise https_fn.HttpsError(
            "permission-denied",
            "Origna Premium required to ask questions. Upgrade to unlock Q&A, chat with sellers, and more.",
        )

    # S-02 FIX: Rate limit question submissions (max 5/hour per user)
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(db)
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid,
        action="ask_product_question",
        max_requests=5,
        window_minutes=60,
        fail_closed=False,
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Rate limit: max 5 questions per user per hour (Firestore count verification)
    one_hour_ago = datetime.now(UTC) - timedelta(hours=1)
    recent_questions = (
        db.collection(Collections.PRODUCT_QUESTIONS)
        .where(Fields.ASKER_ID, "==", req.auth.uid)
        .where(Fields.CREATED_AT, ">=", one_hour_ago)
        .count()
        .get()
    )
    count = recent_questions[0][0].value
    if count >= 5:
        raise https_fn.HttpsError("resource-exhausted", "Rate limit: max 5 questions per hour.")

    from utils.helpers import sanitized_text

    user_id = req.auth.uid
    data = req.data
    product_id = data.get(Fields.PRODUCT_ID)
    question_raw = data.get(Fields.QUESTION_TEXT, "")

    if not product_id or not question_raw:
        raise https_fn.HttpsError("invalid-argument", "productId and question required")

    question = sanitized_text(question_raw)[:500]
    if len(question) < 10:
        raise https_fn.HttpsError("invalid-argument", "Question must be at least 10 characters")

    product_doc = db.collection(Collections.PRODUCTS).document(product_id).get()
    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")
    product_data = product_doc.to_dict() or {}
    # S-03 FIX: Always derive sellerId from the actual product document (prevents spoofing)
    seller_id = product_data.get(Fields.SELLER_ID)

    question_ref = db.collection(Collections.PRODUCT_QUESTIONS).document()
    question_ref.set(
        {
            Fields.QUESTION_ID: question_ref.id,
            Fields.PRODUCT_ID: product_id,
            Fields.SELLER_ID: seller_id,
            Fields.ASKER_ID: user_id,
            Fields.QUESTION_TEXT: question,
            Fields.ANSWER_TEXT: None,
            Fields.ANSWERED_AT: None,
            Fields.ANSWERED_BY: None,
            Fields.IS_ANSWERED: False,
            Fields.UPVOTES: 0,
            Fields.CREATED_AT: datetime.now(UTC),
        }
    )

    # Email seller about new question
    try:
        from services.email_service import send_email

        seller_doc = db.collection(Collections.USERS).document(seller_id).get()
        if seller_doc.exists:
            seller_email = (seller_doc.to_dict() or {}).get(Fields.EMAIL)
            if seller_email:
                product_name = product_data.get(Fields.NAME, "your product")
                subject = f"[Origna] New question on {product_name}"
                html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #5B30F6;">New buyer question</h2>
  <p>A buyer asked a question about <strong>{product_name}</strong>:</p>
  <blockquote style="border-left:3px solid #5B30F6; padding-left:12px; color:#333; margin:16px 0;">
    {question}
  </blockquote>
  <p style="margin-top:20px;">
    <a href="https://orignagta.ca/seller/products/{product_id}/questions"
       style="background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;">
      Answer question
    </a>
  </p>
  <p style="color:#999; font-size:12px; margin-top:24px;">
    Answering buyer questions improves conversions and builds trust.
  </p>
</div>"""
                send_email(seller_email, subject, html)
    except Exception as e:
        logger.error(f"Failed to email seller about new question for product {product_id}: {e}")

    return create_success_response({Fields.QUESTION_ID: question_ref.id})


@https_fn.on_call(**DEFAULT_OPTIONS)
def answer_product_question(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    TASK 09: Seller (or admin) answers a product question.

    Request data:
        questionId: Question document ID
        answer: Answer text (10-2000 chars)
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    from utils.helpers import sanitized_text

    user_id = req.auth.uid
    token = req.auth.token or {}
    is_admin = token.get("admin") is True

    data = req.data
    question_id = data.get(Fields.QUESTION_ID)
    answer_raw = data.get(Fields.ANSWER_TEXT, "")

    if not question_id or not answer_raw:
        raise https_fn.HttpsError("invalid-argument", "questionId and answer required")

    answer = sanitized_text(answer_raw)[:2000]
    if len(answer) < 10:
        raise https_fn.HttpsError("invalid-argument", "Answer must be at least 10 characters")

    question_ref = get_db().collection(Collections.PRODUCT_QUESTIONS).document(question_id)
    question_doc = question_ref.get()
    if not question_doc.exists:
        raise https_fn.HttpsError("not-found", "Question not found")

    question_data = question_doc.to_dict() or {}
    seller_id = question_data.get(Fields.SELLER_ID)

    # Only product's seller or admin can answer
    if not is_admin and user_id != seller_id:
        raise https_fn.HttpsError("permission-denied", "Only the seller or an admin can answer this question")

    now_utc = datetime.now(UTC)
    question_ref.update(
        {
            Fields.ANSWER_TEXT: answer,
            Fields.ANSWERED_AT: now_utc,
            Fields.ANSWERED_BY: user_id,
            Fields.IS_ANSWERED: True,
        }
    )

    # Email asker about the answer
    try:
        from services.email_service import send_email

        asker_id = question_data.get(Fields.ASKER_ID)
        product_id = question_data.get(Fields.PRODUCT_ID)
        if asker_id:
            asker_doc = get_db().collection(Collections.USERS).document(asker_id).get()
            if asker_doc.exists:
                asker_email = (asker_doc.to_dict() or {}).get(Fields.EMAIL)
                product_name = ""
                if product_id:
                    pdoc = get_db().collection(Collections.PRODUCTS).document(product_id).get()
                    if pdoc.exists:
                        product_name = (pdoc.to_dict() or {}).get(Fields.NAME, "")
                if asker_email:
                    subject = "[Origna] Your question was answered"
                    html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #5B30F6;">Your question was answered!</h2>
  {"<p>About <strong>" + product_name + "</strong>:</p>" if product_name else ""}
  <p style="color:#555;"><strong>Your question:</strong></p>
  <blockquote style="border-left:3px solid #5B30F6; padding-left:12px; color:#333; margin:8px 0 16px;">
    {question_data.get(Fields.QUESTION_TEXT, "")}
  </blockquote>
  <p style="color:#555;"><strong>Answer:</strong></p>
  <blockquote style="border-left:3px solid #38A169; padding-left:12px; color:#333; margin:8px 0 16px;">
    {answer}
  </blockquote>
  {"<p><a href='https://orignagta.ca/products/" + product_id + "' style='background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;'>View product</a></p>" if product_id else ""}
  <p style="color:#999; font-size:12px; margin-top:24px;">Origna Ventures Inc.</p>
</div>"""
                    send_email(asker_email, subject, html)
    except Exception as e:
        logger.error(f"Failed to email asker about answer for question {question_id}: {e}")

    return create_success_response({"answered": True})


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_product_questions(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    TASK 09: Get paginated Q&A for a product.

    Request data:
        productId: Product ID
        limit: Max results (default 20, max 50)
        answeredOnly: If true, only return answered questions (default false)
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    data = req.data
    product_id = data.get(Fields.PRODUCT_ID)
    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    limit = min(int(data.get("limit", 20)), 50)
    answered_only = bool(data.get("answeredOnly", False))

    query = get_db().collection(Collections.PRODUCT_QUESTIONS).where(Fields.PRODUCT_ID, "==", product_id)
    if answered_only:
        query = query.where(Fields.IS_ANSWERED, "==", True)
    query = query.order_by(Fields.CREATED_AT, direction="DESCENDING").limit(limit)

    docs = list(query.stream())
    questions = []
    for doc in docs:
        d = doc.to_dict() or {}
        questions.append(
            {
                Fields.QUESTION_ID: doc.id,
                Fields.QUESTION_TEXT: d.get(Fields.QUESTION_TEXT, ""),
                Fields.ANSWER_TEXT: d.get(Fields.ANSWER_TEXT),
                Fields.ANSWERED_AT: d.get(Fields.ANSWERED_AT),
                Fields.IS_ANSWERED: d.get(Fields.IS_ANSWERED, False),
                Fields.UPVOTES: d.get(Fields.UPVOTES, 0),
                Fields.CREATED_AT: d.get(Fields.CREATED_AT),
            }
        )

    return create_success_response({"questions": questions, "total": len(questions)})


# =============================================================================
# N-03: SELLER REPLY TO REVIEWS
# =============================================================================

@https_fn.on_call(**DEFAULT_OPTIONS)
def answer_review(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    N-03: Seller replies to a product rating.

    Request data:
        ratingId: str — product_ratings document ID
        productId: str — product document ID (used for seller verification)
        reply: str — seller reply text (max 500 chars)

    Rules:
        - Only the seller of the product may reply.
        - Reply cannot be empty.
        - Seller can only reply once (sellerReply must not already exist).
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    from utils.helpers import sanitized_text
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="answer_review", max_requests=10, window_minutes=60, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data
    rating_id = data.get(Fields.RATING_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    reply_raw = data.get(Fields.SELLER_REPLY, "")

    if not rating_id or not product_id:
        raise https_fn.HttpsError("invalid-argument", "ratingId and productId required")
    if not reply_raw or not reply_raw.strip():
        raise https_fn.HttpsError("invalid-argument", "reply cannot be empty")

    reply = sanitized_text(reply_raw.strip())[:500]
    if len(reply) < 1:
        raise https_fn.HttpsError("invalid-argument", "reply cannot be empty after sanitization")
    if len(reply) > 500:
        raise https_fn.HttpsError("invalid-argument", "reply must be at most 500 characters")

    # Verify product exists and caller is its seller
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_doc = product_ref.get()
    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")
    product_data = product_doc.to_dict() or {}
    if product_data.get(Fields.SELLER_ID) != user_id:
        raise https_fn.HttpsError("permission-denied", "Only the product seller can reply to reviews")

    # Fetch the rating document
    rating_ref = get_db().collection(Collections.PRODUCT_RATINGS).document(rating_id)
    rating_doc = rating_ref.get()
    if not rating_doc.exists:
        raise https_fn.HttpsError("not-found", "Rating not found")
    rating_data = rating_doc.to_dict() or {}

    # Verify this rating belongs to this product
    if rating_data.get(Fields.PRODUCT_ID) != product_id:
        raise https_fn.HttpsError("invalid-argument", "Rating does not belong to the specified product")

    # Allow update within 24h of original reply; block after that
    existing_reply = rating_data.get(Fields.SELLER_REPLY)
    if existing_reply:
        replied_at = rating_data.get(Fields.SELLER_REPLY_AT)
        if replied_at is None:
            raise https_fn.HttpsError("already-exists", "Seller has already replied to this review")
        reply_age = datetime.now(UTC) - replied_at
        if reply_age.total_seconds() > 86400:  # 24 hours
            raise https_fn.HttpsError("already-exists", "Reply can only be edited within 24 hours")

    rating_ref.update({
        Fields.SELLER_REPLY: reply,
        Fields.SELLER_REPLY_AT: datetime.now(UTC),
    })

    return create_success_response({"replied": True})


# =============================================================================
# N-04: REVIEW HELPFULNESS VOTING
# =============================================================================

@https_fn.on_call(**DEFAULT_OPTIONS)
def vote_review_helpful(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    N-04: Vote a review as helpful (or remove vote).

    Votes are stored in `product_ratings/{ratingId}/review_votes/{userId}` to
    avoid the Firestore 1 MB document limit on an unbounded helpfulVoterIds array.

    Request data:
        ratingId: str — product_ratings document ID
        productId: str — product document ID
        helpful: bool — True = upvote, False = remove vote

    Rules:
        - User cannot vote on their own review.
        - User can only vote once per review.
        - helpful=False removes the vote (decrements helpfulCount).
        - helpfulCount never goes below 0.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    rating_id = data.get(Fields.RATING_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    helpful = data.get("helpful")

    if not rating_id or not product_id:
        raise https_fn.HttpsError("invalid-argument", "ratingId and productId required")
    if not isinstance(helpful, bool):
        raise https_fn.HttpsError("invalid-argument", "helpful must be a boolean")

    db = get_db()
    rating_ref = db.collection(Collections.PRODUCT_RATINGS).document(rating_id)
    vote_ref = rating_ref.collection(Collections.REVIEW_VOTES).document(user_id)

    _result: dict = {}
    _error: dict = {}

    def _vote_txn(transaction):
        rating_snap = rating_ref.get(transaction=transaction)
        if not rating_snap.exists:
            _error["err"] = https_fn.HttpsError("not-found", "Rating not found")
            return

        rating_data = rating_snap.to_dict() or {}

        if rating_data.get(Fields.PRODUCT_ID) != product_id:
            _error["err"] = https_fn.HttpsError("invalid-argument", "Rating does not belong to the specified product")
            return

        # Prevent self-voting
        reviewer_uid = rating_data.get(Fields.USER_ID) or rating_data.get("userId")
        if reviewer_uid == user_id:
            _error["err"] = https_fn.HttpsError("permission-denied", "Users cannot vote on their own reviews")
            return

        # Prevent sellers from voting on their own product's reviews
        product_snap = db.collection(Collections.PRODUCTS).document(product_id).get(transaction=transaction)
        if product_snap.exists and product_snap.to_dict().get(Fields.SELLER_ID) == user_id:
            _error["err"] = https_fn.HttpsError("permission-denied", "Sellers cannot vote on reviews for their own products")
            return

        vote_snap = vote_ref.get(transaction=transaction)
        already_voted = vote_snap.exists
        current_count: int = int(rating_data.get(Fields.HELPFUL_COUNT, 0))

        if helpful:
            if already_voted:
                _error["err"] = https_fn.HttpsError("already-exists", "already-voted")
                return
            transaction.set(vote_ref, {
                "isHelpful": True,
                Fields.CREATED_AT: get_server_timestamp(),
            })
            new_count = current_count + 1
        else:
            if not already_voted:
                _error["err"] = https_fn.HttpsError("failed-precondition", "No vote to remove")
                return
            transaction.delete(vote_ref)
            new_count = max(0, current_count - 1)

        transaction.update(rating_ref, {Fields.HELPFUL_COUNT: new_count})
        _result["helpfulCount"] = new_count

    try:
        from firebase_admin import firestore as _fs_admin
        txn = db.transaction()
        _fs_admin.transactional(_vote_txn)(txn)
    except Exception as e:
        logger.error(f"vote_review_helpful transaction failed for {rating_id}: {e}")
        raise https_fn.HttpsError("internal", "Failed to record vote") from e

    if "err" in _error:
        raise _error["err"]

    return create_success_response({"helpfulCount": _result.get("helpfulCount", 0)})


# =============================================================================
# N-06: PRICE HISTORY — INTERNAL HELPER
# =============================================================================

def _track_price_history(product_id: str, before_data: dict, after_data: dict) -> None:
    """
    N-06: Append a price history entry when price or compareAtPrice changes.
    Keeps the last 30 entries — trims the oldest if the array grows beyond that.

    NOTE: Uses datetime.now(UTC).isoformat() — NOT get_server_timestamp() —
    because server timestamps CANNOT be nested inside ArrayUnion payloads.
    """
    from firebase_admin.firestore import ArrayUnion

    before_price = before_data.get(Fields.PRICE)
    after_price = after_data.get(Fields.PRICE)
    before_compare = before_data.get(Fields.COMPARE_AT_PRICE)
    after_compare = after_data.get(Fields.COMPARE_AT_PRICE)

    if before_price == after_price and before_compare == after_compare:
        return  # No price change — nothing to record

    new_entry = {
        Fields.PRICE: after_price,
        Fields.COMPARE_AT_PRICE: after_compare,
        "changedAt": datetime.now(UTC).isoformat(),
    }

    # Fetch current priceHistory to enforce 30-entry limit
    prod_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    prod_snap = prod_ref.get()
    if not prod_snap.exists:
        return

    existing: list = list((prod_snap.to_dict() or {}).get(Fields.PRICE_HISTORY, []))
    existing.append(new_entry)

    if len(existing) > 30:
        # Trim oldest entries, keep last 30
        existing = existing[-30:]
        prod_ref.update({Fields.PRICE_HISTORY: existing})
    else:
        prod_ref.update({Fields.PRICE_HISTORY: ArrayUnion([new_entry])})

    logger.info(f"Price history recorded for product {product_id}: {before_price} -> {after_price}")


# =============================================================================
# N-08: BULK SELLER OPERATIONS
# =============================================================================

@https_fn.on_call(**DEFAULT_OPTIONS)
def bulk_update_products(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    N-08: Bulk update product status for a seller.

    Request data:
        productIds: list[str] — up to 50 product IDs
        action: str — one of "pause", "activate", "archive"

    Returns:
        {updated: N, skipped: M}

    Rules:
        - Caller must own ALL products (ownership verified per-product).
        - Non-owned products are skipped (not an error).
        - "activate" only succeeds if approvalStatus == "approved".
        - Enforces max 50 products per call.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    product_ids = data.get("productIds", [])
    action = data.get(Fields.ACTION, "")

    if not isinstance(product_ids, list) or len(product_ids) == 0:
        raise https_fn.HttpsError("invalid-argument", "productIds must be a non-empty list")
    if len(product_ids) > 50:
        raise https_fn.HttpsError("invalid-argument", "Maximum 50 products per bulk operation")

    VALID_ACTIONS = {"pause", "activate", "archive"}
    if action not in VALID_ACTIONS:
        raise https_fn.HttpsError("invalid-argument", f"action must be one of: {sorted(VALID_ACTIONS)}")

    # Deduplicate IDs (prevent duplicate operations in batch)
    product_ids = list(dict.fromkeys(product_ids))

    db = get_db()
    batch = db.batch()
    updated = 0
    skipped = 0
    activated_ids: list[str] = []

    # Fetch all product docs in a single RPC (avoid N+1 sequential gets)
    product_refs = [db.collection(Collections.PRODUCTS).document(pid) for pid in product_ids if isinstance(pid, str) and pid.strip()]
    product_snaps = db.get_all(product_refs) if product_refs else []
    snap_by_id = {snap.id: snap for snap in product_snaps}

    for pid in product_ids:
        if not isinstance(pid, str) or not pid.strip():
            skipped += 1
            continue

        prod_snap = snap_by_id.get(pid)

        if not prod_snap or not prod_snap.exists:
            skipped += 1
            continue

        prod_ref = db.collection(Collections.PRODUCTS).document(pid)
        prod_data = prod_snap.to_dict() or {}

        # Skip products not owned by caller
        if prod_data.get(Fields.SELLER_ID) != user_id:
            skipped += 1
            continue

        if action == "pause":
            batch.update(prod_ref, {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
                Fields.UPDATED_AT: datetime.now(UTC),
            })
            updated += 1

        elif action == "activate":
            # Only activate from PAUSED — APPROVED → ACTIVE is admin-only (approval flow)
            current_lifecycle = prod_data.get(Fields.LIFECYCLE_STATUS)
            if current_lifecycle not in {ProductLifecycleStatusValues.PAUSED}:
                skipped += 1
                continue
            batch.update(prod_ref, {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
                Fields.UPDATED_AT: datetime.now(UTC),
            })
            activated_ids.append(pid)
            updated += 1

        elif action == "archive":
            batch.update(prod_ref, {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ARCHIVED,
                Fields.UPDATED_AT: datetime.now(UTC),
            })
            updated += 1

    if updated > 0:
        batch.commit()
        logger.info(f"bulk_update_products: user={user_id} action={action} updated={updated} skipped={skipped}")
        # Re-index activated products in Algolia so they appear in search
        if activated_ids:
            for act_pid in activated_ids:
                try:
                    act_snap = snap_by_id.get(act_pid)
                    if act_snap and act_snap.exists:
                        act_data = act_snap.to_dict() or {}
                        act_data[Fields.LIFECYCLE_STATUS] = ProductLifecycleStatusValues.ACTIVE
                        algolia_partial_update(act_pid, {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE})
                except Exception as alg_err:
                    logger.error(f"bulk_update_products: Algolia re-index failed for {act_pid}: {alg_err}")

    return create_success_response({"updated": updated, "skipped": skipped})
