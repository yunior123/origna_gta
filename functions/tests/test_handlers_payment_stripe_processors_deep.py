from unittest.mock import Mock, patch

from schema_constants import (
    Collections,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    ProductLifecycleStatusValues,
    StripeConstants,
    UserRoleValues,
)


def _snap(data=None, *, exists=True, doc_id="doc_1"):
    snap = Mock()
    snap.exists = exists
    snap.id = doc_id
    snap.to_dict.return_value = {} if data is None else data
    snap.reference = Mock()
    return snap


def _req(uid: str | None, data: dict | None = None):
    req = Mock()
    req.auth = Mock(uid=uid) if uid else None
    req.data = data or {}
    return req


class TestStripeProcessorDeep:
    @patch("handlers.payment_stripe._run_post_payment_side_effects")
    @patch("handlers.payment_stripe._execute_seller_payouts")
    @patch("handlers.payment_stripe.OrderEvent.write")
    @patch("handlers.payment_stripe.ensure_stripe_key")
    @patch("utils.helpers.get_charge_id_from_pi", return_value="ch_123")
    @patch("handlers.payment_stripe.stripe.PaymentIntent.retrieve")
    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_process_async_payment_succeeded_happy_path(
        self,
        mock_get_db,
        _mock_ts,
        mock_retrieve_pi,
        _mock_get_charge,
        _mock_ensure_key,
        _mock_event_write,
        mock_payouts,
        mock_side_effects,
    ):
        from handlers.payment_stripe import process_async_payment_succeeded

        order_data = {
            Fields.PAYMENT_STATUS: PaymentStatusValues.AWAITING_PAYMENT,
            Fields.ORDER_STATUS: OrderStatusValues.PENDING,
            Fields.TOTAL_AMOUNT_CENTS: 1000,
            Fields.ITEMS: [{Fields.PRODUCT_ID: "prod_1", Fields.SELLER_ID: "seller_1"}],
            Fields.USER_ID: "buyer_1",
        }
        order_doc = _snap(order_data, doc_id="order_1")
        order_ref = Mock()
        order_ref.get.return_value = order_doc
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        products_col = Mock()
        products_col.document.side_effect = lambda pid: Mock(id=pid)
        users_col = Mock()
        users_col.document.side_effect = lambda uid: Mock(id=uid)

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PRODUCTS: products_col,
            Collections.USERS: users_col,
        }[name]
        db.get_all.side_effect = [
            [_snap({Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE}, doc_id="prod_1")],
            [_snap({Fields.SUSPENDED: False}, doc_id="seller_1")],
        ]
        mock_get_db.return_value = db
        mock_retrieve_pi.return_value = Mock()

        session = {
            StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_1"},
            "amount_total": 1000,
            StripeConstants.PAYMENT_INTENT: "pi_123",
        }
        out = process_async_payment_succeeded(session)

        assert out == "Order order_1 payment captured"
        order_ref.update.assert_called()
        mock_payouts.assert_called_once()
        mock_side_effects.assert_called_once()

    @patch("handlers.payment_stripe.OrderEvent.write")
    @patch("handlers.payment_stripe._add_stock_restore_to_batch")
    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_process_async_payment_failed_restores_stock_and_marks_failed(
        self,
        mock_get_db,
        _mock_ts,
        mock_restore,
        _mock_event_write,
    ):
        from handlers.payment_stripe import process_async_payment_failed

        order_data = {
            Fields.STOCK_RESTORED: False,
            Fields.USER_ID: "buyer_1",
            Fields.CUSTOMER_EMAIL: "buyer@example.com",
            Fields.CUSTOMER_NAME: "Buyer",
            Fields.PREFERRED_LANGUAGE: "en",
            Fields.TOTAL_AMOUNT_CENTS: 1200,
        }
        order_doc = _snap(order_data, doc_id="order_2")
        order_ref = Mock()
        order_ref.get.return_value = order_doc
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        batch = Mock()
        db = Mock()
        db.collection.return_value = orders_col
        db.batch.return_value = batch
        mock_get_db.return_value = db

        session = {StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_2"}}
        with patch("services.email_service.send_payment_capture_failed_email") as mock_email:
            out = process_async_payment_failed(session)

        assert out == "Order order_2 cancelled due to payment failure"
        mock_restore.assert_called_once_with(batch, order_data)
        batch.commit.assert_called_once()
        mock_email.assert_called_once()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_firestore")
    @patch("handlers.payment_stripe.get_db")
    def test_process_session_expired_marks_order_expired(self, mock_get_db, mock_get_firestore, _mock_ts):
        from handlers.payment_stripe import process_session_expired

        mock_get_firestore.return_value.Increment.side_effect = lambda v: ("inc", v)
        mock_get_firestore.return_value.transactional = lambda fn: fn

        order_data = {
            Fields.STOCK_RESTORED: False,
            Fields.ITEMS: [{Fields.PRODUCT_ID: "prod_1", Fields.QUANTITY: 1}],
        }
        order_doc = _snap(order_data, doc_id="order_3")
        tx = Mock()

        order_ref = Mock()
        order_ref.get.return_value = order_doc
        orders_col = Mock()
        orders_col.document.return_value = order_ref
        products_col = Mock()
        products_col.document.return_value = Mock()

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PRODUCTS: products_col,
        }[name]
        db.transaction.return_value = tx
        mock_get_db.return_value = db

        session = {StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_3"}}
        out = process_session_expired(session)
        assert out == "Order order_3 expired"
        tx.update.assert_called()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_firestore")
    @patch("handlers.payment_stripe.get_db")
    def test_payment_intent_status_handlers_update_expected_states(self, mock_get_db, mock_get_firestore, _mock_ts):
        from handlers.payment_stripe import (
            process_payment_intent_canceled,
            process_payment_intent_failed,
            process_payment_intent_succeeded,
        )

        mock_get_firestore.return_value.transactional = lambda fn: fn
        mock_get_firestore.return_value.Increment.side_effect = lambda v: ("inc", v)

        tx = Mock()
        order_ref = Mock()
        order_doc = _snap({Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURING}, doc_id="order_4")
        order_ref.get.return_value = order_doc
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.collection.return_value = orders_col
        db.transaction.return_value = tx
        mock_get_db.return_value = db

        pi = {StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_4"}}
        out_success = process_payment_intent_succeeded(pi)
        assert "captured" in out_success

        # For failed/canceled flows, return a doc payload with order status.
        order_ref.get.return_value = _snap(
            {Fields.ORDER_STATUS: OrderStatusValues.PENDING, Fields.STOCK_RESTORED: False, Fields.ITEMS: []},
            doc_id="order_4",
        )
        out_failed = process_payment_intent_failed(pi)
        out_canceled = process_payment_intent_canceled(pi)
        assert "failed" in out_failed
        assert "canceled" in out_canceled

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_transfer_reversed_and_payout_failed_update_records(self, mock_get_db, _mock_ts):
        from handlers.payment_stripe import process_payout_failed, process_transfer_reversed

        payout_doc = _snap({Fields.STATUS: PayoutStatusValues.PENDING}, doc_id="payout_1")
        payouts_query = Mock()
        payouts_query.where.return_value = payouts_query
        payouts_query.limit.return_value = payouts_query
        payouts_query.stream.return_value = [payout_doc]

        payouts_col = Mock()
        payouts_col.where.return_value = payouts_query

        security_col = Mock()
        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.PAYOUTS: payouts_col,
            Collections.SECURITY_ALERTS: security_col,
        }[name]
        mock_get_db.return_value = db

        out = process_transfer_reversed({StripeConstants.OBJECT_ID: "tr_123"})
        assert out == "Payout payout_1 reversed"
        process_payout_failed(
            {
                StripeConstants.OBJECT_ID: "po_123",
                Fields.DESTINATION: "acct_1",
                Fields.AMOUNT: 1000,
                "failure_message": "bank rejected",
            }
        )
        security_col.add.assert_called()
        payout_doc.reference.update.assert_called()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.ensure_stripe_key")
    @patch("handlers.payment_stripe.get_db")
    def test_process_refund_failed_flags_order_for_manual_review(self, mock_get_db, _mock_ensure_key, _mock_ts):
        from handlers.payment_stripe import process_refund_failed

        order_doc = _snap({}, doc_id="order_9")
        orders_col = Mock()
        orders_col.where.return_value.limit.return_value.get.return_value = [order_doc]
        sec_col = Mock()
        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.SECURITY_ALERTS: sec_col,
        }[name]
        mock_get_db.return_value = db

        with patch("handlers.payment_stripe.stripe.Charge.retrieve", return_value=Mock(payment_intent="pi_9")):
            process_refund_failed({StripeConstants.CHARGE: "ch_9", Fields.AMOUNT: 400})

        sec_col.add.assert_called_once()
        order_doc.reference.update.assert_called_once()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_process_account_updated_updates_seller_profile_and_role(self, mock_get_db, _mock_ts):
        from handlers.payment_stripe import process_account_updated

        sp_doc = _snap({}, doc_id="seller_1")
        seller_profiles_col = Mock()
        seller_profiles_col.where.return_value.limit.return_value.get.return_value = [sp_doc]

        user_ref = Mock()
        user_ref.get.return_value = _snap({Fields.ROLES: ["buyer"]})
        users_col = Mock()
        users_col.document.return_value = user_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SELLER_PROFILES: seller_profiles_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        with patch("firebase_admin.firestore.ArrayUnion", side_effect=lambda vals: ("au", vals)):
            process_account_updated(
                {
                    StripeConstants.OBJECT_ID: "acct_123",
                    "charges_enabled": True,
                    "payouts_enabled": True,
                    "details_submitted": True,
                    "requirements": {"currently_due": [], "eventually_due": []},
                }
            )

        sp_doc.reference.update.assert_called_once()
        user_ref.update.assert_called_once()


