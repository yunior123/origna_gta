"""
Premium Subscription Handlers
- Create Stripe subscription ($7.86 CAD/month)
- Cancel subscription (at period end)
- Get subscription status
- Webhook event processing (called from payment_stripe.py)
"""

import logging
from datetime import UTC, datetime
from typing import Any

import stripe
from firebase_functions import https_fn

from config import (
    get_stripe_premium_price_id,
    get_stripe_secret_key,
)
from schema_constants import (
    Collections,
    Fields,
    SubscriptionStatusValues,
)
from utils.function_options import DEFAULT_OPTIONS

logger = logging.getLogger(__name__)

_db = None
_firestore = None


def _get_db():
    global _db, _firestore
    if _db is None:
        from firebase_admin import firestore as fs

        _firestore = fs
        _db = fs.client()
    return _db


def _get_server_timestamp():
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore.SERVER_TIMESTAMP


def _stripe_init() -> None:
    stripe.api_key = get_stripe_secret_key()


def _get_or_create_stripe_customer(uid: str, user_data: dict) -> str:
    """Get existing Stripe customer ID or create a new one for the user."""
    _stripe_init()
    customer_id = user_data.get(Fields.CUSTOMER_ID)
    if customer_id:
        return customer_id

    customer = stripe.Customer.create(
        email=user_data.get(Fields.EMAIL, ""),
        name=user_data.get(Fields.NAME, ""),
        metadata={"uid": uid},
    )
    _get_db().collection(Collections.USERS).document(uid).update({Fields.CUSTOMER_ID: customer.id})
    return customer.id


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_subscription(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Create a premium subscription for the authenticated buyer.
    - Creates or reuses a Stripe Customer
    - Returns a Stripe Checkout Session URL (subscription mode)
    - On successful payment, webhook syncs subscription status to Firestore
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required.")

    uid = req.auth.uid
    user_ref = _get_db().collection(Collections.USERS).document(uid)
    user_snap = user_ref.get()
    user_data = user_snap.to_dict() if user_snap.exists else {}

    # Check already subscribed
    sub_snap = _get_db().collection(Collections.SUBSCRIPTIONS).document(uid).get()
    if sub_snap.exists:
        sub_data = sub_snap.to_dict() or {}
        status = sub_data.get(Fields.STATUS, "")
        if status in SubscriptionStatusValues.PREMIUM_ACTIVE:
            raise https_fn.HttpsError("already-exists", "You already have an active premium subscription.")

    price_id = get_stripe_premium_price_id()
    if not price_id:
        raise https_fn.HttpsError("internal", "Premium subscription is not configured yet. Please try again later.")

    _stripe_init()

    from config import BASE_URL

    customer_id = _get_or_create_stripe_customer(uid, user_data)

    try:
        session = stripe.checkout.Session.create(
            customer=customer_id,
            line_items=[{"price": price_id, "quantity": 1}],
            mode="subscription",
            success_url=f"{BASE_URL}/subscription/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{BASE_URL}/subscription/cancel",
            client_reference_id=uid,
            metadata={"uid": uid},
            subscription_data={"metadata": {"uid": uid}},
            # Use 5-minute window idempotency to allow retry after session expiry
            idempotency_key=f"premium_sub_{uid}_{datetime.now(UTC).strftime('%Y%m%d%H%M')}",
        )
        return {"success": True, "checkoutUrl": session.url, "sessionId": session.id}
    except stripe.error.IdempotencyError as e:
        # Same click within the same minute window — re-fetch the existing session
        logger.info(f"Idempotency hit for premium subscription {uid}: {e}")
        existing_session = e.request_id and stripe.checkout.Session.retrieve(
            e.headers.get("idempotency-replayed-request", "")
        ) if hasattr(e, "headers") else None
        if existing_session and existing_session.url:
            return {"success": True, "checkoutUrl": existing_session.url, "sessionId": existing_session.id}
        # Fallback: surface as retriable error
        raise https_fn.HttpsError("already-exists", "A checkout session is already in progress. Please try again in a moment.") from e
    except stripe.StripeError as e:
        logger.error(f"Stripe error creating subscription for {uid}: {e}")
        raise https_fn.HttpsError("internal", "Failed to create subscription. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def cancel_subscription(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Cancel the premium subscription at end of current billing period.
    The user retains premium benefits until premiumExpiresAt.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required.")

    uid = req.auth.uid
    sub_snap = _get_db().collection(Collections.SUBSCRIPTIONS).document(uid).get()
    if not sub_snap.exists:
        raise https_fn.HttpsError("not-found", "No active subscription found.")

    sub_data = sub_snap.to_dict() or {}
    stripe_sub_id = sub_data.get(Fields.STRIPE_SUBSCRIPTION_ID)
    if not stripe_sub_id:
        raise https_fn.HttpsError("not-found", "Subscription ID not found.")

    status = sub_data.get(Fields.STATUS, "")
    if status not in SubscriptionStatusValues.PREMIUM_ACTIVE:
        raise https_fn.HttpsError("failed-precondition", "Subscription is not active.")

    _stripe_init()
    try:
        stripe.Subscription.modify(stripe_sub_id, cancel_at_period_end=True)
        _get_db().collection(Collections.SUBSCRIPTIONS).document(uid).update(
            {
                Fields.CANCEL_AT_PERIOD_END: True,
                Fields.UPDATED_AT: _get_server_timestamp(),
            }
        )
        return {"success": True, "message": "Subscription will cancel at end of billing period."}
    except stripe.StripeError as e:
        logger.error(f"Stripe error canceling subscription for {uid}: {e}")
        raise https_fn.HttpsError("internal", "Failed to cancel subscription. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_subscription_status(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Return the current premium subscription status for the authenticated user."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required.")

    uid = req.auth.uid
    sub_snap = _get_db().collection(Collections.SUBSCRIPTIONS).document(uid).get()
    if not sub_snap.exists:
        return {"isPremium": False, "status": None, "premiumExpiresAt": None}

    sub_data = sub_snap.to_dict() or {}
    status = sub_data.get(Fields.STATUS)
    is_premium = status in SubscriptionStatusValues.PREMIUM_ACTIVE
    period_end = sub_data.get(Fields.CURRENT_PERIOD_END)

    return {
        "isPremium": is_premium,
        "status": status,
        "premiumExpiresAt": period_end.isoformat() if period_end else None,
        "cancelAtPeriodEnd": sub_data.get(Fields.CANCEL_AT_PERIOD_END, False),
    }


# ============================================================================
# WEBHOOK HANDLERS — called by payment_stripe.py webhook dispatcher
# ============================================================================


def handle_subscription_created(event: stripe.Event) -> None:
    """Sync subscription.created → Firestore."""
    _sync_subscription(event.data.object)


def handle_subscription_updated(event: stripe.Event) -> None:
    """Sync subscription.updated → Firestore + user.isPremium cache."""
    _sync_subscription(event.data.object)


def handle_subscription_deleted(event: stripe.Event) -> None:
    """Subscription ended → clear premium status."""
    sub = event.data.object
    uid = sub.get("metadata", {}).get("uid")
    if not uid:
        logger.warning("subscription.deleted: no uid in metadata")
        return

    db = _get_db()
    now = datetime.now(UTC)

    batch = db.batch()

    sub_ref = db.collection(Collections.SUBSCRIPTIONS).document(uid)
    batch.set(
        sub_ref,
        {
            Fields.STRIPE_SUBSCRIPTION_ID: sub["id"],
            Fields.STATUS: SubscriptionStatusValues.CANCELED,
            Fields.CANCEL_AT_PERIOD_END: False,
            Fields.CURRENT_PERIOD_END: _ts_to_datetime(sub.get("current_period_end")),
            Fields.UPDATED_AT: now,
        },
        merge=True,
    )

    # Clear premium cache on user doc — in same batch to avoid partial writes
    user_ref = db.collection(Collections.USERS).document(uid)
    batch.update(
        user_ref,
        {
            Fields.IS_PREMIUM: False,
            Fields.PREMIUM_EXPIRES_AT: None,
            Fields.STRIPE_SUBSCRIPTION_ID: None,
            Fields.PREMIUM_SINCE: None,
            Fields.UPDATED_AT: now,
        }
    )

    batch.commit()
    logger.info(f"Premium cleared for user {uid} (subscription deleted)")


def handle_invoice_payment_failed(event: stripe.Event) -> None:
    """Invoice payment failed → mark past_due."""
    invoice = event.data.object
    sub_id = invoice.get("subscription")
    if not sub_id:
        return

    _stripe_init()
    try:
        sub = stripe.Subscription.retrieve(sub_id)
        _sync_subscription(sub)
    except stripe.StripeError as e:
        logger.error(f"Failed to retrieve subscription {sub_id} after payment failure: {e}")


def _sync_subscription(sub: dict | stripe.Subscription) -> None:
    """Sync a Stripe Subscription object to Firestore and update user.isPremium cache."""
    uid = sub.get("metadata", {}).get("uid") if isinstance(sub, dict) else (sub.metadata or {}).get("uid")
    if not uid:
        logger.warning(
            f"_sync_subscription: no uid in metadata for sub {sub.get('id') if isinstance(sub, dict) else sub.id}"
        )
        return

    status = sub["status"] if isinstance(sub, dict) else sub.status
    sub_id = sub["id"] if isinstance(sub, dict) else sub.id
    period_end_ts = sub.get("current_period_end") if isinstance(sub, dict) else sub.current_period_end
    period_start_ts = sub.get("current_period_start") if isinstance(sub, dict) else sub.current_period_start
    cancel_at_end = sub.get("cancel_at_period_end", False) if isinstance(sub, dict) else sub.cancel_at_period_end

    period_end = _ts_to_datetime(period_end_ts)
    period_start = _ts_to_datetime(period_start_ts)
    is_premium = status in SubscriptionStatusValues.PREMIUM_ACTIVE
    now = datetime.now(UTC)

    db = _get_db()
    from firebase_admin import firestore as _fs

    sub_ref = db.collection(Collections.SUBSCRIPTIONS).document(uid)
    user_ref = db.collection(Collections.USERS).document(uid)

    @_fs.transactional
    def _sync_txn(transaction):
        # Read premiumSince atomically inside the transaction
        user_snap = user_ref.get(transaction=transaction)
        existing_premium_since = (user_snap.to_dict() or {}).get(Fields.PREMIUM_SINCE) if user_snap.exists else None

        transaction.set(
            sub_ref,
            {
                Fields.UID: uid,
                Fields.STRIPE_SUBSCRIPTION_ID: sub_id,
                Fields.STATUS: status,
                Fields.CURRENT_PERIOD_START: period_start,
                Fields.CURRENT_PERIOD_END: period_end,
                Fields.CANCEL_AT_PERIOD_END: cancel_at_end,
                Fields.UPDATED_AT: now,
            },
            merge=True,
        )

        user_update: dict[str, Any] = {
            Fields.IS_PREMIUM: is_premium,
            Fields.STRIPE_SUBSCRIPTION_ID: sub_id,
            Fields.UPDATED_AT: now,
        }
        if is_premium and period_end:
            user_update[Fields.PREMIUM_EXPIRES_AT] = period_end
            if not existing_premium_since:
                user_update[Fields.PREMIUM_SINCE] = period_start or now
        elif not is_premium:
            user_update[Fields.PREMIUM_EXPIRES_AT] = period_end

        transaction.update(user_ref, user_update)

    transaction = db.transaction()
    _sync_txn(transaction)
    logger.info(f"Subscription synced for user {uid}: status={status}, isPremium={is_premium}")


def _ts_to_datetime(ts: int | None) -> datetime | None:
    """Convert Unix timestamp to UTC datetime."""
    if ts is None:
        return None
    return datetime.fromtimestamp(ts, tz=UTC)
