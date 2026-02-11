"""
Product Management Handlers
- Product CRUD operations
- Algolia indexing (Firestore triggers)
- Image upload to Cloudflare R2
- Product deletion with validation
- Rating submission
"""

import uuid
from typing import Any

import boto3
from botocore.config import Config
from firebase_functions import firestore_fn, https_fn, options

from config import R2_ACCESS_KEY_NEW, R2_ACCOUNT_ID_NEW, R2_SECRET_KEY_NEW, R2Config, get_r2_credentials
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
from utils.function_options import DEFAULT_OPTIONS
from utils.helpers import create_success_response

# Constants
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100
CDN_BASE_URL = "https://cdn.origna.ca"

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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid

    # SECURITY: Verify seller onboarding is complete before allowing uploads
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    user_data = user_doc.to_dict()
    if user_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError('permission-denied', 'Your account is suspended')
    if UserRoleValues.SELLER not in user_data.get(Fields.ROLES, []) and UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError('permission-denied', 'Seller role required')
    if not user_data.get(Fields.ONBOARDING_COMPLETED, False) and UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError('failed-precondition', 'Please complete seller onboarding before uploading products')

    # AUDIT FIX: Rate limit image uploads
    from services.rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action='upload_images',
        max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    data = req.data
    file_names_raw = data.get('fileNames', [])
    content_types = data.get('contentTypes', [])

    # Import validation functions
    from utils.helpers import sanitize_path

    if not file_names_raw or len(file_names_raw) == 0:
        raise https_fn.HttpsError('invalid-argument', 'No files specified')

    if len(file_names_raw) > 5:
        raise https_fn.HttpsError('invalid-argument', 'Maximum 5 images allowed')

    if len(file_names_raw) != len(content_types):
        raise https_fn.HttpsError('invalid-argument', 'File names and content types count mismatch')

    # SECURITY: Validate MIME types against whitelist (prevent non-image uploads to CDN)
    ALLOWED_MIME_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'}
    for ct in content_types:
        if ct not in ALLOWED_MIME_TYPES:
            raise https_fn.HttpsError(
                'invalid-argument',
                f"Invalid content type '{ct}'. Allowed: {', '.join(sorted(ALLOWED_MIME_TYPES))}"
            )

    # Sanitize file names to prevent path traversal
    file_names = [sanitize_path(fn) for fn in file_names_raw]

    # SECURITY: Validate file extensions against whitelist
    ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp', 'gif'}
    for fn in file_names:
        ext = fn.rsplit('.', 1)[-1].lower() if '.' in fn else ''
        if ext not in ALLOWED_EXTENSIONS:
            raise https_fn.HttpsError(
                'invalid-argument',
                f"Invalid file extension '.{ext}'. Allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
            )

    # Get R2 credentials based on environment
    r2_creds = get_r2_credentials()
    r2_access_key = r2_creds.get("access_key")
    r2_secret_key = r2_creds.get("secret_key")
    r2_account_id = r2_creds.get("account_id")

    if not all([r2_access_key, r2_secret_key, r2_account_id]):
        raise https_fn.HttpsError('failed-precondition', 'R2 credentials not configured')

    # Initialize R2 client (S3-compatible)
    s3_client = boto3.client(
        's3',
        endpoint_url=f'https://{r2_account_id}.r2.cloudflarestorage.com',
        aws_access_key_id=r2_access_key,
        aws_secret_access_key=r2_secret_key,
        config=Config(signature_version='s3v4'),
        region_name='auto'
    )

    bucket_name = R2Config.BUCKET_NAME
    upload_urls = []

    try:
        for file_name, content_type in zip(file_names, content_types, strict=False):
            # Generate unique key with environment-aware path
            file_extension = file_name.split('.')[-1]
            unique_key = R2Config.get_image_path('products', f'{uuid.uuid4()}.{file_extension}')

            # Generate presigned URL for upload
            # NOTE: ContentLength removed — it enforces EXACT size, not max.
            # Size limit enforced by Cloudflare R2 bucket-level configuration.
            presigned_url = s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': unique_key,
                    'ContentType': content_type,
                    # SECURITY: Force inline display — prevents download-triggered XSS
                    'ContentDisposition': 'inline',
                },
                ExpiresIn=3600  # 1 hour
            )

            public_url = f'{CDN_BASE_URL}/{unique_key}'

            upload_urls.append({
                'uploadUrl': presigned_url,
                'publicUrl': public_url,
                'fileName': file_name,
                'key': unique_key
            })

        return create_success_response({'uploadUrls': upload_urls})

    except Exception as e:
        print(f'ERROR: Failed to generate upload URLs: {e}')
        raise https_fn.HttpsError('internal', 'Failed to generate upload URLs. Please try again.') from e


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    product_id = req.data.get(Fields.PRODUCT_ID)

    if not product_id:
        raise https_fn.HttpsError('invalid-argument', 'productId required')

    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_doc = product_ref.get()

    if not product_doc.exists:
        raise https_fn.HttpsError('not-found', 'Product not found')

    product_data = product_doc.to_dict()

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    is_owner = product_data[Fields.SELLER_ID] == user_id

    if not (is_admin or is_owner):
        raise https_fn.HttpsError('permission-denied', 'Only product owner or admin can delete')

    # Check for pending orders
    # NOTE: Firestore can't filter on nested array map fields with array_contains.
    # Use sellerIds (denormalized on orders) to find related orders for this seller,
    # then check if any contain this productId in items.
    pending_orders_query = get_db().collection(Collections.ORDERS)\
        .where(Fields.SELLER_IDS, 'array_contains', user_id)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING, OrderStatusValues.SHIPPED])\
        .limit(20)

    pending_orders = []
    for order_doc in pending_orders_query.stream():
        order_data_check = order_doc.to_dict()
        for item in order_data_check.get(Fields.ITEMS, []):
            if item.get(Fields.PRODUCT_ID) == product_id:
                pending_orders.append(order_doc)
                break

    if pending_orders:
        raise https_fn.HttpsError(
            'failed-precondition',
            'Cannot delete product with pending orders. Please wait for orders to complete.'
        )

    # Soft delete
    product_ref.update({
        Fields.IS_ACTIVE: False,
        Fields.DELETED_AT: get_server_timestamp(),
        Fields.DELETED_BY: user_id
    })

    # Remove from Algolia index
    try:
        algolia_delete_product(product_id)
    except Exception as e:
        print(f'Failed to delete from Algolia: {str(e)}')

    return create_success_response({'message': 'Product deleted successfully'})


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    # AUDIT FIX: Rate limit rating submissions
    from services.rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action='submit_rating',
        max_requests=5, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    user_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils.helpers import sanitized_text

    product_id = data.get(Fields.PRODUCT_ID)
    order_id = data.get(Fields.ORDER_ID)
    rating = data.get(Fields.RATING)
    review_raw = data.get(Fields.REVIEW, '')

    # Sanitize review text to prevent XSS
    review = sanitized_text(review_raw)[:1000] if review_raw else ''  # Max 1000 chars

    if not product_id or not order_id or rating is None:
        raise https_fn.HttpsError('invalid-argument', 'productId, orderId, and rating required')

    # Validate rating is numeric and in valid range
    if not isinstance(rating, (int, float)) or rating < 1 or rating > 5:
        raise https_fn.HttpsError('invalid-argument', 'Rating must be between 1 and 5')

    # Verify user purchased this product
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()

    if order_data[Fields.USER_ID] != user_id:
        raise https_fn.HttpsError('permission-denied', 'This is not your order')

    if order_data[Fields.ORDER_STATUS] != OrderStatusValues.DELIVERED:
        raise https_fn.HttpsError('failed-precondition', 'Can only rate delivered orders')

    # Check if product is in order
    product_in_order = any(item[Fields.PRODUCT_ID] == product_id for item in order_data[Fields.ITEMS])

    if not product_in_order:
        raise https_fn.HttpsError('invalid-argument', 'Product not in this order')

    # Check if user already rated this product with lazy loading
    existing_ratings_query = get_db().collection(Collections.PRODUCT_RATINGS)\
        .where(Fields.PRODUCT_ID, '==', product_id)\
        .where(Fields.USER_ID, '==', user_id)\
        .limit(1)

    existing_ratings = list(existing_ratings_query.stream())

    if existing_ratings:
        raise https_fn.HttpsError('already-exists', 'You have already rated this product')

    # Save rating
    get_db().collection(Collections.PRODUCT_RATINGS).add({
        Fields.PRODUCT_ID: product_id,
        Fields.USER_ID: user_id,
        Fields.ORDER_ID: order_id,
        Fields.RATING: rating,
        Fields.REVIEW: review,
        Fields.CREATED_AT: get_server_timestamp()
    })

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

        transaction.update(product_ref, {
            Fields.RATING: new_average,
            Fields.RATING_COUNT: new_rating_count
        })
        return new_average, new_rating_count

    transaction = get_db().transaction()
    new_average, new_rating_count = update_rating_transaction(transaction)

    if new_average is not None:
        return create_success_response({
            'newRating': new_average,
            Fields.RATING_COUNT: new_rating_count
        })

    raise https_fn.HttpsError('not-found', 'Product not found')


