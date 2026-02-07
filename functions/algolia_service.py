"""
Algolia indexing service for products
Handles syncing Firestore products to Algolia search index
"""

from algoliasearch.search.client import SearchClient
from config import ALGOLIA_APP_ID, ALGOLIA_WRITE_API_KEY
from schema_constants import Fields
from typing import Dict, Union
from pydantic import ValidationError

# Import Pydantic Product model for type-safe operations
from models.product import Product

# Initialize Algolia client (v4 API)
algolia_client = SearchClient(ALGOLIA_APP_ID, ALGOLIA_WRITE_API_KEY) if ALGOLIA_APP_ID and ALGOLIA_WRITE_API_KEY else None
products_index = algolia_client if algolia_client else None


def format_product_for_algolia(product_id: str, product_data: Union[dict, Product]) -> dict:
    """
    Format product document for Algolia indexing.
    
    Args:
        product_id: Firestore document ID
        product_data: Product document data (dict) or Product Pydantic model
    
    Returns:
        Formatted object for Algolia with objectID
    """
    # Convert Product model to dict if needed
    if isinstance(product_data, Product):
        # Use Pydantic model_dump for clean serialization
        data = product_data.model_dump(exclude_none=True)
    else:
        # Legacy dict support (backward compatibility)
        try:
            # Attempt to validate as Product for consistency
            product = Product(**product_data)
            data = product.model_dump(exclude_none=True)
        except ValidationError:
            # Fallback to raw dict if validation fails (for migration period)
            print(f"⚠️  Product {product_id} validation failed, using raw data")
            data = product_data
    
    # Algolia requires objectID field
    # Algolia requires objectID field
    algolia_object = {
        'objectID': product_id,
        Fields.NAME: data.get(Fields.NAME, ''),
        Fields.DESCRIPTION: data.get(Fields.DESCRIPTION, ''),
        Fields.PRICE: data.get(Fields.PRICE, 0.0),
        Fields.CATEGORY_ID: data.get(Fields.CATEGORY_ID, 0),
        Fields.SELLER_ID: data.get(Fields.SELLER_ID, ''),
        Fields.IMAGE_URLS: data.get(Fields.IMAGE_URLS, []),
        Fields.STOCK_QUANTITY: data.get(Fields.STOCK_QUANTITY, 0),
        Fields.RATING: data.get(Fields.RATING, 0.0),
        Fields.RATING_COUNT: data.get(Fields.RATING_COUNT, 0),
        Fields.IS_ACTIVE: data.get(Fields.IS_ACTIVE, True),
        Fields.KEYWORDS: data.get(Fields.KEYWORDS, []) or data.get('searchKeywords', []),
        Fields.FREE_SHIPPING: data.get(Fields.FREE_SHIPPING, False),
        Fields.IS_PERISHABLE: data.get(Fields.IS_PERISHABLE, False),
        Fields.IS_LOCAL_DELIVERY_ONLY: data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False),
    }
    
    # Seller address - handle both dict and Address object
    seller_address = data.get(Fields.SELLER_ADDRESS)
    if seller_address:
        # Convert Address model to dict if needed
        if hasattr(seller_address, 'model_dump'):
            algolia_object[Fields.SELLER_ADDRESS] = seller_address.model_dump(exclude_none=True)
        else:
            algolia_object[Fields.SELLER_ADDRESS] = seller_address
    
    # Optional fields
    optional_fields = [Fields.WEIGHT_KG, Fields.LENGTH_CM, Fields.WIDTH_CM, Fields.HEIGHT_CM, Fields.TAX_CODE, 
                      Fields.DELIVERY_OPTIONS, Fields.ESTIMATED_SHIP_DAYS, Fields.MINIMUM_ORDER_QUANTITY]
    for field in optional_fields:
        if field in data:
            algolia_object[field] = data[field]
    
    # Add timestamp for sorting (convert Firestore timestamp to Unix timestamp)
    if Fields.DATE_CREATED in data and data[Fields.DATE_CREATED]:
        algolia_object[Fields.DATE_CREATED] = data[Fields.DATE_CREATED].timestamp() if hasattr(data[Fields.DATE_CREATED], 'timestamp') else 0
    
    return algolia_object


def _log_sync_failure(product_id: str, action: str, error: str, retries: int):
    """Log failed Algolia sync to Firestore dead letter queue for later retry."""
    try:
        from firebase_admin import firestore as fs
        db = fs.client()
        db.collection('algolia_sync_failures').add({
            'productId': product_id,
            'action': action,
            'error': error,
            'timestamp': fs.SERVER_TIMESTAMP,
            'retries': retries,
            'resolved': False,
        })
        print(f"  📝 Logged sync failure for {product_id} to dead letter queue")
    except Exception as dlq_err:
        print(f"  ❌ Failed to log to dead letter queue: {dlq_err}")


