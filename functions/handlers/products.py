"""
Product Management Handlers
- Product CRUD operations
- Algolia indexing (Firestore triggers)
- Image upload to Cloudflare R2
- Product deletion with validation
- Rating submission
"""

from function_options import DEFAULT_OPTIONS, WEBHOOK_OPTIONS, CRON_OPTIONS
from firebase_functions import https_fn, firestore_fn, options
from typing import Dict, Any, Optional
import boto3
from botocore.config import Config
import os
import uuid

from config import (
    Collections, R2_ACCESS_KEY_NEW, R2_SECRET_KEY_NEW, R2_ACCOUNT_ID_NEW,
    R2Config, get_r2_credentials, IS_EMULATOR
)
from schema_constants import Fields, UserRoleValues, OrderStatusValues
from utils import create_success_response, create_error_response
from algolia_service import index_product, delete_product

# Lazy loading constants
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

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

# CORS configuration for production
CORS_CONFIG = options.CorsOptions(
    cors_origins=[
        "https://orignagta.ca",
        "https://www.orignagta.ca",
        "https://orignagta.web.app",
        "https://orignagta.firebaseapp.com",
    ],
    cors_methods=["POST", "OPTIONS"],
)


@https_fn.on_call(secrets=[R2_ACCESS_KEY_NEW, R2_SECRET_KEY_NEW, R2_ACCOUNT_ID_NEW])
def upload_product_images(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    data = req.data
    file_names_raw = data.get('fileNames', [])
    content_types = data.get('contentTypes', [])
    
    # Import validation functions
    from utils import sanitize_path
    
    if not file_names_raw or len(file_names_raw) == 0:
        raise https_fn.HttpsError('invalid-argument', 'No files specified')
    
    if len(file_names_raw) > 5:
        raise https_fn.HttpsError('invalid-argument', 'Maximum 5 images allowed')
    
    if len(file_names_raw) != len(content_types):
        raise https_fn.HttpsError('invalid-argument', 'File names and content types count mismatch')
    
    # Sanitize file names to prevent path traversal
    file_names = [sanitize_path(fn) for fn in file_names_raw]
    
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
        for file_name, content_type in zip(file_names, content_types):
            # Generate unique key with environment-aware path
            file_extension = file_name.split('.')[-1]
            unique_key = R2Config.get_image_path('products', f'{uuid.uuid4()}.{file_extension}')
            
            # Generate presigned URL for upload
            presigned_url = s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': unique_key,
                    'ContentType': content_type
                },
                ExpiresIn=3600  # 1 hour
            )
            
            public_url = f'https://cdn.origna.ca/{unique_key}'
            
            upload_urls.append({
                'uploadUrl': presigned_url,
                'publicUrl': public_url,
                'fileName': file_name,
                'key': unique_key
            })
        
        return create_success_response({'uploadUrls': upload_urls})
        
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Failed to generate upload URLs: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS)
def delete_product(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    # Check for pending orders with lazy loading limit
    pending_orders_query = get_db().collection(Collections.ORDERS)\
        .where(f'{Fields.ITEMS}.{Fields.PRODUCT_ID}', 'array_contains', product_id)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING, OrderStatusValues.SHIPPED])\
        .limit(1)
    
    pending_orders = list(pending_orders_query.stream())
    
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
        delete_product(product_id)
    except Exception as e:
        print(f'Failed to delete from Algolia: {str(e)}')
    
    return create_success_response({'message': 'Product deleted successfully'})


@https_fn.on_call(**DEFAULT_OPTIONS)
def submit_product_rating(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    user_id = req.auth.uid
    data = req.data
    
    # Import validation functions
    from utils import sanitized_text
    
    product_id = data.get(Fields.PRODUCT_ID)
    order_id = data.get(Fields.ORDER_ID)
    rating = data.get(Fields.RATING)
    review_raw = data.get('review', '')
    
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
        'review': review,
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
            'ratingCount': new_rating_count
        })
    
    raise https_fn.HttpsError('not-found', 'Product not found')


