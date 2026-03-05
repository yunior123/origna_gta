from datetime import UTC, datetime, timedelta
from unittest.mock import Mock, patch

import stripe

from schema_constants import (
    Collections,
    DeliveryStatusValues,
    Fields,
    PaymentStatusValues,
    PayoutStatusValues,
    UserRoleValues,
)


def _snap(data=None, *, exists=True, doc_id="doc_1"):
    snap = Mock()
    snap.exists = exists
    snap.id = doc_id
    snap.to_dict.return_value = {} if data is None else data
    snap.reference = Mock()
    return snap


def _req(uid: str | None, data: dict):
    req = Mock()
    req.auth = Mock(uid=uid) if uid else None
    req.data = data
    return req


def _base_order_data(*, is_digital: bool = False):
    delivered = datetime.now(UTC) - timedelta(days=2)
    return {
        Fields.USER_ID: "buyer_1",
        Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
        Fields.PAYOUT_STATUS: PayoutStatusValues.COMPLETED,
        Fields.STRIPE_PAYMENT_INTENT_ID: "pi_1",
        Fields.SUBTOTAL_CENTS: 4000,
        Fields.DISCOUNT_AMOUNT_CENTS: 400,
        Fields.SHIPPING_COST_CENTS: 1000,
        Fields.SELLER_SHIPPING_COSTS: {"seller_1": 1000},
        Fields.TAX_AMOUNT_CENTS: 390,
        Fields.ITEMS: [
            {
                Fields.PRODUCT_ID: "prod_1",
                Fields.SELLER_ID: "seller_1",
                Fields.PRICE: 20.0,
                Fields.QUANTITY: 1,
                Fields.STATUS: DeliveryStatusValues.DELIVERED,
                Fields.DELIVERED_AT: delivered,
                Fields.FULFILLMENT_WAREHOUSE_ID: "wh_1",
                Fields.IS_DIGITAL: is_digital,
            },
            {
                Fields.PRODUCT_ID: "prod_2",
                Fields.SELLER_ID: "seller_1",
                Fields.PRICE: 20.0,
                Fields.QUANTITY: 1,
                Fields.STATUS: DeliveryStatusValues.DELIVERED,
                Fields.DELIVERED_AT: delivered,
                Fields.IS_DIGITAL: is_digital,
            },
        ],
    }