@firestore_fn.on_document_created(document="products/{productId}", **DEFAULT_OPTIONS)
def on_product_created(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Indexes product to Algolia when created.
    Also validates product data consistency and fixes known issues.
    """
    product_id = event.params[Fields.PRODUCT_ID]
    product_data = event.data.to_dict()

    if not product_data:
        print(f'No data for product {product_id}')
        return

    # Only index active products
    if not product_data.get(Fields.IS_ACTIVE, True):
        print(f'Product {product_id} is not active, skipping indexing')
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
                print(f'SECURITY: Product {product_id} from suspended seller {seller_id} — deactivating')
                get_db().collection(Collections.PRODUCTS).document(product_id).update({
                    Fields.IS_ACTIVE: False,
                    Fields.DEACTIVATION_REASON: 'Seller is suspended',
                })
                return

    # CRITICAL: Validate price > 0 and <= 100000 CAD
    price = product_data.get(Fields.PRICE)
    if price is None or not isinstance(price, (int, float)) or price <= 0 or price > 100000:
        print(f'SECURITY: Product {product_id} has invalid price ({price}) — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
            Fields.DEACTIVATION_REASON: f'Invalid price: {price}',
        })
        return

    # CRITICAL: Validate stock quantity >= 0
    stock = product_data.get(Fields.STOCK_QUANTITY, 0)
    if not isinstance(stock, (int, float)) or stock < 0:
        print(f'SECURITY: Product {product_id} has invalid stock ({stock}) — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
            Fields.DEACTIVATION_REASON: f'Invalid stock: {stock}',
        })
        return

    # Seller address validation — sellers can be from any country
    # Only verify that a seller address with a non-empty country is present
    seller_address = product_data.get(Fields.SELLER_ADDRESS, {})
    country = (seller_address.get(Fields.COUNTRY) or '')
    if not country:
        print(f'SECURITY: Product {product_id} has empty seller country — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
            Fields.DEACTIVATION_REASON: 'Missing seller country',
        })
        return

    # CRITICAL: Sanitize text fields to prevent stored XSS
    xss_patches = {}
    name = product_data.get(Fields.NAME, '')
    description = product_data.get(Fields.DESCRIPTION, '')

    # CRITICAL: Validate categoryId against allowed categories
    category_id = product_data.get(Fields.CATEGORY_ID)
    if category_id is not None and (not isinstance(category_id, (int, float)) or int(category_id) < CategoryIds.MIN or int(category_id) > CategoryIds.MAX):
        print(f'SECURITY: Product {product_id} has invalid categoryId ({category_id}) — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
            Fields.DEACTIVATION_REASON: f'Invalid categoryId: {category_id}',
        })
        return
    sanitized_name = sanitized_text(name)
    sanitized_desc = sanitized_text(description)
    if sanitized_name != name:
        xss_patches[Fields.NAME] = sanitized_name
        print(f'SECURITY: Sanitized XSS in product {product_id} name')
    if sanitized_desc != description:
        xss_patches[Fields.DESCRIPTION] = sanitized_desc
        print(f'SECURITY: Sanitized XSS in product {product_id} description')
    if xss_patches:
        get_db().collection(Collections.PRODUCTS).document(product_id).update(xss_patches)
        product_data.update(xss_patches)

    # ── DATA CONSISTENCY VALIDATION ──────────────────────────────────
    patches = {}

    # Bug #1: Digital products MUST have freeShipping=true
    is_digital = product_data.get(Fields.IS_DIGITAL, False)
    if is_digital and not product_data.get(Fields.FREE_SHIPPING, False):
        patches[Fields.FREE_SHIPPING] = True
        print(f'FIX: Product {product_id} is digital but freeShipping=false → patching to true')

    # Bug #2: Local-only products should have a pickup delivery option
    is_local_only = product_data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False)
    delivery_options = product_data.get(Fields.DELIVERY_OPTIONS, [])
    if is_local_only and not any(opt.get(Fields.TYPE) == DeliveryTypeValues.PICKUP for opt in delivery_options if isinstance(opt, dict)):
        pickup_option = {Fields.TYPE: DeliveryTypeValues.PICKUP, Fields.DESCRIPTION: 'Local Pickup', Fields.ESTIMATED_DAYS: 0, Fields.COST: 0.0}
        patches[Fields.DELIVERY_OPTIONS] = [pickup_option] + delivery_options
        print(f'FIX: Product {product_id} is local-only but missing pickup option → patching')

    # Bug #4: Physical products with no delivery options (and not local-only) → add standard
    if not is_digital and not is_local_only and not delivery_options:
        standard_option = {Fields.TYPE: DeliveryTypeValues.STANDARD, Fields.DESCRIPTION: 'Standard Delivery', Fields.ESTIMATED_DAYS: 5, Fields.COST: 0.0}
        patches[Fields.DELIVERY_OPTIONS] = [standard_option]
        print(f'FIX: Product {product_id} has no delivery options → adding standard')

    # Apply patches if any
    if patches:
        try:
            get_db().collection(Collections.PRODUCTS).document(product_id).update(patches)
            print(f'Applied {len(patches)} fix(es) to product {product_id}')
            # Update local copy for indexing
            product_data.update(patches)
        except Exception as e:
            print(f'WARNING: Failed to apply patches to product {product_id}: {str(e)}')

    # FOOD SAFETY: Perishable products should have local delivery or same-day option
    is_perishable = product_data.get(Fields.IS_PERISHABLE, False)
    if is_perishable:
        delivery_options = product_data.get(Fields.DELIVERY_OPTIONS, [])
        has_local_or_same_day = any(
            opt.get(Fields.TYPE) in (
                DeliveryTypeValues.LOCAL_DELIVERY,
                DeliveryTypeValues.SAME_DAY,
                DeliveryTypeValues.PICKUP,
            ) or
            opt.get(Fields.ESTIMATED_DAYS, 99) <= 1
            for opt in delivery_options
        ) if delivery_options else product_data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False)

        if not has_local_or_same_day:
            print(f'WARNING: Perishable product {product_id} should have local/same-day delivery')

    try:
        # Add document ID to product data
        product_data['id'] = product_id
        # Ensure sanitized data is sent to Algolia
        if Fields.NAME in product_data:
            product_data[Fields.NAME] = sanitized_text(product_data[Fields.NAME])
        if Fields.DESCRIPTION in product_data:
            product_data[Fields.DESCRIPTION] = sanitized_text(product_data[Fields.DESCRIPTION])
        index_product(product_id, product_data)
        print(f'Product {product_id} indexed to Algolia')
    except Exception as e:
        print(f'Failed to index product {product_id}: {str(e)}')


@firestore_fn.on_document_updated(document="products/{productId}", **DEFAULT_OPTIONS)
def on_product_updated(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Updates product in Algolia when modified.
    """
    product_id = event.params[Fields.PRODUCT_ID]
    product_data = event.data.after.to_dict()

    if not product_data:
        print(f'No data for product {product_id}')
        return

    # If product is inactive, delete from index
    if not product_data.get(Fields.IS_ACTIVE, True):
        try:
            algolia_delete_product(product_id)
            print(f'Product {product_id} removed from Algolia (inactive)')
        except Exception as e:
            print(f'Failed to delete from Algolia: {str(e)}')
        return

    # ── SERVER-SIDE VALIDATION on update (same as on_product_created) ──
    from utils.helpers import sanitized_text

    # CRITICAL: Check if seller is suspended — deactivate product immediately
    seller_id = product_data.get(Fields.SELLER_ID)
    if seller_id:
        seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
        if seller_doc.exists:
            seller_data = seller_doc.to_dict()
            if seller_data.get(Fields.SUSPENDED, False):
                print(f'SECURITY: Product {product_id} from suspended seller {seller_id} — deactivating')
                get_db().collection(Collections.PRODUCTS).document(product_id).update({
                    Fields.IS_ACTIVE: False,
                    Fields.DEACTIVATION_REASON: 'Seller is suspended',
                })
                return

    # Validate price > 0 and <= 100000 CAD
    price = product_data.get(Fields.PRICE)
    if price is not None and (not isinstance(price, (int, float)) or price <= 0 or price > 100000):
        print(f'SECURITY: Product {product_id} updated with invalid price ({price}) — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
        })
        return

    # Validate stock quantity >= 0
    stock = product_data.get(Fields.STOCK_QUANTITY, 0)
    if not isinstance(stock, (int, float)) or stock < 0:
        print(f'SECURITY: Product {product_id} updated with invalid stock ({stock}) — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
        })
        return

    # Seller address validation — sellers can be from any country
    seller_address = product_data.get(Fields.SELLER_ADDRESS, {})
    country = (seller_address.get(Fields.COUNTRY) or '')
    if not country:
        print(f'SECURITY: Product {product_id} updated with empty seller country — deactivating')
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.IS_ACTIVE: False,
        })
        return

    # Sanitize text fields to prevent stored XSS
    xss_patches = {}
    name = product_data.get(Fields.NAME, '')
    description = product_data.get(Fields.DESCRIPTION, '')
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
        product_data['id'] = product_id
        index_product(product_id, product_data)
        print(f'Product {product_id} updated in Algolia')
    except Exception as e:
        print(f'Failed to update product {product_id} in Algolia: {str(e)}')


