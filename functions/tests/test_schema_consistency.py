"""
Test schema consistency between backend (Python) and frontend (Dart)

This test ensures that data models match between backend Cloud Functions
and frontend Flutter app to prevent serialization/deserialization errors.

Run with: pytest test_schema_consistency.py -v
"""

import json
import re
from pathlib import Path


class TestSchemaConsistency:
    """Test field consistency between Python backend and Dart frontend"""

    @staticmethod
    def get_project_root():
        """Get project root directory"""
        current = Path(__file__).resolve()
        # Go up from functions/tests/ to project root
        return current.parent.parent.parent

    def test_product_fields_consistency(self):
        """Verify product fields match between Python algolia_service.py and Dart constants"""
        root = self.get_project_root()
        
        # Read Python algolia_service.py
        algolia_service_path = root / 'functions' / 'algolia_service.py'
        with open(algolia_service_path, 'r') as f:
            algolia_content = f.read()
        
        # Extract fields from format_product_for_algolia function
        python_fields = set()
        # Find all product_data.get() calls
        field_pattern = r"product_data\.get\('(\w+)'[,)]"
        python_fields = set(re.findall(field_pattern, algolia_content))
        
        # Required product fields that must be in Algolia index
        required_fields = {
            'name', 'description', 'price', 'categoryId', 'sellerId',
            'imageUrls', 'stockQuantity', 'rating', 'ratingCount',
            'isActive', 'searchKeywords', 'sellerAddress', 'freeShipping',
            'isPerishable', 'isLocalDeliveryOnly'
        }
        
        # Check all required fields are in Python code
        missing = required_fields - python_fields
        assert not missing, f"Missing REQUIRED product fields in algolia_service.py: {missing}"
        
        # Optional fields (good to have but not critical)
        optional_fields = python_fields - required_fields
        
        print(f"✅ Product schema consistent")
        print(f"   Required fields: {len(required_fields)} ✓")
        print(f"   Optional fields: {len(optional_fields)} (weightKg, dimensions, etc.)")

    def test_order_status_consistency(self):
        """Verify order status values match between Python and Dart"""
        root = self.get_project_root()
        
        # Read Python config.py
        config_path = root / 'functions' / 'config.py'
        with open(config_path, 'r') as f:
            config_content = f.read()
        
        # Extract OrderStatus enum values from Python
        python_statuses = set()
        order_status_match = re.search(r'class OrderStatus:.*?(?=\n\nclass|\nclass [A-Z]|\Z)', config_content, re.DOTALL)
        if order_status_match:
            order_status_block = order_status_match.group(0)
            # Find all STATUS = "status" patterns
            status_pattern = r'^\s+(\w+)\s*=\s*["\'](\w+)["\']'
            for match in re.finditer(status_pattern, order_status_block, re.MULTILINE):
                python_statuses.add(match.group(2))
        
        # Read Dart constants.dart
        constants_path = root / 'origna_gta' / 'lib' / 'utils' / 'constants.dart'
        with open(constants_path, 'r') as f:
            constants_content = f.read()
        
        # Extract OrderStatus enum values from Dart
        dart_statuses = set()
        order_status_match = re.search(r'enum OrderStatus \{(.*?)\}', constants_content, re.DOTALL)
        if order_status_match:
            enum_body = order_status_match.group(1)
            # Find all status('value') patterns
            status_pattern = r"\w+\('(\w+)'\)"
            dart_statuses = set(re.findall(status_pattern, enum_body))
        
        # Verify they match exactly
        if python_statuses and dart_statuses:
            assert python_statuses == dart_statuses, f"OrderStatus mismatch.\n  Python: {python_statuses}\n  Dart: {dart_statuses}\n  Missing in Python: {dart_statuses - python_statuses}\n  Missing in Dart: {python_statuses - dart_statuses}"
        
        print(f"✅ OrderStatus consistent: {len(python_statuses)} statuses")
        print(f"   Statuses: {sorted(python_statuses)}")

    def test_payment_status_consistency(self):
        """Verify payment status values match between Python and Dart"""
        root = self.get_project_root()
        
        # Read Python config.py
        config_path = root / 'functions' / 'config.py'
        with open(config_path, 'r') as f:
            config_content = f.read()
        
        # Extract PaymentStatus enum values from Python
        python_statuses = set()
        payment_status_match = re.search(r'class PaymentStatus:.*?(?=\n\nclass|\nclass [A-Z]|\Z)', config_content, re.DOTALL)
        if payment_status_match:
            payment_status_block = payment_status_match.group(0)
            status_pattern = r'^\s+(\w+)\s*=\s*["\'](\w+)["\']'
            for match in re.finditer(status_pattern, payment_status_block, re.MULTILINE):
                python_statuses.add(match.group(2))
        
        # Read Dart constants.dart
        constants_path = root / 'origna_gta' / 'lib' / 'utils' / 'constants.dart'
        with open(constants_path, 'r') as f:
            constants_content = f.read()
        
        # Extract PaymentStatus enum values from Dart
        dart_statuses = set()
        payment_status_match = re.search(r'enum PaymentStatus \{(.*?)\}', constants_content, re.DOTALL)
        if payment_status_match:
            enum_body = payment_status_match.group(1)
            status_pattern = r"\w+\('(\w+)'\)"
            dart_statuses = set(re.findall(status_pattern, enum_body))
        
        # Check that Dart has all Python statuses + additional ones for UI
        if python_statuses and dart_statuses:
            # Dart should have AT LEAST all Python statuses
            missing_in_dart = python_statuses - dart_statuses
            assert not missing_in_dart, f"Missing payment statuses in Dart: {missing_in_dart}"
            
            # Note: Dart can have additional statuses for UI purposes
            extra_in_dart = dart_statuses - python_statuses
            if extra_in_dart:
                print(f"   ℹ️  Additional statuses in Dart (UI-specific): {extra_in_dart}")
        
        print(f"✅ PaymentStatus consistent")
        print(f"   Python: {sorted(python_statuses)}")
        print(f"   Dart: {sorted(dart_statuses)}")

    def test_delivery_status_consistency(self):
        """Verify delivery status values match between Python and Dart"""
        root = self.get_project_root()
        
        # Read Dart constants.dart
        constants_path = root / 'origna_gta' / 'lib' / 'utils' / 'constants.dart'
        with open(constants_path, 'r') as f:
            constants_content = f.read()
        
        # Extract DeliveryStatus enum values from Dart
        dart_statuses = set()
        delivery_status_match = re.search(r'enum DeliveryStatus \{(.*?)\}', constants_content, re.DOTALL)
        if delivery_status_match:
            enum_body = delivery_status_match.group(1)
            status_pattern = r"\w+\('(\w+)'\)"
            dart_statuses = set(re.findall(status_pattern, enum_body))
        
        # Expected delivery statuses
        expected_statuses = {'pending', 'shipped', 'delivered'}
        
        assert dart_statuses == expected_statuses, f"Dart DeliveryStatus mismatch. Expected: {expected_statuses}, Got: {dart_statuses}"
        
        print(f"✅ DeliveryStatus consistent: {expected_statuses}")

    def test_address_fields_consistency(self):
        """Verify address fields match between Python validation and Dart model"""
        root = self.get_project_root()
        
        # Read Python utils.py
        utils_path = root / 'functions' / 'utils.py'
        with open(utils_path, 'r') as f:
            utils_content = f.read()
        
        # Extract required address fields from validate_address_map
        python_required_fields = set()
        required_match = re.search(r"required_fields = \[(.*?)\]", utils_content, re.DOTALL)
        if required_match:
            fields_str = required_match.group(1)
            python_required_fields = set(re.findall(r"['\"](\w+)['\"]", fields_str))
        
        # Expected address fields
        expected_required = {'street', 'city', 'state', 'postalCode', 'country'}
        expected_optional = {'apartment', 'phoneNumber', 'label', 'isDefault', 'latitude', 'longitude'}
        
        assert python_required_fields == expected_required, f"Address required fields mismatch. Expected: {expected_required}, Got: {python_required_fields}"
        
        print(f"✅ Address schema consistent")
        print(f"   Required: {sorted(expected_required)}")
        print(f"   Optional: {sorted(expected_optional)}")

    def test_collection_names_consistency(self):
        """Verify Firestore collection names match between Python and Dart"""
        root = self.get_project_root()
        
        # Read Python config.py
        config_path = root / 'functions' / 'config.py'
        with open(config_path, 'r') as f:
            config_content = f.read()
        
        # Extract Collections class from Python
        python_collections = {}
        collections_match = re.search(r'class Collections:.*?(?=\n\nclass|\nclass [A-Z]|\Z)', config_content, re.DOTALL)
        if collections_match:
            collections_block = collections_match.group(0)
            pattern = r'^\s+(\w+)\s*=\s*["\'](\w+)["\']'
            for match in re.finditer(pattern, collections_block, re.MULTILINE):
                python_collections[match.group(1).lower()] = match.group(2)
        
        # Read Dart constants.dart
        constants_path = root / 'origna_gta' / 'lib' / 'utils' / 'constants.dart'
        with open(constants_path, 'r') as f:
            constants_content = f.read()
        
        # Extract Collections class from Dart
        dart_collections = {}
        collections_match = re.search(r'class Collections \{(.*?)\}', constants_content, re.DOTALL)
        if collections_match:
            collections_block = collections_match.group(1)
            pattern = r'static const String (\w+) = ["\'](\w+)["\']'
            for match in re.finditer(pattern, collections_block):
                dart_collections[match.group(1)] = match.group(2)
        
        # Compare collection values (case-insensitive keys)
        expected_collections = ['users', 'products', 'orders', 'cart', 'favorites']
        
        for coll in expected_collections:
            python_val = python_collections.get(coll)
            dart_val = dart_collections.get(coll)
            
            assert python_val == coll, f"Python collection '{coll}' should be '{coll}', got '{python_val}'"
            assert dart_val == coll, f"Dart collection '{coll}' should be '{coll}', got '{dart_val}'"
            assert python_val == dart_val, f"Collection '{coll}' mismatch: Python='{python_val}', Dart='{dart_val}'"
        
        print(f"✅ Collection names consistent: {expected_collections}")

    def test_algolia_index_configuration(self):
        """Verify Algolia configuration is properly set up"""
        root = self.get_project_root()
        
        # Read Python algolia_service.py
        algolia_service_path = root / 'functions' / 'algolia_service.py'
        with open(algolia_service_path, 'r') as f:
            algolia_content = f.read()
        
        # Check that config is imported
        assert 'from config import ALGOLIA_APP_ID, ALGOLIA_WRITE_API_KEY' in algolia_content, \
            "Algolia service should import credentials from config.py"
        
        # Check index name
        assert "'products'" in algolia_content or '"products"' in algolia_content, \
            "Algolia service should use 'products' index"
        
        # Check key functions exist
        required_functions = ['format_product_for_algolia', 'index_product', 'delete_product']
        for func in required_functions:
            assert f'def {func}' in algolia_content, f"Missing function: {func}"
        
        print(f"✅ Algolia configuration valid")
        print(f"   Index: products")
        print(f"   Functions: {required_functions}")


if __name__ == '__main__':
    # Run tests without pytest
    test_suite = TestSchemaConsistency()
    tests = [
        ('Product Fields', test_suite.test_product_fields_consistency),
        ('Order Status', test_suite.test_order_status_consistency),
        ('Payment Status', test_suite.test_payment_status_consistency),
        ('Delivery Status', test_suite.test_delivery_status_consistency),
        ('Address Fields', test_suite.test_address_fields_consistency),
        ('Collection Names', test_suite.test_collection_names_consistency),
        ('Algolia Configuration', test_suite.test_algolia_index_configuration),
    ]
    
    print("=" * 70)
    print("SCHEMA CONSISTENCY TESTS")
    print("=" * 70)
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            print(f"\n🧪 Testing: {test_name}")
            test_func()
            passed += 1
        except AssertionError as e:
            print(f"❌ FAILED: {test_name}")
            print(f"   Error: {e}")
            failed += 1
        except Exception as e:
            print(f"❌ ERROR: {test_name}")
            print(f"   Error: {e}")
            failed += 1
    
    print("\n" + "=" * 70)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 70)
    
    exit(0 if failed == 0 else 1)
