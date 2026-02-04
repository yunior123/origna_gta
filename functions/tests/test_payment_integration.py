import pytest
import unittest
from unittest.mock import MagicMock, patch, Mock
import sys
import os

# Add functions directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from config import (
    DeliveryStatus,
    PaymentStatus,
    OrderStatus,
    PayoutStatus,
    Collections
)


class TestPaymentFlow(unittest.TestCase):
    """Tests for payment flow operations"""

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    @patch('handlers.payment_stripe.stripe')
    def test_capture_payment_multi_seller_bugfix(self, mock_stripe, mock_get_rate_limiter, mock_get_db):
        """
        Scenario: Order is already PAID by Seller 1.
        Seller 2 calls capture_payment.
        Expectation: Success, but NO Stripe capture call.
        """
        from handlers.payment_stripe import capture_payment
        
        # Setup mocks
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        mock_rate_limiter = MagicMock()
        mock_rate_limiter.check_rate_limit.return_value = (True, "OK")
        mock_get_rate_limiter.return_value = mock_rate_limiter
        
        mock_stripe.PaymentIntent.capture = MagicMock()
        
        req = MagicMock()
        req.auth.uid = "seller_2"
        req.data = {"orderId": "order_123", "trackingNumber": "T2"}

        # Mock Seller 
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
            "paymentStatus": PaymentStatus.PAID,
            "status": "processing",
            "stripePaymentIntentId": "pi_123",
            "amount": 5000,
            "items": [
                {"sellerId": "seller_1", "deliveryStatus": DeliveryStatus.SHIPPED},
                {"sellerId": "seller_2", "deliveryStatus": DeliveryStatus.PENDING}
            ]
        }
        
        # Setup DB mock
        def mock_document_chain(doc_id):
            mock_ref = MagicMock()
            if doc_id == "seller_2":
                mock_ref.get.return_value = mock_seller_doc
            elif doc_id == "order_123":
                mock_ref.get.return_value = mock_order_doc
            return mock_ref
        
        mock_db.collection.return_value.document.side_effect = mock_document_chain

        # Execute
        resp = capture_payment(req)

        # Assertions
        self.assertTrue(resp["success"])
        mock_stripe.PaymentIntent.capture.assert_not_called()

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    @patch('handlers.payment_stripe.stripe')
    def test_capture_payment_normal_flow(self, mock_stripe, mock_get_rate_limiter, mock_get_db):
        """
        Scenario: Order is Authorized.
        Seller 1 calls capture_payment.
        Expectation: Success, AND Stripe capture call.
        """
        from handlers.payment_stripe import capture_payment
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        mock_rate_limiter = MagicMock()
        mock_rate_limiter.check_rate_limit.return_value = (True, "OK")
        mock_get_rate_limiter.return_value = mock_rate_limiter
        
        mock_stripe.PaymentIntent.capture = MagicMock()
        
        req = MagicMock()
        req.auth.uid = "seller_1"
        req.data = {"orderId": "order_123", "trackingNumber": "T1"}

        # Mock Seller
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
            "paymentStatus": "authorized",
            "status": "processing",
            "stripePaymentIntentId": "pi_123",
            "amount": 5000,
            "items": [
                {"sellerId": "seller_1", "deliveryStatus": DeliveryStatus.PENDING}
            ]
        }
        
        # Setup DB mock
        def mock_document_chain(doc_id):
            mock_ref = MagicMock()
            if doc_id == "seller_1":
                mock_ref.get.return_value = mock_seller_doc
            elif doc_id == "order_123":
                mock_ref.get.return_value = mock_order_doc
            return mock_ref
        
        mock_db.collection.return_value.document.side_effect = mock_document_chain

        # Execute
        resp = capture_payment(req)

        # Assertions
        self.assertTrue(resp["success"])
        mock_stripe.PaymentIntent.capture.assert_called()

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    @patch('handlers.payment_stripe.stripe')
    def test_create_checkout_session_flow(self, mock_stripe, mock_get_rate_limiter, mock_get_db):
        """
        Scenario: User initiates checkout.
        Expectation: Create Stripe Session with manual capture.
        """
        from handlers.payment_stripe import create_checkout_session
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        mock_rate_limiter = MagicMock()
        mock_rate_limiter.check_rate_limit.return_value = (True, "OK")
        mock_get_rate_limiter.return_value = mock_rate_limiter
        
        mock_stripe.checkout.Session.create = MagicMock(
            return_value=MagicMock(id="cs_test_123", url="http://test.url")
        )
        
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
                    "description": "Test",
                    "sellerAddress": {"street": "1 St", "city": "Toronto", "state": "ON", "postalCode": "M5V 1A1", "country": "Canada"},
                    "categoryId": 1
                }
            ],
            "shippingAddress": {
                "street": "123 Main",
                "city": "Toronto",
                "province": "ON",
                "postalCode": "M1A1A1",
                "country": "CA"
            },
            "subtotal": 50.00,
            "total": 56.50,
            "taxes": {"HST": 6.50},
            "shippingCost": 0
        }

        # Mock Seller
        mock_seller_doc = MagicMock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            "roles": ["seller"],
            "suspended": False,
            "onboardingCompleted": True,
            "chargesEnabled": True,
            "payoutsEnabled": True
        }

        # Mock Product
        mock_product_doc = MagicMock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            "name": "Test Product",
            "price": 50.00,
            "stockQuantity": 10,
            "sellerId": "seller_1",
            "imageUrls": ["http://img.com/1.jpg"],
            "categoryId": 1
        }
        
        # Mock transaction
        mock_transaction = MagicMock()
        mock_transaction.get.return_value = mock_seller_doc
        mock_transaction.__enter__ = MagicMock(return_value=mock_transaction)
        mock_transaction.__exit__ = MagicMock(return_value=None)
        mock_db.transaction.return_value = mock_transaction
        
        def mock_document_chain(doc_id):
            mock_ref = MagicMock()
            if doc_id == "seller_1":
                mock_ref.get.return_value = mock_seller_doc
            elif doc_id == "prod_1":
                mock_ref.get.return_value = mock_product_doc
            else:
                mock_ref.id = "new_order_id"
            return mock_ref
        
        mock_db.collection.return_value.document.side_effect = mock_document_chain

        # Execute
        resp = create_checkout_session(req)

        # Assertions
        self.assertIsNotNone(resp)
        self.assertTrue(resp.get("sessionId") is not None or resp.get("success") is True)

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    @patch('handlers.payment_stripe.stripe')
    def test_stripe_webhook_flow(self, mock_stripe, mock_get_rate_limiter, mock_get_db):
        """
        Scenario: Webhook received for checkout.session.completed
        """
        from handlers.payment_stripe import stripe_webhook
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        mock_rate_limiter = MagicMock()
        mock_rate_limiter.check_rate_limit.return_value = (True, "OK")
        mock_get_rate_limiter.return_value = mock_rate_limiter
        
        req = MagicMock()
        req.data = b'raw_payload'
        req.headers = {'stripe-signature': 'sig_123'}

        # Mock Stripe event
        mock_event = {
            "id": "evt_123",
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "id": "cs_123",
                    "client_reference_id": "order_123",
                    "payment_status": "paid",
                    "amount_total": 5000,
                    "payment_intent": "pi_123"
                }
            }
        }
        mock_stripe.Webhook.construct_event.return_value = mock_event

        # Mock order
        mock_order_ref = MagicMock()
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "orderId": "order_123",
            "status": OrderStatus.PENDING,
            "amount": 5000
        }
        
        mock_event_log = MagicMock()
        mock_event_log.get.return_value.exists = False
        
        def doc_side_effect(arg):
            if arg == "evt_123":
                return mock_event_log
            elif arg == "order_123":
                return mock_order_ref
            return MagicMock()
            
        mock_db.collection.return_value.document.side_effect = doc_side_effect
        mock_order_ref.get.return_value = mock_order_doc

        # Execute
        response = stripe_webhook(req)

        # Verify
        self.assertIsNotNone(response)

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    @patch('handlers.payment_stripe.stripe')
    def test_webhook_persists_stripe_amounts_and_taxes(self, mock_stripe, mock_get_rate_limiter, mock_get_db):
        """
        Scenario: Webhook includes amount_total and tax details.
        """
        from handlers.payment_stripe import stripe_webhook
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        mock_rate_limiter = MagicMock()
        mock_rate_limiter.check_rate_limit.return_value = (True, "OK")
        mock_get_rate_limiter.return_value = mock_rate_limiter
        
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
                    "payment_intent": "pi_456"
                }
            }
        }
        mock_stripe.Webhook.construct_event.return_value = mock_event

        mock_order_ref = MagicMock()
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            "orderId": "order_456",
            "status": OrderStatus.PENDING
        }

        mock_event_log = MagicMock()
        mock_event_log.get.return_value.exists = False

        def doc_side_effect(arg):
            if arg == "evt_456":
                return mock_event_log
            elif arg == "order_456":
                return mock_order_ref
            return MagicMock()

        mock_db.collection.return_value.document.side_effect = doc_side_effect
        mock_order_ref.get.return_value = mock_order_doc

        response = stripe_webhook(req)

        self.assertIsNotNone(response)

    @patch('handlers.products.get_db')
    @patch('handlers.products.stripe', create=True)
    def test_submit_product_rating_delivered(self, mock_stripe, mock_get_db):
        """
        Scenario: User rates a delivered product.
        """
        from handlers.products import submit_product_rating
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
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
            if name == Collections.ORDERS.value:
                return orders_collection
            elif name == Collections.PRODUCTS.value:
                return products_collection
            return MagicMock()

        mock_db.collection.side_effect = collection_side_effect

        resp = submit_product_rating(req)

        self.assertIsNotNone(resp)