class TestRefundOrderItemDeep:
    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.OrderEvent.write")
    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("handlers.orders.get_firestore")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.stripe.Transfer.create_reversal")
    @patch("handlers.orders.stripe.Refund.create")
    @patch("handlers.orders.get_db")
    def test_refund_order_item_success_with_transfer_reversal_and_stock_restore(
        self,
        mock_get_db,
        mock_refund_create,
        mock_reversal_create,
        mock_rl,
        _mock_sanitized,
        mock_get_fs,
        _mock_ts,
        mock_order_event,
        _mock_resp,
    ):
        from handlers.orders import refund_order_item

        mock_rl.return_value.check_rate_limit.return_value = (True, "")
        mock_refund_create.return_value = Mock(id="re_1")
        mock_reversal_create.return_value = Mock(id="trr_1")

        fs = Mock()
        fs.transactional = lambda fn: fn
        fs.Increment.side_effect = lambda n: ("inc", n)
        fs.ArrayUnion.side_effect = lambda values: ("arr_union", values)
        mock_get_fs.return_value = fs

        order_ref = Mock()
        order_ref.get.return_value = _snap(_base_order_data(is_digital=False), doc_id="order_1")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        user_ref = Mock()
        user_ref.get.return_value = _snap({Fields.ROLES: [UserRoleValues.SELLER]}, doc_id="seller_1")
        users_col = Mock()
        users_col.document.return_value = user_ref

        product_ref = Mock()
        inv_ref = Mock()
        product_ref.collection.return_value.document.return_value = inv_ref
        products_col = Mock()
        products_col.document.return_value = product_ref

        payout_doc = _snap(
            {
                Fields.AMOUNT_CENTS: 3600,
                Fields.NET_AMOUNT_CENTS: 3000,
                Fields.PLATFORM_FEE_CENTS: 600,
                Fields.STRIPE_TRANSFER_ID: "tr_1",
            },
            doc_id="payout_1",
        )
        payout_query = Mock()
        payout_query.where.return_value = payout_query
        payout_query.limit.return_value = payout_query
        payout_query.get.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payout_query

        licenses_q = Mock()
        licenses_q.where.return_value = licenses_q
        licenses_q.stream.return_value = []
        licenses_col = Mock()
        licenses_col.where.return_value = licenses_q

        tx = Mock()
        db = Mock()
        db.transaction.return_value = tx
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
            Collections.PAYOUTS: payouts_col,
            Collections.LICENSES: licenses_col,
        }[name]
        mock_get_db.return_value = db

        out = refund_order_item(
            _req("seller_1", {Fields.ORDER_ID: "order_1", Fields.PRODUCT_ID: "prod_1", "reason": "Damaged"})
        )

        assert out["success"] is True
        assert out[Fields.REFUND_ID] == "re_1"
        mock_refund_create.assert_called_once()
        mock_reversal_create.assert_called_once()
        payout_doc.reference.update.assert_called_once()
        assert tx.update.call_count >= 2
        tx.set.assert_called_once()
        mock_order_event.assert_called_once()

    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.OrderEvent.write")
    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("handlers.orders.get_firestore")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.stripe.Transfer.create_reversal")
    @patch("handlers.orders.stripe.Refund.create")
    @patch("handlers.orders.get_db")
    def test_refund_order_item_reversal_error_is_logged_but_refund_succeeds(
        self,
        mock_get_db,
        mock_refund_create,
        mock_reversal_create,
        mock_rl,
        _mock_sanitized,
        mock_get_fs,
        _mock_ts,
        mock_order_event,
        _mock_resp,
    ):
        from handlers.orders import refund_order_item

        mock_rl.return_value.check_rate_limit.return_value = (True, "")
        mock_refund_create.return_value = Mock(id="re_2")
        mock_reversal_create.side_effect = stripe.error.StripeError("reversal failed")

        fs = Mock()
        fs.transactional = lambda fn: fn
        fs.Increment.side_effect = lambda n: ("inc", n)
        fs.ArrayUnion.side_effect = lambda values: ("arr_union", values)
        mock_get_fs.return_value = fs

        order_ref = Mock()
        order_ref.get.return_value = _snap(_base_order_data(is_digital=False), doc_id="order_2")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        user_ref = Mock()
        user_ref.get.return_value = _snap({Fields.ROLES: [UserRoleValues.SELLER]}, doc_id="seller_1")
        users_col = Mock()
        users_col.document.return_value = user_ref

        product_ref = Mock()
        product_ref.collection.return_value.document.return_value = Mock()
        products_col = Mock()
        products_col.document.return_value = product_ref

        payout_doc = _snap(
            {
                Fields.AMOUNT_CENTS: 3600,
                Fields.NET_AMOUNT_CENTS: 3000,
                Fields.STRIPE_TRANSFER_ID: "tr_2",
            },
            doc_id="payout_2",
        )
        payout_query = Mock()
        payout_query.where.return_value = payout_query
        payout_query.limit.return_value = payout_query
        payout_query.get.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payout_query

        licenses_q = Mock()
        licenses_q.where.return_value = licenses_q
        licenses_q.stream.return_value = []
        licenses_col = Mock()
        licenses_col.where.return_value = licenses_q

        tx = Mock()
        db = Mock()
        db.transaction.return_value = tx
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
            Collections.PAYOUTS: payouts_col,
            Collections.LICENSES: licenses_col,
        }[name]
        mock_get_db.return_value = db

        out = refund_order_item(
            _req("seller_1", {Fields.ORDER_ID: "order_2", Fields.PRODUCT_ID: "prod_1", "reason": "Defect"})
        )

        assert out["success"] is True
        assert out[Fields.REFUND_ID] == "re_2"
        mock_refund_create.assert_called_once()
        mock_reversal_create.assert_called_once()
        payout_doc.reference.update.assert_not_called()
        mock_order_event.assert_called_once()

    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.OrderEvent.write")
    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("handlers.orders.get_firestore")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.stripe.Refund.create")
    @patch("handlers.orders.get_db")
    def test_refund_order_item_digital_revokes_active_licenses(
        self,
        mock_get_db,
        mock_refund_create,
        mock_rl,
        _mock_sanitized,
        mock_get_fs,
        _mock_ts,
        mock_order_event,
        _mock_resp,
    ):
        from handlers.orders import refund_order_item

        mock_rl.return_value.check_rate_limit.return_value = (True, "")
        mock_refund_create.return_value = Mock(id="re_3")

        fs = Mock()
        fs.transactional = lambda fn: fn
        fs.Increment.side_effect = lambda n: ("inc", n)
        fs.ArrayUnion.side_effect = lambda values: ("arr_union", values)
        mock_get_fs.return_value = fs

        order_ref = Mock()
        order_ref.get.return_value = _snap(_base_order_data(is_digital=True), doc_id="order_3")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        user_ref = Mock()
        user_ref.get.return_value = _snap({Fields.ROLES: [UserRoleValues.SELLER]}, doc_id="seller_1")
        users_col = Mock()
        users_col.document.return_value = user_ref

        product_ref = Mock()
        products_col = Mock()
        products_col.document.return_value = product_ref

        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.get.return_value = []
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        lic_active = _snap({Fields.STATUS: "active"}, doc_id="lic_1")
        lic_revoked = _snap({Fields.STATUS: "revoked"}, doc_id="lic_2")
        licenses_q = Mock()
        licenses_q.where.return_value = licenses_q
        licenses_q.stream.return_value = [lic_active, lic_revoked]
        licenses_col = Mock()
        licenses_col.where.return_value = licenses_q

        tx = Mock()
        batch = Mock()
        db = Mock()
        db.transaction.return_value = tx
        db.batch.return_value = batch
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
            Collections.PAYOUTS: payouts_col,
            Collections.LICENSES: licenses_col,
        }[name]
        mock_get_db.return_value = db

        out = refund_order_item(
            _req("seller_1", {Fields.ORDER_ID: "order_3", Fields.PRODUCT_ID: "prod_1", "reason": "Access issue"})
        )

        assert out["success"] is True
        batch.update.assert_called_once()
        batch.commit.assert_called_once()
        tx.update.assert_called_once()
        mock_order_event.assert_called_once()

    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("handlers.orders.get_firestore")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.stripe.Refund.create")
    @patch("handlers.orders.get_db")
    def test_refund_order_item_race_returns_already_refunded_message(
        self,
        mock_get_db,
        mock_refund_create,
        mock_rl,
        _mock_sanitized,
        mock_get_fs,
        _mock_ts,
        _mock_resp,
    ):
        from handlers.orders import refund_order_item

        mock_rl.return_value.check_rate_limit.return_value = (True, "")
        mock_refund_create.return_value = Mock(id="re_4")

        fs = Mock()
        fs.transactional = lambda fn: fn
        fs.Increment.side_effect = lambda n: ("inc", n)
        fs.ArrayUnion.side_effect = lambda values: ("arr_union", values)
        mock_get_fs.return_value = fs

        initial = _snap(_base_order_data(is_digital=False), doc_id="order_4")
        race_data = _base_order_data(is_digital=False)
        race_data[Fields.ITEMS][0][Fields.STATUS] = DeliveryStatusValues.REFUNDED
        fresh_refunded = _snap(race_data, doc_id="order_4")

        order_ref = Mock()
        order_ref.get.side_effect = [initial, fresh_refunded]
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        user_ref = Mock()
        user_ref.get.return_value = _snap({Fields.ROLES: [UserRoleValues.SELLER]}, doc_id="seller_1")
        users_col = Mock()
        users_col.document.return_value = user_ref

        products_col = Mock()
        products_col.document.return_value = Mock()

        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.get.return_value = []
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        licenses_q = Mock()
        licenses_q.where.return_value = licenses_q
        licenses_q.stream.return_value = []
        licenses_col = Mock()
        licenses_col.where.return_value = licenses_q

        db = Mock()
        db.transaction.return_value = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
            Collections.PAYOUTS: payouts_col,
            Collections.LICENSES: licenses_col,
        }[name]
        mock_get_db.return_value = db

        out = refund_order_item(
            _req("seller_1", {Fields.ORDER_ID: "order_4", Fields.PRODUCT_ID: "prod_1", "reason": "Late race"})
        )

        assert out["success"] is True
        assert out["message"] == "Item was already refunded"
