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


class TestExecuteSellerPayoutsDeep:
    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.stripe.Transfer.create")
    @patch("handlers.payment_stripe._get_seller_stripe_snapshot", return_value={"seller_1": "acct_1"})
    @patch("handlers.payment_stripe.get_db")
    def test_execute_seller_payouts_scoped_coupon_and_transfer_failure(
        self,
        mock_get_db,
        _mock_snapshot,
        mock_transfer_create,
        _mock_ts,
    ):
        from handlers.payment_stripe import _execute_seller_payouts

        def _transfer_side_effect(**kwargs):
            if kwargs.get("destination") == "acct_3":
                raise RuntimeError("bank fail")
            return Mock(id="tr_ok")

        mock_transfer_create.side_effect = _transfer_side_effect

        payout_ref_1 = Mock()
        payout_ref_1.get.return_value = _snap(exists=False)

        payout_ref_2 = Mock()
        payout_ref_2.get.return_value = _snap({Fields.STATUS: PayoutStatusValues.COMPLETED}, exists=True)

        payout_ref_3 = Mock()
        payout_ref_3.get.return_value = _snap({Fields.STATUS: PayoutStatusValues.FAILED}, exists=True)

        payouts_col = Mock()
        payouts_col.document.side_effect = lambda doc_id: {
            "order_1_seller_1": payout_ref_1,
            "order_1_seller_2": payout_ref_2,
            "order_1_seller_3": payout_ref_3,
        }[doc_id]

        seller_profiles_col = Mock()
        seller_profiles_col.document.return_value.get.return_value = _snap(
            {Fields.STRIPE_ACCOUNT_ID: "acct_3"},
            doc_id="seller_3",
        )

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.PAYOUTS: payouts_col,
            Collections.SELLER_PROFILES: seller_profiles_col,
        }[name]
        mock_get_db.return_value = db

        order_data = {
            Fields.ITEMS: [
                {Fields.SELLER_ID: "seller_1", Fields.PRICE: 10.0, Fields.QUANTITY: 1},
                {Fields.SELLER_ID: "seller_2", Fields.PRICE: 10.0, Fields.QUANTITY: 1},
                {Fields.SELLER_ID: "seller_3", Fields.PRICE: 10.0, Fields.QUANTITY: 1},
                {Fields.PRICE: 5.0, Fields.QUANTITY: 1},  # no seller id
            ],
            Fields.PLATFORM_FEE_RATIO: 0.1,
            Fields.SUBTOTAL_CENTS: 3000,
            Fields.DISCOUNT_AMOUNT_CENTS: 500,
            Fields.COUPON_SELLER_ID: "seller_1",
        }

        transfer_errors = _execute_seller_payouts("order_1", order_data, charge_id="ch_1")

        # seller_1: scoped discount ratio => 1000 -> 500, fee 10% => net 450
        payload_1 = payout_ref_1.set.call_args.args[0]
        assert payload_1[Fields.AMOUNT_CENTS] == 500
        assert payload_1[Fields.NET_AMOUNT_CENTS] == 450
        payout_ref_1.update.assert_called_once()

        # seller_2: already completed payout => skipped
        payout_ref_2.set.assert_not_called()
        payout_ref_2.update.assert_not_called()

        # seller_3: previously failed payout gets retried, then transfer failure recorded
        payout_ref_3.set.assert_called_once()
        payout_ref_3.update.assert_called_once()
        assert transfer_errors == [("seller_3", "bank fail")]

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.stripe.Transfer.create")
    @patch("handlers.payment_stripe.get_db")
    def test_execute_seller_payouts_without_charge_id_only_writes_pending_records(
        self,
        mock_get_db,
        mock_transfer_create,
        _mock_ts,
    ):
        from handlers.payment_stripe import _execute_seller_payouts

        payout_ref = Mock()
        payout_ref.get.return_value = _snap(exists=False)

        payouts_col = Mock()
        payouts_col.document.return_value = payout_ref

        db = Mock()
        db.collection.return_value = payouts_col
        mock_get_db.return_value = db

        order_data = {
            Fields.ITEMS: [{Fields.SELLER_ID: "seller_1", Fields.PRICE: 20.0, Fields.QUANTITY: 1}],
            Fields.PLATFORM_FEE_RATIO: 0.1,
            Fields.SUBTOTAL_CENTS: 2000,
            Fields.DISCOUNT_AMOUNT_CENTS: 500,  # platform-wide coupon: seller payout unchanged
            Fields.COUPON_SELLER_ID: None,
        }

        transfer_errors = _execute_seller_payouts("order_no_charge", order_data, charge_id="")

        payload = payout_ref.set.call_args.args[0]
        assert payload[Fields.AMOUNT_CENTS] == 2000
        assert payload[Fields.NET_AMOUNT_CENTS] == 1800
        mock_transfer_create.assert_not_called()
        assert transfer_errors == []