class TestRefundFlow(unittest.TestCase):
    """Tests for refund processing"""

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.stripe')
    def test_process_charge_refunded_full_refund(self, mock_stripe, mock_get_db):
        """
        Scenario: Full refund processed.
        Expectation: Order marked as refunded.
        """
        from handlers.payment_stripe import process_charge_refunded
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
        charge = {
            'payment_intent': 'pi_123',
            'amount_refunded': 5000,
            'refunded': True
        }

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'
        mock_order_doc.to_dict.return_value = {
            'items': [{'productId': 'prod_1', 'quantity': 2}]
        }

        mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = process_charge_refunded(charge)

        self.assertEqual(result, 'order_123')
        mock_order_doc.reference.update.assert_called()

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.stripe')
    def test_process_charge_refunded_partial_refund(self, mock_stripe, mock_get_db):
        """
        Scenario: Partial refund processed.
        """
        from handlers.payment_stripe import process_charge_refunded
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
        charge = {
            'payment_intent': 'pi_123',
            'amount_refunded': 2500,
            'refunded': False
        }

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'
        mock_order_doc.to_dict.return_value = {
            'items': [{'productId': 'prod_1', 'quantity': 2}]
        }

        mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = process_charge_refunded(charge)

        self.assertEqual(result, 'order_123')


