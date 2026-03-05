from unittest.mock import Mock, patch

import pytest
from firebase_functions import https_fn

from schema_constants import (
    ApiKeys,
    Collections,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PlatformDebtStatusValues,
    PayoutStatusValues,
    SecurityAlertTypes,
    StripeConstants,
)


def _snap(data=None, *, exists=True, doc_id="doc_1"):
    snap = Mock()
    snap.exists = exists
    snap.id = doc_id
    snap.to_dict.return_value = {} if data is None else data
    snap.reference = Mock()
    return snap


def _req(uid: str | None, data: dict, token: dict | None = None):
    req = Mock()
    req.auth = Mock(uid=uid, token=(token or {})) if uid else None
    req.data = data
    return req


class TestDisputeHandlersDeep:
    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.enqueue_email_task")
    @patch("handlers.payment_stripe.stripe.Transfer.create_reversal")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_created_partial_reversal_and_seller_email(
        self,
        mock_get_db,
        mock_create_reversal,
        mock_email,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_dispute_created

        mock_create_reversal.return_value = Mock(id="rev_1")

        alert_ref = Mock()
        security_col = Mock()
        security_col.add.return_value = ("wr", alert_ref)

        order_doc = _snap(
            {
                Fields.TOTAL_AMOUNT_CENTS: 1000,
                Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
                Fields.ITEMS: [{Fields.SELLER_ID: "seller_1"}],
            },
            doc_id="order_1",
        )

        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.STRIPE_TRANSFER_ID: "tr_1",
                Fields.NET_AMOUNT_CENTS: 800,
                Fields.CUMULATIVE_REVERSED_CENTS: 0,
                Fields.SELLER_ID: "seller_1",
            },
            doc_id="payout_1",
        )

        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        seller_doc = _snap({Fields.EMAIL: "seller@example.com"})
        users_col = Mock()
        users_col.document.return_value.get.return_value = seller_doc

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SECURITY_ALERTS: security_col,
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        dispute = {
            StripeConstants.OBJECT_ID: "dp_1",
            StripeConstants.CHARGE: "ch_1",
            StripeConstants.PAYMENT_INTENT: "pi_1",
            Fields.AMOUNT: 500,
            Fields.REASON: "fraudulent",
            StripeConstants.CURRENCY: "cad",
        }
        out = process_dispute_created(dispute)

        assert "reversed 1 transfers" in out
        # 500/1000 of payout net 800 => 400 proportional reversal
        assert mock_create_reversal.call_args.kwargs[Fields.AMOUNT] == 400
        payout_doc.reference.update.assert_called_once()
        order_doc.reference.update.assert_called_once()
        mock_email.assert_called_once()
        alert_ref.update.assert_called()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_created_without_payment_intent_returns_early(self, mock_get_db, _mock_ts):
        from handlers.payment_stripe import process_dispute_created

        security_col = Mock()
        security_col.add.return_value = ("wr", Mock())

        db = Mock()
        db.collection.return_value = security_col
        mock_get_db.return_value = db

        out = process_dispute_created({StripeConstants.CHARGE: "ch_1", Fields.AMOUNT: 100})
        assert "no payment_intent" in out

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_firestore")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_created_missing_transfer_id_records_reversal_error(
        self,
        mock_get_db,
        mock_get_firestore,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_dispute_created

        mock_get_firestore.return_value.ArrayUnion.side_effect = lambda vals: ("au", vals)

        alert_ref = Mock()
        security_col = Mock()
        security_col.add.return_value = ("wr", alert_ref)

        order_doc = _snap(
            {
                Fields.TOTAL_AMOUNT_CENTS: 1000,
                Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
                Fields.ITEMS: [],
            },
            doc_id="order_1",
        )
        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.NET_AMOUNT_CENTS: 800,
                Fields.CUMULATIVE_REVERSED_CENTS: 0,
                # No stripeTransferId on purpose
            },
            doc_id="payout_1",
        )
        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SECURITY_ALERTS: security_col,
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: Mock(),
        }[name]
        mock_get_db.return_value = db

        out = process_dispute_created(
            {
                StripeConstants.OBJECT_ID: "dp_2",
                StripeConstants.CHARGE: "ch_2",
                StripeConstants.PAYMENT_INTENT: "pi_2",
                Fields.AMOUNT: 500,
            }
        )

        assert "reversed 0 transfers" in out
        alert_ref.update.assert_called()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_firestore")
    @patch("handlers.payment_stripe.stripe.Transfer.create_reversal")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_created_insufficient_funds_error_suspends_seller(
        self,
        mock_get_db,
        mock_create_reversal,
        mock_get_firestore,
        _mock_ts,
    ):
        from handlers import payment_stripe as hps
        from handlers.payment_stripe import process_dispute_created

        mock_get_firestore.return_value.ArrayUnion.side_effect = lambda vals: ("au", vals)
        mock_create_reversal.side_effect = hps.stripe.error.InvalidRequestError("insufficient funds")

        alert_ref = Mock()
        security_col = Mock()
        security_col.add.return_value = ("wr", alert_ref)

        order_doc = _snap(
            {
                Fields.TOTAL_AMOUNT_CENTS: 1000,
                Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
                Fields.ITEMS: [],
            },
            doc_id="order_3",
        )
        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.STRIPE_TRANSFER_ID: "tr_fail",
                Fields.NET_AMOUNT_CENTS: 800,
                Fields.CUMULATIVE_REVERSED_CENTS: 0,
                Fields.SELLER_ID: "seller_fail",
            },
            doc_id="payout_fail",
        )
        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        users_col = Mock()
        users_col.document.return_value.update = Mock()

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SECURITY_ALERTS: security_col,
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        out = process_dispute_created(
            {
                StripeConstants.OBJECT_ID: "dp_3",
                StripeConstants.CHARGE: "ch_3",
                StripeConstants.PAYMENT_INTENT: "pi_3",
                Fields.AMOUNT: 500,
            }
        )

        assert "reversed 0 transfers" in out
        assert users_col.document.return_value.update.called
        alert_ref.update.assert_called()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_updated_updates_alert_and_order(self, mock_get_db, _mock_ts):
        from handlers.payment_stripe import process_dispute_updated

        alert_doc = _snap({}, doc_id="alert_1")
        order_doc = _snap({}, doc_id="order_1")

        alerts_q = Mock()
        alerts_q.where.return_value = alerts_q
        alerts_q.limit.return_value = alerts_q
        alerts_q.stream.return_value = [alert_doc]

        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]

        sec_col = Mock()
        sec_col.where.return_value = alerts_q
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SECURITY_ALERTS: sec_col,
            Collections.ORDERS: orders_col,
        }[name]
        mock_get_db.return_value = db

        out = process_dispute_updated(
            {
                StripeConstants.OBJECT_ID: "dp_1",
                StripeConstants.CHARGE: "ch_1",
                StripeConstants.PAYMENT_INTENT: "pi_1",
                Fields.STATUS: "under_review",
                Fields.REASON: "fraudulent",
            }
        )

        assert "dp_1" in out
        alert_doc.reference.update.assert_called_once()
        order_doc.reference.update.assert_called_once()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_funds_reinstated_logs_low_severity_alert(self, mock_get_db, _mock_ts):
        from handlers.payment_stripe import process_dispute_funds_reinstated

        security_col = Mock()
        db = Mock()
        db.collection.return_value = security_col
        mock_get_db.return_value = db

        out = process_dispute_funds_reinstated(
            {
                StripeConstants.OBJECT_ID: "dp_1",
                StripeConstants.CHARGE: "ch_1",
                StripeConstants.PAYMENT_INTENT: "pi_1",
                Fields.AMOUNT: 250,
            }
        )

        assert "Funds reinstated" in out
        payload = security_col.add.call_args.args[0]
        assert payload[Fields.TYPE] == SecurityAlertTypes.DISPUTE_FUNDS_REINSTATED
        assert payload[Fields.RESOLVED] is True

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("services.email_task.enqueue_email_task")
    @patch("handlers.payment_stripe._get_seller_stripe_snapshot", return_value={"seller_1": "acct_1"})
    @patch("handlers.payment_stripe.stripe.Transfer.create")
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_closed_won_retransfers_and_restores_order_status(
        self,
        mock_get_db,
        mock_transfer_create,
        _mock_snapshot,
        mock_email,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_dispute_closed

        mock_transfer_create.return_value = Mock(id="tr_new")

        alert_doc = _snap({}, doc_id="alert_1")
        alerts_q = Mock()
        alerts_q.where.return_value = alerts_q
        alerts_q.limit.return_value = alerts_q
        alerts_q.stream.return_value = [alert_doc]
        sec_col = Mock()
        sec_col.where.return_value = alerts_q

        order_doc = _snap(
            {
                Fields.PRE_DISPUTE_STATUS: OrderStatusValues.CONFIRMED,
                Fields.ITEMS: [{Fields.SELLER_ID: "seller_1"}],
            },
            doc_id="order_1",
        )
        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.SELLER_ID: "seller_1",
                Fields.CUMULATIVE_REVERSED_CENTS: 320,
            },
            doc_id="order_1_seller_1",
        )
        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        seller_doc = _snap({Fields.EMAIL: "seller@example.com"})
        users_col = Mock()
        users_col.document.return_value.get.return_value = seller_doc

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SECURITY_ALERTS: sec_col,
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: users_col,
        }[name]
        mock_get_db.return_value = db

        out = process_dispute_closed(
            {
                StripeConstants.CHARGE: "ch_1",
                StripeConstants.PAYMENT_INTENT: "pi_1",
                StripeConstants.OBJECT_ID: "dp_1",
                Fields.STATUS: "won",
            }
        )

        assert out == "Dispute closed: won"
        alert_doc.reference.update.assert_called_once()
        payout_doc.reference.update.assert_called_once()
        order_doc.reference.update.assert_called_once()
        mock_transfer_create.assert_called_once()
        mock_email.assert_called_once()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe._get_seller_stripe_snapshot", return_value={"seller_1": "acct_1"})
    @patch("handlers.payment_stripe.stripe.Transfer.create", side_effect=RuntimeError("transfer failed"))
    @patch("handlers.payment_stripe.get_db")
    def test_process_dispute_closed_won_retransfer_failure_logs_security_alert(
        self,
        mock_get_db,
        _mock_transfer,
        _mock_snapshot,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_dispute_closed

        alert_doc = _snap({}, doc_id="alert_1")
        alerts_q = Mock()
        alerts_q.where.return_value = alerts_q
        alerts_q.limit.return_value = alerts_q
        alerts_q.stream.return_value = [alert_doc]

        sec_col = Mock()
        sec_col.where.return_value = alerts_q

        order_doc = _snap({Fields.PRE_DISPUTE_STATUS: OrderStatusValues.CONFIRMED, Fields.ITEMS: []}, doc_id="order_1")
        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap({Fields.SELLER_ID: "seller_1", Fields.CUMULATIVE_REVERSED_CENTS: 200}, doc_id="order_1_seller_1")
        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.SECURITY_ALERTS: sec_col,
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: Mock(),
        }[name]
        mock_get_db.return_value = db

        out = process_dispute_closed(
            {
                StripeConstants.CHARGE: "ch_1",
                StripeConstants.PAYMENT_INTENT: "pi_1",
                StripeConstants.OBJECT_ID: "dp_1",
                Fields.STATUS: "won",
            }
        )

        assert out == "Dispute closed: won"
        assert sec_col.add.called


