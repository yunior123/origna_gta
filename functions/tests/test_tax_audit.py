import os
import sys
import unittest
from unittest.mock import MagicMock, patch

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
    from handlers import payment_stripe
    from main import create_checkout_session

class TestTaxAudit(unittest.TestCase):
    def setUp(self):
        # CRITICAL: Reset module-level globals before each test
        payment_stripe._db = None
        payment_stripe._rate_limiter = None
        payment_stripe._firestore = None

        main.stripe = mock_stripe
        mock_stripe.checkout.Session.create.reset_mock()

        # Create mock DB
        self.mock_db = MagicMock()

        # Create mock rate limiter
        self.mock_rate_limiter = MagicMock()
        self.mock_rate_limiter.check_rate_limit.return_value = (True, "OK")

        # Start patches using patch.object
        self.patcher_db = patch.object(payment_stripe, 'get_db', return_value=self.mock_db)
        self.patcher_rate_limiter = patch.object(payment_stripe, 'get_rate_limiter', return_value=self.mock_rate_limiter)
        self.patcher_shipping = patch.object(main, 'calculate_shipping_cost', return_value=0.0)

        self.patcher_db.start()
        self.patcher_rate_limiter.start()
        self.patcher_shipping.start()

    def tearDown(self):
        self.patcher_db.stop()
        self.patcher_rate_limiter.stop()
        self.patcher_shipping.stop()

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
            "amount": 100,
            "subtotal": 100.00,  # Must match price * quantity: 100.00 * 1 = 100.00
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
                "state": "ON",
                "country": "Canada"
            }
        }

        # Mock Seller Document (returned by collection('users').document(seller_id).get())
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
            "sellerAddress": {"state": "ON"},
            "isActive": True
        }

        # Setup mock db to return different docs based on collection/document
        def mock_collection(name):
            mock_coll = MagicMock()
            def mock_document(doc_id=None):
                mock_doc_ref = MagicMock()
                mock_doc_ref.id = doc_id or 'order_123'
                if name == 'users':
                    mock_doc_ref.get.return_value = mock_seller_doc
                elif name == 'products':
                    mock_doc_ref.get.return_value = mock_product
                else:  # orders
                    mock_doc_ref.get.return_value = MagicMock(exists=True, to_dict=lambda: {})
                return mock_doc_ref
            mock_coll.document = mock_document
            return mock_coll

        self.mock_db.collection.side_effect = mock_collection
        self.mock_db.transaction.return_value = MagicMock()

        mock_session = MagicMock(id="sess_1", url="http://test")
        mock_stripe.checkout.Session.create.return_value = mock_session

        create_checkout_session(req)

        # Inspect Stripe Call
        args, kwargs = mock_stripe.checkout.Session.create.call_args

        # OrignaGTA calculates tax server-side and adds it as a line item.
        # Stripe automatic_tax is intentionally disabled to avoid double taxation.
        self.assertFalse(kwargs.get('automatic_tax', {}).get('enabled', False))

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
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "shopper@example.com",
            "amount": 1,
            "subtotal": 1.00,  # Must match price * quantity: 1.00 * 1 = 1.00
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
                "state": "ON",
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
            "sellerAddress": {"state": "ON"},
            "isActive": True
        }

        # Setup mock db to return different docs based on collection/document
        def mock_collection(name):
            mock_coll = MagicMock()
            def mock_document(doc_id=None):
                mock_doc_ref = MagicMock()
                mock_doc_ref.id = doc_id or 'order_123'
                if name == 'users':
                    mock_doc_ref.get.return_value = mock_seller_doc
                elif name == 'products':
                    mock_doc_ref.get.return_value = mock_product
                else:  # orders
                    mock_doc_ref.get.return_value = MagicMock(exists=True, to_dict=lambda: {})
                return mock_doc_ref
            mock_coll.document = mock_document
            return mock_coll

        self.mock_db.collection.side_effect = mock_collection
        self.mock_db.transaction.return_value = MagicMock()

        mock_stripe.checkout.Session.create.return_value = MagicMock(id="sess_2", url="http://test")

        create_checkout_session(req)

        args, kwargs = mock_stripe.checkout.Session.create.call_args
        line_items = kwargs['line_items']
        product_item = line_items[0]
        tax_code = product_item['price_data']['product_data']['tax_code']

        print(f"[AUDIT] Grocery Tax Code Used: {tax_code}")

        self.assertEqual(tax_code, "txcd_30060005", "Should use Basic Groceries tax code for Category 19")

if __name__ == '__main__':
    unittest.main()
