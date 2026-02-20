"""
Chat Handlers — Product-scoped buyer↔seller messaging.
Premium buyers only. One chat thread per buyer+product combination.
Messages are written directly to Firestore by the client (Firestore rules enforce access).
The backend provides:
- get_or_create_chat: idempotent thread creation with premium guard
- mark_messages_read: mark all messages in a thread as read
"""

import logging
from datetime import UTC, datetime
from typing import Any

from firebase_functions import https_fn

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


def _is_premium(uid: str) -> bool:
    """Check if user has active premium subscription (uses cached isPremium field)."""
    user_snap = _get_db().collection(Collections.USERS).document(uid).get()
    if not user_snap.exists:
        return False
    return bool((user_snap.to_dict() or {}).get(Fields.IS_PREMIUM, False))


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_or_create_chat(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Get or create a product-scoped chat thread between buyer and the product's seller.
    Premium buyers only. Idempotent — returns existing chatId if thread already exists.

    Request data: { productId: str }
    Returns: { chatId: str, isNew: bool }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required.")

    buyer_id = req.auth.uid
    data = req.data
    product_id = data.get(Fields.PRODUCT_ID, "").strip()

    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId is required.")

    # Premium gate
    if not _is_premium(buyer_id):
        raise https_fn.HttpsError(
            "permission-denied",
            "Premium subscription required to chat with sellers. Upgrade to Origna Premium to unlock this feature."
        )

    db = _get_db()

    # Fetch product to get sellerId and denormalized info
    product_snap = db.collection(Collections.PRODUCTS).document(product_id).get()
    if not product_snap.exists:
        raise https_fn.HttpsError("not-found", "Product not found.")

    product_data = product_snap.to_dict() or {}
    if not product_data.get(Fields.IS_ACTIVE, True):
        raise https_fn.HttpsError("not-found", "Product is no longer available.")

    seller_id = product_data.get(Fields.SELLER_ID, "")
    if not seller_id:
        raise https_fn.HttpsError("internal", "Product has no seller.")

    # Prevent self-chat (seller trying to chat with themselves)
    if seller_id == buyer_id:
        raise https_fn.HttpsError("permission-denied", "You cannot chat with yourself.")

    # Check for existing thread (idempotent)
    existing = (
        db.collection(Collections.CHATS)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.BUYER_ID, "==", buyer_id)
        .limit(1)
        .get()
    )
    if existing:
        return {"chatId": existing[0].id, "isNew": False}

    # Create new thread
    product_title = product_data.get(Fields.NAME, "Product")
    product_image_url = (product_data.get(Fields.IMAGE_URLS) or [None])[0]
    now = datetime.now(UTC)

    chat_ref = db.collection(Collections.CHATS).document()
    chat_ref.set({
        Fields.CHAT_ID: chat_ref.id,
        Fields.PRODUCT_ID: product_id,
        Fields.PRODUCT_TITLE: product_title,
        Fields.PRODUCT_IMAGE_URL: product_image_url,
        Fields.BUYER_ID: buyer_id,
        Fields.SELLER_ID: seller_id,
        Fields.LAST_MESSAGE: None,
        Fields.LAST_MESSAGE_AT: None,
        Fields.CREATED_AT: now,
        Fields.UPDATED_AT: now,
    })

    logger.info(f"Chat thread created: {chat_ref.id} for buyer={buyer_id} product={product_id}")
    return {"chatId": chat_ref.id, "isNew": True}


@https_fn.on_call(**DEFAULT_OPTIONS)
def mark_messages_read(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Mark all unread messages in a chat thread as read for the authenticated user.

    Request data: { chatId: str }
    Returns: { success: bool, count: int }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required.")

    uid = req.auth.uid
    chat_id = (req.data.get(Fields.CHAT_ID) or "").strip()
    if not chat_id:
        raise https_fn.HttpsError("invalid-argument", "chatId is required.")

    db = _get_db()
    chat_snap = db.collection(Collections.CHATS).document(chat_id).get()
    if not chat_snap.exists:
        raise https_fn.HttpsError("not-found", "Chat thread not found.")

    chat_data = chat_snap.to_dict() or {}
    if chat_data.get(Fields.BUYER_ID) != uid and chat_data.get(Fields.SELLER_ID) != uid:
        raise https_fn.HttpsError("permission-denied", "Access denied.")

    # Batch-mark unread messages sent by the OTHER party
    messages = (
        db.collection(Collections.CHATS).document(chat_id)
        .collection(Collections.CHAT_MESSAGES)
        .where(Fields.IS_READ, "==", False)
        .where(Fields.SENDER_ID, "!=", uid)
        .stream()
    )

    batch = db.batch()
    count = 0
    for msg in messages:
        batch.update(msg.reference, {Fields.IS_READ: True})
        count += 1

    if count > 0:
        batch.commit()

    return {"success": True, "count": count}
