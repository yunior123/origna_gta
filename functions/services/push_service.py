"""
FCM Push Notification Service
Sends Firebase Cloud Messaging notifications to user devices.
"""

import logging

from schema_constants import Collections, Fields

logger = logging.getLogger(__name__)

_db = None


def _get_db():
    """Lazy Firestore client initialization."""
    global _db
    if _db is None:
        from firebase_admin import firestore as fs

        _db = fs.client()
    return _db


def send_push_notification(user_id: str, title: str, body: str, data: dict | None = None) -> bool:
    """
    Send FCM push notification to all active devices for a user.
    Reads tokens from users/{uid}/fcm_tokens subcollection (multi-device support).
    On UnregisteredError per token, removes the stale token doc atomically.
    Returns True if at least one message succeeded, False otherwise.
    """
    try:
        from firebase_admin import messaging
    except ImportError:
        logger.warning("firebase_admin.messaging not available — push skipped")
        return False

    try:
        user_ref = _get_db().collection(Collections.USERS).document(user_id)
        user_doc = user_ref.get()
        if not user_doc.exists:
            return False

        user_data = user_doc.to_dict() or {}

        # Respect opt-out preference
        if not user_data.get(Fields.PUSH_ENABLED, True):
            return False

        # Collect all tokens from subcollection (multi-device)
        token_docs = list(user_ref.collection(Collections.FCM_TOKENS).stream())
        
        # Deduplicate tokens to avoid sending multiple pushes to the same device
        unique_tokens: dict[str, object] = {}
        for d in token_docs:
            token_str = d.to_dict().get("token")
            if token_str:
                unique_tokens[token_str] = d.reference
                
        tokens_with_refs: list[tuple[str, object]] = list(unique_tokens.items())

        if not tokens_with_refs:
            return False

        token_list = [t for t, _ in tokens_with_refs]
        msg = messaging.MulticastMessage(
            tokens=token_list,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )
        batch_response = messaging.send_each_for_multicast(msg)

        success = False
        for idx, response in enumerate(batch_response.responses):
            if response.success:
                success = True
            elif response.exception:
                err_str = str(response.exception)
                if "registration-token-not-registered" in err_str or "invalid-registration-token" in err_str:
                    # Remove stale token from subcollection
                    _, token_ref = tokens_with_refs[idx]
                    try:
                        if token_ref:
                            token_ref.delete()
                        logger.info(f"Removed stale FCM token for user {user_id}")
                    except Exception as del_err:
                        logger.warning(f"Failed to remove stale FCM token: {del_err}")

        if success:
            logger.info(f"Push sent to user {user_id} ({batch_response.success_count}/{len(token_list)} tokens)")
        return success
    except Exception as e:
        logger.warning(f"FCM push failed for user {user_id}: {e}")
        return False
