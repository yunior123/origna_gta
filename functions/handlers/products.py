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
from datetime import datetime
from typing import Any

import boto3
import requests
from botocore.config import Config
from firebase_functions import firestore_fn, https_fn

from config import (
    R2_ACCESS_KEY_PARAM,
    R2_ACCOUNT_ID_PARAM,
    R2_SECRET_KEY_PARAM,
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
    ProductStatusValues,
    UserRoleValues,
    WarehouseTypeValues,
)
from services.algolia_service import delete_product as algolia_delete_product
from services.algolia_service import index_product
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


@https_fn.on_call(secrets=[R2_ACCESS_KEY_PARAM, R2_SECRET_KEY_PARAM, R2_ACCOUNT_ID_PARAM])
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


@https_fn.on_call(secrets=[R2_ACCESS_KEY_PARAM, R2_SECRET_KEY_PARAM, R2_ACCOUNT_ID_PARAM])
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
            upload_urls.append({"uploadUrl": presigned_url, "publicUrl": public_url, "fileName": file_name, "key": unique_key})

        return create_success_response({"uploadUrls": upload_urls})

    except Exception as e:
        logger.error(f"ERROR: Failed to generate review upload URLs: {e}")
        raise https_fn.HttpsError("internal", "Failed to generate upload URLs. Please try again.") from e



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
    product_ref.update({Fields.IS_ACTIVE: False, Fields.DELETED_AT: get_server_timestamp(), Fields.DELETED_BY: user_id})

    # Remove from Algolia index
    try:
        algolia_delete_product(product_id)
    except Exception as e:
        logger.error(f"Failed to delete from Algolia: {str(e)}")

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

    # TASK 06: Validate reviewImageUrls — max 3, must be from CDN
    if review_image_urls_raw:
        if not isinstance(review_image_urls_raw, list):
            raise https_fn.HttpsError("invalid-argument", "reviewImageUrls must be a list")
        if len(review_image_urls_raw) > 3:
            raise https_fn.HttpsError("invalid-argument", "Maximum 3 review images allowed")
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

    if order_data[Fields.USER_ID] != user_id:
        raise https_fn.HttpsError("permission-denied", "This is not your order")

    if order_data[Fields.ORDER_STATUS] != OrderStatusValues.DELIVERED:
        raise https_fn.HttpsError("failed-precondition", "Can only rate delivered orders")

    # Check if product is in order
    product_in_order = any(item[Fields.PRODUCT_ID] == product_id for item in order_data[Fields.ITEMS])

    if not product_in_order:
        raise https_fn.HttpsError("invalid-argument", "Product not in this order")

    # Check if user already rated this product with lazy loading
    existing_ratings_query = (
        get_db()
        .collection(Collections.PRODUCT_RATINGS)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.USER_ID, "==", user_id)
        .limit(1)
    )

    existing_ratings = list(existing_ratings_query.stream())

    if existing_ratings:
        raise https_fn.HttpsError("already-exists", "You have already rated this product")

    # Save rating
    rating_doc: dict = {
        Fields.PRODUCT_ID: product_id,
        Fields.USER_ID: user_id,
        Fields.ORDER_ID: order_id,
        Fields.RATING: rating,
        Fields.REVIEW: review,
        Fields.CREATED_AT: get_server_timestamp(),
    }
    if review_image_urls:
        rating_doc[Fields.REVIEW_IMAGE_URLS] = review_image_urls
    get_db().collection(Collections.PRODUCT_RATINGS).add(rating_doc)

    # Update product's average rating using transaction (atomic, prevents race conditions)
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)

    @_firestore.transactional
    def update_rating_transaction(transaction):
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

        transaction.update(product_ref, {Fields.RATING: new_average, Fields.RATING_COUNT: new_rating_count})
        return new_average, new_rating_count

    transaction = get_db().transaction()
    new_average, new_rating_count = update_rating_transaction(transaction)

    if new_average is not None:
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
        url = (
            f"https://api.geoapify.com/v1/geocode/reverse"
            f"?lat={lat}&lon={lon}&apiKey={geo_key}"
        )
        response = requests.get(url, timeout=AppConfig.GEOAPIFY_TIMEOUT_SECONDS)
        if response.status_code != 200:
            return False, f"Address verification failed (HTTP {response.status_code})"

        data = response.json()
        features = data.get("features", [])
        if not features:
            return (
                False,
                f"Address verification returned no results — coordinates ({lat}, {lon}) may be invalid"
            )

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

    # Only index active products
    if not product_data.get(Fields.IS_ACTIVE, True):
        logger.info(f"Product {product_id} is not active, skipping indexing")
        return

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
                        Fields.IS_ACTIVE: False,
                        Fields.STATUS: ProductStatusValues.DRAFT,
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
            .where(Fields.IS_ACTIVE, "!=", False)
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
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.DRAFT,
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
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.DRAFT,
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
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.DRAFT,
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
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.DRAFT,
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
            logger.info(f"SECURITY: Product {product_id} missing lat/lng — address not verified via Geoapify — REJECTING")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.DRAFT,
                    Fields.DEACTIVATION_REASON: "Address not verified via Geoapify (missing coordinates)",
                }
            )
            return
        else:
            is_valid, error_reason = _verify_address_with_geoapify(
                product_id, seller_lat, seller_lon,
                seller_street, seller_city, seller_postal, country,
            )
            if not is_valid:
                logger.info(f"SECURITY: Product {product_id} failed address verification: {error_reason} — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.IS_ACTIVE: False,
                        Fields.STATUS: ProductStatusValues.DRAFT,
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
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.DRAFT,
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
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.DRAFT,
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
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.DRAFT,
                    Fields.DEACTIVATION_REASON: f"Digital download URLs must use HTTPS: {', '.join(bad_urls)}",
                    Fields.APPROVAL_STATUS: ProductApprovalStatusValues.REJECTED,
                    Fields.APPROVAL_REJECTION_REASON: f"Download URLs must use HTTPS: {', '.join(bad_urls)}",
                }
            )
            return

    # ── ADMIN APPROVAL GATE: All products land in under_review ──
    # Products are NOT indexed to Algolia until an admin explicitly approves them.
    # The admin_approve_product callable sets isActive=True and triggers indexing.
    try:
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.DRAFT,
                Fields.APPROVAL_STATUS: ProductApprovalStatusValues.UNDER_REVIEW,
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

