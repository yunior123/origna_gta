import logging
from unittest.mock import MagicMock, Mock, patch

# Ensure Firebase functions are mocked before imports
import firebase_functions.https_fn as https_fn
import pytest

from handlers.orders import confirm_item_receipt
from handlers.payment_stripe import create_checkout_session
from schema_constants import BusinessRules, Collections, DeliveryStatusValues, Fields, OrderStatusValues

logger = logging.getLogger(__name__)

class TestCheckoutFixesFeb2026:
    """Targeted tests for checkout and orders fixes implemented in Feb 2026"""

    @patch("handlers.payment_stripe.get_db")
    @patch("handlers.payment_stripe.calculate_shipping_cost")
    @patch("handlers.payment_stripe._check_premium_from_sub")
    @patch("handlers.payment_stripe.stripe.checkout.Session.create")
    @patch("handlers.payment_stripe.get_rate_limiter")
    @patch("handlers.payment_stripe.ensure_stripe_key")
    def test_free_shipping_threshold_enforced(self, mock_ensure_key, mock_get_rate_limiter, mock_stripe_create, mock_premium, mock_shipping_calc, mock_get_db):
        """Verify that subtotals >= $75 get free shipping (C12)"""
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        mock_rl = MagicMock()
        mock_rl.check_rate_limit.return_value = (True, "")
        mock_get_rate_limiter.return_value = mock_rl

        def mock_doc_get(*args, **kwargs):
            # doc_id is usually the first arg if called as ref.get() or implicitly in mocks
            doc = MagicMock()
            doc.exists = True

            # Since we can't easily get doc_id from the get() call on a mock ref without more setup,
            # we'll look at the record of which document created this mock.
            # But let's simplify: return a generic doc that has the fields needed
            # based on common keys it looks for.

            doc.to_dict.return_value = {
                Fields.EMAIL: "buyer@example.com",
                Fields.SUSPENDED: False,
                "onboardingCompleted": True, "chargesEnabled": True, "payoutsEnabled": True, "stripeConnectId": "acct_123",
                Fields.NAME: "Test Product",
                Fields.PRICE: 80.00, Fields.SELLER_ID: "seller_123",
                Fields.LIFECYCLE_STATUS: "active", Fields.STOCK_QUANTITY: 10,
                Fields.WAREHOUSE_STOCK: {"wh1": 100}
            }
            return doc

        # Track all .set() calls across all document refs
        set_calls_data = []

        def make_doc_ref(doc_id=None):
            mock_ref = MagicMock()
            if doc_id is not None:
                mock_ref.id = doc_id
            mock_ref.get.side_effect = mock_doc_get

            def capture_set(data, **kwargs):
                set_calls_data.append(data)

            mock_ref.set.side_effect = capture_set
            return mock_ref

        mock_db.collection.return_value.document.side_effect = make_doc_ref

        def get_all_impl(refs):
            results = []
            for ref in refs:
                doc = mock_doc_get()
                if hasattr(ref, "id") and isinstance(ref.id, str):
                    doc.id = ref.id
                results.append(doc)
            return results

        mock_db.get_all = MagicMock(side_effect=get_all_impl)

        mock_shipping_calc.return_value = 15.00
        mock_premium.return_value = False
        mock_stripe_create.return_value = Mock(id="sess_123", url="https://stripe.com/pay")

        mock_req = MagicMock()
        mock_req.auth.uid = "user_123"
        mock_req.data = {
            "items": [{"productId": "prod_123", "quantity": 1, "price": 80.00, "sellerId": "seller_123"}],
            "subtotal": 80.00,
            "shippingAddress": {
                Fields.STREET: "123 Main St",
                Fields.CITY: "Toronto",
                Fields.POSTAL_CODE: "M5V 2N8",
                Fields.STATE: "ON",
                Fields.COUNTRY: "Canada"
            },
            "deliverySpeed": "standard"
        }

        with patch("handlers.payment_stripe.STRIPE_TAX_ENABLED", False):
            with patch("handlers.payment_stripe.get_server_timestamp", return_value="mock_ts"):
                create_checkout_session(mock_req)

        order_save = next((d for d in set_calls_data if Fields.SHIPPING_COST_CENTS in d), None)

        assert order_save is not None, f"Order was not saved. Set calls: {set_calls_data}"
        assert order_save[Fields.SHIPPING_COST_CENTS] == 0

    @patch("handlers.orders.get_db")
    @patch("handlers.orders.get_firestore")
    def test_confirm_receipt_uses_cart_item_id(self, mock_get_firestore, mock_get_db):
        """Verify confirm_item_receipt uses cartItemId instead of productId (BUG-O1)"""
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        mock_transaction = MagicMock()
        mock_get_firestore.return_value.transactional.side_effect = lambda f: lambda *args, **kwargs: f(mock_transaction)

        # Force correct field name
        user_id_field = "userId"

        order_data = {
            user_id_field: "buyer_123",
            Fields.SELLER_IDS: ["seller_123"],
            Fields.ITEMS: [
                {Fields.CART_ITEM_ID: "cart_item_A", Fields.PRODUCT_ID: "p1", Fields.STATUS: DeliveryStatusValues.SHIPPED},
                {Fields.CART_ITEM_ID: "cart_item_B", Fields.PRODUCT_ID: "p1", Fields.STATUS: DeliveryStatusValues.SHIPPED},
            ]
        }

        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = order_data

        # In confirm_item_receipt, it does order_ref.get(transaction=transaction)
        # But wait, it's actually order_ref.get(transaction=transaction)
        # In transactional context, it's often transaction.get(order_ref)
        # Let's see orders.py again.

        # transactional decorated function:
        # def _confirm_item_txn(transaction):
        #     order_doc = order_ref.get(transaction=transaction)

        # We need to mock the document's get method specifically
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc

        mock_req = MagicMock()
        mock_req.auth.uid = "buyer_123"
        mock_req.data = {
            Fields.ORDER_ID: "order_123",
            Fields.CART_ITEM_ID: "cart_item_B"
        }

        with patch("handlers.orders.get_server_timestamp", return_value="mock_ts"):
            confirm_item_receipt(mock_req)

        # Verify correct item was updated
        mock_transaction.update.assert_called_once()
        args, kwargs = mock_transaction.update.call_args
        updated_data = args[1]
        updated_items = updated_data[Fields.ITEMS]

        assert updated_items[1][Fields.STATUS] == DeliveryStatusValues.DELIVERED
        assert updated_items[0][Fields.STATUS] == DeliveryStatusValues.SHIPPED
