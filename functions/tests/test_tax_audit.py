import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# Global Mocks
mock_firebase_functions = MagicMock()
mock_firebase_admin = MagicMock()
mock_stripe = MagicMock()

# Decorator passthrough
def pass_through_decorator(*args, **kwargs):
    def decorator(f):
        return f
    return decorator

mock_firebase_functions.https_fn.on_call.side_effect = pass_through_decorator
mock_firebase_functions.https_fn.on_request.side_effect = pass_through_decorator
mock_firebase_functions.firestore_fn.on_document_updated.side_effect = pass_through_decorator
mock_firebase_functions.params.SecretParam.return_value.value = "test_key"
mock_firebase_admin.firestore.transactional = lambda f: f

class MockHttpsError(Exception):
    def __init__(self, code, message, details=None):
        self.code = code
        self.message = message
        self.details = details

mock_firebase_functions.https_fn.HttpsError = MockHttpsError

module_mocks = {
    'firebase_functions': mock_firebase_functions,
    'firebase_functions.https_fn': mock_firebase_functions.https_fn,
    'firebase_functions.firestore_fn': mock_firebase_functions.firestore_fn,
    'firebase_functions.params': mock_firebase_functions.params,
    'firebase_admin': mock_firebase_admin,
    'firebase_admin.firestore': mock_firebase_admin.firestore,
    'firebase_admin.auth': mock_firebase_admin.auth,
    'stripe': mock_stripe,
    'google.cloud.firestore': MagicMock(),
    'mailjet_rest': MagicMock(),
    'boto3': MagicMock(),
    'botocore': MagicMock(),
    'botocore.config': MagicMock(),
    # Standard library mocks if needed
}

with patch.dict(sys.modules, module_mocks):
    sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    import main
    from main import create_checkout_session