class TestPostPaymentSideEffectsDeep:
    @patch("services.push_service.send_push_notification")
    @patch("handlers.payment_stripe._clear_user_cart")
    @patch("handlers.coupons.redeem_coupon")
    @patch("handlers.payment_stripe._email_t", side_effect=lambda key, _lang="en": f"{key} {{oid}}")
    @patch("handlers.payment_stripe.get_seller_notification_email", return_value="<p>seller</p>")
    @patch("handlers.payment_stripe.get_order_confirmation_email", return_value="<p>buyer</p>")
    @patch("handlers.payment_stripe.generate_invoice_pdf", return_value=b"%PDF-1.7")
    @patch("handlers.payment_stripe.send_email")
    @patch("handlers.payment_stripe.enqueue_email_task")
    @patch("handlers.payment_stripe._generate_digital_licenses")
    @patch("handlers.payment_stripe.get_db")
    def test_run_post_payment_side_effects_happy_path(
        self,
        mock_get_db,
        _mock_generate_licenses,
        mock_enqueue,
        mock_send_email,
        _mock_pdf,
        _mock_buyer_tpl,
        _mock_seller_tpl,
        _mock_t,
        mock_redeem,
        mock_clear_cart,
        mock_push,
    ):
        from handlers.payment_stripe import _run_post_payment_side_effects

        order_data = {
            Fields.USER_ID: "buyer_1",
            Fields.PREFERRED_LANGUAGE: "en",
            Fields.ITEMS: [
                {Fields.SELLER_ID: "seller_1", Fields.NAME: "Item A"},
                {Fields.SELLER_ID: "seller_2", Fields.NAME: "Fresh Fish", Fields.IS_PERISHABLE: True},
            ],
            Fields.COUPON_CODE: "SAVE10",
            Fields.COUPON_PRERESERVED: False,
        }

        refreshed_order = dict(order_data)
        refreshed_doc = _snap(refreshed_order, doc_id="order_1")

        buyer_ref = Mock()
        buyer_ref.get.return_value = _snap({Fields.EMAIL: "buyer@example.com", Fields.PREFERRED_LANGUAGE: "en"}, doc_id="buyer_1")
        seller_1_ref = Mock()
        seller_1_ref.get.return_value = _snap({Fields.EMAIL: "s1@example.com", Fields.PREFERRED_LANGUAGE: "en"}, doc_id="seller_1")
        seller_2_ref = Mock()
        seller_2_ref.get.return_value = _snap({Fields.EMAIL: "s2@example.com", Fields.PREFERRED_LANGUAGE: "fr"}, doc_id="seller_2")

        orders_col = Mock()
        orders_col.document.return_value.get.return_value = refreshed_doc

        users_col = Mock()
        users_col.document.side_effect = lambda uid: {
            "buyer_1": buyer_ref,
            "seller_1": seller_1_ref,
            "seller_2": seller_2_ref,
        }[uid]

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        _run_post_payment_side_effects("order_1", order_data)

        mock_send_email.assert_called_once()  # PDF attachment path
        assert mock_enqueue.call_count >= 3  # seller notifications + perishable email
        mock_redeem.assert_called_once_with("SAVE10", "buyer_1", order_id="order_1")
        mock_clear_cart.assert_called_once_with("buyer_1")
        buyer_ref.update.assert_called_once()
        assert mock_push.call_count >= 3  # seller push + perishable urgent push

    @patch("services.push_service.send_push_notification", side_effect=RuntimeError("push down"))
    @patch("handlers.payment_stripe._clear_user_cart", side_effect=RuntimeError("cart down"))
    @patch("handlers.coupons.redeem_coupon")
    @patch("handlers.payment_stripe._email_t", side_effect=lambda key, _lang="en": f"{key} {{oid}}")
    @patch("handlers.payment_stripe.get_seller_notification_email", return_value="<p>seller</p>")
    @patch("handlers.payment_stripe.get_order_confirmation_email", return_value="<p>buyer</p>")
    @patch("handlers.payment_stripe.generate_invoice_pdf", side_effect=RuntimeError("pdf failed"))
    @patch("handlers.payment_stripe.send_email")
    @patch("handlers.payment_stripe.enqueue_email_task")
    @patch("handlers.payment_stripe._generate_digital_licenses", side_effect=RuntimeError("license failed"))
    @patch("handlers.payment_stripe.get_db")
    def test_run_post_payment_side_effects_tolerates_non_critical_failures(
        self,
        mock_get_db,
        _mock_generate_licenses,
        mock_enqueue,
        mock_send_email,
        _mock_pdf,
        _mock_buyer_tpl,
        _mock_seller_tpl,
        _mock_t,
        mock_redeem,
        _mock_clear_cart,
        _mock_push,
    ):
        from handlers.payment_stripe import _run_post_payment_side_effects

        order_data = {
            Fields.USER_ID: "buyer_2",
            Fields.CUSTOMER_EMAIL: "buyer2@example.com",
            Fields.PREFERRED_LANGUAGE: "en",
            Fields.ITEMS: [{Fields.SELLER_ID: "seller_3", Fields.NAME: "Perishable", Fields.IS_PERISHABLE: True}],
            Fields.COUPON_CODE: "SAVE5",
            Fields.COUPON_PRERESERVED: True,
        }

        refreshed_doc = _snap(order_data, exists=False, doc_id="order_2")
        orders_col = Mock()
        orders_col.document.return_value.get.return_value = refreshed_doc

        seller_3_ref = Mock()
        seller_3_ref.get.return_value = _snap({Fields.EMAIL: "s3@example.com", Fields.PREFERRED_LANGUAGE: "en"}, doc_id="seller_3")
        buyer_2_ref = Mock()
        buyer_2_ref.get.return_value = _snap({Fields.EMAIL: "buyer2@example.com"}, doc_id="buyer_2")

        users_col = Mock()
        users_col.document.side_effect = lambda uid: {
            "seller_3": seller_3_ref,
            "buyer_2": buyer_2_ref,
        }[uid]

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        _run_post_payment_side_effects("order_2", order_data)

        # PDF failure should fall back to queued buyer email.
        mock_send_email.assert_not_called()
        assert mock_enqueue.call_count >= 1
        # Pre-reserved coupon must not be redeemed a second time.
        mock_redeem.assert_not_called()