@firestore_fn.on_document_created(document="products/{productId}", **DEFAULT_OPTIONS)
def on_product_created(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Indexes product to Algolia when created.
    Also validates product data consistency and fixes known issues.
    """
    product_id = event.params['productId']
    product_data = event.data.to_dict()
    
    if not product_data:
        print(f'No data for product {product_id}')
        return
    
    # Only index active products
    if not product_data.get(Fields.IS_ACTIVE, True):
        print(f'Product {product_id} is not active, skipping indexing')
        return
    
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
    if is_local_only and not any(opt.get('type') == 'pickup' for opt in delivery_options if isinstance(opt, dict)):
        pickup_option = {'type': 'pickup', 'description': 'Local Pickup', 'estimatedDays': 0, 'cost': 0.0}
        patches[Fields.DELIVERY_OPTIONS] = [pickup_option] + delivery_options
        print(f'FIX: Product {product_id} is local-only but missing pickup option → patching')
    
    # Bug #4: Physical products with no delivery options (and not local-only) → add standard
    if not is_digital and not is_local_only and not delivery_options:
        standard_option = {'type': 'standard', 'description': 'Standard Delivery', 'estimatedDays': 5, 'cost': 0.0}
        patches[Fields.DELIVERY_OPTIONS] = [standard_option]
        print(f'FIX: Product {product_id} has no delivery options → adding standard')
    
    # Apply patches if any
    if patches:
        try:
            get_db().collection('products').document(product_id).update(patches)
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
            opt.get('type') in ['local_delivery', 'same_day', 'local', 'pickup'] or 
            opt.get('estimatedDays', 99) <= 1
            for opt in delivery_options
        ) if delivery_options else product_data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False)
        
        if not has_local_or_same_day:
            print(f'WARNING: Perishable product {product_id} should have local/same-day delivery')
    
    try:
        # Add document ID to product data
        product_data['id'] = product_id
        index_product(product_data)
        print(f'Product {product_id} indexed to Algolia')
    except Exception as e:
        print(f'Failed to index product {product_id}: {str(e)}')


@firestore_fn.on_document_updated(document="products/{productId}", **DEFAULT_OPTIONS)
def on_product_updated(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Updates product in Algolia when modified.
    """
    product_id = event.params['productId']
    product_data = event.data.after.to_dict()
    
    if not product_data:
        print(f'No data for product {product_id}')
        return
    
    # If product is inactive, delete from index
    if not product_data.get(Fields.IS_ACTIVE, True):
        try:
            delete_product(product_id)
            print(f'Product {product_id} removed from Algolia (inactive)')
        except Exception as e:
            print(f'Failed to delete from Algolia: {str(e)}')
        return
    
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
    product_id = event.params['productId']
    
    try:
        delete_product(product_id)
        print(f'Product {product_id} deleted from Algolia')
    except Exception as e:
        print(f'Failed to delete product {product_id} from Algolia: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
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
        from algolia_service import configure_algolia_index
        configure_algolia_index()
        return create_success_response({'message': 'Algolia index configured'})
    except Exception as e:
        raise https_fn.HttpsError('internal', str(e))


@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
def get_products_paginated(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    if order_by not in [Fields.CREATED_AT, Fields.PRICE, Fields.RATING, Fields.RATING_COUNT, 'title']:
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
            query = query.where('category', '==', category)
        
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
        raise https_fn.HttpsError('internal', f'Failed to fetch products: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
def get_seller_products_paginated(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
        raise https_fn.HttpsError('internal', f'Failed to fetch seller products: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
def get_product_ratings_paginated(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    if min_rating is not None:
        if not isinstance(min_rating, (int, float)) or min_rating < 1 or min_rating > 5:
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
            'ratings': ratings,
            'nextCursor': next_cursor,
            'hasMore': has_more,
            'totalFetched': len(ratings)
        })
        
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Failed to fetch ratings: {str(e)}')
