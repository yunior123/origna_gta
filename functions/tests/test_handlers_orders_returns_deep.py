from datetime import UTC, datetime, timedelta
from unittest.mock import Mock, patch

import pytest
from firebase_functions import https_fn

from schema_constants import (
    ApiKeys,
    Collections,
    DeliveryStatusValues,
    Fields,
    NotificationTypes,
    ReturnStatusValues,
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


class TestCreateReturnRequestDeep:
    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.enqueue_email_task")
    @patch("handlers.orders.send_push_notification")
    @patch("handlers.orders.get_return_request_submitted_email", return_value="<p>seller return request</p>")
    @patch("handlers.orders._email_t", side_effect=lambda key, _lang="en": f"{key} {{oid}}")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_create_return_request_success(
        self,
        mock_get_db,
        mock_rl,
        _mock_sanitized,
        _mock_t,
        _mock_tpl,
        mock_push,
        mock_email,
        _mock_resp,
    ):
        from handlers.orders import create_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_doc = _snap(
            {
                Fields.USER_ID: "buyer_1",
                Fields.ITEMS: [
                    {
                        Fields.PRODUCT_ID: "prod_1",
                        Fields.IS_DIGITAL: False,
                        Fields.STATUS: DeliveryStatusValues.DELIVERED,
                        Fields.DELIVERED_AT: datetime.now(UTC) - timedelta(days=2),
                        Fields.NAME: "Headphones",
                        Fields.QUANTITY: 1,
                        Fields.SELLER_ID: "seller_1",
                        Fields.CART_ITEM_ID: "ci_1",
                    }
                ],
            },
            doc_id="order_1",
        )

        order_ref = Mock()
        order_ref.get.return_value = order_doc
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        returns_query = Mock()
        returns_query.where.return_value = returns_query
        returns_query.limit.return_value = returns_query
        returns_query.get.return_value = []

        return_ref = Mock()
        return_ref.id = "ret_1"
        returns_col = Mock()
        returns_col.where.return_value = returns_query
        returns_col.document.return_value = return_ref

        seller_doc = _snap({Fields.EMAIL: "seller@example.com", Fields.PREFERRED_LANGUAGE: "en"}, doc_id="seller_1")
        users_col = Mock()
        users_col.document.return_value.get.return_value = seller_doc

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.RETURN_REQUESTS: returns_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        req = _req(
            "buyer_1",
            {Fields.ORDER_ID: "order_1", Fields.PRODUCT_ID: "prod_1", Fields.RETURN_REASON: "Damaged item"},
        )
        out = create_return_request(req)

        assert out["success"] is True
        assert out[Fields.RETURN_ID] == "ret_1"
        return_ref.set.assert_called_once()
        mock_push.assert_called_once()
        mock_email.assert_called_once()

    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_create_return_request_rejects_duplicate_active_return(self, mock_get_db, mock_rl, _mock_sanitized):
        from handlers.orders import create_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_doc = _snap(
            {
                Fields.USER_ID: "buyer_1",
                Fields.ITEMS: [
                    {
                        Fields.PRODUCT_ID: "prod_1",
                        Fields.IS_DIGITAL: False,
                        Fields.STATUS: DeliveryStatusValues.DELIVERED,
                        Fields.DELIVERED_AT: datetime.now(UTC) - timedelta(days=1),
                    }
                ],
            }
        )

        orders_col = Mock()
        orders_col.document.return_value.get.return_value = order_doc

        existing_return_doc = _snap({Fields.RETURN_STATUS: ReturnStatusValues.REQUESTED}, doc_id="ret_existing")
        returns_query = Mock()
        returns_query.where.return_value = returns_query
        returns_query.limit.return_value = returns_query
        returns_query.get.return_value = [existing_return_doc]
        returns_col = Mock()
        returns_col.where.return_value = returns_query

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.RETURN_REQUESTS: returns_col,
        }[name]
        mock_get_db.return_value = db

        req = _req(
            "buyer_1",
            {Fields.ORDER_ID: "order_1", Fields.PRODUCT_ID: "prod_1", Fields.RETURN_REASON: "Damaged"},
        )

        with pytest.raises(https_fn.HttpsError) as exc:
            create_return_request(req)
        assert exc.value.code == "already-exists"

    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_create_return_request_rejects_digital_item(self, mock_get_db, mock_rl, _mock_sanitized):
        from handlers.orders import create_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        order_doc = _snap(
            {
                Fields.USER_ID: "buyer_1",
                Fields.ITEMS: [
                    {
                        Fields.PRODUCT_ID: "prod_1",
                        Fields.IS_DIGITAL: True,
                        Fields.STATUS: DeliveryStatusValues.DELIVERED,
                    }
                ],
            }
        )
        orders_col = Mock()
        orders_col.document.return_value.get.return_value = order_doc

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.ORDERS: orders_col}[name]
        mock_get_db.return_value = db

        req = _req(
            "buyer_1",
            {Fields.ORDER_ID: "order_1", Fields.PRODUCT_ID: "prod_1", Fields.RETURN_REASON: "No longer needed"},
        )

        with pytest.raises(https_fn.HttpsError) as exc:
            create_return_request(req)
        assert exc.value.code == "invalid-argument"


