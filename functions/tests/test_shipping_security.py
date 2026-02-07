import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Set TESTING environment variable BEFORE importing main
os.environ['TESTING'] = 'true'

# 1. Setup global mocks BEFORE importing main
mock_firebase_functions = MagicMock()
mock_firebase_admin = MagicMock()
mock_stripe = MagicMock()
mock_boto3 = MagicMock()
mock_mailjet = MagicMock()
mock_google_auth = MagicMock()
mock_google_cloud_firestore = MagicMock()
mock_secret_manager = MagicMock()

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
mock_firebase_functions.https_fn.FunctionsErrorCode = MagicMock()

module_mocks = {
    'firebase_functions': mock_firebase_functions,
    'firebase_functions.https_fn': mock_firebase_functions.https_fn,
    'firebase_functions.firestore_fn': mock_firebase_functions.firestore_fn,
    'firebase_functions.params': mock_firebase_functions.params,
    'firebase_admin': mock_firebase_admin,
    'firebase_admin.firestore': mock_firebase_admin.firestore,
    'firebase_admin.auth': mock_firebase_admin.auth,
    'firebase_admin.credentials': mock_firebase_admin.credentials,
    'stripe': mock_stripe,
    'google.cloud.firestore': mock_google_cloud_firestore,
    'google.cloud.firestore_v1.base_client': MagicMock(),
    'google.auth': mock_google_auth,
    'google.auth.transport.requests': MagicMock(),
    'google.cloud.secretmanager': mock_secret_manager,
    'google.cloud.secretmanager.SecretManagerServiceClient': MagicMock(),
    'mailjet_rest': mock_mailjet,
    'boto3': mock_boto3
}

with patch.dict(sys.modules, module_mocks):
    import main
    from handlers import payment_stripe
    from main import calculate_shipping_cost, create_checkout_session

