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
from typing import Any

import boto3
import requests
from botocore.config import Config
from firebase_functions import firestore_fn, https_fn

from config import (
    R2_ACCESS_KEY_NEW,
    R2_ACCOUNT_ID_NEW,
    R2_SECRET_KEY_NEW,
    R2Config,
    get_geoapify_api_key,
    get_r2_credentials,
)
from schema_constants import (
    AppConfig,
    CategoryIds,
    Collections,
    DeliveryTypeValues,
    Fields,
    OrderStatusValues,
    UserRoleValues,
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


@https_fn.on_call(secrets=[R2_ACCESS_KEY_NEW, R2_SECRET_KEY_NEW, R2_ACCOUNT_ID_NEW])
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

    # Sanitize review text to prevent XSS
    review = sanitized_text(review_raw)[:1000] if review_raw else ""  # Max 1000 chars

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
    get_db().collection(Collections.PRODUCT_RATINGS).add(
        {
            Fields.PRODUCT_ID: product_id,
            Fields.USER_ID: user_id,
            Fields.ORDER_ID: order_id,
            Fields.RATING: rating,
            Fields.REVIEW: review,
            Fields.CREATED_AT: get_server_timestamp(),
        }
    )

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
                        Fields.DEACTIVATION_REASON: "Seller is suspended",
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
                Fields.DEACTIVATION_REASON: f"Invalid stock: {stock}",
            }
        )
        return

    # Seller address validation — verify address exists via Geoapify geocoding
    seller_address = product_data.get(Fields.SELLER_ADDRESS, {})
    country = seller_address.get(Fields.COUNTRY) or ""
    if not country:
        logger.info(f"SECURITY: Product {product_id} has empty seller country — deactivating")
        get_db().collection(Collections.PRODUCTS).document(product_id).update(
            {
                Fields.IS_ACTIVE: False,
                Fields.DEACTIVATION_REASON: "Missing seller country",
            }
        )
        return

    # SECURITY: Validate address coordinates via Geoapify reverse geocoding
    # Ensures the seller address is a real, verified location
    seller_lat = seller_address.get(Fields.LATITUDE)
    seller_lon = seller_address.get(Fields.LONGITUDE)
    seller_street = seller_address.get(Fields.STREET, "")
    seller_city = seller_address.get(Fields.CITY, "")
    seller_postal = seller_address.get(Fields.POSTAL_CODE, "")

    # Skip digital products (no physical address needed)
    is_digital = product_data.get(Fields.IS_DIGITAL, False)

    if not is_digital:
        # Require lat/lng from frontend Geoapify autocomplete
        if seller_lat is None or seller_lon is None:
            logger.info(f"SECURITY: Product {product_id} missing lat/lng — address not verified via Geoapify — REJECTING")
            get_db().collection(Collections.PRODUCTS).document(product_id).update(
                {
                    Fields.IS_ACTIVE: False,
                    Fields.DEACTIVATION_REASON: "Address not verified via Geoapify (missing coordinates)",
                }
            )
            return
        else:
            # Verify coordinates match the declared address via Geoapify reverse geocoding
            is_valid, error_reason = _verify_address_with_geoapify(
                product_id, seller_lat, seller_lon,
                seller_street, seller_city, seller_postal, country,
            )
            if not is_valid:
                logger.info(f"SECURITY: Product {product_id} failed address verification: {error_reason} — REJECTING")
                get_db().collection(Collections.PRODUCTS).document(product_id).update(
                    {
                        Fields.IS_ACTIVE: False,
                        Fields.DEACTIVATION_REASON: f"Address verification failed: {error_reason}",
                    }
                )
                return

    # CRITICAL: Sanitize text fields to prevent stored XSS
    xss_patches = {}
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

    try:
        # Add document ID to product data
        product_data["id"] = product_id
        # Ensure sanitized data is sent to Algolia
        if Fields.NAME in product_data:
            product_data[Fields.NAME] = sanitized_text(product_data[Fields.NAME])
        if Fields.DESCRIPTION in product_data:
            product_data[Fields.DESCRIPTION] = sanitized_text(product_data[Fields.DESCRIPTION])
        index_product(product_id, product_data)
        logger.info(f"Product {product_id} indexed to Algolia")
    except Exception as e:
        logger.error(f"Failed to index product {product_id}: {str(e)}")


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
    }
    _address_changed = False
    if before_data:
        changed_fields = {
            key for key in set(list(product_data.keys()) + list(before_data.keys()))
            if product_data.get(key) != before_data.get(key)
        }
        if changed_fields and changed_fields.issubset(_SKIP_VALIDATION_FIELDS):
            # Non-security-relevant update — just re-index and return
            if product_data.get(Fields.IS_ACTIVE, True):
                try:
                    product_data["id"] = product_id
                    index_product(product_id, product_data)
                except Exception as e:
                    logger.error(f"Failed to index product {product_id} after metadata update: {str(e)}")
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
        index_product(product_id, product_data)
        logger.info(f"Product {product_id} updated in Algolia")
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