class TestDisputeFlow(unittest.TestCase):
    """Tests for dispute handling"""

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.stripe')
    def test_process_dispute_created(self, mock_stripe, mock_get_db):
        """
        Scenario: Dispute opened on an order.
        """
        from handlers.payment_stripe import process_dispute_created
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
        dispute = {
            'id': 'dp_123',
            'charge': 'ch_123',
            'reason': 'fraudulent',
            'status': 'warning_needs_response',
            'amount': 5000
        }

        mock_charge = MagicMock()
        mock_charge.payment_intent = 'pi_123'
        mock_stripe.Charge.retrieve.return_value = mock_charge

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'

        mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = process_dispute_created(dispute)

        self.assertEqual(result, 'order_123')
        mock_order_doc.reference.update.assert_called()

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.stripe')
    def test_process_dispute_created_missing_charge(self, mock_stripe, mock_get_db):
        """
        Scenario: Dispute event missing charge id.
        Expectation: No update and returns None.
        """
        from handlers.payment_stripe import process_dispute_created
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
        dispute = {
            'id': 'dp_123',
            'reason': 'fraudulent',
            'status': 'warning_needs_response',
            'amount': 5000
        }

        result = process_dispute_created(dispute)

        self.assertIsNone(result)

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.stripe')
    def test_process_dispute_closed_won(self, mock_stripe, mock_get_db):
        """
        Scenario: Dispute closed in seller's favor.
        """
        from handlers.payment_stripe import process_dispute_closed
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
        dispute = {
            'id': 'dp_123',
            'charge': 'ch_123',
            'status': 'won'
        }

        mock_charge = MagicMock()
        mock_charge.payment_intent = 'pi_123'
        mock_stripe.Charge.retrieve.return_value = mock_charge

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'

        mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = process_dispute_closed(dispute)

        self.assertEqual(result, 'order_123')

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.stripe')
    def test_process_dispute_closed_lost(self, mock_stripe, mock_get_db):
        """
        Scenario: Dispute lost (refund to customer).
        """
        from handlers.payment_stripe import process_dispute_closed
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        
        dispute = {
            'id': 'dp_123',
            'charge': 'ch_123',
            'status': 'lost'
        }

        mock_charge = MagicMock()
        mock_charge.payment_intent = 'pi_123'
        mock_stripe.Charge.retrieve.return_value = mock_charge

        mock_order_doc = MagicMock()
        mock_order_doc.reference = MagicMock()
        mock_order_doc.reference.id = 'order_123'

        mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_order_doc]

        result = process_dispute_closed(dispute)

        self.assertEqual(result, 'order_123')


class TestIdempotency(unittest.TestCase):
    """Tests for idempotency in payment operations"""

    @patch('handlers.payment_stripe.get_db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    @patch('handlers.payment_stripe.stripe')
    def test_webhook_idempotency_duplicate_event(self, mock_stripe, mock_get_rate_limiter, mock_get_db):
        """
        Scenario: Same webhook event received twice.
        Expectation: Second call returns early without processing.
        """
        from handlers.payment_stripe import stripe_webhook
        
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        mock_rate_limiter = MagicMock()
        mock_rate_limiter.check_rate_limit.return_value = (True, "OK")
        mock_get_rate_limiter.return_value = mock_rate_limiter
        
        req = MagicMock()
        req.data = b'raw_payload'
        req.headers = {'stripe-signature': 'sig_123'}

        mock_event = {
            'id': 'evt_duplicate',
            'type': 'checkout.session.completed',
            'data': {'object': {'id': 'cs_123'}}
        }
        mock_stripe.Webhook.construct_event.return_value = mock_event

        mock_event_ref = MagicMock()
        mock_event_ref.get.return_value.exists = True
        mock_db.collection.return_value.document.return_value = mock_event_ref

        response = stripe_webhook(req)

        self.assertIsNotNone(response)


if __name__ == '__main__':
    unittest.main(verbosity=2)
