from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import Mock, patch

from google.api_core import exceptions as google_exceptions
from schema_constants import (
    AlgoliaActionValues,
    BusinessRules,
    Collections,
    CronLockStatusValues,
    DeliveryStatusValues,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    ProductLifecycleStatusValues,
    SubscriptionStatusValues,
)


def _query(*, stream_return=None, stream_side_effect=None, get_return=None):
    query = Mock()
    query.where.return_value = query
    query.order_by.return_value = query
    query.limit.return_value = query
    query.start_after.return_value = query
    if stream_side_effect is not None:
        query.stream.side_effect = stream_side_effect
    else:
        query.stream.return_value = stream_return if stream_return is not None else []
    query.get.return_value = [] if get_return is None else get_return
    return query


def _snapshot(doc_id: str, data=None, *, exists=True):
    snap = Mock()
    snap.id = doc_id
    snap.exists = exists
    snap.to_dict.return_value = {} if data is None else data
    snap.reference = Mock()
    return snap


class TestCronLockHelpers:
    @patch("handlers.cron_jobs.get_firestore")
    @patch("handlers.cron_jobs.get_db")
    def test_acquire_cron_lock_returns_false_when_recent_lock_exists(self, mock_get_db, mock_get_fs):
        from handlers.cron_jobs import acquire_cron_lock

        tx = Mock()
        db = Mock()
        db.transaction.return_value = tx
        mock_get_db.return_value = db

        lock_doc = Mock()
        lock_doc.exists = True
        lock_doc.to_dict.return_value = {
            # Naive datetime exercises tz-normalization branch.
            Fields.LOCKED_AT: datetime.now(UTC).replace(tzinfo=None, microsecond=0),
        }

        lock_ref = Mock()
        lock_ref.get.return_value = lock_doc
        db.collection.return_value.document.return_value = lock_ref
        mock_get_fs.return_value.transactional = lambda fn: fn

        assert acquire_cron_lock("job_recent") is False
        tx.set.assert_not_called()

    @patch("handlers.cron_jobs.get_firestore")
    @patch("handlers.cron_jobs.get_db")
    def test_acquire_cron_lock_sets_running_status_when_lock_is_stale(self, mock_get_db, mock_get_fs):
        from handlers.cron_jobs import acquire_cron_lock

        tx = Mock()
        db = Mock()
        db.transaction.return_value = tx
        mock_get_db.return_value = db

        lock_doc = Mock()
        lock_doc.exists = True
        lock_doc.to_dict.return_value = {Fields.LOCKED_AT: datetime.now(UTC) - timedelta(hours=3)}

        lock_ref = Mock()
        lock_ref.get.return_value = lock_doc
        db.collection.return_value.document.return_value = lock_ref
        mock_get_fs.return_value.transactional = lambda fn: fn

        assert acquire_cron_lock("job_stale") is True
        tx.set.assert_called_once()
        written = tx.set.call_args.args[1]
        assert written[Fields.STATUS] == CronLockStatusValues.RUNNING
        assert written[Fields.LOCKED_BY] == "cron_job_stale"

    @patch("handlers.cron_jobs.get_firestore")
    @patch("handlers.cron_jobs.get_db")
    def test_acquire_cron_lock_returns_false_on_internal_error(self, mock_get_db, mock_get_fs):
        from handlers.cron_jobs import acquire_cron_lock

        db = Mock()
        db.transaction.side_effect = RuntimeError("tx failed")
        mock_get_db.return_value = db
        mock_get_fs.return_value.transactional = lambda fn: fn

        assert acquire_cron_lock("job_error") is False

    @patch("handlers.cron_jobs.get_db")
    def test_release_cron_lock_swallows_update_error(self, mock_get_db):
        from handlers.cron_jobs import release_cron_lock

        lock_ref = Mock()
        lock_ref.update.side_effect = RuntimeError("update failed")
        mock_get_db.return_value.collection.return_value.document.return_value = lock_ref

        release_cron_lock("job_release")

    @patch("handlers.cron_jobs.sentry_sdk")
    @patch("handlers.cron_jobs.get_db")
    def test_alert_cron_failure_writes_record(self, mock_get_db, mock_sentry):
        from handlers.cron_jobs import _alert_cron_failure

        failures_col = Mock()
        mock_get_db.return_value.collection.return_value = failures_col

        _alert_cron_failure("job_alert", ValueError("boom"))

        mock_sentry.capture_exception.assert_called_once()
        failures_col.add.assert_called_once()

    @patch("handlers.cron_jobs.sentry_sdk")
    @patch("handlers.cron_jobs.get_db")
    def test_alert_cron_failure_handles_write_error(self, mock_get_db, mock_sentry):
        from handlers.cron_jobs import _alert_cron_failure

        failures_col = Mock()
        failures_col.add.side_effect = RuntimeError("write failed")
        mock_get_db.return_value.collection.return_value = failures_col

        _alert_cron_failure("job_alert_error", RuntimeError("boom"))
        mock_sentry.capture_exception.assert_called_once()