class TestStripeConnectEndpointsDeep:
    @patch("handlers.payment_stripe.get_rate_limiter")
    @patch("handlers.payment_stripe.get_db")
    def test_create_connect_account_returns_existing_account(self, mock_get_db, mock_get_rate_limiter):
        from handlers.payment_stripe import create_connect_account

        mock_get_rate_limiter.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.EMAIL: "seller@example.com", Fields.SUSPENDED: False}, doc_id="seller_1")
        user_ref = Mock()
        user_ref.get.return_value = user_doc
        users_col = Mock()
        users_col.document.return_value = user_ref

        sp_doc = _snap({Fields.STRIPE_ACCOUNT_ID: "acct_existing"}, doc_id="seller_1")
        sp_ref = Mock()
        sp_ref.get.return_value = sp_doc
        sp_col = Mock()
        sp_col.document.return_value = sp_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: sp_col,
        }[name]
        mock_get_db.return_value = db

        out = create_connect_account(_req("seller_1"))
        assert out["success"] is True
        assert out["existing"] is True
        assert out["accountId"] == "acct_existing"

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_rate_limiter")
    @patch("handlers.payment_stripe.get_db")
    def test_create_connect_account_creates_new_stripe_account_and_profile(
        self,
        mock_get_db,
        mock_get_rate_limiter,
        _mock_ts,
    ):
        from handlers.payment_stripe import create_connect_account

        mock_get_rate_limiter.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.EMAIL: "seller@example.com", Fields.SUSPENDED: False}, doc_id="seller_2")
        user_ref = Mock()
        user_ref.get.return_value = user_doc
        users_col = Mock()
        users_col.document.return_value = user_ref

        sp_doc = _snap({}, exists=False, doc_id="seller_2")
        sp_ref = Mock()
        sp_ref.get.return_value = sp_doc
        sp_col = Mock()
        sp_col.document.return_value = sp_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: sp_col,
        }[name]
        mock_get_db.return_value = db

        fake_account = Mock(id="acct_new")

        class _FakeSellerProfile:
            def __init__(self, **_kwargs):
                self._payload = {
                    Fields.STRIPE_ACCOUNT_ID: "acct_new",
                    Fields.ONBOARDING_COMPLETED: False,
                    Fields.CHARGES_ENABLED: False,
                    Fields.PAYOUTS_ENABLED: False,
                }

            def model_dump(self, exclude_none=True):
                return dict(self._payload)

        with (
            patch("handlers.payment_stripe.stripe.Account.create", return_value=fake_account),
            patch("models.seller_profile.SellerProfile", _FakeSellerProfile),
        ):
            out = create_connect_account(_req("seller_2", {Fields.COUNTRY: "CA", "businessType": "individual"}))

        assert out["success"] is True
        assert out["accountId"] == "acct_new"
        sp_ref.set.assert_called_once()

    @patch("handlers.payment_stripe.get_rate_limiter")
    @patch("handlers.payment_stripe.get_db")
    def test_create_account_link_success(self, mock_get_db, mock_get_rate_limiter):
        from handlers.payment_stripe import create_account_link

        mock_get_rate_limiter.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({}, doc_id="seller_3")
        users_col = Mock()
        users_col.document.return_value.get.return_value = user_doc

        sp_doc = _snap({Fields.STRIPE_ACCOUNT_ID: "acct_link"}, doc_id="seller_3")
        sp_col = Mock()
        sp_col.document.return_value.get.return_value = sp_doc

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: sp_col,
        }[name]
        mock_get_db.return_value = db

        with patch("handlers.payment_stripe.stripe.AccountLink.create", return_value=Mock(url="https://stripe.test/onboard")):
            out = create_account_link(_req("seller_3"))
        assert out["success"] is True
        assert out["url"] == "https://stripe.test/onboard"

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_rate_limiter")
    @patch("handlers.payment_stripe.get_db")
    def test_get_connect_account_status_success_updates_profile_and_role(
        self,
        mock_get_db,
        mock_get_rate_limiter,
        _mock_ts,
    ):
        from handlers.payment_stripe import get_connect_account_status

        mock_get_rate_limiter.return_value.check_rate_limit.return_value = (True, "")

        user_doc = _snap({Fields.ROLES: ["buyer"], Fields.SUSPENDED: False}, doc_id="seller_4")
        user_ref = Mock()
        user_ref.get.return_value = user_doc
        users_col = Mock()
        users_col.document.return_value = user_ref

        sp_doc = _snap({Fields.STRIPE_ACCOUNT_ID: "acct_status"}, doc_id="seller_4")
        sp_ref = Mock()
        sp_ref.get.return_value = sp_doc
        sp_col = Mock()
        sp_col.document.return_value = sp_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: sp_col,
        }[name]
        mock_get_db.return_value = db

        requirements = Mock(currently_due=[], eventually_due=["verification.document"])
        acct = Mock(charges_enabled=True, payouts_enabled=True, details_submitted=True, requirements=requirements)
        with (
            patch("handlers.payment_stripe.stripe.Account.retrieve", return_value=acct),
            patch("firebase_admin.firestore.ArrayUnion", side_effect=lambda vals: ("au", vals)),
        ):
            out = get_connect_account_status(_req("seller_4"))

        assert out["success"] is True
        sp_ref.update.assert_called_once()
        user_ref.update.assert_called_once()