class TestProcessReturnRefundDeep:
    @patch("handlers.orders._finalise_return_refunded")
    @patch("handlers.orders.get_db")
    def test_process_return_refund_already_refunded_item_short_circuit(self, mock_get_db, mock_finalise):
        from handlers.orders import _process_return_refund

        order_doc = _snap(
            {
                Fields.STRIPE_PAYMENT_INTENT_ID: "pi_1",
                Fields.ITEMS: [{Fields.PRODUCT_ID: "prod_1", Fields.STATUS: DeliveryStatusValues.REFUNDED}],
            },
            doc_id="order_1",
        )
        orders_col = Mock()
        orders_col.document.return_value.get.return_value = order_doc

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.ORDERS: orders_col}[name]
        mock_get_db.return_value = db

        _process_return_refund("order_1", "prod_1", "ret_1", "buyer_1")

        mock_finalise.assert_called_once_with("order_1", "prod_1", "ret_1")

    @patch("handlers.orders._finalise_return_refunded")
    @patch("stripe.Refund.create")
    @patch("handlers.orders.get_db")
    def test_process_return_refund_success_updates_order_item_and_finalises(
        self,
        mock_get_db,
        mock_refund_create,
        mock_finalise,
    ):
        from handlers.orders import _process_return_refund

        mock_refund_create.return_value = Mock(id="re_123")

        order_ref = Mock()
        order_doc = _snap(
            {
                Fields.STRIPE_PAYMENT_INTENT_ID: "pi_1",
                Fields.SUBTOTAL_CENTS: 1000,
                Fields.TAX_AMOUNT_CENTS: 130,
                Fields.SHIPPING_COST_CENTS: 100,
                Fields.ITEMS: [
                    {
                        Fields.PRODUCT_ID: "prod_1",
                        Fields.SELLER_ID: "seller_1",
                        Fields.PRICE: 10.0,
                        Fields.QUANTITY: 1,
                        Fields.STATUS: DeliveryStatusValues.DELIVERED,
                    }
                ],
            },
            doc_id="order_2",
        )
        order_ref.get.return_value = order_doc

        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.ORDERS: orders_col}[name]
        mock_get_db.return_value = db

        _process_return_refund("order_2", "prod_1", "ret_2", "buyer_1")

        mock_refund_create.assert_called_once()
        order_ref.update.assert_called_once()
        mock_finalise.assert_called_once()