class TestAutoCaptureWrappers:
    @patch("handlers.cron_jobs._run_auto_capture")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=False)
    def test_auto_capture_confirmed_receipts_skips_when_lock_is_held(self, _mock_lock, mock_run):
        from handlers.cron_jobs import auto_capture_confirmed_receipts

        auto_capture_confirmed_receipts(Mock())
        mock_run.assert_not_called()

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs._alert_cron_failure")
    @patch("handlers.cron_jobs._run_auto_capture", side_effect=RuntimeError("capture failed"))
    @patch("handlers.cron_jobs.get_stripe_secret_key", return_value="STRIPE_SECRET_KEY_REDACTED")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    def test_auto_capture_confirmed_receipts_alerts_and_releases_on_error(
        self, _mock_lock, _mock_secret, _mock_run, mock_alert, mock_release
    ):
        from handlers.cron_jobs import auto_capture_confirmed_receipts

        auto_capture_confirmed_receipts(Mock())
        mock_alert.assert_called_once()
        mock_release.assert_called_once_with("auto_capture_confirmed_receipts")

    @patch("handlers.payment_providers.is_provider_enabled", return_value=False)
    def test_run_auto_capture_returns_early_when_stripe_disabled(self, _mock_enabled):
        from handlers.cron_jobs import _run_auto_capture

        with patch("handlers.cron_jobs.get_db") as mock_get_db:
            _run_auto_capture()
        mock_get_db.assert_not_called()


class TestSellerMetricsAndTrending:
    @patch("handlers.cron_jobs.get_db")
    def test_compute_avg_response_time_returns_average_of_numeric_values(self, mock_get_db):
        from handlers.cron_jobs import _compute_avg_response_time

        chats = [
            _snapshot("c1", {Fields.FIRST_REPLY_HOURS: 1.2}),
            _snapshot("c2", {Fields.FIRST_REPLY_HOURS: 2.8}),
            _snapshot("c3", {Fields.FIRST_REPLY_HOURS: "n/a"}),
        ]
        chats_query = _query(stream_return=chats)
        mock_get_db.return_value.collection.return_value = chats_query

        assert _compute_avg_response_time("seller_1", datetime.now(UTC) - timedelta(days=7)) == 2.0

    @patch("handlers.cron_jobs.get_db")
    def test_compute_avg_response_time_returns_zero_on_error(self, mock_get_db):
        from handlers.cron_jobs import _compute_avg_response_time

        mock_get_db.return_value.collection.side_effect = RuntimeError("db down")
        assert _compute_avg_response_time("seller_1", datetime.now(UTC)) == 0.0

    @patch("handlers.cron_jobs.get_db")
    def test_compute_seller_metrics_logic_writes_metrics_and_alerts(self, mock_get_db):
        from handlers.cron_jobs import _compute_seller_metrics_logic

        created_at = datetime.now().replace(microsecond=0)
        shipped_at = created_at + timedelta(days=5)
        orders = [
            _snapshot(
                "order_1",
                {
                    Fields.SELLER_IDS: ["seller_1"],
                    Fields.HAS_DISPUTE: True,
                    Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                    Fields.CREATED_AT: created_at,
                    Fields.ITEMS: [
                        {
                            Fields.SELLER_ID: "seller_1",
                            Fields.STATUS: DeliveryStatusValues.REFUNDED,
                            Fields.SHIPPED_AT: shipped_at,
                            Fields.ESTIMATED_SHIP_DAYS: 1,
                        }
                    ],
                    Fields.SELLER_PAYOUTS: [{Fields.SELLER_ID: "seller_1", Fields.SELLER_AMOUNT_CENTS: 2599}],
                },
            )
        ]
        chats = [_snapshot("chat_1", {Fields.SELLER_ID: "seller_1", Fields.FIRST_REPLY_HOURS: 3.5})]
        sellers = [_snapshot("seller_1", {})]

        orders_query = _query(stream_return=orders)
        chats_query = _query(stream_return=chats)
        sellers_query = _query(stream_return=sellers)
        alerts_query = _query(get_return=[])

        metrics_ref = Mock()
        metrics_col = Mock()
        metrics_col.document.return_value = metrics_ref

        alerts_col = Mock()
        alerts_col.where.return_value = alerts_query

        def collection_side_effect(name):
            mapping = {
                Collections.ORDERS: orders_query,
                Collections.CHATS: chats_query,
                Collections.USERS: sellers_query,
                Collections.SELLER_METRICS: metrics_col,
                Collections.SECURITY_ALERTS: alerts_col,
            }
            return mapping[name]

        db = Mock()
        db.collection.side_effect = collection_side_effect
        mock_get_db.return_value = db

        _compute_seller_metrics_logic()

        metrics_ref.set.assert_called_once()
        payload = metrics_ref.set.call_args.args[0]
        assert payload[Fields.SELLER_ID] == "seller_1"
        assert payload[Fields.TOTAL_ORDERS_30D] == 1
        assert payload[Fields.TOTAL_REVENUE_CENTS_30D] == 2599
        alerts_col.add.assert_called_once()

    @patch("handlers.cron_jobs._compute_seller_metrics_logic")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=False)
    def test_compute_seller_metrics_skips_when_lock_is_held(self, _mock_lock, mock_logic):
        from handlers.cron_jobs import compute_seller_metrics

        compute_seller_metrics(Mock())
        mock_logic.assert_not_called()

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs._alert_cron_failure")
    @patch("handlers.cron_jobs._compute_seller_metrics_logic", side_effect=RuntimeError("metrics failed"))
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    def test_compute_seller_metrics_alerts_and_releases_on_error(
        self, _mock_lock, _mock_logic, mock_alert, mock_release
    ):
        from handlers.cron_jobs import compute_seller_metrics

        compute_seller_metrics(Mock())
        mock_alert.assert_called_once()
        mock_release.assert_called_once_with("compute_seller_metrics")

    @patch("handlers.cron_jobs.get_db")
    @patch("handlers.cron_jobs._notify_trending_products")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    def test_compute_trending_products_marks_top_and_clears_old(
        self, _mock_lock, mock_release, mock_notify, mock_get_db
    ):
        from handlers.cron_jobs import compute_trending_products

        products = [
            _snapshot(
                "p_top",
                {
                    Fields.NAME: "Top Product",
                    Fields.IMAGE_URLS: ["https://cdn.example.com/top.png"],
                    Fields.VIEW_COUNT: 10,
                    Fields.PURCHASE_COUNT: 2,
                    Fields.FAVORITE_COUNT: 1,
                    Fields.IS_TRENDING: False,
                },
            ),
            _snapshot(
                "p_old",
                {
                    Fields.NAME: "Old Product",
                    Fields.IMAGE_URLS: [],
                    Fields.VIEW_COUNT: 0,
                    Fields.PURCHASE_COUNT: 0,
                    Fields.FAVORITE_COUNT: 0,
                    Fields.IS_TRENDING: True,
                },
            ),
            _snapshot(
                "p_second",
                {
                    Fields.NAME: "Second Product",
                    Fields.IMAGE_URLS: ["https://cdn.example.com/second.png"],
                    Fields.VIEW_COUNT: 4,
                    Fields.PURCHASE_COUNT: 1,
                    Fields.FAVORITE_COUNT: 0,
                    Fields.IS_TRENDING: False,
                },
            ),
        ]

        products_query = _query(stream_return=products)
        products_col = Mock()
        products_col.where.return_value = products_query
        products_col.document.side_effect = lambda pid: Mock(name=f"product_ref_{pid}")

        batch = Mock()
        db = Mock()
        db.batch.return_value = batch
        db.collection.side_effect = lambda name: products_col if name == Collections.PRODUCTS else Mock()
        mock_get_db.return_value = db

        compute_trending_products(Mock())

        assert batch.update.call_count >= 3
        batch.commit.assert_called()
        mock_notify.assert_called_once()
        notified_products = mock_notify.call_args.args[1]
        assert notified_products
        assert notified_products[0][1] == "p_top"
        mock_release.assert_called_once_with("compute_trending_products")

    @patch("handlers.cron_jobs.get_db")
    @patch("handlers.cron_jobs._alert_cron_failure")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    def test_compute_trending_products_alerts_on_exception(self, _mock_lock, mock_release, mock_alert, mock_get_db):
        from handlers.cron_jobs import compute_trending_products

        db = Mock()
        db.collection.side_effect = RuntimeError("query failure")
        mock_get_db.return_value = db

        compute_trending_products(Mock())
        mock_alert.assert_called_once()
        mock_release.assert_called_once_with("compute_trending_products")

    def test_notify_trending_products_no_tokens_does_not_send(self):
        from handlers.cron_jobs import _notify_trending_products

        users_query = _query(stream_return=[])
        db = Mock()
        db.collection.return_value = users_query

        messaging = Mock()
        messaging.send_each_for_multicast.return_value = SimpleNamespace(success_count=0, failure_count=0)

        with patch("firebase_admin.messaging", messaging, create=True):
            _notify_trending_products(db, [(9, "p1", "Top Product", "img")])

        messaging.send_each_for_multicast.assert_not_called()

    def test_notify_trending_products_sends_multicast_for_collected_tokens(self):
        from handlers.cron_jobs import _notify_trending_products

        token_docs = [_snapshot("t1", {"token": "tok_1"}), _snapshot("t2", {"token": "tok_2"})]
        token_query = _query(stream_return=token_docs)

        user_ref = Mock()
        user_ref.collection.return_value = token_query
        user_doc = _snapshot("user_1", {})
        user_doc.reference = user_ref

        users_query = _query(stream_return=[user_doc])
        db = Mock()
        db.collection.return_value = users_query

        messaging = Mock()
        messaging.Notification.return_value = Mock()
        messaging.MulticastMessage.return_value = Mock()
        messaging.send_each_for_multicast.return_value = SimpleNamespace(success_count=2, failure_count=0)

        with patch("firebase_admin.messaging", messaging, create=True):
            _notify_trending_products(db, [(12, "p1", "Top Product", "img"), (8, "p2", "Next Product", "img2")])

        messaging.send_each_for_multicast.assert_called_once()


