import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# 1. Setup global mocks BEFORE importing main
mock_firebase_functions = MagicMock()
mock_firebase_admin = MagicMock()
mock_stripe = MagicMock()
mock_boto3 = MagicMock()
mock_mailjet = MagicMock()
mock_requests = MagicMock()

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
    'stripe': mock_stripe,
    'google.cloud.firestore': MagicMock(),
    'mailjet_rest': mock_mailjet,
    'boto3': mock_boto3,
    'requests': mock_requests
}

with patch.dict(sys.modules, module_mocks):
    sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    import main
    from main import create_checkout_session, calculate_shipping_cost

class TestPaymentSecurity(unittest.TestCase):
    def setUp(self):
        main.db = MagicMock()
        main.stripe = mock_stripe
        main.requests = mock_requests
        mock_stripe.checkout.Session.create.reset_mock()

    def test_price_tampering_protection(self):
        """
        Scenario: Malicious user sends price=1 for a $100 product.
        Expectation: Session created with $100 (server DB price).
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "hacker@example.com",
            # HACKER SENDING FAKE TOTALS
            "amount": 100, 
            "total": 1.00,
            "items": [{
                "productId": "prod_1",
                "quantity": 1,
                "price": 1.00, # FAKE PRICE
                "sellerId": "seller_elon", 
                "name": "Tesla Cybertruck"
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

        # Mock DB Product Return (REAL PRICE)
        mock_product = MagicMock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            "name": "Tesla Cybertruck",
            "price": 100000.00, # REAL PRICE
            "stockQuantity": 5,
            "sellerId": "seller_elon",
            "sellerAddress": {"state": "TX", "longitude": -97.0, "latitude": 30.0}
        }

        # Setup Transaction Mock
        mock_transaction = MagicMock()
        main.db.transaction.return_value.__enter__.return_value = mock_transaction
        
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product
        main.db.collection.return_value.document.return_value = mock_doc_ref

        # Mock Stripe Return
        main.stripe.checkout.Session.create.return_value = MagicMock(id="sess_1", url="http://pay")

        # Execute
        create_checkout_session(req)

        # CHECK STRIPE CALL
        args, kwargs = main.stripe.checkout.Session.create.call_args
        line_items = kwargs['line_items']
        
        # Verify line item 0 is the product
        product_item = line_items[0]
        unit_amount = product_item['price_data']['unit_amount']
        
        # Should be 100000 * 100 cents = 10,000,000
        self.assertEqual(unit_amount, 10000000, "Should use DB price (100k), not request price (1)")

    def test_server_side_shipping_calculation(self):
        """
        Test that shipping is calculated using helper function, ignoring client request.
        """
        # Scenario: Same province (ON to ON) fallback shipping
        # We won't mock Geoapify, so it falls back to matrix.
        
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

        # Mock requests to fail or return nothing to force fallback
        main.requests.post.side_effect = Exception("Geoapify down")

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

        main.requests.post.side_effect = Exception("Geoapify down")

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
        Scenario: Malicious user sends quantity above allowed max.
        Expectation: HttpsError thrown.
        """
        req = MagicMock()
        req.auth.uid = "user_1"
        req.data = {
            "userId": "user_1",
            "customerEmail": "abuse@example.com",
            "amount": 100,
            "items": [{
                "productId": "prod_1",
                "quantity": 101,
                "price": 10.0,
                "sellerId": "seller_1",
                "name": "Test Product"
            }],
            "deliveryInfo": {
                "street": "123 Test St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON",
                "country": "Canada"
            }
        }

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
            "items": [{
                "productId": "prod_1",
                "quantity": 1,
                "price": 10.0,
                "sellerId": "seller_1",
                "name": "Test Product"
            }],
            "deliveryInfo": {
                "state": "ON",
                "country": "Canada"
            }
        }

        with self.assertRaises(MockHttpsError):
            create_checkout_session(req)

if __name__ == '__main__':
    unittest.main()
