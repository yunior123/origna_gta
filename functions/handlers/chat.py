"""
Chat Handlers — Product-scoped buyer↔seller messaging.
Premium buyers only. One chat thread per buyer+product pair (requires a prior order).
All messages are written through the send_message Cloud Function (sanitized server-side).
The backend provides:
- get_or_create_chat: idempotent thread creation with premium + order guards
- send_message: sanitize and persist a message, update thread, push notification
- mark_messages_read: mark all messages in a thread as read
"""

import logging
import re
from datetime import UTC, datetime
from typing import Any

from firebase_functions import https_fn
from google.cloud import firestore

from schema_constants import (
    Collections,
    Fields,
    ProductLifecycleStatusValues,
    ValidationLimits,
)
from utils.db import get_db as _get_db
from utils.function_options import DEFAULT_OPTIONS

logger = logging.getLogger(__name__)


def _is_premium(uid: str) -> bool:
    """Check if user has active premium subscription (reads authoritative subscriptions doc)."""
    from utils.premium_check import is_premium_authoritative
    return is_premium_authoritative(uid, db=_get_db())

def _sanitize_text(text: str) -> str:
    """Strip HTML/script injection and off-platform contact info from user text."""
    text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.IGNORECASE | re.DOTALL)
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'javascript:', '', text, flags=re.IGNORECASE)
    # Redact off-platform contact info to protect marketplace transaction flow
    text = re.sub(r'\b[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}\b', '[email removed]', text)
    text = re.sub(r'\b(\+?1[\s\-.]?)?\(?\d{3}\)?[\s\-.]?\d{3}[\s\-.]?\d{4}\b', '[phone removed]', text)
    text = re.sub(r'https?://[^\s]+', '[link removed]', text, flags=re.IGNORECASE)
    text = re.sub(r'www\.[^\s]+', '[link removed]', text, flags=re.IGNORECASE)
    return text.strip()




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
            "Premium subscription required to chat with sellers. Upgrade to Origna Premium to unlock this feature.",
        )

    db = _get_db()

    # Fetch product to get sellerId and denormalized info
    product_snap = db.collection(Collections.PRODUCTS).document(product_id).get()
    if not product_snap.exists:
        raise https_fn.HttpsError("not-found", "Product not found.")

    product_data = product_snap.to_dict() or {}
    if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
        raise https_fn.HttpsError("not-found", "Product is no longer available.")

    seller_id = product_data.get(Fields.SELLER_ID, "")
    if not seller_id:
        raise https_fn.HttpsError("internal", "Product has no seller.")

    # Prevent self-chat (seller trying to chat with themselves)
    if seller_id == buyer_id:
        raise https_fn.HttpsError("permission-denied", "You cannot chat with yourself.")

    # Require an existing order: buyer must have purchased this specific product
    # (productId uniquely identifies the seller — no need for double array_contains)
    order_query = (
        db.collection(Collections.ORDERS)
        .where(Fields.USER_ID, "==", buyer_id)
        .where(Fields.PRODUCT_IDS, "array_contains", product_id)
        .limit(1)
        .get()
    )
    if not order_query:
        raise https_fn.HttpsError(
            "failed-precondition",
            "An order is required to chat with the seller. Please purchase a product from this seller first.",
        )

    # Deterministic chat ID prevents race condition on concurrent thread creation
    # Two simultaneous requests for the same product+buyer will both attempt to create
    # the same document — the second will fail with AlreadyExists, which we handle.
    chat_doc_id = f"{product_id}_{buyer_id}"
    chat_ref = db.collection(Collections.CHATS).document(chat_doc_id)

    # Check for existing thread (idempotent read before write)
    existing_snap = chat_ref.get()
    if existing_snap.exists:
        return {"chatId": chat_doc_id, "isNew": False}

    # Create new thread
    product_title = product_data.get(Fields.NAME, "Product")
    product_image_url = (product_data.get(Fields.IMAGE_URLS) or [None])[0]
    now = datetime.now(UTC)

    try:
        chat_ref.create(
            {
                Fields.PRODUCT_ID: product_id,
                Fields.PRODUCT_TITLE: product_title,
                Fields.PRODUCT_IMAGE_URL: product_image_url,
                Fields.BUYER_ID: buyer_id,
                Fields.SELLER_ID: seller_id,
                Fields.LAST_MESSAGE: None,
                Fields.LAST_MESSAGE_AT: None,
                Fields.BUYER_UNREAD_COUNT: 0,
                Fields.SELLER_UNREAD_COUNT: 0,
                Fields.CREATED_AT: now,
                Fields.UPDATED_AT: now,
            }
        )
    except Exception as e:
        if "ALREADY_EXISTS" in str(e):
            return {"chatId": chat_doc_id, "isNew": False}
        raise

    logger.info(f"Chat thread created: {chat_doc_id} for buyer={buyer_id} product={product_id}")
    return {"chatId": chat_doc_id, "isNew": True}


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
        db.collection(Collections.CHATS)
        .document(chat_id)
        .collection(Collections.CHAT_MESSAGES)
        .where(Fields.IS_READ, "==", False)
        .where(Fields.SENDER_ID, "!=", uid)
        .stream()
    )

    # Batch-mark unread messages in chunks of ≤ 499 (Firestore batch limit is 500)
    BATCH_LIMIT = 499
    messages_list = list(messages)
    count = len(messages_list)
    for i in range(0, count, BATCH_LIMIT):
        chunk = messages_list[i:i + BATCH_LIMIT]
        batch = db.batch()
        for msg in chunk:
            batch.update(msg.reference, {Fields.IS_READ: True})
        batch.commit()

    # Reset the caller's unread counter only when there were unread messages
    if count > 0:
        unread_field = Fields.BUYER_UNREAD_COUNT if uid == chat_data.get(Fields.BUYER_ID) else Fields.SELLER_UNREAD_COUNT
        db.collection(Collections.CHATS).document(chat_id).update({unread_field: 0})

    return {"success": True, "count": count}

