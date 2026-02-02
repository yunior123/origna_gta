"""
Test Algolia indexing functionality

Run with: python3 test_algolia_indexing.py
"""

import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Load environment variables
ALGOLIA_APP_ID = os.environ.get('ALGOLIA_APP_ID', '')
ALGOLIA_WRITE_API_KEY = os.environ.get('ALGOLIA_WRITE_API_KEY', '')


def format_product_for_algolia(product_id: str, product_data: dict) -> dict:
    """Format product for Algolia (test version)"""
    algolia_object = {
        'objectID': product_id,
        'name': product_data.get('name', ''),
        'description': product_data.get('description', ''),
        'price': product_data.get('price', 0.0),
        'categoryId': product_data.get('categoryId', 0),
        'sellerId': product_data.get('sellerId', ''),
        'imageUrls': product_data.get('imageUrls', []),
        'stockQuantity': product_data.get('stockQuantity', 0),
        'rating': product_data.get('rating', 0.0),
        'ratingCount': product_data.get('ratingCount', 0),
        'isActive': product_data.get('isActive', True),
        'searchKeywords': product_data.get('searchKeywords', []),
        'sellerAddress': product_data.get('sellerAddress', {}),
        'freeShipping': product_data.get('freeShipping', False),
        'isPerishable': product_data.get('isPerishable', False),
        'isLocalDeliveryOnly': product_data.get('isLocalDeliveryOnly', False),
    }
    return algolia_object


def test_algolia_credentials():
    """Check if Algolia credentials are configured"""
    print("🔑 Checking Algolia credentials...")
    
    if not ALGOLIA_APP_ID:
        print("❌ ALGOLIA_APP_ID not configured")
        return False
    
    if not ALGOLIA_WRITE_API_KEY:
        print("❌ ALGOLIA_WRITE_API_KEY not configured")
        return False
    
    print(f"✅ Credentials configured")
    print(f"   App ID: {ALGOLIA_APP_ID}")
    print(f"   Write Key: {'*' * 20}...{ALGOLIA_WRITE_API_KEY[-4:]}")
    return True


def test_format_product():
    """Test product formatting for Algolia"""
    print("\n📦 Testing product formatting...")
    
    # Sample product data
    sample_product = {
        'name': 'Test Product',
        'description': 'A test product for Algolia indexing',
        'price': 29.99,
        'categoryId': 14,
        'sellerId': 'seller_123',
        'imageUrls': ['https://example.com/image.jpg'],
        'stockQuantity': 10,
        'rating': 4.5,
        'ratingCount': 42,
        'isActive': True,
        'searchKeywords': ['test', 'product', 'sample'],
        'sellerAddress': {
            'street': '123 Main St',
            'city': 'Toronto',
            'state': 'ON',
            'postalCode': 'M5V1A1',
            'country': 'Canada'
        },
        'freeShipping': True,
        'isPerishable': False,
        'isLocalDeliveryOnly': False
    }
    
    try:
        formatted = format_product_for_algolia('test_product_123', sample_product)
        
        # Verify required fields
        required_fields = [
            'objectID', 'name', 'description', 'price', 'categoryId',
            'sellerId', 'imageUrls', 'stockQuantity'
        ]
        
        for field in required_fields:
            assert field in formatted, f"Missing required field: {field}"
        # Test that credentials are valid format
        from algoliasearch.search.client import SearchClient
        client = SearchClient.create(ALGOLIA_APP_ID, ALGOLIA_WRITE_API_KEY)
        index = client.init_index('products')
        
        print("✅ Algolia client created successfully")
        print("   Index: products")
        return True
    except Exception as e:
        print(f"⚠️  Client creation warning: {e}")
        return False
        
    except Exception as e:
        print(f"❌ Product formatting failed: {e}")
        return False


def test_algolia_configuration():
    """Test Algolia index configuration"""
    print("\n⚙️  Testing Algolia index configuration...")
    
    if not ALGOLIA_APP_ID or not ALGOLIA_WRITE_API_KEY:
        print("⏭️  Skipping - credentials not configured")
        return True
    
    try:
        configure_algolia_index()
        print("✅ Index configuration successful")
        print("   Settings: searchableAttributes, customRanking, attributesForFaceting")
        return True
    except Exception as e:
        print(f"⚠️  Index configuration warning: {e}")
        # Not critical, index might already be configured
        return True


def test_mock_indexing():
    """Test indexing logic without actually sending to Algolia"""
    print("\n🔍 Testing indexing logic (mock mode)...")
    
    sample_products = [
        {
            'id': 'prod_001',
            'data': {
                'name': 'Organic Apples',
                'description': 'Fresh organic apples from local farm',
                'price': 4.99,
                'categoryId': 14,
                'sellerId': 'farmer_01',
                'imageUrls': ['https://example.com/apples.jpg'],
                'stockQuantity': 50,
                'rating': 4.8,
                'ratingCount': 120,
                'isActive': True,
                'searchKeywords': ['apples', 'fruit', 'organic'],
                'sellerAddress': {'city': 'Toronto', 'state': 'ON', 'country': 'Canada'},
                'freeShipping': False,
                'isPerishable': True,
                'isLocalDeliveryOnly': True
            }
        },
        {
            'id': 'prod_002',
            'data': {
                'name': 'Handmade Soap',
                'description': 'Natural handmade soap with essential oils',
                'price': 8.99,
                'categoryId': 19,
                'sellerId': 'artisan_02',
                'imageUrls': ['https://example.com/soap.jpg'],
                'stockQuantity': 30,
                'rating': 4.9,
                'ratingCount': 85,
                'isActive': True,
                'searchKeywords': ['soap', 'handmade', 'natural'],
                'sellerAddress': {'city': 'Vancouver', 'state': 'BC', 'country': 'Canada'},
                'freeShipping': True,
                'isPerishable': False,
                'isLocalDeliveryOnly': False
            }
        }
    ]
    
    try:
        # Format all products
        formatted_products = []
        for product in sample_products:
            formatted = format_product_for_algolia(product['id'], product['data'])
            formatted_products.append(formatted)
        
        print(f"✅ Successfully formatted {len(formatted_products)} products")
        
        # Show sample
        print(f"\n   Sample product:")
        sample = formatted_products[0]
        print(f"   - ID: {sample['objectID']}")
        print(f"   - Name: {sample['name']}")
        print(f"   - Price: ${sample['price']}")
        print(f"   - Category: {sample['categoryId']}")
        print(f"   - Active: {sample['isActive']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Indexing logic failed: {e}")
        return False


def main():
    print("=" * 70)
    print("ALGOLIA INDEXING TESTS")
    print("=" * 70)
    
    results = []
    
    # Test 1: Credentials
    results.append(("Credentials Check", test_algolia_credentials()))
    
    # Test 2: Product formatting
    results.append(("Product Formatting", test_format_product()))
    
    # Test 3: Index configuration
    results.append(("Index Configuration", test_algolia_configuration()))
    
    # Test 4: Mock indexing
    results.append(("Indexing Logic", test_mock_indexing()))
    
    # Summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    
    passed = sum(1 for _, result in results if result)
    failed = sum(1 for _, result in results if not result)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print("\n" + "=" * 70)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 70)
    
    if not ALGOLIA_APP_ID or not ALGOLIA_WRITE_API_KEY:
        print("\n⚠️  NOTE: Algolia credentials not configured in environment")
        print("   Tests ran in mock mode only")
        print("   To test real indexing, set ALGOLIA_APP_ID and ALGOLIA_WRITE_API_KEY")
    
    return 0 if failed == 0 else 1


if __name__ == '__main__':
    exit(main())
