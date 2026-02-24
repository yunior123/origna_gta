# STATE.md

[MEDIUM] functions/handlers/orders.py (missing)
PROBLEM: No dispute escalation path for unresolved return requests — when a return stays in 'requested' status for N days, it should auto-escalate to admin review queue.
FIX: Add a cron or scheduled function that escalates ReturnRequest documents older than N days in 'requested' status.

[HIGH] functions/handlers/orders.py (on_order_status_changed trigger)
PROBLEM: No email or push notification sent when return request is created, approved, or rejected via Firestore trigger.
STATUS: Push notifications are sent from the CF handlers (create/approve/reject) but no Firestore trigger covers status transitions outside those handlers.

[MEDIUM] lib/features/orders/orders_screen.dart:_confirmReceipt ~line 490
PROBLEM: `confirmReceipt(widget.order.orderId, [item.productId])` passes `itemIds` but `confirm_order_receipt` / `_capture_payment_impl` ignores them — it captures full payment regardless.
FIX: Either remove `itemIds` parameter (confirm full order) or implement per-item receipt confirmation on backend.
NOTE: Dart-side already uses `confirmReceipt(orderId)` without itemIds. Backend fix pending if per-item needed.

[MEDIUM] seller_account_status_viewmodel.dart:refreshSellerStatusProvider (~line 44)
PROBLEM: ref.invalidate(sellerAccountStatusProvider) is called after a manual refresh, but the FutureProvider returns from CF while the stream is Firestore-backed — brief stale UI.
FIX: Return SellerAccountStatus from stream provider only; let FutureProvider side-effect update Firestore.

[BONUS] products.py:answer_review
PROBLEM: No rate limiting on reply edits; `already-exists` prevents fixing typos in replies.
FIX: Add rate limit + allow update within 24h of original reply.

[BONUS] products.py:vote_review_helpful
PROBLEM: `_firestore.transactional(...)` risks None if lazy global wasn't set.
FIX: Already guarded at line 714. Verify initialization path covers all edge cases.

[BONUS] warehouses_viewmodel.dart:createWarehouse
PROBLEM: No client-side validation before calling Cloud Function (blank label or missing city passes silently).
FIX: Add validation matching backend rules (label 1-100 chars, address.city non-empty).

[BONUS] add_product_viewmodel.dart:_compressImages
PROBLEM: `_validateAndCompressImage` throws on files > 10MB but doesn't validate image format.
FIX: Add `if (img.decodeImage(bytes) == null) throw ...` before compression.

[BONUS] warehouses_viewmodel.dart:sellerWarehousesStreamProvider
PROBLEM: `ref.keepAlive()` lifecycle edge case — if stream restarts, `onDispose` may close new stream's link.
FIX: Store link at class level in StateNotifier or use ref.listen.

[LOW] product_repository.dart:uploadImages (~line 320)
PROBLEM: On partial image upload failure, successfully uploaded images to R2 are never cleaned up.
FIX: Implement cleanup step before throwing.

[BONUS] addproduct_screen.dart:_buildVariantBuilderSection
PROBLEM: `state.variants.length.toString()` passed as `count` to `.tr()` — silently renders empty if translation key has no `{count}` placeholder.
FIX: Verify translation key `product.variant_combinations` has `{count}` placeholder.

[BONUS] addproduct_screen.dart:_buildWarehouseSelector — hardcoded strings
PROBLEM: Multiple hardcoded English strings in warehouse selector UI.
FIX: Move all to translation keys per CLAUDE.md rule #7.

[BONUS] payment_stripe.py:3304
PROBLEM: Country code validated only by len==2 and isalpha(). Accepts invalid codes like 'XX', 'ZZ'.
FIX: Validate against a whitelist of Stripe-supported country codes, or check against pycountry.

[BONUS] payment_stripe.py:verify_cart_prices (~line 327-330)
PROBLEM: Price comparison uses float from Firestore — floating-point precision errors can mask real price changes.
FIX: Store and compare all prices as integer cents (priceCents). Until migration, round both values to 2 decimal places.

[BONUS] lib/features/chat/chat_repository.dart — isNew not surfaced to UI
PROBLEM: `getOrCreateChat` returns `{chatId, isNew}` but `ChatRepository.getOrCreateChat` only parses `chatId`; the `isNew` flag is discarded.
FIX: Return `(chatId: String, isNew: bool)` record from `getOrCreateChat`.

[BONUS] lib/features/chat/chat_screen.dart — no unread badge count on thread list
PROBLEM: No `unreadCount` field tracked per participant on the chat thread doc.
FIX: Add `buyerUnreadCount` and `sellerUnreadCount` int fields to the chat thread doc; increment on message write, reset to 0 in `mark_messages_read` CF.

[BONUS] lib/features/chat/chat_screen.dart — empty state missing CTA
PROBLEM: "No messages yet. Say hello! 👋" empty state has no CTA button.
FIX: Add a secondary "Send a message" button below the text that focuses the TextField.

[BONUS] lib/features/chat/chat_repository.dart — comment mismatch
PROBLEM: Comment says "We do two queries and merge" but only a single buyer query is executed.
FIX: Either remove the misleading comment or implement RxDart merge of buyerId + sellerId queries.

[BONUS] lib/features/chat/chat_screen.dart — missing staggered list animation
PROBLEM: `ListView.builder` renders messages with no entrance animation.
FIX: Wrap each `_MessageBubble` in `AnimatedListItem` with staggered delay based on index.