@https_fn.on_call(**DEFAULT_OPTIONS)
def send_message(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Send a message in a chat thread — sanitizes text server-side before Firestore write.
    Buyers must be premium; sellers can reply without premium.

    Request data: { chatId: str, text: str }
    Returns: { success: bool, messageId: str }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required.")

    uid = req.auth.uid
    chat_id = (req.data.get(Fields.CHAT_ID) or "").strip()
    raw_text = req.data.get(Fields.MESSAGE_TEXT, "")

    if not chat_id:
        raise https_fn.HttpsError("invalid-argument", "chatId is required.")
    if not raw_text or not isinstance(raw_text, str):
        raise https_fn.HttpsError("invalid-argument", "text is required.")

    # Sanitize before any Firestore write
    text = _sanitize_text(raw_text)
    if len(text.strip()) < ValidationLimits.MIN_MESSAGE_LENGTH:
        raise https_fn.HttpsError("invalid-argument", "Message text is empty or too short.")
    if len(text) > ValidationLimits.MAX_MESSAGE_LENGTH:
        raise https_fn.HttpsError("invalid-argument", f"Message text exceeds {ValidationLimits.MAX_MESSAGE_LENGTH} characters.")

    db = _get_db()
    chat_snap = db.collection(Collections.CHATS).document(chat_id).get()
    if not chat_snap.exists:
        raise https_fn.HttpsError("not-found", "Chat thread not found.")

    chat_data = chat_snap.to_dict() or {}
    buyer_id = chat_data.get(Fields.BUYER_ID)
    seller_id = chat_data.get(Fields.SELLER_ID)

    if uid not in (buyer_id, seller_id):
        raise https_fn.HttpsError("permission-denied", "Access denied.")

    # Buyers must be premium to send messages
    if uid == buyer_id and not _is_premium(uid):
        raise https_fn.HttpsError(
            "permission-denied",
            "Premium subscription required to send messages.",
        )

    # Rate limit: max 60 messages per minute per user
    from services.rate_limiter import RateLimiter
    limiter = RateLimiter(db)
    allowed, msg = limiter.check_rate_limit(
        identifier=f"{uid}_chat",
        action="send_message",
        max_requests=60,
        window_minutes=1,
        fail_closed=False,
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", "Too many messages. Please slow down.")

    now = datetime.now(UTC)
    msg_ref = (
        db.collection(Collections.CHATS)
        .document(chat_id)
        .collection(Collections.CHAT_MESSAGES)
        .document()
    )
    msg_ref.set(
        {
            Fields.SENDER_ID: uid,
            Fields.MESSAGE_TEXT: text,
            Fields.CREATED_AT: now,
            Fields.IS_READ: False,
        }
    )

    # Update thread: last message + increment recipient's unread counter
    recipient_unread_field = Fields.SELLER_UNREAD_COUNT if uid == buyer_id else Fields.BUYER_UNREAD_COUNT
    thread_update: dict = {
        Fields.LAST_MESSAGE: text[:100],
        Fields.LAST_MESSAGE_AT: now,
        Fields.UPDATED_AT: now,
        recipient_unread_field: firestore.Increment(1),
    }

    # Response time tracking:
    # • Buyer's first message → record firstBuyerMessageAt (once only)
    # • Seller's first reply after a buyer message → record firstSellerReplyAt + firstReplyHours
    if uid == buyer_id and not chat_data.get(Fields.FIRST_BUYER_MESSAGE_AT):
        thread_update[Fields.FIRST_BUYER_MESSAGE_AT] = now
    elif uid == seller_id and not chat_data.get(Fields.FIRST_SELLER_REPLY_AT):
        first_buyer_msg_at = chat_data.get(Fields.FIRST_BUYER_MESSAGE_AT)
        if first_buyer_msg_at is not None:
            # Normalize timezone before diff
            if hasattr(first_buyer_msg_at, "tzinfo") and first_buyer_msg_at.tzinfo is None:
                first_buyer_msg_at = first_buyer_msg_at.replace(tzinfo=UTC)
            delta_hours = (now - first_buyer_msg_at).total_seconds() / 3600
            thread_update[Fields.FIRST_SELLER_REPLY_AT] = now
            thread_update[Fields.FIRST_REPLY_HOURS] = round(max(delta_hours, 0.0), 4)

    db.collection(Collections.CHATS).document(chat_id).update(thread_update)

    logger.info(f"Message sent in chat {chat_id} by user {uid}")

    # Push notification to the recipient
    recipient_id = seller_id if uid == buyer_id else buyer_id
    try:
        from services.push_service import send_push_notification
        sender_snap = db.collection(Collections.USERS).document(uid).get()
        sender_name = (sender_snap.to_dict() or {}).get(Fields.NAME, "Someone") if sender_snap.exists else "Someone"
        send_push_notification(
            recipient_id,
            title=f"New message from {sender_name}",
            body=text[:80],
            data={Fields.CHAT_ID: chat_id, Fields.PRODUCT_ID: chat_data.get(Fields.PRODUCT_ID, "")},
        )
    except Exception as push_err:
        logger.warning(f"Push notification failed for chat {chat_id}: {push_err}")

    return {"success": True, "messageId": msg_ref.id}