class TestPremiumRenewalAndSubscriptionSync:
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=False)
    def test_send_premium_renewal_reminders_skips_when_locked(self, _mock_lock, mock_release):
        from handlers.cron_jobs import send_premium_renewal_reminders

        send_premium_renewal_reminders(Mock())
        mock_release.assert_not_called()

    @patch("services.email_task.enqueue_email_task")
    @patch("services.email_service.get_premium_renewal_reminder_email", return_value="<p>renewal</p>")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_send_premium_renewal_reminders_enqueues_email_and_sets_dedup(
        self, mock_get_db, _mock_lock, mock_release, _mock_template, mock_enqueue
    ):
        from handlers.cron_jobs import send_premium_renewal_reminders

        active_status = next(iter(SubscriptionStatusValues.PREMIUM_ACTIVE))
        sub_doc = _snapshot(
            "user_1",
            {
                Fields.STATUS: active_status,
                Fields.CANCEL_AT_PERIOD_END: False,
                Fields.CURRENT_PERIOD_END: datetime.now(UTC) + timedelta(days=7),
            },
        )
        subs_query = _query(stream_side_effect=[[sub_doc], []])

        subs_col = Mock()
        subs_col.where.return_value = subs_query
        sub_ref = Mock()
        subs_col.document.return_value = sub_ref

        user_doc = _snapshot("user_1", {Fields.EMAIL: "user@example.com", Fields.PREFERRED_LANGUAGE: "en"}, exists=True)
        user_ref = Mock()
        user_ref.get.return_value = user_doc
        users_col = Mock()
        users_col.document.return_value = user_ref

        db = Mock()
        db.collection.side_effect = lambda name: subs_col if name == Collections.SUBSCRIPTIONS else users_col
        mock_get_db.return_value = db

        send_premium_renewal_reminders(Mock())

        mock_enqueue.assert_called_once()
        sub_ref.update.assert_called_once()
        update_payload = sub_ref.update.call_args.args[0]
        assert any(key.startswith("renewalReminderSentDays") for key in update_payload)
        mock_release.assert_called_once_with("send_premium_renewal_reminders")

    @patch("handlers.cron_jobs._alert_cron_failure")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db", side_effect=RuntimeError("db failed"))
    def test_send_premium_renewal_reminders_alerts_on_outer_failure(
        self, _mock_db, _mock_lock, mock_release, mock_alert
    ):
        from handlers.cron_jobs import send_premium_renewal_reminders

        send_premium_renewal_reminders(Mock())
        mock_alert.assert_called_once()
        mock_release.assert_called_once_with("send_premium_renewal_reminders")

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=False)
    def test_sync_expired_subscriptions_skips_when_locked(self, _mock_lock, mock_release):
        from handlers.cron_jobs import sync_expired_subscriptions

        sync_expired_subscriptions(Mock())
        mock_release.assert_not_called()

    @patch("handlers.subscriptions._sync_subscription")
    @patch("stripe.Subscription.retrieve", return_value=Mock(id="sub_123"))
    @patch("handlers.cron_jobs.get_stripe_secret_key", return_value="STRIPE_SECRET_KEY_REDACTED")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_sync_expired_subscriptions_syncs_and_clears_orphaned_users(
        self, mock_get_db, _mock_lock, mock_release, _mock_key, _mock_retrieve, mock_sync
    ):
        from handlers.cron_jobs import sync_expired_subscriptions

        expired_sub = _snapshot("user_1", {Fields.STRIPE_SUBSCRIPTION_ID: "sub_123"})
        expired_query = _query(stream_return=[expired_sub])

        subs_col = Mock()
        subs_col.where.return_value = expired_query
        subs_col.document.side_effect = lambda uid: Mock(name=f"sub_ref_{uid}")

        premium_user = _snapshot("user_1", {})
        users_query = _query(stream_return=[premium_user])
        users_col = Mock()
        users_col.where.return_value = users_query
        users_col.document.side_effect = lambda uid: Mock(name=f"user_ref_{uid}")

        db = Mock()
        db.collection.side_effect = lambda name: subs_col if name == Collections.SUBSCRIPTIONS else users_col
        db.get_all.return_value = [_snapshot("user_1", exists=False)]
        batch = Mock()
        db.batch.return_value = batch
        mock_get_db.return_value = db

        sync_expired_subscriptions(Mock())

        mock_sync.assert_called_once()
        batch.update.assert_called_once()
        batch.commit.assert_called_once()
        mock_release.assert_called_once_with("sync_expired_subscriptions")

    @patch("handlers.cron_jobs.sentry_sdk.capture_exception")
    @patch("stripe.Subscription.retrieve", side_effect=RuntimeError("stripe failed"))
    @patch("handlers.cron_jobs.get_stripe_secret_key", return_value="STRIPE_SECRET_KEY_REDACTED")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_sync_expired_subscriptions_captures_per_subscription_error(
        self, mock_get_db, _mock_lock, mock_release, _mock_key, _mock_retrieve, mock_capture
    ):
        from handlers.cron_jobs import sync_expired_subscriptions

        expired_sub = _snapshot("user_1", {Fields.STRIPE_SUBSCRIPTION_ID: "sub_123"})
        expired_query = _query(stream_return=[expired_sub])
        empty_users_query = _query(stream_return=[])

        subs_col = Mock()
        subs_col.where.return_value = expired_query
        users_col = Mock()
        users_col.where.return_value = empty_users_query

        db = Mock()
        db.collection.side_effect = lambda name: subs_col if name == Collections.SUBSCRIPTIONS else users_col
        mock_get_db.return_value = db

        sync_expired_subscriptions(Mock())
        mock_capture.assert_called_once()
        mock_release.assert_called_once_with("sync_expired_subscriptions")