@firestore_fn.on_document_deleted(document="products/{productId}", **DEFAULT_OPTIONS)
def on_product_deleted(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Removes product from Algolia when deleted.
    """
    product_id = event.params[Fields.PRODUCT_ID]

    try:
        algolia_delete_product(product_id)
        print(f'Product {product_id} deleted from Algolia')
    except Exception as e:
        print(f'Failed to delete product {product_id} from Algolia: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS)
def configure_algolia(req: https_fn.CallableRequest) -> dict:
    """
    One-time setup: Configures Algolia index settings.
    Admin only.
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid

    # Check admin role
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()

    if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError('permission-denied', 'Admin only')

    try:
        from services.algolia_service import configure_algolia_index
        configure_algolia_index()
        return create_success_response({'message': 'Algolia index configured'})
    except Exception as e:
        print(f'ERROR: Algolia configuration failed: {e}')
        raise https_fn.HttpsError('internal', 'Failed to configure Algolia. Please try again.') from e


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
    data = req.data or {}

    # Paramètres de pagination
    limit = min(data.get('limit', DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE)
    start_after_id = data.get('startAfter')
    category = data.get('category')
    seller_id = data.get(Fields.SELLER_ID)
    is_active = data.get(Fields.IS_ACTIVE, True)
    order_by = data.get('orderBy', Fields.CREATED_AT)
    order_direction = data.get('orderDirection', 'desc')

    # Validation
    if order_by not in [Fields.CREATED_AT, Fields.PRICE, Fields.RATING, Fields.RATING_COUNT, Fields.NAME]:
        raise https_fn.HttpsError('invalid-argument', 'Invalid orderBy field')

    if order_direction not in ['asc', 'desc']:
        raise https_fn.HttpsError('invalid-argument', 'orderDirection must be asc or desc')

    try:
        # Construction de la requête de base
        query = get_db().collection(Collections.PRODUCTS)

        # Filtres
        if is_active is not None:
            query = query.where(Fields.IS_ACTIVE, '==', is_active)

        if category:
            query = query.where(Fields.CATEGORY_ID, '==', category)

        if seller_id:
            query = query.where(Fields.SELLER_ID, '==', seller_id)

        # Tri
        if order_direction == 'desc':
            query = query.order_by(order_by, direction='DESCENDING')
        else:
            query = query.order_by(order_by, direction='ASCENDING')

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
            product_data['id'] = doc.id
            products.append(product_data)

        # Cursor pour la prochaine page
        next_cursor = docs[-1].id if has_more and docs else None

        return create_success_response({
            'products': products,
            'nextCursor': next_cursor,
            'hasMore': has_more,
            'totalFetched': len(products)
        })

    except Exception as e:
        print(f'ERROR: Failed to fetch products: {e}')
        raise https_fn.HttpsError('internal', 'Failed to fetch products. Please try again.') from e


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
    data = req.data or {}

    seller_id = data.get(Fields.SELLER_ID)
    limit = min(data.get('limit', DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE)
    start_after_id = data.get('startAfter')
    include_inactive = data.get('includeInactive', False)

    # Si pas de sellerId, utiliser l'utilisateur connecté
    if not seller_id:
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
        seller_id = req.auth.uid

    # Vérifier les permissions pour includeInactive
    if include_inactive:
        if not req.auth:
            raise https_fn.HttpsError('permission-denied', 'Authentication required to view inactive products')

        user_id = req.auth.uid

        # Vérifier que c'est le propriétaire ou un admin
        if user_id != seller_id:
            user_ref = get_db().collection(Collections.USERS).document(user_id)
            user_doc = user_ref.get()

            if not user_doc.exists:
                raise https_fn.HttpsError('not-found', 'User not found')

            user_data = user_doc.to_dict()
            if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
                raise https_fn.HttpsError('permission-denied', 'Only owner or admin can view inactive products')

    try:
        # Construction de la requête
        query = get_db().collection(Collections.PRODUCTS)\
            .where(Fields.SELLER_ID, '==', seller_id)

        # Filtrer par statut si nécessaire
        if not include_inactive:
            query = query.where(Fields.IS_ACTIVE, '==', True)

        # Tri par date de création (plus récent en premier)
        query = query.order_by(Fields.CREATED_AT, direction='DESCENDING')

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
            product_data['id'] = doc.id
            products.append(product_data)

        next_cursor = docs[-1].id if has_more and docs else None

        return create_success_response({
            'products': products,
            'nextCursor': next_cursor,
            'hasMore': has_more,
            'totalFetched': len(products)
        })

    except Exception as e:
        print(f'ERROR: Failed to fetch seller products: {e}')
        raise https_fn.HttpsError('internal', 'Failed to fetch seller products. Please try again.') from e


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
    data = req.data or {}

    product_id = data.get(Fields.PRODUCT_ID)
    if not product_id:
        raise https_fn.HttpsError('invalid-argument', 'productId required')

    limit = min(data.get('limit', 10), 50)
    start_after_id = data.get('startAfter')
    min_rating = data.get('minRating')

    # Validation
    if min_rating is not None and (not isinstance(min_rating, (int, float)) or min_rating < 1 or min_rating > 5):
        raise https_fn.HttpsError('invalid-argument', 'minRating must be between 1 and 5')

    try:
        # Construction de la requête
        query = get_db().collection(Collections.PRODUCT_RATINGS)\
            .where(Fields.PRODUCT_ID, '==', product_id)

        # Filtrer par rating minimum
        if min_rating is not None:
            query = query.where(Fields.RATING, '>=', min_rating)

        # Tri par date (plus récent en premier)
        query = query.order_by(Fields.CREATED_AT, direction='DESCENDING')

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
            rating_data['id'] = doc.id
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
                batch_user_ids = user_ids_list[i:i+10]
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
                rating_data['userName'] = user_data.get(Fields.NAME, 'Anonymous')
                rating_data['userAvatar'] = user_data.get('profilePictureUrl')

            ratings.append(rating_data)

        next_cursor = docs[-1].id if has_more and docs else None

        return create_success_response({
            Fields.RATINGS: ratings,
            'nextCursor': next_cursor,
            'hasMore': has_more,
            'totalFetched': len(ratings)
        })

    except Exception as e:
        print(f'ERROR: Failed to fetch ratings: {e}')
        raise https_fn.HttpsError('internal', 'Failed to fetch ratings. Please try again.') from e