def _compute_is_active(status: str, approval_status: str) -> bool:
    """Single source of truth: isActive = status=='active' AND approvalStatus=='approved'.

    This invariant must be enforced at every product write path.
    """
    return (
        status == ProductStatusValues.ACTIVE
        and approval_status == ProductApprovalStatusValues.APPROVED
    )


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
        get_db()
        .collection(Collections.USERS)
        .where(Fields.ROLES, "array-contains", UserRoleValues.ADMIN)
        .get()
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
                    Fields.APPROVAL_STATUS: ProductApprovalStatusValues.REJECTED,
                    Fields.APPROVAL_REJECTION_REASON: reason,
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.PAUSED,
                }
            )
            if seller_email:
                _send_product_rejection_email(seller_email, product_data.get(Fields.NAME, ""), reason)
            return create_success_response(
                {"approved": False, "rejected": True, "reason": reason},
                message=f"Product auto-rejected: {reason}",
            )

    # Approve — STATUS must be set to 'active' atomically with IS_ACTIVE=True
    product_ref.update(
        {
            Fields.APPROVAL_STATUS: ProductApprovalStatusValues.APPROVED,
            Fields.APPROVAL_REJECTION_REASON: None,
            Fields.IS_ACTIVE: _compute_is_active(ProductStatusValues.ACTIVE, ProductApprovalStatusValues.APPROVED),
            Fields.STATUS: ProductStatusValues.ACTIVE,
        }
    )

    # Index to Algolia now that it's approved
    try:
        product_data.update(
            {
                "id": product_id,
                Fields.IS_ACTIVE: True,
                Fields.APPROVAL_STATUS: ProductApprovalStatusValues.APPROVED,
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
            Fields.APPROVAL_STATUS: ProductApprovalStatusValues.REJECTED,
            Fields.APPROVAL_REJECTION_REASON: reason,
            Fields.IS_ACTIVE: False,
            Fields.STATUS: ProductStatusValues.PAUSED,
        }
    )

    # Remove from Algolia if it was previously approved
    try:
        algolia_delete_product(product_id)
    except Exception:
        pass

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

    # If product is inactive, delete from index
    if not product_data.get(Fields.IS_ACTIVE, True):
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
        Fields.STOCK_QUANTITY, Fields.UPDATED_AT, Fields.STOCK_RESTORED,
        Fields.IS_ACTIVE, Fields.DEACTIVATION_REASON,
        Fields.APPROVAL_STATUS, Fields.APPROVAL_REJECTION_REASON,
        Fields.STATUS,  # seller pause/unpause — synced via _compute_is_active below
    }
    _address_changed = False
    if before_data:
        changed_fields = {
            key for key in set(list(product_data.keys()) + list(before_data.keys()))
            if product_data.get(key) != before_data.get(key)
        }

        # ── RESUBMIT: Seller edited a rejected product — reset to under_review ──
        _SELLER_EDITABLE_FIELDS = {
            Fields.NAME, Fields.DESCRIPTION, Fields.PRICE, Fields.IMAGE_URLS,
            Fields.CATEGORY_ID, Fields.KEYWORDS, Fields.DIGITAL_BUILDS,
            Fields.BOOK_SOURCE_URL, Fields.STOCK_QUANTITY, Fields.DIGITAL_TYPE,
        }
        before_approval = before_data.get(Fields.APPROVAL_STATUS)
        after_approval = product_data.get(Fields.APPROVAL_STATUS)
        if (
            before_approval == ProductApprovalStatusValues.REJECTED
            and after_approval == ProductApprovalStatusValues.REJECTED
            and changed_fields & _SELLER_EDITABLE_FIELDS
        ):
            logger.info(f"Product {product_id}: rejected product edited by seller — resetting to under_review")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.APPROVAL_STATUS: ProductApprovalStatusValues.UNDER_REVIEW,
                    Fields.APPROVAL_REJECTION_REASON: None,
                    Fields.IS_ACTIVE: False,
                    Fields.STATUS: ProductStatusValues.PAUSED,
                }
            )
            # Notify admins of the resubmission
            try:
                _notify_admins_new_product(product_id, product_data)
            except Exception as e:
                logger.error(f"Failed to notify admins of resubmission for {product_id}: {e}")
            return

        if changed_fields and changed_fields.issubset(_SKIP_VALIDATION_FIELDS):
            # Non-security-relevant update — sync IS_ACTIVE from STATUS+APPROVAL_STATUS, then re-index
            current_status = product_data.get(Fields.STATUS, ProductStatusValues.DRAFT)
            current_approval = product_data.get(Fields.APPROVAL_STATUS, ProductApprovalStatusValues.UNDER_REVIEW)
            correct_is_active = _compute_is_active(current_status, current_approval)
            if product_data.get(Fields.IS_ACTIVE) != correct_is_active:
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {Fields.IS_ACTIVE: correct_is_active}
                )
                product_data[Fields.IS_ACTIVE] = correct_is_active
            if correct_is_active:
                try:
                    product_data["id"] = product_id
                    index_product(product_id, product_data)
                except Exception as e:
                    logger.error(f"Failed to index product {product_id} after metadata update: {str(e)}")

            # TASK 07: Fire back-in-stock notifications when stockQuantity 0→>0
            try:
                _fire_back_in_stock_notifications(product_id, before_data, product_data)
            except Exception as e:
                logger.error(f"Back-in-stock notification error for {product_id}: {e}")

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
                        Fields.IS_ACTIVE: False,
                        Fields.STATUS: ProductStatusValues.PAUSED,
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
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.PAUSED,
            }
        )
        return

    # Validate stock quantity >= 0
    stock = product_data.get(Fields.STOCK_QUANTITY, 0)
    if not isinstance(stock, (int, float)) or stock < 0:
        logger.info(f"SECURITY: Product {product_id} updated with invalid stock ({stock}) — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.PAUSED,
            }
        )
        return

    # Seller address validation — verify address exists via Geoapify geocoding
    seller_address = product_data.get(Fields.SELLER_ADDRESS, {})
    country = seller_address.get(Fields.COUNTRY) or ""
    if not country:
        logger.info(f"SECURITY: Product {product_id} updated with empty seller country — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.IS_ACTIVE: False,
                Fields.STATUS: ProductStatusValues.PAUSED,
            }
        )
        return

    # SECURITY: Validate address coordinates on updates — only if address actually changed
    # Skip geocoding re-validation if the sellerAddress is unchanged from the previous version.
    # Products are fully validated at creation time; re-validating on every stock/metadata update
    # is wasteful and can deactivate products due to transient geocoding API failures.
    if _address_changed:
        seller_lat = seller_address.get(Fields.LATITUDE)
        seller_lon = seller_address.get(Fields.LONGITUDE)
        seller_street = seller_address.get(Fields.STREET, "")
        seller_city = seller_address.get(Fields.CITY, "")
        seller_postal = seller_address.get(Fields.POSTAL_CODE, "")
        is_digital = product_data.get(Fields.IS_DIGITAL, False)

        if not is_digital:
            if seller_lat is None or seller_lon is None:
                logger.info(f"SECURITY: Product {product_id} updated with missing coordinates — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.IS_ACTIVE: False,
                        Fields.STATUS: ProductStatusValues.PAUSED,
                        Fields.DEACTIVATION_REASON: "Address not verified via Geoapify (missing coordinates)",
                    }
                )
                return

            is_valid, error_reason = _verify_address_with_geoapify(
                product_id, seller_lat, seller_lon,
                seller_street, seller_city, seller_postal, country,
            )
            if not is_valid:
                logger.info(f"SECURITY: Product {product_id} updated with invalid address: {error_reason} — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.IS_ACTIVE: False,
                        Fields.STATUS: ProductStatusValues.PAUSED,
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

    try:
        product_data["id"] = product_id
        # Only index if product is approved — prevents bypassing the approval gate
        approval_status = product_data.get(Fields.APPROVAL_STATUS, ProductApprovalStatusValues.UNDER_REVIEW)
        if approval_status == ProductApprovalStatusValues.APPROVED and product_data.get(Fields.IS_ACTIVE, True):
            index_product(product_id, product_data)
            logger.info(f"Product {product_id} updated in Algolia")
        else:
            logger.info(f"Product {product_id} not indexed — approvalStatus={approval_status}")
    except Exception as e:
        logger.error(f"Failed to update product {product_id} in Algolia: {str(e)}") 


@firestore_fn.on_document_deleted(document="products/{productId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_product_deleted(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Removes product from Algolia when deleted.
    """
    product_id = event.params[Fields.PRODUCT_ID]

    try:
        algolia_delete_product(product_id)
        logger.info(f"Product {product_id} deleted from Algolia")
    except Exception as e:
        logger.error(f"Failed to delete product {product_id} from Algolia: {str(e)}")


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

    # SECURITY FIX #14: Force isActive=True for public API — only admins can list inactive products
    # Prevents client-side bypass where isActive=false exposes deleted/hidden products
    is_admin = False
    if req.auth:
        user_doc = get_db().collection(Collections.USERS).document(req.auth.uid).get()
        if user_doc.exists:
            roles = user_doc.to_dict().get(Fields.ROLES, [])
            is_admin = UserRoleValues.ADMIN in roles

    is_active = True  # Public always sees active products only
    if is_admin:
        # Admins can optionally filter by isActive
        is_active = data.get(Fields.IS_ACTIVE, True)

    # Validation
    if order_by not in [Fields.CREATED_AT, Fields.PRICE, Fields.RATING, Fields.RATING_COUNT, Fields.NAME]:
        raise https_fn.HttpsError("invalid-argument", "Invalid orderBy field")

    if order_direction not in ["asc", "desc"]:
        raise https_fn.HttpsError("invalid-argument", "orderDirection must be asc or desc")

    try:
        # Construction de la requête de base
        query = get_db().collection(Collections.PRODUCTS)

        # Filtres
        if is_active is not None:
            query = query.where(Fields.IS_ACTIVE, "==", is_active)

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
            query = query.where(Fields.IS_ACTIVE, "==", True)

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
                rating_data["userName"] = user_data.get(Fields.NAME, "Anonymous")
                rating_data["userAvatar"] = user_data.get("profilePictureUrl")

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

        is_default = bool(data.get("isDefault", False))

        # If setting as default, clear any existing default
        if is_default:
            _clear_default_warehouse(seller_id)

        from datetime import UTC
        warehouse_doc = get_db().collection(Collections.USERS).document(seller_id).collection(Collections.WAREHOUSES).document()
        warehouse_doc.set({
            "label": label,
            "type": w_type,
            "address": address,
            "isDefault": is_default,
            "createdAt": get_server_timestamp(),
        })

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
        wh_ref = get_db().collection(Collections.USERS).document(seller_id).collection(Collections.WAREHOUSES).document(warehouse_id)
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
            patches["address"] = data["address"]

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
    """Delete a warehouse. Products referencing it will retain the ID but lose that location."""
    try:
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "Authentication required")

        seller_id = req.auth.uid
        data = req.data or {}

        warehouse_id = data.get("warehouseId", "").strip()
        if not warehouse_id:
            raise https_fn.HttpsError("invalid-argument", "warehouseId is required")

        wh_ref = get_db().collection(Collections.USERS).document(seller_id).collection(Collections.WAREHOUSES).document(warehouse_id)
        if not wh_ref.get().exists:
            raise https_fn.HttpsError("not-found", "Warehouse not found")

        wh_ref.delete()
        logger.info(f"Warehouse {warehouse_id} deleted for seller {seller_id}")
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
    from datetime import timezone

    before_stock = before_data.get(Fields.STOCK_QUANTITY, 0)
    after_stock = after_data.get(Fields.STOCK_QUANTITY, 0)

    # Only trigger on 0→>0 transition on active products
    if before_stock > 0 or after_stock <= 0:
        return
    if not after_data.get(Fields.IS_ACTIVE):
        return

    from services.email_service import send_email

    product_name = after_data.get(Fields.NAME, "A product you wanted")
    now_utc = datetime.now(timezone.utc)

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
    if product_data.get(Fields.STOCK_QUANTITY, 0) > 0:
        raise https_fn.HttpsError("failed-precondition", "Product is already in stock")

    # Fetch buyer email
    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_email = (user_doc.to_dict() or {}).get(Fields.EMAIL)
    if not user_email:
        raise https_fn.HttpsError("failed-precondition", "Account has no email")

    # Idempotency: skip if active subscription already exists
    existing = list(
        get_db()
        .collection(Collections.STOCK_NOTIFICATIONS)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.USER_ID, "==", user_id)
        .where(Fields.NOTIFIED_AT, "==", None)
        .limit(1)
        .stream()
    )
    if existing:
        return create_success_response({"alreadySubscribed": True})

    from datetime import timezone
    get_db().collection(Collections.STOCK_NOTIFICATIONS).add({
        Fields.PRODUCT_ID: product_id,
        Fields.USER_ID: user_id,
        Fields.EMAIL: user_email,
        Fields.NAME: product_data.get(Fields.NAME, ""),
        Fields.NOTIFIED_AT: None,
        Fields.CREATED_AT: datetime.now(timezone.utc),
    })
    return create_success_response({"subscribed": True})


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

def ask_product_question(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    TASK 09: Buyer submits a question about a product.

    Request data:
        productId: Product ID
        question: Question text (10-500 chars)
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    from utils.helpers import sanitized_text
    from datetime import timezone

    user_id = req.auth.uid
    data = req.data
    product_id = data.get(Fields.PRODUCT_ID)
    question_raw = data.get(Fields.QUESTION_TEXT, "")

    if not product_id or not question_raw:
        raise https_fn.HttpsError("invalid-argument", "productId and question required")

    question = sanitized_text(question_raw)[:500]
    if len(question) < 10:
        raise https_fn.HttpsError("invalid-argument", "Question must be at least 10 characters")

    product_doc = get_db().collection(Collections.PRODUCTS).document(product_id).get()
    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")
    product_data = product_doc.to_dict() or {}
    seller_id = product_data.get(Fields.SELLER_ID)

    question_ref = get_db().collection(Collections.PRODUCT_QUESTIONS).document()
    question_ref.set({
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
        Fields.CREATED_AT: datetime.now(timezone.utc),
    })

    # Email seller about new question
    try:
        from services.email_service import send_email
        seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
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
    from datetime import timezone

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

    now_utc = datetime.now(timezone.utc)
    question_ref.update({
        Fields.ANSWER_TEXT: answer,
        Fields.ANSWERED_AT: now_utc,
        Fields.ANSWERED_BY: user_id,
        Fields.IS_ANSWERED: True,
    })

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
                    subject = f"[Origna] Your question was answered"
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

    query = (
        get_db()
        .collection(Collections.PRODUCT_QUESTIONS)
        .where(Fields.PRODUCT_ID, "==", product_id)
    )
    if answered_only:
        query = query.where(Fields.IS_ANSWERED, "==", True)
    query = query.order_by(Fields.CREATED_AT, direction="DESCENDING").limit(limit)

    docs = list(query.stream())
    questions = []
    for doc in docs:
        d = doc.to_dict() or {}
        questions.append({
            Fields.QUESTION_ID: doc.id,
            Fields.QUESTION_TEXT: d.get(Fields.QUESTION_TEXT, ""),
            Fields.ANSWER_TEXT: d.get(Fields.ANSWER_TEXT),
            Fields.ANSWERED_AT: d.get(Fields.ANSWERED_AT),
            Fields.IS_ANSWERED: d.get(Fields.IS_ANSWERED, False),
            Fields.UPVOTES: d.get(Fields.UPVOTES, 0),
            Fields.CREATED_AT: d.get(Fields.CREATED_AT),
        })

    return create_success_response({"questions": questions, "total": len(questions)})