class TestAdditionalCronCoverage:
    @patch("handlers.payment_providers.is_provider_enabled", return_value=True)
    @patch("handlers.cron_jobs.IS_EMULATOR", True)
    @patch("handlers.cron_jobs.get_server_timestamp", return_value="ts")
    @patch("handlers.cron_jobs.get_firestore")
    @patch("handlers.cron_jobs.get_db")
    def test_run_auto_capture_emulator_authorized_order_happy_path(
        self, mock_get_db, mock_get_firestore, _mock_ts, _mock_enabled
    ):
        from handlers.cron_jobs import _run_auto_capture

        order_data = {
            Fields.ORDER_STATUS: OrderStatusValues.DELIVERED,
            Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED,
            Fields.STRIPE_PAYMENT_INTENT_ID: "pi_test_1",
            Fields.ITEMS: [
                {
                    Fields.SELLER_ID: "seller_1",
                    Fields.STATUS: DeliveryStatusValues.DELIVERED,
                    Fields.PRICE: 10.0,
                    Fields.QUANTITY: 2,
                    Fields.DELIVERED_AT: datetime.now(UTC) - timedelta(days=60),
                }
            ],
            Fields.SELLER_STRIPE_ACCOUNTS: {"seller_1": "acct_1"},
            Fields.PLATFORM_FEE_RATIO: 0.1,
        }
        order_doc = _snapshot("ord_1", order_data)
        order_doc.reference.get.return_value = _snapshot("ord_1", {Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED})

        delivered_q = _query(stream_return=[order_doc])
        shipped_q = _query(stream_return=[])
        orders_col = Mock()
        orders_col.where.side_effect = [delivered_q, shipped_q]

        alerts_query = _query(get_return=[])
        alerts_col = Mock()
        alerts_col.where.return_value = alerts_query

        returns_query = _query(get_return=[])
        returns_col = Mock()
        returns_col.where.return_value = returns_query

        payout_lookup_query = _query(get_return=[])
        payout_ref = Mock()
        payouts_col = Mock()
        payouts_col.where.return_value = payout_lookup_query
        payouts_col.document.return_value = payout_ref

        users_col = Mock()
        users_col.document.side_effect = lambda sid: SimpleNamespace(id=sid, _kind="user")
        sp_col = Mock()
        sp_col.document.side_effect = lambda sid: SimpleNamespace(id=sid, _kind="sp")

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.SECURITY_ALERTS: alerts_col,
            Collections.RETURN_REQUESTS: returns_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: users_col,
            Collections.SELLER_PROFILES: sp_col,
        }[name]

        def _get_all(refs):
            snaps = []
            for ref in refs:
                if ref._kind == "user":
                    snaps.append(_snapshot(ref.id, {Fields.SUSPENDED: False}, exists=True))
                else:
                    snaps.append(
                        _snapshot(
                            ref.id,
                            {Fields.CHARGES_ENABLED: True, Fields.STRIPE_ACCOUNT_ID: "acct_1"},
                            exists=True,
                        )
                    )
            return snaps

        db.get_all.side_effect = _get_all
        tx = Mock()
        db.transaction.return_value = tx
        mock_get_db.return_value = db

        mock_get_firestore.return_value = SimpleNamespace(transactional=lambda fn: fn)

        with (
            patch("handlers.cron_jobs.stripe.PaymentIntent.retrieve", return_value=SimpleNamespace(latest_charge="ch_1")),
            patch("handlers.cron_jobs.stripe.Transfer.create", return_value=SimpleNamespace(id="tr_1")),
        ):
            _run_auto_capture()

        payout_ref.set.assert_called_once()
        payout_ref.update.assert_called_once()
        # Order should end with completed payout status
        assert any(
            call.args and isinstance(call.args[0], dict) and call.args[0].get(Fields.PAYOUT_STATUS) == PayoutStatusValues.COMPLETED
            for call in order_doc.reference.update.call_args_list
        )
        assert tx.update.called

    @patch.dict(
        "os.environ",
        {"STALE_ORDER_WORKER_URL": "https://worker.example.com", "TASK_HANDLER_SA_EMAIL": "tasks@example.iam.gserviceaccount.com"},
        clear=True,
    )
    @patch("handlers.cron_jobs.sentry_sdk.capture_exception")
    @patch("handlers.cron_jobs.tasks_v2.CloudTasksClient")
    @patch("handlers.cron_jobs.get_db")
    def test_dispatch_stale_orders_creates_tasks_and_handles_duplicate_and_error(
        self, mock_get_db, mock_tasks_client_cls, mock_capture
    ):
        from handlers.cron_jobs import _dispatch_stale_orders

        orders = [_snapshot("o1", {}), _snapshot("o2", {}), _snapshot("o3", {})]
        orders_query = _query(stream_return=orders)
        db = Mock()
        db.collection.return_value = orders_query
        mock_get_db.return_value = db

        client = Mock()
        client.queue_path.return_value = "projects/p/locations/l/queues/q"
        client.create_task.side_effect = [None, google_exceptions.AlreadyExists("duplicate"), RuntimeError("task failure")]
        mock_tasks_client_cls.return_value = client

        _dispatch_stale_orders()

        assert client.create_task.call_count == 3
        mock_capture.assert_called_once()

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_server_timestamp", return_value="ts")
    @patch("handlers.cron_jobs.get_db")
    def test_auto_archive_old_orders_archives_only_non_archived(
        self, mock_get_db, _mock_ts, _mock_lock, mock_release
    ):
        from handlers.cron_jobs import auto_archive_old_orders

        already_archived = _snapshot("a1", {Fields.ARCHIVED: True})
        to_archive = _snapshot("a2", {Fields.ARCHIVED: False})
        orders_query = _query(stream_return=[already_archived, to_archive])

        batch = Mock()
        db = Mock()
        db.batch.return_value = batch
        db.collection.return_value = orders_query
        mock_get_db.return_value = db

        auto_archive_old_orders(Mock())

        batch.update.assert_called_once()
        batch.commit.assert_called_once()
        mock_release.assert_called_once_with("auto_archive_old_orders")

    @patch("services.algolia_service.get_index_stats", return_value=50)
    @patch("handlers.cron_jobs.get_db")
    def test_monitor_algolia_sync_creates_alert_on_mismatch(self, mock_get_db, _mock_stats):
        from handlers.cron_jobs import monitor_algolia_sync

        count_query = Mock()
        count_query.get.return_value = [[SimpleNamespace(value=100)]]
        products_query = Mock()
        products_query.count.return_value = count_query

        products_col = Mock()
        products_col.where.return_value = products_query

        alerts_query = _query(get_return=[])
        alerts_col = Mock()
        alerts_col.where.return_value = alerts_query

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.PRODUCTS: products_col,
            Collections.SECURITY_ALERTS: alerts_col,
        }[name]
        mock_get_db.return_value = db

        monitor_algolia_sync(Mock())
        alerts_col.add.assert_called_once()

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_cleanup_stale_rate_limits_deletes_with_pagination(self, mock_get_db, _mock_lock, mock_release):
        from handlers.cron_jobs import cleanup_stale_rate_limits

        stale_doc = _snapshot("rl1", {Fields.LAST_REQUEST: datetime.now(UTC) - timedelta(days=1)})
        q = _query(stream_side_effect=[[stale_doc], []])
        rate_limits_col = Mock()
        rate_limits_col.where.return_value = q

        batch = Mock()
        db = Mock()
        db.collection.return_value = rate_limits_col
        db.batch.return_value = batch
        mock_get_db.return_value = db

        cleanup_stale_rate_limits(Mock())

        batch.delete.assert_called_once_with(stale_doc.reference)
        batch.commit.assert_called_once()
        mock_release.assert_called_once_with("cleanup_stale_rate_limits")

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("config.get_r2_credentials", return_value={"access_key": "ak", "secret_key": "sk", "account_id": "acc"})
    @patch("boto3.client")
    @patch("handlers.cron_jobs.get_db")
    def test_cleanup_orphaned_r2_images_deletes_unreferenced_keys(
        self, mock_get_db, mock_boto_client, _mock_creds, _mock_lock, mock_release
    ):
        from handlers.cron_jobs import cleanup_orphaned_r2_images

        product_doc = _snapshot("p1", {Fields.IMAGE_URLS: ["https://cdn.origna.ca/products/keep.jpg"]})
        product_query = _query(stream_side_effect=[[product_doc], []])
        products_col = Mock()
        products_col.select.return_value = product_query

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.PRODUCTS: products_col}[name]
        mock_get_db.return_value = db

        s3 = Mock()
        s3.list_objects_v2.return_value = {
            "Contents": [
                {"Key": "products/keep.jpg", "LastModified": datetime.now(UTC) - timedelta(days=2)},
                {"Key": "products/orphan.jpg", "LastModified": datetime.now(UTC) - timedelta(days=2)},
            ],
            "IsTruncated": False,
        }
        mock_boto_client.return_value = s3

        cleanup_orphaned_r2_images(Mock())

        s3.delete_objects.assert_called_once()
        deleted_keys = [obj["Key"] for obj in s3.delete_objects.call_args.kwargs["Delete"]["Objects"]]
        assert deleted_keys == ["products/orphan.jpg"]
        mock_release.assert_called_once_with("cleanup_orphaned_r2_images")

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_cleanup_stale_webhook_events_deletes_docs(self, mock_get_db, _mock_lock, mock_release):
        from handlers.cron_jobs import cleanup_stale_webhook_events

        webhook_doc = _snapshot("we1", {Fields.TIMESTAMP: datetime.now(UTC) - timedelta(days=30)})
        webhook_query = _query(stream_return=[webhook_doc])
        webhook_col = Mock()
        webhook_col.where.return_value = webhook_query

        batch = Mock()
        db = Mock()
        db.collection.side_effect = lambda name: {Collections.WEBHOOK_EVENTS: webhook_col}[name]
        db.batch.return_value = batch
        mock_get_db.return_value = db

        cleanup_stale_webhook_events(Mock())

        batch.delete.assert_called_once_with(webhook_doc.reference)
        batch.commit.assert_called_once()
        mock_release.assert_called_once_with("cleanup_stale_webhook_events")

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_cleanup_stale_security_alerts_deletes_resolved_docs(self, mock_get_db, _mock_lock, mock_release):
        from handlers.cron_jobs import cleanup_stale_security_alerts

        alert_doc = _snapshot("sa1", {Fields.RESOLVED: True, Fields.TIMESTAMP: datetime.now(UTC) - timedelta(days=120)})
        alerts_query = _query(stream_return=[alert_doc])
        alerts_col = Mock()
        alerts_col.where.return_value = alerts_query

        batch = Mock()
        db = Mock()
        db.collection.side_effect = lambda name: {Collections.SECURITY_ALERTS: alerts_col}[name]
        db.batch.return_value = batch
        mock_get_db.return_value = db

        cleanup_stale_security_alerts(Mock())

        batch.delete.assert_called_once_with(alert_doc.reference)
        batch.commit.assert_called_once()
        mock_release.assert_called_once_with("cleanup_stale_security_alerts")

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("services.algolia_service.index_product")
    @patch("services.algolia_service.delete_product")
    @patch("handlers.cron_jobs.get_server_timestamp", return_value="ts")
    @patch("handlers.cron_jobs.get_db")
    def test_retry_failed_algolia_syncs_handles_core_retry_paths(
        self,
        mock_get_db,
        _mock_ts,
        mock_algolia_delete,
        mock_algolia_index,
        _mock_lock,
        mock_release,
    ):
        from handlers.cron_jobs import retry_failed_algolia_syncs

        max_retries = BusinessRules.ALGOLIA_DLQ_MAX_RETRIES
        missing_pid = _snapshot("f1", {Fields.PRODUCT_ID: None})
        exceeded = _snapshot("f2", {Fields.PRODUCT_ID: "p2", Fields.RETRY_COUNT: max_retries})
        delete_ok = _snapshot("f3", {Fields.PRODUCT_ID: "p3", Fields.ACTION: AlgoliaActionValues.DELETE, Fields.RETRY_COUNT: 0})
        index_ok = _snapshot("f4", {Fields.PRODUCT_ID: "p4", Fields.ACTION: AlgoliaActionValues.INDEX, Fields.RETRY_COUNT: 0})
        index_fail = _snapshot("f5", {Fields.PRODUCT_ID: "p5", Fields.ACTION: AlgoliaActionValues.INDEX, Fields.RETRY_COUNT: 0})

        failures_query = _query(stream_return=[missing_pid, exceeded, delete_ok, index_ok, index_fail])
        failures_col = Mock()
        failures_col.where.return_value = failures_query

        def _product_doc(pid: str):
            if pid in ("p4", "p5"):
                return _snapshot(pid, {Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE}, exists=True)
            return _snapshot(pid, {}, exists=False)

        products_col = Mock()
        products_col.document.side_effect = lambda pid: SimpleNamespace(get=lambda: _product_doc(pid))

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ALGOLIA_SYNC_FAILURES: failures_col,
            Collections.PRODUCTS: products_col,
        }[name]
        mock_get_db.return_value = db

        def _index_side_effect(pid, _data):
            if pid == "p5":
                raise RuntimeError("index down")
            return None

        mock_algolia_index.side_effect = _index_side_effect

        retry_failed_algolia_syncs(Mock())

        mock_algolia_delete.assert_called_with("p3")
        mock_algolia_index.assert_any_call("p4", _product_doc("p4").to_dict())
        # Failed retry should increment counter
        assert index_fail.reference.update.called
        mock_release.assert_called_once_with("retry_failed_algolia_syncs")

    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("services.algolia_service.delete_product")
    @patch("handlers.products._send_product_rejection_email")
    @patch("handlers.products._get_seller_email", return_value="seller@example.com")
    @patch("requests.head")
    @patch("handlers.cron_jobs.get_db")
    def test_revalidate_digital_product_urls_deactivates_dead_links(
        self,
        mock_get_db,
        mock_head,
        _mock_get_email,
        mock_send_rejection,
        mock_algolia_delete,
        _mock_lock,
        mock_release,
    ):
        from handlers.cron_jobs import revalidate_digital_product_urls

        mock_head.return_value = SimpleNamespace(status_code=404)

        product_doc = _snapshot(
            "pd1",
            {
                Fields.IS_DIGITAL: True,
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
                Fields.BOOK_SOURCE_URL: "https://files.example.com/book.pdf",
                Fields.DIGITAL_BUILDS: {"windows": "https://files.example.com/win.exe"},
                Fields.SELLER_ID: "seller_1",
                Fields.NAME: "Digital Pack",
            },
        )
        products_query = _query(stream_return=[product_doc])
        products_col = Mock()
        products_col.where.return_value = products_query

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.PRODUCTS: products_col}[name]
        mock_get_db.return_value = db

        revalidate_digital_product_urls(Mock())

        product_doc.reference.update.assert_called_once()
        mock_algolia_delete.assert_called_once_with("pd1")
        mock_send_rejection.assert_called_once()
        mock_release.assert_called_once_with("revalidate_digital_product_urls")

    @patch("services.email_task.enqueue_email_task")
    @patch("services.email_service._email_wrapper", return_value="<html>abandoned</html>")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db")
    def test_send_abandoned_cart_emails_sends_for_en_and_fr_users(
        self, mock_get_db, _mock_lock, mock_release, _mock_wrapper, mock_enqueue
    ):
        from handlers.cron_jobs import send_abandoned_cart_emails

        user_en = _snapshot(
            "u_en",
            {
                Fields.EMAIL: "en@example.com",
                Fields.EMAIL_CONSENT: True,
                Fields.MARKETING_OPT_IN: True,
                Fields.NAME: "Alice",
                Fields.PREFERRED_LANGUAGE: "en",
            },
        )
        user_fr = _snapshot(
            "u_fr",
            {
                Fields.EMAIL: "fr@example.com",
                Fields.EMAIL_CONSENT: True,
                Fields.MARKETING_OPT_IN: True,
                Fields.NAME: "Jean",
                Fields.PREFERRED_LANGUAGE: "fr",
            },
        )
        users_query = _query(stream_return=[user_en, user_fr])
        users_col = Mock()
        users_col.where.return_value = users_query

        cart_doc = _snapshot("cart_1", {Fields.PRODUCT_ID: "p1"})
        cart_query = _query(stream_return=[cart_doc])
        user_ref_en = Mock()
        user_ref_en.collection.return_value = cart_query
        user_ref_fr = Mock()
        user_ref_fr.collection.return_value = cart_query
        users_col.document.side_effect = lambda uid: {"u_en": user_ref_en, "u_fr": user_ref_fr}[uid]

        products_col = Mock()
        products_col.document.side_effect = lambda pid: SimpleNamespace(id=pid)
        active_product_doc = _snapshot(
            "p1",
            {
                Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
                Fields.STOCK_QUANTITY: 3,
                Fields.NAME: "Widget",
            },
            exists=True,
        )

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.USERS: users_col,
            Collections.PRODUCTS: products_col,
        }[name]
        db.get_all.return_value = [active_product_doc]
        mock_get_db.return_value = db

        send_abandoned_cart_emails(Mock())

        assert mock_enqueue.call_count == 2
        subjects = [c.kwargs["subject"] for c in mock_enqueue.call_args_list]
        assert any("You left something in your cart" in s for s in subjects)
        assert any("Votre panier vous attend" in s for s in subjects)
        user_ref_en.update.assert_called_once()
        user_ref_fr.update.assert_called_once()
        mock_release.assert_called_once_with("send_abandoned_cart_emails")

    @patch("handlers.cron_jobs._alert_cron_failure")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    @patch("handlers.cron_jobs.get_db", side_effect=RuntimeError("db failed"))
    def test_send_abandoned_cart_emails_alerts_on_outer_failure(
        self, _mock_db, _mock_lock, mock_release, mock_alert
    ):
        from handlers.cron_jobs import send_abandoned_cart_emails

        send_abandoned_cart_emails(Mock())
        mock_alert.assert_called_once()
        mock_release.assert_called_once_with("send_abandoned_cart_emails")


