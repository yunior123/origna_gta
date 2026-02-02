import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# 1. Setup global mocks BEFORE importing main
mock_firebase_functions = MagicMock()
mock_firebase_admin = MagicMock()
mock_stripe = MagicMock()
mock_boto3 = MagicMock()
mock_botocore = MagicMock()
mock_mailjet = MagicMock()

# Configure decorators to pass through the function immediately
# This ensures we test the ACTUAL function, not a mock wrapper
def pass_through_decorator(*args, **kwargs):
    def decorator(f):
        return f
    return decorator

mock_firebase_functions.https_fn.on_call.side_effect = pass_through_decorator
mock_firebase_functions.https_fn.on_request.side_effect = pass_through_decorator
mock_firebase_functions.firestore_fn.on_document_updated.side_effect = pass_through_decorator
mock_firebase_functions.scheduler_fn.on_schedule.side_effect = pass_through_decorator

# Configure params
mock_firebase_functions.params.SecretParam.return_value.value = "test_secret"
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
    'firebase_functions.scheduler_fn': mock_firebase_functions.scheduler_fn,
    'firebase_functions.params': mock_firebase_functions.params,
    'firebase_admin': mock_firebase_admin,
    'firebase_admin.firestore': mock_firebase_admin.firestore,
    'firebase_admin.auth': mock_firebase_admin.auth,
    'stripe': mock_stripe,
    'google.cloud.firestore': MagicMock(),
    'mailjet_rest': mock_mailjet,
    'boto3': mock_boto3,
    'botocore': mock_botocore,
    'botocore.config': mock_botocore.config
}

with patch.dict(sys.modules, module_mocks):
    # Add functions directory to path
    sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    
    # Import main modules within the patch context
    import main
    from main import (
        capture_payment,
        stripe_webhook,
        create_checkout_session,
        submit_product_rating,
        DeliveryStatus,
        PaymentStatus,
        OrderStatus,
        PayoutStatus
    )

