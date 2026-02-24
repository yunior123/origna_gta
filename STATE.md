# STATE.md


[MEDIUM] functions/handlers/orders.py (missing)
PROBLEM: No dispute escalation path for unresolved return requests — when a return stays in 'requested' status for N days, it should auto-escalate to admin review queue.
FIX: Add a cron or scheduled function that escalates ReturnRequest documents older than N days in 'requested' status.

[MEDIUM] functions/handlers/orders.py:refund_order_item ~line 397
PROBLEM: The 7-day return window is only enforced in `refund_order_item` (direct refund). The `create_return_request` handler has the shared `_assert_within_return_window` helper but admin-initiated refunds do not check the window.
STATUS: `_assert_within_return_window` helper implemented and used in `create_return_request`.

[MEDIUM] lib/features/orders/orders_screen.dart:_confirmReceipt ~line 490
PROBLEM: `confirmReceipt(widget.order.orderId, [item.productId])` passes `itemIds` but `confirm_order_receipt` / `_capture_payment_impl` ignores them — it captures full payment regardless.
FIX: Either remove `itemIds` parameter (confirm full order) or implement per-item receipt confirmation on backend.

[HIGH] functions/handlers/orders.py (on_order_status_changed trigger)
PROBLEM: No email or push notification sent when return request is created, approved, or rejected via Firestore trigger.
STATUS: Push notifications are sent from the CF handlers (create/approve/reject) but no Firestore trigger covers status transitions outside those handlers.

[BONUS] functions/handlers/orders.py:on_order_status_changed ~line 762
PROBLEM: `_handle_payment_status_email` is called with `buyer_email=None` every time from the Firestore trigger — always incurs an extra Firestore read even when no refund email is needed.
FIX: Return early before the DB read if `payment_status` is not `REFUNDED` or `PARTIALLY_REFUNDED`.
STATUS: Check already added at top of `_handle_payment_status_email` (line 1573 area). Verify the early return guards the DB read too.

[MEDIUM] products.py:get_product_ratings_paginated (~line 860)
PROBLEM: User names and avatars leaked to any authenticated user who queries ratings, including seller.
FIX: Omit `userAvatar` and truncate `userName` to first name only, or add a privacy preference check.

[MEDIUM] addproduct_screen.dart:_buildCategorySelector (~line 385)
PROBLEM: `onChanged` sets `_categoryController.text = v ?? ''` but never calls `viewModel.setCategoryId(...)`.
FIX: Call `viewModel.setCategoryId(int.parse(v!))` to persist to state.

[MEDIUM] product_repository.dart:fetchProducts (~line 240)
PROBLEM: Double-filters by `lifecycleStatus == active` — once in Firestore query and once in Dart `.where()`.
FIX: Remove redundant Dart-side `.where()` filter.

[MEDIUM] addproduct_screen.dart:_buildMarginPreview
PROBLEM: Margin preview computed with raw supplier cost when `_selectedSupplierCurrency != 'CAD'` — wrong margin displayed.
FIX: If `_selectedSupplierCurrency != 'CAD'`, show `N/A - convert cost to CAD first`.

[BONUS] products.py:submit_product_rating (~line 410)
PROBLEM: `order_data[Fields.USER_ID] != user_id` uses direct dict access — crashes with `KeyError` on legacy order.
FIX: Replace with `order_data.get(Fields.USER_ID) != user_id`.

[BONUS] products.py:on_product_created
PROBLEM: `priceCents` not set server-side in trigger — trigger reads raw Firestore dict without instantiating Product model.
FIX: Add `patches[Fields.PRICE_CENTS] = round(price * 100)` in the trigger's patch block.

[BONUS] products.py:answer_review
PROBLEM: No rate limiting on reply edits; `already-exists` prevents fixing typos in replies.
FIX: Add rate limit + allow update within 24h of original reply.

[BONUS] products.py:vote_review_helpful
PROBLEM: `_firestore.transactional(...)` risks None if lazy global wasn't set.
FIX: Use `from firebase_admin import firestore as fs; fs.transactional(_vote_txn)(txn)`.

[BONUS] products.py:bulk_update_products (~line 1050)
PROBLEM: `activate` action does NOT call Algolia indexing after batch commit — products won't appear in search after bulk re-activation.
FIX: Add `algolia_partial_update` call after `activate` batch.commit().

[BONUS] warehouses_viewmodel.dart:createWarehouse
PROBLEM: No client-side validation before calling Cloud Function (blank label or missing city passes silently).
FIX: Add validation matching backend rules (label 1-100 chars, address.city non-empty).

[BONUS] add_product_viewmodel.dart:_compressImages
PROBLEM: `_validateAndCompressImage` throws on files > 10MB but doesn't validate image format.
FIX: Add `if (img.decodeImage(bytes) == null) throw ...` before compression.

[BONUS] warehouses_viewmodel.dart:sellerWarehousesStreamProvider
PROBLEM: `ref.keepAlive()` lifecycle edge case — if stream restarts, `onDispose` may close new stream's link.
FIX: Low-risk; store link at class level in StateNotifier or use ref.listen.

[LOW] product_repository.dart:uploadImages (~line 320)
PROBLEM: On partial image upload failure, successfully uploaded images to R2 are never cleaned up.
FIX: Implement cleanup step before throwing.

[BONUS] addproduct_screen.dart:_buildVariantBuilderSection
PROBLEM: `state.variants.length.toString()` passed as `count` to `.tr()` — silently renders empty if translation key has no `{count}` placeholder.
FIX: Verify translation key `product.variant_combinations` has `{count}` placeholder.

[BONUS] addproduct_screen.dart:_buildWarehouseSelector — hardcoded strings
PROBLEM: Multiple hardcoded English strings in warehouse selector UI.
FIX: Move all to translation keys per CLAUDE.md rule #7.

[BONUS] products.py:_fire_back_in_stock_notifications — variant URL
PROBLEM: `variant_url` uses `variant_key` (variantId) which works for subscriptions but may not match frontend URL format.
FIX: Verify variant URL format matches frontend routing.

[BONUS] - Add `import_supplier_product` Cloud Function (maps supplier images to R2, enforces sellerSku dedup, sellerId == auth.uid)
[BONUS] - Move all supplier/inventory UI state out of addproduct_screen.dart into AddProductState/ViewModel (BONUS MVVM — large refactor)
