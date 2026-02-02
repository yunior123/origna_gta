"""
Algolia indexing service for products
Handles syncing Firestore products to Algolia search index
"""

from algoliasearch.search.client import SearchClient
from config import ALGOLIA_APP_ID, ALGOLIA_WRITE_API_KEY
from typing import Dict, Union
from pydantic import ValidationError

# Import Pydantic Product model for type-safe operations
from models.product import Product

# Initialize Algolia client
algolia_client = SearchClient.create(ALGOLIA_APP_ID, ALGOLIA_WRITE_API_KEY) if ALGOLIA_APP_ID and ALGOLIA_WRITE_API_KEY else None
products_index = algolia_client.init_index('products') if algolia_client else None


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
    algolia_object = {
        'objectID': product_id,
        'name': data.get('name', ''),
        'description': data.get('description', ''),
        'price': data.get('price', 0.0),
        'categoryId': data.get('categoryId', 0),
        'sellerId': data.get('sellerId', ''),
        'imageUrls': data.get('imageUrls', []),
        'stockQuantity': data.get('stockQuantity', 0),
        'rating': data.get('rating', 0.0),
        'ratingCount': data.get('ratingCount', 0),
        'isActive': data.get('isActive', True),
        'searchKeywords': data.get('searchKeywords', []),
        'freeShipping': data.get('freeShipping', False),
        'isPerishable': data.get('isPerishable', False),
        'isLocalDeliveryOnly': data.get('isLocalDeliveryOnly', False),
    }
    
    # Seller address - handle both dict and Address object
    seller_address = data.get('sellerAddress')
    if seller_address:
        # Convert Address model to dict if needed
        if hasattr(seller_address, 'model_dump'):
            algolia_object['sellerAddress'] = seller_address.model_dump(exclude_none=True)
        else:
            algolia_object['sellerAddress'] = seller_address
    
    # Optional fields
    optional_fields = ['weightKg', 'lengthCm', 'widthCm', 'heightCm', 'taxCode', 
                      'deliveryOptions', 'estimatedShipDays', 'minimumOrderQuantity']
    for field in optional_fields:
        if field in data:
            algolia_object[field] = data[field]
    
    # Add timestamp for sorting (convert Firestore timestamp to Unix timestamp)
    if 'dateCreated' in data and data['dateCreated']:
        algolia_object['dateCreated'] = data['dateCreated'].timestamp() if hasattr(data['dateCreated'], 'timestamp') else 0
    
    return algolia_object


def index_product(product_id: str, product_data: dict) -> bool:
    """
    Index a single product to Algolia
    
    Args:
        product_id: Firestore document ID
        product_data: Product document data
    
    Returns:
        True if successful, False otherwise
    """
    if not products_index:
        print("⚠️  Algolia not configured - skipping indexing")
        return False
    
    try:
        # Only index active products
        if not product_data.get('isActive', True):
            print(f"  ⏭️  Product {product_id} is inactive - removing from index if exists")
            delete_product(product_id)
            return True
        
        algolia_object = format_product_for_algolia(product_id, product_data)
        products_index.save_object(algolia_object)
        print(f"  ✅ Indexed product {product_id} to Algolia")
        return True
    except Exception as e:
        print(f"  ❌ Failed to index product {product_id}: {str(e)}")
        return False


def delete_product(product_id: str) -> bool:
    """
    Delete a product from Algolia index
    
    Args:
        product_id: Firestore document ID
    
    Returns:
        True if successful, False otherwise
    """
    if not products_index:
        print("⚠️  Algolia not configured - skipping deletion")
        return False
    
    try:
        products_index.delete_object(product_id)
        print(f"  ✅ Deleted product {product_id} from Algolia")
        return True
    except Exception as e:
        print(f"  ❌ Failed to delete product {product_id}: {str(e)}")
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
            if product_data.get('isActive', True):
                algolia_objects.append(format_product_for_algolia(product_id, product_data))
        
        if algolia_objects:
            products_index.save_objects(algolia_objects)
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
                'name',                    # Highest priority
                'description',
                'searchKeywords',
            ],
            'attributesForFaceting': [
                'categoryId',
                'sellerId',
                'isActive',
                'freeShipping',
                'isPerishable',
            ],
            'customRanking': [
                'desc(rating)',           # Sort by rating first
                'desc(ratingCount)',      # Then by number of ratings
                'desc(dateCreated)',      # Then by newest
            ],
            'attributesToRetrieve': [
                'objectID',
                'name',
                'description',
                'price',
                'categoryId',
                'sellerId',
                'imageUrls',
                'stockQuantity',
                'rating',
                'ratingCount',
                'isActive',
                'searchKeywords',
                'sellerAddress',
                'weightKg',
                'lengthCm',
                'widthCm',
                'heightCm',
                'isLocalDeliveryOnly',
                'estimatedShipDays',
                'taxCode',
                'deliveryOptions',
                'isPerishable',
                'minimumOrderQuantity',
                'freeShipping',
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
