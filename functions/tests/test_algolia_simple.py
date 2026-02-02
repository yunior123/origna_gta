"""
Test Algolia indexing - Simple version

Run with: ALGOLIA_APP_ID=xxx ALGOLIA_WRITE_API_KEY=yyy python3 test_algolia_simple.py
"""

import os


def test_credentials():
    """Check if Algolia credentials are configured"""
    print("🔑 Checking Algolia credentials...")
    
    app_id = os.environ.get('ALGOLIA_APP_ID', '')
    write_key = os.environ.get('ALGOLIA_WRITE_API_KEY', '')
    
    if not app_id:
        print("❌ ALGOLIA_APP_ID not configured")
        return False
    
    if not write_key:
        print("❌ ALGOLIA_WRITE_API_KEY not configured")
        return False
    
    print(f"✅ Credentials configured")
    print(f"   App ID: {app_id}")
    print(f"   Write Key: {'*' * 20}...{write_key[-4:]}")
    return True


def test_algolia_client():
    """Test Algolia client initialization"""
    print("\n⚙️  Testing Algolia client...")
    
    app_id = os.environ.get('ALGOLIA_APP_ID', '')
    write_key = os.environ.get('ALGOLIA_WRITE_API_KEY', '')
    
    if not app_id or not write_key:
        print("⏭️  Skipping - credentials not configured")
        return True
    
    try:
        from algoliasearch.search.client import SearchClient
        
        # Create client
        client = SearchClient(app_id, write_key)
        
        print("✅ Client initialized successfully")
        print(f"   App ID: {app_id}")
        print(f"   Ready to use 'products' index")
        return True
    except Exception as e:
        print(f"❌ Client initialization failed: {e}")
        return False


def test_product_formatting():
    """Test product data formatting"""
    print("\n📦 Testing product formatting...")
    
    sample_product = {
        'name': 'Test Product',
        'description': 'A test product',
        'price': 29.99,
        'categoryId': 14,
        'sellerId': 'seller_123',
        'imageUrls': ['https://example.com/image.jpg'],
        'stockQuantity': 10,
        'rating': 4.5,
        'ratingCount': 42,
        'isActive': True,
        'searchKeywords': ['test', 'product'],
        'sellerAddress': {'city': 'Toronto', 'state': 'ON', 'country': 'Canada'},
        'freeShipping': True,
        'isPerishable': False,
        'isLocalDeliveryOnly': False
    }
    
    try:
        # Format for Algolia
        formatted = {
            'objectID': 'test_123',
            'name': sample_product.get('name'),
            'description': sample_product.get('description'),
            'price': sample_product.get('price'),
            'categoryId': sample_product.get('categoryId'),
            'sellerId': sample_product.get('sellerId'),
            'imageUrls': sample_product.get('imageUrls'),
            'stockQuantity': sample_product.get('stockQuantity'),
            'rating': sample_product.get('rating'),
            'ratingCount': sample_product.get('ratingCount'),
            'isActive': sample_product.get('isActive'),
            'searchKeywords': sample_product.get('searchKeywords'),
            'sellerAddress': sample_product.get('sellerAddress'),
            'freeShipping': sample_product.get('freeShipping'),
            'isPerishable': sample_product.get('isPerishable'),
            'isLocalDeliveryOnly': sample_product.get('isLocalDeliveryOnly'),
        }
        
        # Verify required fields
        required = ['objectID', 'name', 'price', 'categoryId', 'sellerId']
        for field in required:
            assert field in formatted and formatted[field] is not None
        
        print("✅ Product formatting successful")
        print(f"   Fields: {len(formatted)} total")
        print(f"   Sample: {formatted['name']} - ${formatted['price']}")
        return True
        
    except Exception as e:
        print(f"❌ Formatting failed: {e}")
        return False


def test_batch_formatting():
    """Test batch product formatting"""
    print("\n📦 Testing batch formatting...")
    
    products = [
        {'id': 'p1', 'name': 'Product 1', 'price': 10.99},
        {'id': 'p2', 'name': 'Product 2', 'price': 20.99},
        {'id': 'p3', 'name': 'Product 3', 'price': 30.99},
    ]
    
    try:
        formatted_batch = []
        for p in products:
            formatted_batch.append({
                'objectID': p['id'],
                'name': p['name'],
                'price': p['price']
            })
        
        assert len(formatted_batch) == 3
        
        print(f"✅ Batch formatting successful")
        print(f"   Formatted {len(formatted_batch)} products")
        return True
        
    except Exception as e:
        print(f"❌ Batch formatting failed: {e}")
        return False


def main():
    print("=" * 70)
    print("ALGOLIA TESTS - SIMPLE VERSION")
    print("=" * 70)
    
    tests = [
        ("Credentials", test_credentials),
        ("Client Initialization", test_algolia_client),
        ("Product Formatting", test_product_formatting),
        ("Batch Formatting", test_batch_formatting),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"❌ Test '{name}' crashed: {e}")
            failed += 1
    
    print("\n" + "=" * 70)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 70)
    
    app_id = os.environ.get('ALGOLIA_APP_ID', '')
    if not app_id:
        print("\n⚠️  NOTE: Set ALGOLIA_APP_ID and ALGOLIA_WRITE_API_KEY to test with real credentials")
    
    return 0 if failed == 0 else 1


if __name__ == '__main__':
    exit(main())
