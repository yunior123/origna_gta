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
        # Import payment_stripe handler
        from handlers import payment_stripe
        
        # Mock the db and rate_limiter at module level
        main.db = MagicMock()
        payment_stripe._db = MagicMock()
        payment_stripe._rate_limiter = MagicMock()
        payment_stripe._firestore = MagicMock()
        
        # Make get_db return mocked db
        payment_stripe.get_db = MagicMock(return_value=payment_stripe._db)
        
        # Make get_rate_limiter return mocked rate limiter
        payment_stripe._rate_limiter.check_rate_limit.return_value = (True, "OK")
        payment_stripe._rate_limiter.get_identifier.return_value = "test_user"
        payment_stripe.get_rate_limiter = MagicMock(return_value=payment_stripe._rate_limiter)
        
        main.stripe = mock_stripe
        mock_stripe.checkout.Session.create.reset_mock()

    def test_ontario_children_clothing_tax_code(self):
        """
        Scenario: Buying Children's Clothing (Category 17).
        Expectation: Passed 'txcd_20030002' to Stripe.
        """
        from handlers import payment_stripe
        
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "parent@example.com",
            "amount": 10000, 
            "subtotal": 10000,
            "items": [{
                "productId": "prod_kids_shirt",
                "quantity": 1,
                "price": 100.00,
                "sellerId": "seller_1",
                "name": "Kids Shirt",
                "description": "Children's clothing item",
                "imageUrls": ["http://img.com/shirt.jpg"],
                "sellerAddress": {"street": "123 Test St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"},
                "categoryId": 17
            }],
            "shippingAddress": {
                "street": "123 Kids St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "province": "ON",
                "country": "Canada"
            }
        }

        # Mock Seller Document
        mock_seller_doc = MagicMock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }

        # Mock DB Product
        mock_product = MagicMock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            "name": "Kids Shirt",
            "price": 100.00,
            "categoryId": 17,
            "stockQuantity": 50,
            "sellerId": "seller_1",
            "sellerAddress": {"state": "ON"}
        }

        # Setup mocks
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        payment_stripe._db.collection.return_value.document.return_value = mock_doc_ref
        
        mock_transaction = MagicMock()
        mock_transaction.get.return_value = mock_seller_doc
        payment_stripe._db.transaction.return_value = mock_transaction
        payment_stripe._db.transaction.return_value.__enter__.return_value = mock_transaction
        payment_stripe._db.transaction.return_value.__exit__.return_value = None

        mock_session = MagicMock(id="sess_1", url="http://test")
        mock_stripe.checkout.Session.create.return_value = mock_session

        with patch.object(main, 'calculate_shipping_cost', return_value=0.0):
            create_checkout_session(req)

        # Inspect Stripe Call
        args, kwargs = mock_stripe.checkout.Session.create.call_args
        
        # Verify automatic_tax enabled
        self.assertTrue(kwargs.get('automatic_tax', {}).get('enabled'))
        
        # Verify Line Item Tax Code
        line_items = kwargs['line_items']
        product_item = line_items[0]
        tax_code = product_item['price_data']['product_data']['tax_code']
        
        print(f"\n[AUDIT] Tax Code Used: {tax_code}")
        
        self.assertEqual(tax_code, "txcd_20030002", "Should use Children's Clothing tax code for Category 17")

    def test_basic_groceries_tax_code(self):
        """
        Scenario: Buying Groceries (Category 19).
        Expectation: Passed 'txcd_30060005' to Stripe.
        """
        from handlers import payment_stripe
        
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "shopper@example.com",
            "amount": 100, 
            "subtotal": 100,
            "items": [{
                "productId": "prod_apple",
                "quantity": 1,
                "sellerId": "seller_1",
                "name": "Apple",
                "price": 1.00,
                "description": "Fresh fruit",
                "imageUrls": ["http://img.com/apple.jpg"],
                "sellerAddress": {"street": "123 Farm St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"},
                "categoryId": 19
            }],
            "shippingAddress": {
                "street": "123 Grocery St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "province": "ON",
                "country": "Canada"
            }
        }

        # Mock Seller Document
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
            "categoryId": 19,
            "stockQuantity": 100,
            "sellerId": "seller_1",
            "sellerAddress": {"state": "ON"}
        }

        # Setup mocks
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        payment_stripe._db.collection.return_value.document.return_value = mock_doc_ref
        
        mock_transaction = MagicMock()
        mock_transaction.get.return_value = mock_seller_doc
        payment_stripe._db.transaction.return_value = mock_transaction
        payment_stripe._db.transaction.return_value.__enter__.return_value = mock_transaction
        payment_stripe._db.transaction.return_value.__exit__.return_value = None
        
        mock_stripe.checkout.Session.create.return_value = MagicMock(id="sess_2", url="http://test")

        with patch.object(main, 'calculate_shipping_cost', return_value=0.0):
            create_checkout_session(req)

        args, kwargs = mock_stripe.checkout.Session.create.call_args
        line_items = kwargs['line_items']
        product_item = line_items[0]
        tax_code = product_item['price_data']['product_data']['tax_code']

        print(f"[AUDIT] Grocery Tax Code Used: {tax_code}")
        
        self.assertEqual(tax_code, "txcd_30060005", "Should use Basic Groceries tax code for Category 19")

if __name__ == '__main__':
    unittest.main()