class TestPaymentFlow(unittest.TestCase):
    def setUp(self):
        # Reset mocks
        main.db = MagicMock()
        main.stripe = mock_stripe # Ensure we use the same mock object
        main.stripe.api_key = "STRIPE_SECRET_KEY_REDACTED"
        
        # Mock rate limiter to always allow requests
        main.rate_limiter = MagicMock()
        main.rate_limiter.check_rate_limit.return_value = (True, "OK")
        main.rate_limiter.get_identifier.return_value = "test_user"
        
        # Determine strict behaviors
        mock_stripe.PaymentIntent.capture.reset_mock()
        mock_stripe.checkout.Session.create.reset_mock()
        mock_stripe.Webhook.construct_event.reset_mock()
        
    def test_capture_payment_multi_seller_bugfix(self):
        """
        Scenario: Order is already PAID by Seller 1.
        Seller 2 calls capture_payment.
        Expectation: Success, but NO Stripe capture call.
        """
        req = MagicMock()
        req.auth.uid = "seller_2"
        req.data = {"orderId": "order_123", "trackingNumber": "T2"}

        # Mock Seller (must be active and approved)
        mock_seller_doc = MagicMock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }

        # Mock Order
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "orderId": "order_123",
            "paymentStatus": PaymentStatus.PAID,  # KEY: Already paid
            "stripePaymentIntentId": "pi_123",
            "amount": 5000,
            "items": [
                {"sellerId": "seller_1", "deliveryStatus": DeliveryStatus.SHIPPED},
                {"sellerId": "seller_2", "deliveryStatus": DeliveryStatus.PENDING}
            ]
        }
        
        # Setup DB Chain - mock both seller and order lookups
        def mock_document_chain(doc_id):
            mock_ref = MagicMock()
            if doc_id == "seller_2":
                mock_ref.get.return_value = mock_seller_doc
            elif doc_id == "order_123":
                mock_ref.get.return_value = mock_order_doc
            return mock_ref
        
        main.db.collection.return_value.document.side_effect = mock_document_chain
        
        # Mock order update ref
        mock_order_ref = mock_document_chain("order_123")

        # Execute
        resp = capture_payment(req)

        # Assertions
        self.assertTrue(resp["success"])
        main.stripe.PaymentIntent.capture.assert_not_called()  # Should SKIP capture

    def test_capture_payment_normal_flow(self):
        """
        Scenario: Order is Authorized.
        Seller 1 calls capture_payment.
        Expectation: Success, AND Stripe capture call.
        """
        req = MagicMock()
        req.auth.uid = "seller_1"
        req.data = {"orderId": "order_123", "trackingNumber": "T1"}

        # Mock Seller (must be active and approved)
        mock_seller_doc = MagicMock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }

        # Mock Order
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "orderId": "order_123",
            "paymentStatus": "authorized",  # KEY: Authorized only
            "stripePaymentIntentId": "pi_123",
            "amount": 5000,
            "items": [
                {"sellerId": "seller_1", "deliveryStatus": DeliveryStatus.PENDING}
            ]
        }
        
        # Setup DB Chain - mock both seller and order lookups
        def mock_document_chain(doc_id):
            mock_ref = MagicMock()
            if doc_id == "seller_1":
                mock_ref.get.return_value = mock_seller_doc
            elif doc_id == "order_123":
                mock_ref.get.return_value = mock_order_doc
            return mock_ref
        
        main.db.collection.return_value.document.side_effect = mock_document_chain
        
        # Mock order update ref
        mock_order_ref = mock_document_chain("order_123")

        # Execute
        resp = capture_payment(req)

        # Assertions
        self.assertTrue(resp["success"])
        main.stripe.PaymentIntent.capture.assert_called_with("pi_123", amount_to_capture=5000)

    def test_stripe_webhook_flow(self):
        """
        Scenario: Webhook received for checkout.session.completed
        Expectation: Verify signature and update order.
        """
        req = MagicMock()
        req.data = b'raw_payload'
        req.headers = {'stripe-signature': 'sig_123'}

        # Mock Stripe Verification
        mock_event = {
            "id": "evt_123",
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "id": "cs_123",
                    "client_reference_id": "order_123",
                    "payment_status": "paid",
                    "amount_total": 5000,
                    "metadata": {"userId": "u1"},
                    "payment_intent": "pi_123"
                }
            }
        }
        main.stripe.Webhook.construct_event.return_value = mock_event

        # Mock DB
        mock_order_ref = MagicMock()
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "orderId": "order_123",
            "status": OrderStatus.PENDING,
            "amount": 5000,
            "captureMethod": "manual"
        }
        
        # DB Chain: 
        # 1. webhook_events check (idempotency) -> exists=False
        # 2. orders/order_123 get -> exists=True
        # 3. orders/order_123 update
        
        mock_event_log = MagicMock()
        mock_event_log.get.return_value.exists = False
        
        def doc_side_effect(arg):
            if arg == "evt_123": return mock_event_log
            if arg == "order_123": return mock_order_ref
            return MagicMock()
            
        main.db.collection.return_value.document.side_effect = doc_side_effect
        mock_order_ref.get.return_value = mock_order_doc

        # Execute
        stripe_webhook(req)

        # Assertions
        main.stripe.Webhook.construct_event.assert_called()
        self.assertTrue(mock_order_ref.update.called)
        
        # Verify status update was 'authorized' since captureMethod is manual
        call_args = mock_order_ref.update.call_args[0][0]
        # In main.py: if capture_method == CaptureMethod.MANUAL: update paymentStatus="authorized"
        self.assertEqual(call_args.get("paymentStatus"), "authorized")

    def test_webhook_persists_stripe_amounts_and_taxes(self):
        """
        Scenario: Webhook includes amount_total, amount_subtotal, and tax details.
        Expectation: Order is updated with amount/total/taxes and authorizedAmount.
        """
        req = MagicMock()
        req.data = b'raw_payload'
        req.headers = {'stripe-signature': 'sig_456'}

        mock_event = {
            "id": "evt_456",
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "id": "cs_456",
                    "client_reference_id": "order_456",
                    "payment_status": "paid",
                    "amount_total": 6200,
                    "amount_subtotal": 6000,
                    "total_details": {"amount_tax": 200},
                    "metadata": {"userId": "u2"},
                    "payment_intent": "pi_456"
                }
            }
        }
        main.stripe.Webhook.construct_event.return_value = mock_event

        mock_order_ref = MagicMock()
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "orderId": "order_456",
            "status": OrderStatus.PENDING,
            "captureMethod": "manual",
            "amount": None,
            "expectedSubtotalCents": 6000,
        }

        mock_event_log = MagicMock()
        mock_event_log.get.return_value.exists = False

        def doc_side_effect(arg):
            if arg == "evt_456":
                return mock_event_log
            if arg == "order_456":
                return mock_order_ref
            return MagicMock()

        main.db.collection.return_value.document.side_effect = doc_side_effect
        mock_order_ref.get.return_value = mock_order_doc

        stripe_webhook(req)

        call_args = mock_order_ref.update.call_args[0][0]
        self.assertEqual(call_args.get("amount"), 6200)
        self.assertEqual(call_args.get("total"), 62.0)
        self.assertEqual(call_args.get("taxes"), {"stripeTax": 2.0})
        self.assertEqual(call_args.get("authorizedAmount"), 6200)

    def test_submit_product_rating_delivered(self):
        req = MagicMock()
        req.auth.uid = "buyer_1"
        req.data = {"orderId": "order_1", "productId": "prod_1", "rating": 5}

        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "userId": "buyer_1",
            "paymentStatus": PaymentStatus.PAID,
            "items": [{"productId": "prod_1", "deliveryStatus": DeliveryStatus.DELIVERED}],
            "ratings": {}
        }

        mock_product_doc = MagicMock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {"rating": 4.0, "ratingCount": 2}

        order_ref = MagicMock()
        order_ref.get.return_value = mock_order_doc
        product_ref = MagicMock()
        product_ref.get.return_value = mock_product_doc

        orders_collection = MagicMock()
        orders_collection.document.return_value = order_ref
        products_collection = MagicMock()
        products_collection.document.return_value = product_ref

        def collection_side_effect(name):
            if name == main.Collections.ORDERS:
                return orders_collection
            if name == main.Collections.PRODUCTS:
                return products_collection
            return MagicMock()

        main.db.collection.side_effect = collection_side_effect

        resp = submit_product_rating(req)

        self.assertTrue(resp["success"])
        mock_transaction = main.db.transaction.return_value
        mock_transaction.update.assert_any_call(
            product_ref,
            {
                "rating": 4.333333333333333,
                "ratingCount": 3,
            },
        )
        mock_transaction.update.assert_any_call(
            order_ref,
            {
                "ratings.prod_1": {
                    "rating": 5,
                    "ratedAt": main.firestore.SERVER_TIMESTAMP,
                },
                "updatedAt": main.firestore.SERVER_TIMESTAMP,
            },
        )

    def test_create_checkout_session_flow(self):
        """
        Scenario: User initiates checkout.
        Expectation: Validate stock, create Stripe Session (manual capture), create Order.
        """
        req = MagicMock()
        req.auth.uid = "user_123"
        req.data = {
            "userId": "user_123",
            "customerEmail": "test@example.com",
            "amount": 5000,
            "currency": "cad",
            "items": [
                {
                    "name": "Test Product",
                    "price": 50.00,
                    "quantity": 1,
                    "productId": "prod_1",
                    "sellerId": "seller_1",
                    "imageUrls": ["http://img.com/1.jpg"],
                    "description": "Test product description",
                    "sellerAddress": {"street": "1 Test St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"},
                    "categoryId": 1
                }
            ],
            "deliveryInfo": {
                "street": "123 Test St",
                "city": "Toronto",
                "postalCode": "M5V 1A1",
                "state": "ON", # Needs to be Canadian
                "country": "Canada",
                "formattedAddress": "123 Test St, Toronto, ON"
            },
            "subtotal": 50.00,
            "total": 50.00,
            "taxes": {"HST": 6.50},
            "shippingCost": 0
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

        # Mock Firestore Transaction for Stock Check
        mock_transaction = MagicMock()
        
        # transaction.get() is ONLY called for seller lookup (product uses product_ref.get(transaction=transaction))
        mock_transaction.get.return_value = mock_seller_doc
        
        # Configure both the context manager AND direct return
        main.db.transaction.return_value = mock_transaction
        main.db.transaction.return_value.__enter__.return_value = mock_transaction
        
        # Mock Product for Stock Validation
        mock_product_doc = MagicMock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            "name": "Test Product",
            "price": 50.00,
            "stockQuantity": 10,
            "sellerId": "seller_1",
            "sellerAddress": {"state": "ON", "longitude": -79.0, "latitude": 43.0},
            "imageUrls": ["http://img.com/1.jpg"],
            "categoryId": 1
        }
        
        # Create document chain that handles both seller and product lookups
        def mock_document_chain(doc_id=None):
            mock_ref = MagicMock()
            if doc_id == "seller_1":
                mock_ref.get.return_value = mock_seller_doc
            elif doc_id == "prod_1":
                mock_ref.get.return_value = mock_product_doc
            elif doc_id is None:
                # For new order creation
                mock_ref.id = "new_order_id"
                return mock_ref
            else:
                mock_ref.get.return_value = mock_product_doc
            return mock_ref
        
        main.db.collection.return_value.document.side_effect = mock_document_chain

        # Mock Stripe Session
        main.stripe.checkout.Session.create.return_value = MagicMock(
            id="cs_new_123",
            url="http://checkout.url"
        )

        # Mock Order Reference for Set()
        mock_order_ref = MagicMock()
        mock_order_ref.id = "new_order_id"

        # EXECUTE
        resp = create_checkout_session(req)

        # VERIFY
        self.assertEqual(resp["sessionId"], "cs_new_123")
        self.assertEqual(resp["url"], "http://checkout.url")
        
        # Verify Stripe Session creation params
        main.stripe.checkout.Session.create.assert_called()
        call_kwargs = main.stripe.checkout.Session.create.call_args[1]
        
        # CRITICAL: Verify Manual Capture
        self.assertEqual(
            call_kwargs["payment_intent_data"]["capture_method"], 
            "manual",
            "Must use manual capture for authorization workflow"
        )