class TestReturnEscalationCron:
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=False)
    def test_escalate_stale_return_requests_skips_when_lock_is_held(self, _mock_lock, mock_release):
        from handlers.cron_jobs import escalate_stale_return_requests

        escalate_stale_return_requests(Mock())
        mock_release.assert_not_called()

    @patch("handlers.cron_jobs._alert_cron_failure")
    @patch("handlers.cron_jobs.release_cron_lock")
    @patch("handlers.cron_jobs._run_return_escalation", side_effect=RuntimeError("boom"))
    @patch("handlers.cron_jobs.acquire_cron_lock", return_value=True)
    def test_escalate_stale_return_requests_alerts_and_releases_on_error(
        self, _mock_lock, _mock_run, mock_release, mock_alert
    ):
        from handlers.cron_jobs import escalate_stale_return_requests

        escalate_stale_return_requests(Mock())
        mock_alert.assert_called_once()
        mock_release.assert_called_once_with("escalate_stale_return_requests")

    @patch("services.push_service.send_push_notification")
    @patch("handlers.cron_jobs.get_db")
    def test_run_return_escalation_escalates_and_notifies_buyer_and_admins(self, mock_get_db, mock_push):
        from handlers.cron_jobs import _run_return_escalation

        return_doc = _snapshot(
            "ret_1",
            {
                Fields.ORDER_ID: "ord_12345",
                Fields.BUYER_ID: "buyer_1",
            },
        )
        stale_query = _query(stream_return=[return_doc])
        returns_col = Mock()
        returns_col.where.return_value = stale_query

        admin_doc = _snapshot("admin_1", {})
        admin_query = _query(stream_return=[admin_doc])
        users_col = Mock()
        users_col.where.return_value = admin_query

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.RETURN_REQUESTS: returns_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        _run_return_escalation()

        return_doc.reference.update.assert_called_once()
        assert mock_push.call_count == 2
        recipient_ids = [c.args[0] for c in mock_push.call_args_list]
        assert "buyer_1" in recipient_ids
        assert "admin_1" in recipient_ids

    @patch("handlers.cron_jobs.sentry_sdk.capture_exception")
    @patch("services.push_service.send_push_notification")
    @patch("handlers.cron_jobs.get_db")
    def test_run_return_escalation_prefetch_and_update_failures_are_handled(
        self, mock_get_db, mock_push, mock_capture
    ):
        from handlers.cron_jobs import _run_return_escalation

        broken_return = _snapshot("ret_2", {Fields.ORDER_ID: "ord_2", Fields.BUYER_ID: "buyer_2"})
        broken_return.reference.update.side_effect = RuntimeError("update failed")
        stale_query = _query(stream_return=[broken_return])
        returns_col = Mock()
        returns_col.where.return_value = stale_query

        users_col = Mock()
        users_col.where.side_effect = RuntimeError("admin prefetch failed")

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.RETURN_REQUESTS: returns_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        _run_return_escalation()

        mock_capture.assert_called_once()
        mock_push.assert_not_called()

    @patch("handlers.cron_jobs.sentry_sdk.capture_exception")
    @patch("handlers.cron_jobs.get_db")
    def test_run_return_escalation_handles_query_failure(self, mock_get_db, mock_capture):
        from handlers.cron_jobs import _run_return_escalation

        stale_query = _query(stream_side_effect=RuntimeError("query failed"))
        returns_col = Mock()
        returns_col.where.return_value = stale_query

        db = Mock()
        db.collection.side_effect = lambda name: {Collections.RETURN_REQUESTS: returns_col}[name]
        mock_get_db.return_value = db

        _run_return_escalation()
        mock_capture.assert_called_once()


class TestStaleOrdersDispatcherEdges:
    @patch.dict("os.environ", {}, clear=True)
    def test_dispatch_stale_orders_raises_when_required_env_missing(self):
        from handlers.cron_jobs import _dispatch_stale_orders

        with patch("handlers.cron_jobs.get_db"):
            try:
                _dispatch_stale_orders()
                assert False, "Expected ValueError for missing env"
            except ValueError:
                pass

    @patch.dict(
        "os.environ",
        {"STALE_ORDER_WORKER_URL": "https://worker.example.com", "TASK_HANDLER_SA_EMAIL": "tasks@example.iam.gserviceaccount.com"},
        clear=True,
    )
    @patch("handlers.cron_jobs.tasks_v2.CloudTasksClient")
    @patch("handlers.cron_jobs.get_db")
    def test_dispatch_stale_orders_returns_when_no_orders(self, mock_get_db, mock_tasks_client_cls):
        from handlers.cron_jobs import _dispatch_stale_orders

        orders_query = _query(stream_return=[])
        mock_get_db.return_value.collection.return_value = orders_query

        _dispatch_stale_orders()
        mock_tasks_client_cls.assert_not_called()