class TestRefundAndCaptureDeep:
    @patch("handlers.payment_stripe.get_db")
    def test_process_charge_refunded_blocks_transitional_payment_status(self, mock_get_db):
        from handlers.payment_stripe import process_charge_refunded

        order_doc = _snap({Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURING}, doc_id="order_1")
        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        with pytest.raises(Exception):
            process_charge_refunded(
                {
                    StripeConstants.PAYMENT_INTENT: "pi_1",
                    "amount_refunded": 500,
                    Fields.AMOUNT: 500,
                }
            )

    @patch("handlers.payment_stripe.get_db")
    def test_process_charge_refunded_idempotent_when_already_counted(self, mock_get_db):
        from handlers.payment_stripe import process_charge_refunded

        order_doc = _snap(
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.CUMULATIVE_REFUNDED_CENTS: 700,
            },
            doc_id="order_1",
        )
        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        db = Mock()
        db.collection.return_value = orders_col
        mock_get_db.return_value = db

        out = process_charge_refunded(
            {
                StripeConstants.PAYMENT_INTENT: "pi_1",
                "amount_refunded": 500,
                Fields.AMOUNT: 1000,
            }
        )
        assert "already processed" in out

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.stripe.Transfer.create_reversal")
    @patch("handlers.digital._revoke_digital_licenses_for_order", return_value=0)
    @patch("handlers.payment_stripe.get_db")
    def test_process_charge_refunded_partial_success_tracks_cumulative_reversed(
        self,
        mock_get_db,
        _mock_revoke,
        mock_reversal,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_charge_refunded

        mock_reversal.return_value = Mock(id="rev_ok")

        order_ref = Mock()
        order_doc = _snap(
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.CUMULATIVE_REFUNDED_CENTS: 0,
                Fields.SUBTOTAL_CENTS: 1000,
            },
            doc_id="order_partial",
        )
        order_doc.reference = order_ref

        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.STRIPE_TRANSFER_ID: "tr_partial",
                Fields.CUMULATIVE_REVERSED_CENTS: 100,
                Fields.NET_AMOUNT_CENTS: 1000,
                Fields.SELLER_ID: "seller_1",
            },
            doc_id="payout_partial",
        )
        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.SECURITY_ALERTS: Mock(),
            Collections.USERS: Mock(),
            Collections.PLATFORM_DEBT: Mock(),
        }[name]
        mock_get_db.return_value = db

        out = process_charge_refunded(
            {
                StripeConstants.PAYMENT_INTENT: "pi_partial",
                "amount_refunded": 300,
                Fields.AMOUNT: 1000,
            }
        )

        # cumulative_target=300, already_reversed=100 => delta=200
        assert mock_reversal.call_args.kwargs[Fields.AMOUNT] == 200
        payout_doc.reference.update.assert_called_once()
        assert "partially refunded" in out

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe._restore_stock_for_order")
    @patch("handlers.payment_stripe.stripe.Transfer.create_reversal", return_value=Mock(id="rev_full"))
    @patch("handlers.digital._revoke_digital_licenses_for_order", return_value=1)
    @patch("handlers.payment_stripe.get_db")
    def test_process_charge_refunded_full_refund_restores_stock_when_needed(
        self,
        mock_get_db,
        _mock_revoke,
        _mock_reversal,
        mock_restore_stock,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_charge_refunded

        order_ref = Mock()
        order_doc = _snap(
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.CUMULATIVE_REFUNDED_CENTS: 0,
                Fields.STOCK_RESTORED: False,
                Fields.SUBTOTAL_CENTS: 1000,
            },
            doc_id="order_full",
        )
        order_doc.reference = order_ref

        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.STRIPE_TRANSFER_ID: "tr_full",
                Fields.CUMULATIVE_REVERSED_CENTS: 0,
                Fields.NET_AMOUNT_CENTS: 900,
                Fields.SELLER_ID: "seller_1",
            },
            doc_id="payout_full",
        )
        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.SECURITY_ALERTS: Mock(),
            Collections.USERS: Mock(),
            Collections.PLATFORM_DEBT: Mock(),
        }[name]
        mock_get_db.return_value = db

        out = process_charge_refunded(
            {
                StripeConstants.PAYMENT_INTENT: "pi_full",
                "amount_refunded": 1000,
                Fields.AMOUNT: 1000,
            }
        )

        mock_restore_stock.assert_called_once()
        order_ref.update.assert_called_once()
        assert "fully refunded" in out

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("handlers.payment_stripe.stripe.Transfer.create_reversal", side_effect=RuntimeError("reversal failed"))
    @patch("handlers.digital._revoke_digital_licenses_for_order", return_value=0)
    @patch("handlers.payment_stripe.get_db")
    def test_process_charge_refunded_reversal_failure_suspends_seller_and_tracks_platform_debt(
        self,
        mock_get_db,
        _mock_revoke,
        _mock_reversal,
        _mock_ts,
    ):
        from handlers.payment_stripe import process_charge_refunded

        order_ref = Mock()
        order_doc = _snap(
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.CUMULATIVE_REFUNDED_CENTS: 0,
                Fields.STOCK_RESTORED: True,
                Fields.SUBTOTAL_CENTS: 1000,
            },
            doc_id="order_1",
        )
        order_ref.get.return_value = order_doc
        order_doc.reference = order_ref

        orders_q = Mock()
        orders_q.where.return_value = orders_q
        orders_q.limit.return_value = orders_q
        orders_q.stream.return_value = [order_doc]
        orders_col = Mock()
        orders_col.where.return_value = orders_q

        payout_doc = _snap(
            {
                Fields.STRIPE_TRANSFER_ID: "tr_1",
                Fields.CUMULATIVE_REVERSED_CENTS: 0,
                Fields.NET_AMOUNT_CENTS: 900,
                Fields.SELLER_ID: "seller_1",
                Fields.AMOUNT_CENTS: 900,
            },
            doc_id="payout_1",
        )

        failed_lookup_doc = _snap({Fields.SELLER_ID: "seller_1", Fields.AMOUNT_CENTS: 900}, doc_id="payout_lookup")

        payouts_q = Mock()
        payouts_q.where.return_value = payouts_q
        payouts_q.limit.return_value = payouts_q
        payouts_q.stream.return_value = [payout_doc]
        payouts_q.get.return_value = [failed_lookup_doc]
        payouts_col = Mock()
        payouts_col.where.return_value = payouts_q

        users_col = Mock()
        users_col.document.return_value.update = Mock()

        security_col = Mock()
        platform_debt_col = Mock()

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.USERS: users_col,
            Collections.SECURITY_ALERTS: security_col,
            Collections.PLATFORM_DEBT: platform_debt_col,
        }[name]
        mock_get_db.return_value = db

        out = process_charge_refunded(
            {
                StripeConstants.PAYMENT_INTENT: "pi_1",
                "amount_refunded": 1000,
                Fields.AMOUNT: 1000,
            }
        )

        assert "fully refunded" in out
        assert security_col.add.called
        assert users_col.document.return_value.update.called
        assert platform_debt_col.add.called
        order_ref.update.assert_called_once()

    @patch("handlers.payment_stripe.get_server_timestamp", return_value="ts")
    @patch("utils.helpers.get_charge_id_from_pi", return_value="ch_1")
    @patch("handlers.payment_stripe.stripe.PaymentIntent.retrieve")
    @patch("handlers.payment_stripe.stripe.Transfer.create")
    @patch("handlers.payment_stripe._get_seller_stripe_snapshot", return_value={"seller_1": "acct_1"})
    @patch("handlers.payment_stripe.ensure_stripe_key")
    @patch("handlers.payment_providers.require_provider_enabled")
    @patch("handlers.payment_stripe.get_db")
    def test_capture_payment_impl_already_captured_creates_missing_payout_records(
        self,
        mock_get_db,
        _mock_provider,
        _mock_ensure,
        _mock_snapshot,
        mock_transfer_create,
        _mock_pi_retrieve,
        _mock_charge,
        _mock_ts,
    ):
        from handlers.payment_stripe import _capture_payment_impl

        mock_transfer_create.return_value = Mock(id="tr_1")

        order_ref = Mock()
        order_ref.get.return_value = _snap(
            {
                Fields.USER_ID: "buyer_1",
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.ORDER_STATUS: OrderStatusValues.DELIVERED,
                Fields.CONFIRMED_BY_CLIENT: False,
                Fields.STRIPE_PAYMENT_INTENT_ID: "pi_1",
                Fields.ITEMS: [
                    {
                        Fields.SELLER_ID: "seller_1",
                        Fields.PRICE: 10.0,
                        Fields.QUANTITY: 2,
                        Fields.STATUS: "delivered",
                    }
                ],
                Fields.SUBTOTAL_CENTS: 2000,
                Fields.DISCOUNT_AMOUNT_CENTS: 0,
            },
            doc_id="order_1",
        )

        orders_col = Mock()
        orders_col.document.return_value = order_ref

        payout_ref = Mock()
        payout_ref.get.return_value = _snap(exists=False)
        payouts_col = Mock()
        payouts_col.document.return_value = payout_ref

        db = Mock()
        db.collection.side_effect = lambda name: {
            Collections.ORDERS: orders_col,
            Collections.PAYOUTS: payouts_col,
            Collections.SELLER_PROFILES: Mock(),
        }[name]
        mock_get_db.return_value = db

        req = _req("buyer_1", {Fields.ORDER_ID: "order_1"}, token={})
        out = _capture_payment_impl(req)

        assert out[ApiKeys.SUCCESS] is True
        assert out[ApiKeys.CAPTURED] is True
        order_ref.update.assert_called_once()
        payout_ref.set.assert_called_once()
        payout_ref.update.assert_called_once()