class TestRefundFlow(unittest.TestCase):
    """Tests for refund processing"""

    def setUp(self):
        main.db = MagicMock()
        main.stripe = mock_stripe

    def test_process_charge_refunded_full_refund(self):
        """
        Scenario: Full refund processed.
        Expectation: Order marked as refunded, stock restored.
        """
        charge = {
            'payment_intent': 'pi_123',
            'amount_refunded': 5000,
            'refunded': True  # Full refund
        }

        # Mock order lookup
        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'
        mock_order_doc.to_dict.return_value = {
            'items': [
                {'productId': 'prod_1', 'quantity': 2}
            ]
        }

        main.db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        # Mock product lookup for stock restoration
        mock_product_ref = MagicMock()
        mock_product_doc = MagicMock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {'stockQuantity': 5}
        mock_product_ref.get.return_value = mock_product_doc

        # Setup collection chain
        def collection_side_effect(name):
            if name == 'orders':
                mock = MagicMock()
                mock.where.return_value.limit.return_value.get.return_value = [mock_order_doc]
                return mock
            elif name == 'products':
                mock = MagicMock()
                mock.document.return_value = mock_product_ref
                return mock
            return MagicMock()

        main.db.collection.side_effect = collection_side_effect

        # Execute
        result = main.process_charge_refunded(charge)

        # Verify
        self.assertEqual(result, 'order_123')
        mock_order_doc.reference.update.assert_called()
        call_args = mock_order_doc.reference.update.call_args[0][0]
        self.assertEqual(call_args['status'], OrderStatus.REFUNDED)
        self.assertEqual(call_args['paymentStatus'], PaymentStatus.REFUNDED)

    def test_process_charge_refunded_partial_refund(self):
        """
        Scenario: Partial refund processed.
        Expectation: Order marked as partially refunded, stock NOT restored.
        """
        charge = {
            'payment_intent': 'pi_123',
            'amount_refunded': 2500,
            'refunded': False  # Partial refund
        }

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'
        mock_order_doc.to_dict.return_value = {
            'items': [{'productId': 'prod_1', 'quantity': 2}]
        }

        main.db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = main.process_charge_refunded(charge)

        self.assertEqual(result, 'order_123')
        call_args = mock_order_doc.reference.update.call_args[0][0]
        self.assertEqual(call_args['status'], OrderStatus.PARTIALLY_REFUNDED)