class TestApproveRejectEscalateReturnDeep:
    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.send_push_notification")
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_approve_return_request_approve_action(self, mock_get_db, mock_rl, mock_push, _mock_resp):
        from handlers.orders import approve_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.ROLES: [UserRoleValues.SELLER]}, doc_id="seller_1")
        return_doc = _snap(
            {
                Fields.SELLER_ID: "seller_1",
                Fields.BUYER_ID: "buyer_1",
                Fields.ORDER_ID: "order_1",
                Fields.PRODUCT_ID: "prod_1",
                Fields.RETURN_STATUS: ReturnStatusValues.REQUESTED,
            },
            doc_id="ret_1",
        )

        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc

        return_ref = Mock()
        return_ref.get.return_value = return_doc
        returns_col = Mock()
        returns_col.document.return_value = return_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.RETURN_REQUESTS: returns_col,
        }[name]
        mock_get_db.return_value = db

        req = _req("seller_1", {Fields.RETURN_ID: "ret_1", "action": "approve"})
        out = approve_return_request(req)

        assert out["success"] is True
        assert out[Fields.RETURN_STATUS] == ReturnStatusValues.APPROVED
        return_ref.update.assert_called_once()
        mock_push.assert_called_once()

    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders._process_return_refund")
    @patch("handlers.orders.send_push_notification")
    @patch("handlers.orders.get_firestore")
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_approve_return_request_mark_received_action_restores_stock_and_refunds(
        self,
        mock_get_db,
        mock_rl,
        mock_get_fs,
        mock_push,
        mock_process_refund,
        _mock_resp,
    ):
        from handlers.orders import approve_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")
        mock_get_fs.return_value.transactional = lambda fn: fn
        mock_get_fs.return_value.Increment.side_effect = lambda n: ("inc", n)

        user_doc = _snap({Fields.ROLES: [UserRoleValues.SELLER]}, doc_id="seller_1")
        return_doc = _snap(
            {
                Fields.SELLER_ID: "seller_1",
                Fields.BUYER_ID: "buyer_1",
                Fields.ORDER_ID: "order_2",
                Fields.PRODUCT_ID: "prod_2",
                Fields.QUANTITY: 1,
                Fields.FULFILLMENT_WAREHOUSE_ID: "wh_1",
                Fields.RETURN_STATUS: ReturnStatusValues.LABEL_ISSUED,
            },
            doc_id="ret_2",
        )

        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc

        return_ref = Mock()
        return_ref.get.return_value = return_doc
        returns_col = Mock()
        returns_col.document.return_value = return_ref

        product_ref = Mock()
        products_col = Mock()
        products_col.document.return_value = product_ref

        tx = Mock()
        db = Mock()
        db.transaction.return_value = tx
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.RETURN_REQUESTS: returns_col,
            Collections.PRODUCTS: products_col,
        }[name]
        mock_get_db.return_value = db

        req = _req("seller_1", {Fields.RETURN_ID: "ret_2", "action": "mark_received"})
        out = approve_return_request(req)

        assert out["success"] is True
        assert out[Fields.RETURN_STATUS] == ReturnStatusValues.REFUNDED
        assert tx.update.call_count >= 2
        mock_process_refund.assert_called_once_with("order_2", "prod_2", "ret_2", "buyer_1")
        mock_push.assert_called_once()

    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.send_push_notification")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_reject_return_request_success(
        self,
        mock_get_db,
        mock_rl,
        _mock_sanitized,
        mock_push,
        _mock_resp,
    ):
        from handlers.orders import reject_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.ROLES: [UserRoleValues.ADMIN]}, doc_id="admin_1")
        return_doc = _snap(
            {
                Fields.SELLER_ID: "seller_1",
                Fields.BUYER_ID: "buyer_1",
                Fields.ORDER_ID: "order_3",
                Fields.RETURN_STATUS: ReturnStatusValues.REQUESTED,
            },
            doc_id="ret_3",
        )

        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc

        return_ref = Mock()
        return_ref.get.return_value = return_doc
        returns_col = Mock()
        returns_col.document.return_value = return_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.RETURN_REQUESTS: returns_col,
        }[name]
        mock_get_db.return_value = db

        req = _req(
            "admin_1",
            {Fields.RETURN_ID: "ret_3", Fields.RETURN_ADMIN_NOTE: "Item returned damaged by buyer"},
        )
        out = reject_return_request(req)

        assert out["success"] is True
        assert out[Fields.RETURN_STATUS] == ReturnStatusValues.REJECTED
        return_ref.update.assert_called_once()
        mock_push.assert_called_once()

    @patch("handlers.orders.create_success_response", side_effect=lambda payload: {"success": True, **payload})
    @patch("handlers.orders.send_push_notification")
    @patch("utils.helpers.sanitized_text", side_effect=lambda s: s)
    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.orders.get_db")
    def test_escalate_return_request_success_notifies_admins(
        self,
        mock_get_db,
        mock_rl,
        _mock_sanitized,
        mock_push,
        _mock_resp,
    ):
        from handlers.orders import escalate_return_request

        mock_rl.return_value.check_rate_limit.return_value = (True, "")

        return_ref = Mock()
        return_ref.get.return_value = _snap(
            {
                Fields.BUYER_ID: "buyer_1",
                Fields.ORDER_ID: "order_4",
                Fields.RETURN_STATUS: ReturnStatusValues.REQUESTED,
            },
            doc_id="ret_4",
        )
        returns_col = Mock()
        returns_col.document.return_value = return_ref

        admin_doc_1 = _snap({}, doc_id="admin_1")
        admin_doc_2 = _snap({}, doc_id="admin_2")
        users_q = Mock()
        users_q.where.return_value = users_q
        users_q.limit.return_value = users_q
        users_q.stream.return_value = [admin_doc_1, admin_doc_2]
        users_col = Mock()
        users_col.where.return_value = users_q

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.RETURN_REQUESTS: returns_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        req = _req(
            "buyer_1",
            {Fields.RETURN_ID: "ret_4", Fields.ESCALATION_REASON: "Seller unresponsive for 10 days"},
        )
        out = escalate_return_request(req)

        assert out["success"] is True
        assert out[Fields.RETURN_STATUS] == ReturnStatusValues.ESCALATED
        return_ref.update.assert_called_once()
        assert mock_push.call_count == 2
        first_call = mock_push.call_args_list[0]
        assert first_call.kwargs["data"]["type"] == NotificationTypes.RETURN_STATUS
