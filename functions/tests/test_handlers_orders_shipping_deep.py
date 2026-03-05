from unittest.mock import Mock, patch

import pytest
import stripe
from firebase_functions import https_fn

from schema_constants import (
    ApiKeys,
    Collections,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    ShippingApprovalStatusValues,
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


class TestApproveShippingCostDeep:
    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("handlers.orders._restore_stock_to_batch")
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_reject_shipping_authorized_cancels_pi_and_restores_stock(
        self,
        mock_get_db,
        mock_rl,
        mock_restore_stock,
        _mock_ts,
        _mock_resp,
    ):
        from handlers.orders import approve_shipping_cost

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_data = {
            Fields.USER_ID: "buyer_1",
            Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED,
            Fields.STRIPE_PAYMENT_INTENT_ID: "pi_auth",
            Fields.SHIPPING_APPROVAL: {
                Fields.STATUS: ShippingApprovalStatusValues.PENDING,
            },
            Fields.ITEMS: [{Fields.PRODUCT_ID: "prod_1", Fields.QUANTITY: 2}],
        }

        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_auth")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        tx = Mock()
        batch = Mock()
        db = Mock()
        db.transaction.return_value = tx
        db.batch.return_value = batch
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
        }[name]
        mock_get_db.return_value = db

        out = approve_shipping_cost(_req("buyer_1", {Fields.ORDER_ID: "order_auth", ApiKeys.APPROVED: False}))

        assert out["success"] is True
        assert out[ApiKeys.APPROVED] is False
        mock_restore_stock.assert_called_once_with(batch, order_data[Fields.ITEMS])
        batch.commit.assert_called_once()
        assert tx.update.call_count == 1
        assert order_ref.update.call_count == 1

    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("handlers.orders._restore_stock_to_batch")
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_reject_shipping_captured_refund_failure_flags_manual_review(
        self,
        mock_get_db,
        mock_rl,
        mock_restore_stock,
        _mock_ts,
    ):
        from handlers.orders import approve_shipping_cost

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_data = {
            Fields.USER_ID: "buyer_1",
            Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
            Fields.STRIPE_PAYMENT_INTENT_ID: "pi_cap",
            Fields.SHIPPING_APPROVAL: {
                Fields.STATUS: ShippingApprovalStatusValues.PENDING,
            },
            Fields.ITEMS: [{Fields.PRODUCT_ID: "prod_1", Fields.QUANTITY: 1}],
        }

        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_cap")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        tx = Mock()
        db = Mock()
        db.transaction.return_value = tx
        db.batch.return_value = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
        }[name]
        mock_get_db.return_value = db

        with patch("handlers.orders.stripe.Refund.create", side_effect=stripe.error.StripeError("refund failed")):
            with pytest.raises(https_fn.HttpsError) as exc:
                approve_shipping_cost(_req("buyer_1", {Fields.ORDER_ID: "order_cap", ApiKeys.APPROVED: False}))

        assert exc.value.code == "internal"
        assert tx.update.call_count == 1
        mock_restore_stock.assert_not_called()

    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_approve_shipping_expected_cost_mismatch_rejected(self, mock_get_db, mock_rl):
        from handlers.orders import approve_shipping_cost

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_data = {
            Fields.USER_ID: "buyer_1",
            Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED,
            Fields.STRIPE_PAYMENT_INTENT_ID: "pi_auth2",
            Fields.SHIPPING_COST_CENTS: 1000,
            Fields.TAX_AMOUNT_CENTS: 100,
            Fields.TOTAL_AMOUNT_CENTS: 3000,
            Fields.SELLER_SHIPPING_COSTS: {"seller_1": 1000},
            Fields.SHIPPING_APPROVAL: {
                Fields.STATUS: ShippingApprovalStatusValues.PENDING,
                Fields.REQUESTED_BY: "seller_1",
                Fields.ACTUAL_COST: 12.50,
                Fields.NEW_COST_CENTS: 1250,
            },
            Fields.SHIPPING_ADDRESS: {Fields.STATE: "ON"},
        }
        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_exp_mismatch")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.transaction.return_value = Mock()
        db.collection.side_effect = lambda name: {Collections.ORDERS: orders_col}[name]
        mock_get_db.return_value = db

        with pytest.raises(https_fn.HttpsError) as exc:
            approve_shipping_cost(
                _req(
                    "buyer_1",
                    {
                        Fields.ORDER_ID: "order_exp_mismatch",
                        ApiKeys.APPROVED: True,
                        "expectedCostCents": 1200,
                    },
                )
            )

        assert exc.value.code == "failed-precondition"


class TestUpdateShippingCostDeep:
    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.get_server_timestamp", return_value="ts")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_update_shipping_free_shipping_order_requires_buyer_approval(
        self,
        mock_get_db,
        mock_rl,
        _mock_sanitized,
        _mock_ts,
        _mock_resp,
    ):
        from handlers.orders import update_shipping_cost

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_data = {
            Fields.USER_ID: "buyer_1",
            Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
            Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED,
            Fields.SHIPPING_COST_CENTS: 0,
            Fields.SELLER_SHIPPING_COSTS: {},
            Fields.ITEMS: [{Fields.SELLER_ID: "seller_1", Fields.PRODUCT_ID: "prod_1", Fields.QUANTITY: 1}],
        }
        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_free_ship")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.ORDERS: orders_col}[name]
        mock_get_db.return_value = db

        out = update_shipping_cost(
            _req(
                "seller_1",
                {
                    Fields.ORDER_ID: "order_free_ship",
                    ApiKeys.NEW_SHIPPING_COST: 3.75,
                    ApiKeys.REASON: "Carrier fee",
                },
            )
        )

        assert out["success"] is True
        assert out[ApiKeys.APPROVAL_REQUIRED] is True
        update_payload = order_ref.update.call_args.args[0]
        assert update_payload[Fields.SHIPPING_APPROVAL][Fields.STATUS] == ShippingApprovalStatusValues.PENDING
        assert update_payload[Fields.SHIPPING_APPROVAL][Fields.ORIGINAL_COST_CENTS] == 0

    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_update_shipping_rejects_invalid_payment_status(self, mock_get_db, mock_rl, _mock_sanitized):
        from handlers.orders import update_shipping_cost

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_data = {
            Fields.USER_ID: "buyer_1",
            Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
            Fields.PAYMENT_STATUS: "pending",
            Fields.SHIPPING_COST_CENTS: 500,
            Fields.SELLER_SHIPPING_COSTS: {"seller_1": 500},
            Fields.ITEMS: [{Fields.SELLER_ID: "seller_1", Fields.PRODUCT_ID: "prod_1", Fields.QUANTITY: 1}],
        }
        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_bad_pay")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.ORDERS: orders_col}[name]
        mock_get_db.return_value = db

        with pytest.raises(https_fn.HttpsError) as exc:
            update_shipping_cost(
                _req(
                    "seller_1",
                    {
                        Fields.ORDER_ID: "order_bad_pay",
                        ApiKeys.NEW_SHIPPING_COST: 7.25,
                        ApiKeys.REASON: "Carrier update",
                    },
                )
            )

        assert exc.value.code == "failed-precondition"