class TestTaxAudit(unittest.TestCase):
    def setUp(self):
        main.db = MagicMock()
        main.stripe = mock_stripe
        mock_stripe.checkout.Session.create.reset_mock()
        
        # Mock rate limiter to always allow requests
        main.rate_limiter = MagicMock()
        main.rate_limiter.check_rate_limit.return_value = (True, "OK")
        main.rate_limiter.get_identifier.return_value = "test_user"

    def test_ontario_children_clothing_tax_code(self):
        """
        Scenario: Buying Children's Clothing (Category 17).
        Expectation: Passed 'txcd_20030002' to Stripe.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "parent@example.com",
            "amount": 10000, # Required by validator
            "items": [{
                "productId": "prod_kids_shirt",
                "quantity": 1,
                "price": 100.00,
                "sellerId": "seller_1",
                "name": "Kids Shirt",
                "description": "Children's clothing item",  # Required field
                "imageUrls": ["http://img.com/shirt.jpg"],
                "sellerAddress": {"street": "123 Test St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"},
                "categoryId": 17
            }],
            "deliveryInfo": {
                "street": "123 Kids St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON",
                "country": "Canada"
            }
        }

        # Mock Seller Document (Required by _assert_seller_active)
        mock_seller_doc = MagicMock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }

        # Mock DB Product (Category 17 = Baby & Kids)
        mock_product = MagicMock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            "name": "Kids Shirt",
            "price": 100.00,
            "categoryId": 17, # Baby & Kids
            "stockQuantity": 50,
            "sellerId": "seller_1",
            "sellerAddress": {"state": "ON"}
        }

        mock_transaction = MagicMock()
        
        # transaction.get() is ONLY called for seller lookup
        mock_transaction.get.return_value = mock_seller_doc
        
        # Configure both the context manager AND direct return
        main.db.transaction.return_value = mock_transaction
        main.db.transaction.return_value.__enter__.return_value = mock_transaction
        
        # Create document chain for product lookups
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        main.db.collection.return_value.document.return_value = mock_doc_ref

        # Return a session object
        mock_session = MagicMock(id="sess_1", url="http://test")
        main.stripe.checkout.Session.create.return_value = mock_session

        with patch.object(main, 'calculate_shipping_cost', return_value=0.0):
            create_checkout_session(req)

        # Inspect Stripe Call
        args, kwargs = main.stripe.checkout.Session.create.call_args
        
        # Verify automatic_tax enabled
        self.assertTrue(kwargs.get('automatic_tax', {}).get('enabled'))
        
        # Verify Line Item Tax Code
        line_items = kwargs['line_items']
        product_item = line_items[0]
        tax_code = product_item['price_data']['product_data']['tax_code']
        
        print(f"\n[AUDIT] Tax Code Used: {tax_code}")
        
        self.assertEqual(tax_code, "txcd_20030002", "Should use Children's Clothing tax code for Category 17")

        def test_checkout_session_rejects_non_cad_currency(self):
            """CRITICAL: CAD-only enforcement at checkout"""
            req = MagicMock()
            req.auth.uid = "user_1"
            req.data = {
                "userId": "user_1",
                "customerEmail": "buyer@example.com",
                "currency": "usd",
                "amount": 100,
                "items": [{
                    "productId": "prod_1",
                    "quantity": 1,
                    "price": 1.00,
                    "sellerId": "seller_1",
                    "name": "Test Product",
                    "description": "Test",
                    "imageUrls": ["http://img.com/a.jpg"],
                    "sellerAddress": {"street": "1 St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"}
                }],
                "deliveryInfo": {
                    "street": "123 Test St",
                    "city": "Toronto",
                    "postalCode": "M5V 1A1",
                    "state": "ON",
                    "country": "Canada",
                    "longitude": -79.0,
                    "latitude": 43.0
                }
            }

            with self.assertRaises(MockHttpsError) as ctx:
                create_checkout_session(req)

            self.assertIn("Only CAD currency is supported", ctx.exception.message)

    def test_basic_groceries_tax_code(self):
        """
        Scenario: Buying Groceries (Category 19).
        Expectation: Passed 'txcd_30060005' to Stripe.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "shopper@example.com",
            "amount": 100, # Required by validator
            "items": [{
                "productId": "prod_apple",
                "quantity": 1,
                "sellerId": "seller_1",
                "name": "Apple",
                "price": 1.00,
                "description": "Fresh fruit",  # Required field
                "imageUrls": ["http://img.com/apple.jpg"],
                "sellerAddress": {"street": "123 Farm St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"},
                "categoryId": 19
            }],
            "deliveryInfo": {
                "street": "123 Grocery St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON",
                "country": "Canada"
            }
        }

        # Mock Seller Document (Required by _assert_seller_active)
        mock_seller_doc = MagicMock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }


        mock_product = MagicMock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            "name": "Apple",
            "price": 1.00,
            "categoryId": 19, # Groceries
            "stockQuantity": 100,
            "sellerId": "seller_1",
             "sellerAddress": {"state": "ON"}
        }

        # Create document chain for product lookups
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        main.db.collection.return_value.document.return_value = mock_doc_ref
        
        # Mock transaction for seller lookup
        mock_transaction = MagicMock()
        
        # transaction.get() is ONLY called for seller lookup
        mock_transaction.get.return_value = mock_seller_doc
        
        # Configure both the context manager AND direct return
        main.db.transaction.return_value = mock_transaction
        main.db.transaction.return_value.__enter__.return_value = mock_transaction
        
        main.stripe.checkout.Session.create.return_value = MagicMock(id="sess_2", url="http://test")

        with patch.object(main, 'calculate_shipping_cost', return_value=0.0):
            create_checkout_session(req)

        args, kwargs = main.stripe.checkout.Session.create.call_args
        line_items = kwargs['line_items']
        product_item = line_items[0]
        tax_code = product_item['price_data']['product_data']['tax_code']

        print(f"[AUDIT] Grocery Tax Code Used: {tax_code}")
        
        self.assertEqual(tax_code, "txcd_30060005", "Should use Basic Groceries tax code for Category 19")

if __name__ == '__main__':
    unittest.main()
