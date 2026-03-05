from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import Mock, patch

from schema_constants import (
    Collections,
    CronLockStatusValues,
    DeliveryStatusValues,
    Fields,
    OrderStatusValues,
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