class TestPaymentSecurity(unittest.TestCase):
    def setUp(self):
        # Configure Firebase Admin mock properly
        main.firebase_admin = mock_firebase_admin
        mock_firebase_admin.initialize_app = MagicMock()
        mock_firebase_admin._apps = {}
        mock_firebase_admin.get_app = MagicMock()
        mock_firebase_admin.delete_app = MagicMock()

        main.stripe = mock_stripe
        mock_stripe.checkout.Session.create.reset_mock()

        # Create default mock db and rate limiter for all tests
        self.mock_db = MagicMock()
        self.mock_rate_limiter = MagicMock()
        self.mock_rate_limiter.check_rate_limit.return_value = (True, "OK")

        # Patch get_db and get_rate_limiter for all tests
        self.patcher_db = patch.object(payment_stripe, 'get_db', return_value=self.mock_db)
        self.patcher_rate_limiter = patch.object(payment_stripe, 'get_rate_limiter', return_value=self.mock_rate_limiter)
        self.patcher_db.start()
        self.patcher_rate_limiter.start()

    def tearDown(self):
        self.patcher_db.stop()
        self.patcher_rate_limiter.stop()

    def test_price_tampering_protection(self):
        """
        Scenario: Malicious user sends price=1 for a $100 product.
        Expectation: Session rejected due to price mismatch.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "hacker@example.com",
            "amount": 100000,
            "subtotal": 100000.00,
            "items": [{
                "productId": "prod_1",
                "quantity": 1,
                "price": 1.00,  # FAKE PRICE
                "sellerId": "seller_elon",
                "name": "Tesla Cybertruck",
                "description": "Electric pickup truck",
                "imageUrls": ["http://img.com/truck.jpg"],
                "sellerAddress": {"street": "1 Tesla St", "city": "Markham", "state": "ON", "postalCode": "L3R 4H5", "country": "Canada"}
            }],
            "shippingAddress": {
                "street": "123 Test St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON",
                "country": "Canada",
                "longitude": -79.0,
                "latitude": 43.0
            }
        }

        # Mock DB Product Return (REAL PRICE)
        mock_product = MagicMock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            "name": "Tesla Cybertruck",
            "price": 100000.00,  # REAL PRICE
            "stockQuantity": 5,
            "sellerId": "seller_elon",
            "sellerAddress": {"state": "TX", "longitude": -97.0, "latitude": 30.0}
        }

        # Mock seller
        mock_seller = MagicMock()
        mock_seller.exists = True
        mock_seller.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }

        # Setup Database mocks
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        mock_transaction = MagicMock()
        mock_transaction.get.return_value = mock_seller
        self.mock_db.transaction.return_value = mock_transaction
        self.mock_db.transaction.return_value.__enter__.return_value = mock_transaction
        self.mock_db.transaction.return_value.__exit__.return_value = None

        # Mock Stripe Return
        mock_stripe.checkout.Session.create.return_value = MagicMock(id="sess_1", url="http://pay")

        # Execute - Should REJECT the tampered price
        with self.assertRaises(MockHttpsError) as context:
            create_checkout_session(req)

        # Verify the error message indicates price mismatch
        self.assertIn("Price mismatch", str(context.exception.message))

        # Verify Stripe was NOT called (transaction rejected before payment)
        mock_stripe.checkout.Session.create.assert_not_called()

    def test_server_side_shipping_calculation(self):
        """
        Test that shipping is calculated using helper function, ignoring client request.
        """
        # Scenario: Same province (ON to ON) fallback shipping
        items = [{
            "sellerId": "s1",
            "sellerAddress": {"state": "ON"},
            "quantity": 1
        }]
        buyer_addr = {
            "street": "123 Test St",
            "city": "Toronto",
            "postalCode": "M5V 1A1",
            "state": "ON",
            "country": "Canada",
            "latitude": 43.0,
            "longitude": -79.0
        }

        cost = calculate_shipping_cost(items, buyer_addr)

        # Fallback same province = 12.99
        self.assertEqual(cost, 12.99)

    def test_free_shipping_items_are_ignored(self):
        """
        Scenario: All items are marked freeShipping.
        Expectation: Shipping cost is zero (no fixed/tiered/fallback applied).
        """
        items = [{
            "sellerId": "s1",
            "sellerAddress": {"state": "ON"},
            "quantity": 2,
            "freeShipping": True
        }]
        buyer_addr = {
            "street": "123 Test St",
            "city": "Toronto",
            "postalCode": "M5V 1A1",
            "state": "ON",
            "country": "Canada",
            "latitude": 43.0,
            "longitude": -79.0
        }

        cost = calculate_shipping_cost(items, buyer_addr)
        self.assertEqual(cost, 0.0)

    def test_multi_seller_fixed_price_shipping(self):
        """
        Scenario: Multiple sellers, all items have fixed price for speed.
        Expectation: Fixed price total is used (no tiered/fallback).
        """
        items = [
            {
                "sellerId": "s1",
                "sellerAddress": {"state": "ON"},
                "quantity": 2,
                "deliveryOptions": [
                    {"speed": "express", "isEnabled": True, "price": 4.0}
                ]
            },
            {
                "sellerId": "s2",
                "sellerAddress": {"state": "ON"},
                "quantity": 1,
                "deliveryOptions": [
                    {"speed": "express", "isEnabled": True, "price": 7.5}
                ]
            }
        ]
        buyer_addr = {
            "street": "123 Test St",
            "city": "Toronto",
            "postalCode": "M5V 1A1",
            "state": "ON",
            "country": "Canada",
            "latitude": 43.0,
            "longitude": -79.0
        }

        cost = calculate_shipping_cost(items, buyer_addr, speed="express")
        # Seller s1: 2 * 4.0 = 8.0, Seller s2: 1 * 7.5 = 7.5
        self.assertEqual(cost, 15.5)

    def test_mixed_delivery_options_fallback(self):
        """
        Scenario: Mixed delivery options across sellers.
        Expectation: Fixed price used only for seller with full coverage, fallback for others.
        """
        items = [
            {
                "sellerId": "s1",
                "sellerAddress": {"state": "ON"},
                "quantity": 1,
                "deliveryOptions": [
                    {"speed": "standard", "isEnabled": True, "price": 5.0}
                ]
            },
            {
                "sellerId": "s2",
                "sellerAddress": {"state": "ON"},
                "quantity": 1,
                "deliveryOptions": []
            }
        ]
        buyer_addr = {
            "street": "123 Test St",
            "city": "Toronto",
            "postalCode": "M5V 1A1",
            "state": "ON",
            "country": "Canada",
            "latitude": 43.0,
            "longitude": -79.0
        }

        # For seller s1: fixed price 5.0, seller s2: fallback same province 12.99
        cost = calculate_shipping_cost(items, buyer_addr, speed="standard")
        self.assertAlmostEqual(cost, 17.99, places=2)

    def test_checkout_rejects_abusive_quantity(self):
        """
        Scenario: Malicious user sends quantity above allowed max (100).
        Expectation: HttpsError thrown.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "abuse@example.com",
            "amount": 100,
            "subtotal": 1010,
            "items": [{
                "productId": "prod_1",
                "quantity": 101,  # ABUSIVE QUANTITY
                "price": 10.0,
                "sellerId": "seller_1",
                "name": "Test Product"
            }],
            "shippingAddress": {
                "street": "123 Test St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON",
                "country": "Canada"
            }
        }

        # Mock DB Product with stock check
        mock_product = MagicMock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            "name": "Test Product",
            "price": 10.0,
            "stockQuantity": 50,  # Only 50 in stock
            "sellerId": "seller_1"
        }

        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        self.mock_db.collection.return_value.document.return_value = mock_doc_ref

        with self.assertRaises(MockHttpsError):
            create_checkout_session(req)

    def test_checkout_rejects_missing_address_fields(self):
        """
        Scenario: Malicious user sends incomplete address.
        Expectation: HttpsError thrown.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "abuse@example.com",
            "amount": 100,
            "subtotal": 100,
            "items": [{
                "productId": "prod_1",
                "quantity": 1,
                "price": 10.0,
                "sellerId": "seller_1",
                "name": "Test Product"
            }],
            "shippingAddress": {
                "state": "ON",
                "country": "Canada"
            }
        }

        with self.assertRaises(MockHttpsError):
            create_checkout_session(req)

    def test_checkout_rejects_invalid_postal_code(self):
        """
        Scenario: Malicious user sends invalid postal code.
        Expectation: HttpsError thrown.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "abuse@example.com",
            "amount": 100,
            "subtotal": 100,
            "items": [{
                "productId": "prod_1",
                "quantity": 1,
                "price": 10.0,
                "sellerId": "seller_1",
                "name": "Test Product"
            }],
            "shippingAddress": {
                "street": "123 Test St",
                "city": "Toronto",
                "postalCode": "INVALID",
                "state": "ON",
                "country": "Canada"
            }
        }

        with self.assertRaises(MockHttpsError):
            create_checkout_session(req)

    def test_checkout_rejects_overlong_address_fields(self):
        """
        Scenario: Malicious user sends overly long address fields.
        Expectation: HttpsError thrown.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "abuse@example.com",
            "amount": 100,
            "subtotal": 100,
            "items": [{
                "productId": "prod_1",
                "quantity": 1,
                "price": 10.0,
                "sellerId": "seller_1",
                "name": "Test Product"
            }],
            "shippingAddress": {
                "street": "X" * 200,
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON",
                "country": "Canada"
            }
        }

        with self.assertRaises(MockHttpsError):
            create_checkout_session(req)

if __name__ == '__main__':
    unittest.main()