class TestDisputeFlow(unittest.TestCase):
    """Tests for dispute handling"""

    def setUp(self):
        main.db = MagicMock()
        main.stripe = mock_stripe

    def test_process_dispute_created(self):
        """
        Scenario: Dispute opened on an order.
        Expectation: Order marked with dispute, payouts frozen.
        """
        dispute = {
            'id': 'dp_123',
            'charge': 'ch_123',
            'reason': 'fraudulent',
            'status': 'warning_needs_response',
            'amount': 5000
        }

        # Mock charge retrieval
        mock_charge = MagicMock()
        mock_charge.payment_intent = 'pi_123'
        main.stripe.Charge.retrieve.return_value = mock_charge

        # Mock order lookup
        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'

        main.db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = main.process_dispute_created(dispute)

        self.assertEqual(result, 'order_123')
        mock_order_doc.reference.update.assert_called()
        call_args = mock_order_doc.reference.update.call_args[0][0]
        self.assertTrue(call_args['hasDispute'])
        self.assertEqual(call_args['disputeId'], 'dp_123')
        self.assertEqual(call_args['disputeReason'], 'fraudulent')
        self.assertEqual(call_args['payoutStatus'], PayoutStatus.PENDING)

    def test_process_dispute_created_missing_charge(self):
        """
        Scenario: Dispute event missing charge id.
        Expectation: No update and returns None.
        """
        dispute = {
            'id': 'dp_123',
            'reason': 'fraudulent',
            'status': 'warning_needs_response',
            'amount': 5000
        }

        result = main.process_dispute_created(dispute)

        self.assertIsNone(result)
        main.db.collection.return_value.where.assert_not_called()

    def test_process_dispute_closed_won(self):
        """
        Scenario: Dispute closed in seller's favor.
        Expectation: Dispute flag cleared, payouts unfrozen.
        """
        dispute = {
            'id': 'dp_123',
            'charge': 'ch_123',
            'status': 'won'
        }

        mock_charge = MagicMock()
        mock_charge.payment_intent = 'pi_123'
        main.stripe.Charge.retrieve.return_value = mock_charge

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'

        main.db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = main.process_dispute_closed(dispute)

        self.assertEqual(result, 'order_123')
        call_args = mock_order_doc.reference.update.call_args[0][0]
        self.assertFalse(call_args['hasDispute'])
        self.assertEqual(call_args['disputeStatus'], 'won')

    def test_process_dispute_closed_lost(self):
        """
        Scenario: Dispute lost (refund to customer).
        Expectation: Order marked as refunded.
        """
        dispute = {
            'id': 'dp_123',
            'charge': 'ch_123',
            'status': 'lost'
        }

        mock_charge = MagicMock()
        mock_charge.payment_intent = 'pi_123'
        main.stripe.Charge.retrieve.return_value = mock_charge

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'

        main.db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = main.process_dispute_closed(dispute)

        self.assertEqual(result, 'order_123')
        call_args = mock_order_doc.reference.update.call_args[0][0]
        self.assertEqual(call_args['status'], OrderStatus.REFUNDED)


class TestIdempotency(unittest.TestCase):
    """Tests for idempotency in payment operations"""

    def setUp(self):
        main.db = MagicMock()
        main.stripe = mock_stripe

    def test_webhook_idempotency_duplicate_event(self):
        """
        Scenario: Same webhook event received twice.
        Expectation: Second call returns early without processing.
        """
        req = MagicMock()
        req.data = b'raw_payload'
        req.headers = {'stripe-signature': 'sig_123'}

        mock_event = {
            'id': 'evt_duplicate',
            'type': 'checkout.session.completed',
            'data': {'object': {'id': 'cs_123'}}
        }
        main.stripe.Webhook.construct_event.return_value = mock_event

        # Event already processed (exists in webhook_events)
        mock_event_ref = MagicMock()
        mock_event_ref.get.return_value.exists = True  # Event already processed
        main.db.collection.return_value.document.return_value = mock_event_ref

        # Execute
        response = stripe_webhook(req)

        # Verify it returned a response (function completed without crash)
        # The actual return value is a Flask Response object
        self.assertIsNotNone(response)


if __name__ == '__main__':
    unittest.main(verbosity=2)
