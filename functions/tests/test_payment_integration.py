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
        DeliveryStatus,
        PaymentStatus,
        OrderStatus
    )

class TestPaymentFlow(unittest.TestCase):
    def setUp(self):
        # Reset mocks
        main.db = MagicMock()
        main.stripe = mock_stripe # Ensure we use the same mock object
        main.stripe.api_key = "STRIPE_SECRET_KEY_REDACTED"
        
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
        
        # Setup DB Chain
        mock_order_ref = MagicMock()
        mock_order_ref.get.return_value = mock_order_doc
        main.db.collection.return_value.document.return_value = mock_order_ref

        # Execute
        resp = capture_payment(req)

        # Assertions
        self.assertTrue(resp["success"])
        main.stripe.PaymentIntent.capture.assert_not_called()  # Should SKIP capture
        mock_order_ref.update.assert_called()  # Should UPDATE firestore

    def test_capture_payment_normal_flow(self):
        """
        Scenario: Order is Authorized.
        Seller 1 calls capture_payment.
        Expectation: Success, AND Stripe capture call.
        """
        req = MagicMock()
        req.auth.uid = "seller_1"
        req.data = {"orderId": "order_123", "trackingNumber": "T1"}

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
        
        # Setup DB Chain
        mock_order_ref = MagicMock()
        mock_order_ref.get.return_value = mock_order_doc
        main.db.collection.return_value.document.return_value = mock_order_ref

        # Execute
        resp = capture_payment(req)

        # Assertions
        self.assertTrue(resp["success"])
        main.stripe.PaymentIntent.capture.assert_called_with("pi_123", amount_to_capture=5000)
        mock_order_ref.update.assert_called()

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
                    "imageUrls": ["http://img.com/1.jpg"]
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

        # Mock Firestore Transaction for Stock Check
        mock_transaction = MagicMock()
        main.db.transaction.return_value.__enter__.return_value = mock_transaction
        
        # Mock Product for Stock Validation
        mock_product_doc = MagicMock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            "name": "Test Product",
            "stockQuantity": 10
        }
        
        # When transaction.get() is called with a ref, return the product doc
        mock_transaction.get.return_value = [mock_product_doc] # Some transaction mocks return list
        # But wait, main.py uses: product_doc = product_ref.get(transaction=transaction)
        # OR main.py uses transaction.get(product_ref)
        # Let's check main.py line 626: product_doc = product_ref.get(transaction=transaction)
        # We need to mock the get() method on the document reference to handle the transaction arg
        
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_product_doc
        main.db.collection.return_value.document.return_value = mock_doc_ref

        # Mock Stripe Session
        main.stripe.checkout.Session.create.return_value = MagicMock(
            id="cs_new_123",
            url="http://checkout.url"
        )

        # Mock Order Reference for Set()
        mock_order_ref = MagicMock()
        mock_order_ref.id = "new_order_id"
        # main.py line 658: order_ref = db.collection(Collections.ORDERS).document()
        # We need to distinguish between get() for product and document() for new order
        # Since this is tricky with the same mock chain, let's just ensure no exception is raised
        # and verify the stripe call specifically.
        
        # We can try to side_effect the document() call
        def document_side_effect(arg=None):
            if arg == "prod_1": return mock_doc_ref
            return mock_order_ref # for new order (no arg)
            
        main.db.collection.return_value.document.side_effect = document_side_effect

        # EXECUTE
        # We need to mock the transactional decorator to just run the function
        # But we can't easily patch the decorator that's already applied in import
        # The verify logic: The function `validate_and_reserve_stock` is defined INSIDE.
        # So we just rely on `db.transaction()` returning a context manager.
        
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