class TestCheckoutSessionCompletedDeep:
    def test_checkout_session_completed_defers_when_payment_not_paid(self):
        from handlers.payment_stripe import process_checkout_session_completed

        out = process_checkout_session_completed(
            {StripeConstants.OBJECT_ID: "cs_1", StripeConstants.PAYMENT_STATUS: "unpaid"}
        )
        assert out is None

    def test_checkout_session_completed_missing_order_id_returns_none(self):
        from handlers.payment_stripe import process_checkout_session_completed

        out = process_checkout_session_completed(
            {StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID, StripeConstants.METADATA: {}}
        )
        assert out is None

    @patch("handlers.payment_stripe.get_db")
    def test_checkout_session_completed_order_not_found_returns_none(self, mock_get_db):
        from handlers.payment_stripe import process_checkout_session_completed

        orders_col = Mock()
        orders_col.document.return_value.get.return_value = _snap(exists=False)
        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        out = process_checkout_session_completed(
            {
                StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID,
                StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "missing"},
            }
        )
        assert out is None

    @patch("handlers.payment_stripe.get_db")
    def test_checkout_session_completed_non_pending_order_is_skipped(self, mock_get_db):
        from handlers.payment_stripe import process_checkout_session_completed

        order_data = {
            Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
            Fields.TOTAL_AMOUNT_CENTS: 1000,
            Fields.ITEMS: [],
        }
        orders_col = Mock()
        orders_col.document.return_value.get.return_value = _snap(order_data, doc_id="order_skip")
        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        out = process_checkout_session_completed(
            {
                StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID,
                "amount_total": 1000,
                StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_skip"},
            }
        )
        assert out == "Order order_skip skipped (status: confirmed)"

    @patch("handlers.payment_stripe._restore_stock_and_cancel_order")
    @patch("handlers.payment_stripe.get_db")
    def test_checkout_session_completed_amount_mismatch_cancels_order(self, mock_get_db, mock_restore):
        from handlers.payment_stripe import process_checkout_session_completed

        order_data = {
            Fields.ORDER_STATUS: OrderStatusValues.PENDING,
            Fields.TOTAL_AMOUNT_CENTS: 2000,
            Fields.ITEMS: [],
        }
        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_amt")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        session = {
            StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID,
            "amount_total": 1500,
            StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_amt"},
        }

        out = process_checkout_session_completed(session)

        assert out == "Order order_amt cancelled - amount mismatch"
        mock_restore.assert_called_once()

    @patch("handlers.payment_stripe._restore_stock_and_cancel_order")
    @patch("handlers.payment_stripe.get_db")
    def test_checkout_session_completed_address_mismatch_cancels_order(self, mock_get_db, mock_restore):
        from handlers.payment_stripe import process_checkout_session_completed

        order_data = {
            Fields.ORDER_STATUS: OrderStatusValues.PENDING,
            Fields.TOTAL_AMOUNT_CENTS: 2000,
            Fields.SHIPPING_ADDRESS: {Fields.COUNTRY: "CA", Fields.STATE: "ON", Fields.POSTAL_CODE: "M5V 2T6"},
            Fields.ITEMS: [],
        }
        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_addr")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        session = {
            StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID,
            "amount_total": 2000,
            StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_addr"},
            "shipping_details": {"address": {"country": "CA", "state": "ON", "postal_code": "H2X1Y4"}},
        }

        out = process_checkout_session_completed(session)

        assert out == "Order order_addr cancelled - address mismatch"
        mock_restore.assert_called_once()

    @patch("handlers.payment_stripe._restore_stock_and_cancel_order")
    @patch("handlers.payment_stripe.get_db")
    def test_checkout_session_completed_country_and_state_mismatch_cancels_order(self, mock_get_db, mock_restore):
        from handlers.payment_stripe import process_checkout_session_completed

        order_data = {
            Fields.ORDER_STATUS: OrderStatusValues.PENDING,
            Fields.TOTAL_AMOUNT_CENTS: 1200,
            Fields.SHIPPING_ADDRESS: {Fields.COUNTRY: "CA", Fields.STATE: "ON", Fields.POSTAL_CODE: "M5V2T6"},
            Fields.ITEMS: [],
        }
        orders_col = Mock()
        orders_col.document.return_value.get.return_value = _snap(order_data, doc_id="order_addr2")
        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        out = process_checkout_session_completed(
            {
                StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID,
                "amount_total": 1200,
                StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_addr2"},
                "shipping_details": {"address": {"country": "US", "state": "NY", "postal_code": "M5V2T6"}},
            }
        )
        assert out == "Order order_addr2 cancelled - address mismatch"
        mock_restore.assert_called_once()

    @patch("utils.helpers.get_charge_id_from_pi", return_value=None)
    @patch("handlers.payment_stripe._run_post_payment_side_effects")
    @patch("handlers.payment_stripe._execute_seller_payouts")
    @patch("handlers.payment_stripe.OrderEvent.write")
    @patch("handlers.payment_stripe.stripe.PaymentIntent.retrieve")
    @patch("handlers.payment_stripe.stripe.Refund.create")
    @patch("handlers.payment_stripe.ensure_stripe_key")
    @patch("handlers.payment_stripe._add_stock_restore_to_batch")
    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_checkout_session_completed_partial_bad_sellers_refunds_and_continues(
        self,
        mock_get_db,
        _mock_ts,
        mock_add_restore,
        _mock_ensure,
        mock_refund_create,
        mock_pi_retrieve,
        _mock_event,
        mock_exec_payouts,
        mock_side_effects,
        _mock_charge_id,
    ):
        from handlers.payment_stripe import process_checkout_session_completed

        mock_refund_create.return_value = Mock(id="re_partial")
        mock_pi_retrieve.return_value = Mock()

        order_data = {
            Fields.ORDER_STATUS: OrderStatusValues.PENDING,
            Fields.TOTAL_AMOUNT_CENTS: 3000,
            Fields.SUBTOTAL_CENTS: 3000,
            Fields.DISCOUNT_AMOUNT_CENTS: 300,
            Fields.SHIPPING_ADDRESS: {Fields.COUNTRY: "CA", Fields.STATE: "ON", Fields.POSTAL_CODE: "M5V 2T6"},
            Fields.ITEMS: [
                {Fields.PRODUCT_ID: "prod_bad", Fields.SELLER_ID: "seller_bad", Fields.PRICE: 10.0, Fields.QUANTITY: 1},
                {Fields.PRODUCT_ID: "prod_good", Fields.SELLER_ID: "seller_good", Fields.PRICE: 20.0, Fields.QUANTITY: 1},
            ],
        }

        order_ref = Mock()
        order_ref.get.return_value = _snap(order_data, doc_id="order_partial")
        orders_col = Mock()
        orders_col.document.return_value = order_ref

        products_col = Mock()
        products_col.document.side_effect = lambda pid: Mock(
            get=Mock(
                return_value=_snap(
                    {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED}
                    if pid == "prod_bad"
                    else {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE},
                    doc_id=pid,
                )
            )
        )

        users_col = Mock()
        users_col.document.side_effect = lambda _uid: Mock(get=Mock(return_value=_snap({Fields.SUSPENDED: False})))

        batch = Mock()
        db = Mock()
        db.batch.return_value = batch
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PRODUCTS: products_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        session = {
            StripeConstants.PAYMENT_STATUS: StripeConstants.STATUS_PAID,
            "amount_total": 3000,
            StripeConstants.PAYMENT_INTENT: "pi_partial",
            StripeConstants.METADATA: {StripeConstants.METADATA_ORDER_ID: "order_partial"},
            "shipping_details": {"address": {"country": "CA", "state": "ON", "postal_code": "M5V2T6"}},
        }

        out = process_checkout_session_completed(session)

        assert out == "Order order_partial confirmed"
        # Discount ratio 0.9 on bad seller item 1000c => 900c partial refund
        assert mock_refund_create.call_args.kwargs[Fields.AMOUNT] == 900
        mock_add_restore.assert_called_once()
        batch.commit.assert_called_once()
        mock_exec_payouts.assert_not_called()  # no charge_id resolved
        mock_side_effects.assert_called_once()


class TestCartCleanupDeep:
    @patch("handlers.payment_stripe.get_db")
    def test_clear_user_cart_uses_paginated_batches(self, mock_get_db):
        from handlers.payment_stripe import _clear_user_cart

        page_1 = []
        for _ in range(500):
            d = Mock()
            d.reference = Mock()
            page_1.append(d)
        doc_last = Mock()
        doc_last.reference = Mock()
        page_2 = [doc_last]

        cart_ref = Mock()
        cart_ref.limit.return_value.stream.side_effect = [page_1, page_2]

        user_ref = Mock()
        user_ref.collection.return_value = cart_ref
        users_col = Mock()
        users_col.document.return_value = user_ref

        batch_1 = Mock()
        batch_2 = Mock()
        db = Mock()
        db.collection.return_value = users_col
        db.batch.side_effect = [batch_1, batch_2]
        mock_get_db.return_value = db

        _clear_user_cart("buyer_1")

        assert batch_1.delete.call_count == 500
        assert batch_2.delete.call_count == 1
        batch_1.commit.assert_called_once()
        batch_2.commit.assert_called_once()