def index_product(product_id: str, product_data: dict, max_retries: int = 3) -> bool:
    """
    Index a single product to Algolia with retry + exponential backoff.
    On final failure, logs to algolia_sync_failures collection for later reconciliation.
    
    Args:
        product_id: Firestore document ID
        product_data: Product document data
        max_retries: Number of retry attempts (default 3)
    
    Returns:
        True if successful, False otherwise
    """
    import time

    if not products_index:
        print("⚠️  Algolia not configured - skipping indexing")
        return False
    
    # Only index active products
    if not product_data.get(Fields.IS_ACTIVE, True):
        print(f"  ⏭️  Product {product_id} is inactive - removing from index if exists")
        delete_product(product_id)
        return True
    
    algolia_object = format_product_for_algolia(product_id, product_data)
    last_error = None

    for attempt in range(max_retries):
        try:
            products_index.save_object(index_name='products', body=algolia_object)
            print(f"  ✅ Indexed product {product_id} to Algolia")
            return True
        except Exception as e:
            last_error = e
            wait = 2 ** attempt
            print(f"  ⚠️  Algolia index attempt {attempt + 1}/{max_retries} failed for {product_id}: {e}")
            if attempt < max_retries - 1:
                time.sleep(wait)

    # All retries exhausted — log to dead letter queue
    _log_sync_failure(product_id, 'index', str(last_error), max_retries)
    return False


def delete_product(product_id: str, max_retries: int = 3) -> bool:
    """
    Delete a product from Algolia index with retry + exponential backoff.
    On final failure, logs to algolia_sync_failures collection.
    
    Args:
        product_id: Firestore document ID
        max_retries: Number of retry attempts (default 3)
    
    Returns:
        True if successful, False otherwise
    """
    import time

    if not products_index:
        print("⚠️  Algolia not configured - skipping deletion")
        return False
    
    last_error = None

    for attempt in range(max_retries):
        try:
            products_index.delete_object(index_name='products', object_id=product_id)
            print(f"  ✅ Deleted product {product_id} from Algolia")
            return True
        except Exception as e:
            last_error = e
            wait = 2 ** attempt
            print(f"  ⚠️  Algolia delete attempt {attempt + 1}/{max_retries} failed for {product_id}: {e}")
            if attempt < max_retries - 1:
                time.sleep(wait)

    # All retries exhausted — log to dead letter queue
    _log_sync_failure(product_id, 'delete', str(last_error), max_retries)
    return False


def batch_index_products(products: list) -> tuple:
    """
    Index multiple products in batch
    
    Args:
        products: List of tuples (product_id, product_data)
    
    Returns:
        Tuple of (success_count, failure_count)
    """
    if not products_index:
        print("⚠️  Algolia not configured - skipping batch indexing")
        return (0, len(products))
    
    try:
        algolia_objects = []
        for product_id, product_data in products:
            # Only index active products
            if product_data.get(Fields.IS_ACTIVE, True):
                algolia_objects.append(format_product_for_algolia(product_id, product_data))
        
        if algolia_objects:
            products_index.save_objects(index_name='products', objects=algolia_objects)
            print(f"  ✅ Batch indexed {len(algolia_objects)} products to Algolia")
            return (len(algolia_objects), len(products) - len(algolia_objects))
        
        return (0, len(products))
    except Exception as e:
        print(f"  ❌ Failed to batch index products: {str(e)}")
        return (0, len(products))


def configure_algolia_index():
    """
    Configure Algolia index settings and replicas
    Should be run once during setup or when index configuration changes
    """
    if not products_index:
        print("⚠️  Algolia not configured - skipping index configuration")
        return False
    
    try:
        # Set searchable attributes with priority
        products_index.set_settings({
            'searchableAttributes': [
                Fields.NAME,                    # Highest priority
                Fields.DESCRIPTION,
                Fields.KEYWORDS,
            ],
            'attributesForFaceting': [
                Fields.CATEGORY_ID,
                Fields.SELLER_ID,
                Fields.IS_ACTIVE,
                Fields.FREE_SHIPPING,
                Fields.IS_PERISHABLE,
            ],
            'customRanking': [
                f'desc({Fields.RATING})',           # Sort by rating first
                f'desc({Fields.RATING_COUNT})',      # Then by number of ratings
                f'desc({Fields.DATE_CREATED})',      # Then by newest
            ],
            'attributesToRetrieve': [
                'objectID',
                Fields.NAME,
                Fields.DESCRIPTION,
                Fields.PRICE,
                Fields.CATEGORY_ID,
                Fields.SELLER_ID,
                Fields.IMAGE_URLS,
                Fields.STOCK_QUANTITY,
                Fields.RATING,
                Fields.RATING_COUNT,
                Fields.IS_ACTIVE,
                Fields.KEYWORDS,
                Fields.SELLER_ADDRESS,
                Fields.WEIGHT_KG,
                Fields.LENGTH_CM,
                Fields.WIDTH_CM,
                Fields.HEIGHT_CM,
                Fields.IS_LOCAL_DELIVERY_ONLY,
                Fields.ESTIMATED_SHIP_DAYS,
                Fields.TAX_CODE,
                Fields.DELIVERY_OPTIONS,
                Fields.IS_PERISHABLE,
                Fields.MINIMUM_ORDER_QUANTITY,
                Fields.FREE_SHIPPING,
            ],
            'highlightPreTag': '<mark>',
            'highlightPostTag': '</mark>',
            'hitsPerPage': 20,
        })
        print("  ✅ Configured Algolia index settings")
        return True
    except Exception as e:
        print(f"  ❌ Failed to configure Algolia index: {str(e)}")
        return False
