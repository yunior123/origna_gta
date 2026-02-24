# STATE.md

[MEDIUM] seller_account_status_viewmodel.dart:refreshSellerStatusProvider (~line 44)
PROBLEM: ref.invalidate(sellerAccountStatusProvider) is called after a manual refresh, but the FutureProvider returns from CF while the stream is Firestore-backed — brief stale UI.
FIX: Return SellerAccountStatus from stream provider only; let FutureProvider side-effect update Firestore.

[BONUS] warehouses_viewmodel.dart:sellerWarehousesStreamProvider
PROBLEM: `ref.keepAlive()` lifecycle edge case — if stream restarts, `onDispose` may close new stream's link.
FIX: Store link at class level in StateNotifier or use ref.listen.

[BONUS] payment_stripe.py:3304
PROBLEM: Country code validated only by len==2 and isalpha(). Accepts invalid codes like 'XX', 'ZZ'.
FIX: Validate against a whitelist of Stripe-supported country codes, or check against pycountry.

[BONUS] lib/features/chat/chat_screen.dart — no unread badge count on thread list
PROBLEM: No `unreadCount` field tracked per participant on the chat thread doc.
FIX: Add `buyerUnreadCount` and `sellerUnreadCount` int fields to the chat thread doc; increment on message write, reset to 0 in `mark_messages_read` CF.

[BONUS] lib/features/chat/chat_screen.dart — missing staggered list animation
PROBLEM: `ListView.builder` renders messages with no entrance animation.
FIX: Wrap each `_MessageBubble` in `AnimatedListItem` with staggered delay based on index.
