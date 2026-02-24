# STATE.md

Now I have enough context to write the full audit. Let me compile findings:

---

```
[CRITICAL] functions/handlers/orders.py:808–841
PROBLEM: cancel_order sets CANCELLING lock (line 739), issues Stripe refund (line 758), then calls cancel_batch.commit() (line 841). If cancel_batch.commit() throws, the order is permanently stuck with paymentStatus=CANCELLING — no subsequent cancel attempt can proceed (blocked at line 726), while Stripe has already refunded the buyer.
FIX: Wrap cancel_batch.commit() in try/except; on failure restore original payment_status via a separate update:
try:
    cancel_batch.commit()
except Exception as batch_err:
    order_ref.update({Fields.PAYMENT_STATUS: payment_status, Fields.REQUIRES_MANUAL_REVIEW: True, ...})
    raise https_fn.HttpsError("internal", "Order state update failed after Stripe action") from batch_err
```

```
[CRITICAL] functions/handlers/orders.py:1083–1089
PROBLEM: _apply_refund_atomically in refund_order_item only increments global stockQuantity; it does NOT restore warehouseStock map or inventoryLevels subcollection. cancel_order (lines 817–826) and shipping rejection (lines 1469–1477) both restore all three. Warehouse-level inventory diverges permanently after every item refund.
FIX: Inside _apply_refund_atomically, after the stockQuantity increment, add:
    fulfillment_wh = it.get(Fields.FULFILLMENT_WAREHOUSE_ID)
    if fulfillment_wh and not is_digital:
        transaction.update(product_ref, {
            f"{Fields.WAREHOUSE_STOCK}.{fulfillment_wh}": get_firestore().Increment(item_quantity),
        })
        inv_ref = product_ref.collection(Collections.INVENTORY_LEVELS).document(fulfillment_wh)
        transaction.set(inv_ref, {Fields.AVAILABLE_QUANTITY: get_firestore().Increment(item_quantity), ...}, merge=True)
```

```
[CRITICAL] functions/handlers/orders.py:1441–1479
PROBLEM: _reject_shipping_transactional sets STOCK_RESTORED: True inside the transaction (line 1451), but stock is restored in a SEPARATE reject_batch.commit() (lines 1459–1479) outside it. If the batch commit fails (transient error), STOCK_RESTORED=True is already committed in Firestore — the retry path hits "No pending shipping approval" and stock is never restored permanently.
FIX: Move stock restore inside the transaction (Firestore transactions support up to 500 doc writes), and remove STOCK_RESTORED from the transaction update — set it only after the stock batch commits:
    # In _reject_shipping_transactional, omit Fields.STOCK_RESTORED: True
    # After reject_batch.commit() succeeds:
    order_ref.update({Fields.STOCK_RESTORED: True, Fields.UPDATED_AT: get_server_timestamp()})
```

```
[HIGH] functions/handlers/payment_stripe.py:2895
PROBLEM: stripe.Transfer.create_reversal(transfer_id, **reversal_kwargs) has no idempotency_key. On dispute webhook retry, a second reversal is issued before the cumulativeReversedCents guard can protect (guard only works if Firestore was updated — which hasn't happened before the retry fires).
FIX: Add idempotency_key=f"dispute_reversal_{dispute.get('id')}_{transfer_id}" to the create_reversal call:
    reversal = stripe.Transfer.create_reversal(
        transfer_id,
        **reversal_kwargs,
        idempotency_key=f"dispute_reversal_{dispute.get('id')}_{transfer_id}",
    )
```

```
[HIGH] functions/cron_jobs.py:183
PROBLEM: auto_capture queries DELIVERED orders with WHERE updatedAt <= cutoff_date. Any field write to the order (rating added, tracking update, etc.) resets updatedAt, pushing the order out of the query window indefinitely — seller payout may never fire.
FIX: Query by deliveredAt (or confirmedAt for auto-confirmed orders) instead:
    .where(Fields.DELIVERED_AT, "<=", cutoff_date)
    (Requires a Firestore composite index on orderStatus + deliveredAt.)
ALSO: functions/cron_jobs.py:715 — auto_archive_old_orders has the same bug with updatedAt.
```

```
[HIGH] functions/handlers/orders.py:306–365
PROBLEM: The shipping approval gate check (lines 306–314) reads from the pre-fetched non-transactional order_data. The _update_seller_items transaction (lines 325–365) does NOT re-validate shippingApprovalStatus inside the transaction. A buyer who rejects shipping between the guard read and the transaction commit cannot prevent the seller from marking items as SHIPPED.
FIX: Re-check inside _update_seller_items:
    fresh_approval_status = fresh_data.get(Fields.SHIPPING_APPROVAL, {}).get(Fields.STATUS)
    if fresh_approval_status == ShippingApprovalStatusValues.PENDING:
        return None, "Shipping cost approval still pending"
    if fresh_approval_status == ShippingApprovalStatusValues.REJECTED:
        return None, "Buyer rejected the shipping cost"
```

```
[HIGH] lib/models/generated/base_models.dart:~100 + functions/models/base.py:~30
PROBLEM: Dart PaymentStatus enum has @JsonValue('disputed') disputed; Python PaymentStatusEnum does NOT have a DISPUTED value. If any backend code ever writes paymentStatus: "disputed" to Firestore, Dart deserialization will throw an unknown enum value exception and crash the order screen.
FIX: Add to Python PaymentStatusEnum:
    DISPUTED = "disputed"
and add PaymentStatusValues.DISPUTED = "disputed" to schema_constants.py.
```

```
[MEDIUM] functions/cron_jobs.py:301–316
PROBLEM: Auto-confirm cron changes SHIPPED→DELIVERED order and item statuses (lines 301–316) but never calls OrderEvent.write(). The audit trail for auto-confirmed deliveries is empty, making it impossible to investigate disputes or seller payment queries.
FIX: After line 316, add:
    from models.order_event import OrderEvent
    OrderEvent.write(
        get_db(), order_id, OrderEventTypes.AUTO_CONFIRMED,
        actor="system", actor_type="system",
        from_status=OrderStatusValues.SHIPPED, to_status=OrderStatusValues.DELIVERED,
        metadata={"autoCaptured": True, "cutoffDays": AUTO_CONFIRM_DAYS},
    )
```

```
[MEDIUM] functions/handlers/orders.py:2005–2009
PROBLEM: on_order_status_changed Firestore trigger applies transactional dedup (NOTIFICATIONS_SENT) only when orderStatus changes. When only paymentStatus changes (line 2007), _handle_payment_status_email() is called directly with NO dedup. On Firestore trigger retry, buyer receives duplicate refund/failure emails.
FIX: Apply the same transactional dedup pattern to payment-status email sends, using a composite key like f"payment_{new_payment_status}" in the NOTIFICATIONS_SENT array.
```

```
[MEDIUM] functions/cron_jobs.py:654–655
PROBLEM: _run_expired_authorizations restores stock from pre-transaction order_data.get(Fields.ITEMS) (line 655), not from fresh_data returned inside the transaction. If items changed between the initial stream fetch and the transactional lock, wrong quantities are restored.
FIX: Return items from the transactional function:
    # In try_expire_order, return items too:
    return "locked", stock_already_restored, fresh_data.get(Fields.ITEMS, [])
    # Then use returned items for the stock batch.
```

```
[MEDIUM] functions/handlers/orders.py:1168
PROBLEM: OrderEvent.write() in refund_order_item hardcodes actor_type="admin" — sellers can also call this endpoint. All seller-initiated refund events are incorrectly attributed to admins in the audit log.
FIX: Determine actor type dynamically:
    actor_type = "admin" if is_admin else "seller"
    OrderEvent.write(get_db(), order_id, OrderEventTypes.REFUND_ISSUED, actor=user_id, actor_type=actor_type, ...)
```

```
[BONUS] lib/features/orders/orders_screen.dart:50,52,77,79,600,608,613,1013,1014,1021
PROBLEM: Multiple hardcoded Color(0xFF06B6D4), Color(0xFF14B8A6), Color(0xFF3A3A50), Color(0xFFE0E4EE) for "shipped" and "in_transit" statuses and timeline inactive steps. Violates DesignTokens-only rule; dark mode and theme changes won't propagate.
FIX: Add DesignTokens.shipped = Color(0xFF06B6D4) and DesignTokens.inTransit = Color(0xFF14B8A6) to design_tokens.dart and replace all hardcoded Color(0xFF...) references.
```

```
[BONUS] functions/cron_jobs.py:362–376
PROBLEM: Inside _run_auto_capture(), seller_ref.get() (line 362) is called per seller inside a per-order loop. With 250 orders × avg 2 sellers each = 500 individual Firestore reads per cron run. At 100M users/year this is significant cost and latency.
FIX: Collect all unique seller_ids from the batch before the loop, then use db.get_all():
    all_seller_ids = list({item[Fields.SELLER_ID] for order_doc in all_orders for item in order_doc.to_dict().get(Fields.ITEMS, [])})
    seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in all_seller_ids]
    seller_docs = {doc.id: doc for doc in get_db().get_all(seller_refs)}
    # Then lookup: seller_doc = seller_docs.get(seller_id)
```

```
[BONUS] lib/features/orders/seller_orders_screen.dart:160
PROBLEM: IconButton at line 160 (forum/QA button in the seller AppBar) has no tooltip parameter. Accessibility violation — screen readers cannot identify the button purpose.
FIX: Wrap in a Tooltip or add tooltip parameter:
    IconButton(
      tooltip: 'seller.qa_questions'.tr(),
      icon: const Icon(Icons.forum_outlined),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.sellerProducts),
    )
```

```
[BONUS] functions/handlers/orders.py:2994–2995
PROBLEM: process_dispute_created sends seller notification emails using order_doc.to_dict() AFTER order_doc.reference.update() (line 2982). The local order_doc snapshot is stale — it was last fetched during the Firestore stream at line 2824 and does not reflect the disputedAt/orderStatus fields just written.
FIX: Fetch fresh data for the email call or, since only items are needed for seller_ids, read them from the pre-update snapshot (which is fine since items don't change in update()):
    seller_ids = set(item.get(Fields.SELLER_ID) for item in order_data_for_dispute.get(Fields.ITEMS, []))
    # Use order_data_for_dispute (line 2839) instead of re-calling order_doc.to_dict()
```

```
[BONUS] functions/handlers/orders.py:991
PROBLEM: item_price_cents = round(item_data[Fields.PRICE] * 100) converts a float price to cents. If price is a float stored in Firestore (e.g., 4.99), round(4.99 * 100) = 499 but floating-point math can give 498.99999... = 499 or 500 depending on the value. Pydantic model stores price as float, not cents. Risk of ±1¢ refund errors compounding across partial refunds.
FIX: Store prices as integer cents in OrderItem (align with the rest of the money-as-cents convention). At minimum, use Decimal: from decimal import Decimal; item_price_cents = int(Decimal(str(item_data[Fields.PRICE])) * 100).
```

Here is the full audit:

---

```
[CRITICAL] orders_screen.dart:1313
PROBLEM: Uses `FirebaseFunctions.instanceFor(region: 'us-central1')` directly instead of the app-wide `firebaseFunctionsProvider`, bypassing any emulator/dev/staging environment routing — download calls always hit production.
FIX: Replace `FirebaseFunctions.instanceFor(region: 'us-central1')` with `ref.read(firebaseFunctionsProvider)` in both `_SoftwareDownloadLinksState._download` and `_BookDownloadButtonState._download`.
```

```
[CRITICAL] orders_screen.dart:1314,1384
PROBLEM: Cloud function names `'generate_software_download_session'` and `'generate_book_download_session'` are magic strings; any typo silently fails at runtime, and they're not in `CloudFunctionEndpoints`.
FIX: Add `GENERATE_SOFTWARE_DOWNLOAD_SESSION = 'generate_software_download_session'` and `GENERATE_BOOK_DOWNLOAD_SESSION = 'generate_book_download_session'` to `CloudFunctionEndpoints`, then use those constants.
```

```
[CRITICAL] productdetails_screen.dart:1378
PROBLEM: Subscription price `'CAD $7.86/month'` is hardcoded in the paywall description — a pricing change requires a code deploy.
FIX: Move price to a constant (e.g., `SubscriptionConfig.MONTHLY_PRICE_DISPLAY = 'CAD \$7.86/month'`) in `schema_constants.dart/py` and reference it: `description: 'qa.paywall_description'.tr(args: [SubscriptionConfig.monthlyPriceDisplay])`.
```

```
[HIGH] checkout_screen.dart:873
PROBLEM: `CircularProgressIndicator` used inside the coupon apply button — banned by design system; breaks visual consistency.
FIX: Replace `const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))` with `const ModernLoadingIndicator(size: 18, strokeWidth: 2, centered: false)`.
```

```
[HIGH] orders_screen.dart:50,52,77,79
PROBLEM: Status colors `const Color(0xFF06B6D4)` (shipped) and `const Color(0xFF14B8A6)` (in-transit) are hardcoded hex — banned; they won't respect theme and will drift from DesignTokens.
FIX: Add `static const Color statusShipped = Color(0xFF06B6D4);` and `static const Color statusInTransit = Color(0xFF14B8A6);` to `DesignTokens`, then reference `DesignTokens.statusShipped` / `DesignTokens.statusInTransit` at those lines.
```

```
[HIGH] checkout_screen.dart:152
PROBLEM: `Colors.white` hardcoded in `_CheckoutButton` container decoration — banned color literal.
FIX: Replace `Colors.white` with `DesignTokens.surface`.
```

```
[HIGH] orders_screen.dart:1249
PROBLEM: `Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128)` — not a DesignToken color, uses deprecated `.withAlpha()` API.
FIX: Replace with `DesignTokens.surfaceVariant.withValues(alpha: 0.5)` (add `surfaceVariant` to DesignTokens if missing).
```

```
[HIGH] productdetails_screen.dart — entire file
PROBLEM: No "Customers also bought" / "Similar items" section — major product discovery gap vs. Amazon/AliExpress/Etsy; directly impacts conversion.
FIX: Add a `_SimilarProductsSection` widget below the reviews section that queries Algolia with the same category + excludes current productId, rendered as a horizontal `ListView` of `ModernProductCard`.
```

```
[HIGH] checkout_screen.dart — no free-shipping threshold banner
PROBLEM: No "Spend $X more for free shipping" indicator — Amazon/Shopify baseline feature; missing it increases cart abandonment.
FIX: Add a `_FreeShippingProgress` widget in the order summary section: `if (subtotal < threshold) LinearProgressIndicator(value: subtotal/threshold)` + localized label `'checkout.free_shipping_progress'.tr(args: ['${(threshold - subtotal).toStringAsFixed(2)}'])`.
```

```
[HIGH] checkout_screen.dart — no buyer protection notice before payment
PROBLEM: Only a "Secure Payment / Stripe" badge shown; no dispute/refund policy surfaced at checkout — AliExpress/eBay explicitly show buyer protection policy here to build trust and reduce disputes.
FIX: Add a `_BuyerProtectionBanner` widget above the place-order button: icon + `'checkout.buyer_protection'.tr()` + `GestureDetector` linking to the returns policy page.
```

```
[HIGH] home_screen.dart — no wishlist/save-for-later
PROBLEM: No wishlist feature visible on home or product card — every major platform has this; absence directly loses intent-to-buy signals and repeat visits.
FIX: Add a heart `IconButton` to `ModernProductCard` that calls `ref.read(favoritesProvider.notifier).toggle(productId)`; render filled/outline based on `ref.watch(isFavoriteProvider(productId))`.
```

```
[MEDIUM] checkout_provider.dart:152
PROBLEM: Comment reads `// Fallback to legacy address` — "legacy" is forbidden per CLAUDE.md rule 2.
FIX: Change comment to `// Fallback to address field on user doc (addresses subcollection is empty)`.
```

```
[MEDIUM] orders_screen.dart:1315
PROBLEM: `{'licenseKey': widget.item.licenseKey, 'platform': platform}` — magic string key `'licenseKey'` and `'platform'` not from `Fields`/`ApiKeys`.
FIX: Add `LICENSE_KEY = 'licenseKey'` and `PLATFORM = 'platform'` to `ApiKeys` in both `schema_constants.py` and `schema_constants.dart`, then use `{ApiKeys.licenseKey: ..., ApiKeys.platform: platform}`.
```

```
[MEDIUM] orders_screen.dart:1256,1268,1273,1343,1407
PROBLEM: Strings `'License Key'`, `'Copy'`, `'License key copied'`, `'Download'`, `'Download Book'` are hardcoded English — not localized via `.tr()`.
FIX: Add translation keys (`orders.license_key`, `common.copy`, `orders.license_key_copied`, `common.download`, `orders.download_book`) and replace literals with `.tr()` calls.
```

```
[MEDIUM] modern_product_card.dart:102
PROBLEM: `'Trending'` badge text is hardcoded English — not localized.
FIX: Replace `'Trending'` with `'product.trending'.tr()`.
```

```
[MEDIUM] productdetails_screen.dart:1376
PROBLEM: `featureName: 'Ask Questions'` is hardcoded English — not localized.
FIX: Replace with `featureName: 'qa.feature_name'.tr()`.
```

```
[MEDIUM] home_screen.dart:944
PROBLEM: `Key('product_card_${product.name}')` — product name is not unique; two products with the same name get the same key, causing Flutter widget tree bugs and list animation issues.
FIX: Change to `Key('product_card_${product.productId}')`.
```

```
[MEDIUM] subscription_provider.dart:60-65
PROBLEM: `updateNotificationPreferences` writes directly to `Firestore.collection(Collections.users).doc(uid).update(...)` — bypasses `UserRepository`, violates layered architecture, and skips any validation.
FIX: Add `updateNotificationPreferences({bool? notifyNewProducts, bool? notifyTrending})` to `UserRepository` and call it via `_ref.read(userRepositoryProvider).updateNotificationPreferences(...)`.
```

```
[MEDIUM] productdetails_screen.dart — review section
PROBLEM: Review system lacks verified purchase badge and photo reviews — Amazon standard; absence reduces buyer trust signals for new marketplace.
FIX: Add `verifiedPurchase: bool` field to `ProductRating` model; show a "Verified Purchase" chip (`DesignTokens.success` color) on reviews where `verifiedPurchase == true`. Photo reviews require `reviewImageUrls: List<String>` field and a `_ReviewImages` horizontal scroll widget.
```

```
[MEDIUM] productdetails_screen.dart — seller section
PROBLEM: Seller profile chip shows name only; no response rate, avg ship time, or positive feedback % — eBay/Etsy baseline trust signals.
FIX: Read `seller_metrics/{sellerId}` doc (already in schema) and display `avgResponseHours`, `avgShipDays`, `positiveRatePct` in the seller info row on product detail.
```

```
[LOW] checkout_provider.dart:389
PROBLEM: Local delivery radius `50` km is a magic number — hardcoded, untestable, and not queryable from config.
FIX: Add `LOCAL_DELIVERY_RADIUS_KM = 50` to `AppConfig` in `schema_constants.py`/`.dart`, then use `AppConfig.localDeliveryRadiusKm` at that line.
```

```
[LOW] productdetails_screen.dart:69
PROBLEM: Share text `'Check out ${product.name} on Origna!\n${envConfig.baseUrl}/p/${product.slug}'` is hardcoded English — not localized.
FIX: Add translation key `product.share_text` with `{name}` and `{url}` placeholders and use `.tr(args: [product.name, '${envConfig.baseUrl}/p/${product.slug}'])`.
```

```
[LOW] orders_screen.dart — abandoned cart
PROBLEM: No abandoned cart recovery mechanism visible (no email trigger on cart with items + no checkout for 1h/24h) — Shopify/Amazon standard; silent revenue loss.
FIX: Add a Firestore-triggered Cloud Function on `users/{uid}/cart` write: if cart is non-empty and `lastCheckoutTimestamp` is older than 1h, enqueue a Mailjet reminder via Cloud Tasks; dedup with idempotency check on `lastAbandonedCartEmailAt` field.
```

```
[BONUS] orders_screen.dart:1249
PROBLEM: `.withAlpha(128)` is deprecated API — should use `.withValues(alpha: 0.502)` (same as all other files correctly use `.withValues(alpha:)`).
FIX: `Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)`.
```

```
[BONUS] orders_screen.dart:1316,1386
PROBLEM: `result.data['downloadUrl'] as String` — unsafe cast; if backend returns null or wrong type on error, throws unhandled `CastError` instead of showing a user-friendly message.
FIX: `final downloadUrl = result.data['downloadUrl'] as String?; if (downloadUrl == null) throw Exception('No download URL');`
```

```
[BONUS] checkout_provider.dart:291,316,328,335,344
PROBLEM: `if (!mounted) return CheckoutError(...)` — `StateNotifier` doesn't have a `mounted` property; this compiles (Dart sees the outer widget's `mounted` via closure) but the check is unreliable. The notifier is `autoDispose`, so it can be disposed mid-flight; the correct guard is checking `ref`'s liveness.
FIX: Remove `!mounted` guards inside the notifier. The `autoDispose` provider will cancel the notifier's state on disposal; wrap the try-block instead with a disposed flag: `bool _disposed = false;` set in `dispose()`, check `if (_disposed) return CheckoutError(...)`.
```

```
[BONUS] home_screen.dart:55-57
PROBLEM: `debugPrint` calls leak internal role/permission state to device logs in production builds — security info exposure.
FIX: Wrap in `assert(() { debugPrint(...); return true; }())` so prints are stripped in release builds, or remove entirely.
```

```
[BONUS] productdetails_screen.dart:36
PROBLEM: `ref.read(productDetailViewModelProvider.notifier)` called directly in `ConsumerWidget.build()` — `ref.read` in build is a lint warning and will not re-subscribe if the notifier is recreated.
FIX: Since the notifier is only used for callbacks, this is acceptable, but add a `// ignore: use_read_to_hold_ref` comment or convert `ProductDetailScreen` to `ConsumerStatefulWidget` and cache the notifier reference in `initState`.
```

```
[BONUS] modern_product_card.dart — no wishlist heart button
PROBLEM: Product card has no save/favorite action — user must navigate into detail page to save a product; all competitor apps have inline wishlist on card.
FIX: Add a `VoidCallback? onToggleFavorite` and `bool isFavorited = false` parameter; render a `Positioned` heart `IconButton` in the top-right image corner with `icon: isFavorited ? Icons.favorite : Icons.favorite_border`.
```

```
[BONUS] checkout_screen.dart — no order review step
PROBLEM: Checkout goes directly from summary → Stripe external page with no "Review your order" confirmation step — <3 taps from PDP is good, but zero chance to catch errors before leaving the app.
FIX: Add an expandable `_OrderReviewSection` with item thumbnails, quantities, and seller names above the place-order button so users can verify without leaving the screen.
```

```
[CRITICAL] functions/handlers/payment_stripe.py:3976
PROBLEM: `stored_fee_rate = PLATFORM_FEE_RATIO` reads the CURRENT module-level config at capture time, not the rate snapshotted at checkout. Comment lies — if PLATFORM_FEE_RATIO changes between checkout and capture, captured orders use the wrong fee rate.
FIX: Snapshot the fee rate on the order doc at checkout (e.g., `Fields.PLATFORM_FEE_RATIO`) and read it here: `stored_fee_rate = order_data.get(Fields.PLATFORM_FEE_RATIO, PLATFORM_FEE_RATIO)`.

[CRITICAL] functions/handlers/orders.py:1081
PROBLEM: `it` is referenced outside the for-loop after a potential non-break exit. If fresh_items has no match for product_id (fresh data changed concurrently), the loop exhausts without break, `it` is the last item, and `is_digital = it.get(Fields.IS_DIGITAL, False)` silently evaluates the wrong item — causing incorrect stock restore for digital products.
FIX: Track the found item explicitly:
```python
found_item = None
for idx, it in enumerate(fresh_items):
    if it[Fields.PRODUCT_ID] == product_id:
        ...
        found_item = it
        break
if found_item is None:
    raise https_fn.HttpsError("not-found", f"Product {product_id} not found in fresh order")
is_digital = found_item.get(Fields.IS_DIGITAL, False)
```

[CRITICAL] functions/handlers/payment_stripe.py:714-716
PROBLEM: N+1 Firestore reads — `product_ref.get()` called inside `for item in items` loop in `create_checkout_session`. At checkout volume (100M users/year), this reads each product individually instead of batch-fetching. 10-item cart = 10 serial round-trips to Firestore.
FIX: Before the loop, batch-read all product docs: `product_docs = {doc.id: doc for doc in get_db().get_all([get_db().collection(Collections.PRODUCTS).document(i[Fields.PRODUCT_ID]) for i in items])}`, then use `product_docs.get(item[Fields.PRODUCT_ID])` inside the loop.

[HIGH] functions/handlers/orders.py:780-804
PROBLEM: `cancel_order` has a full AUTHORIZED path that voids a PaymentIntent — but Payment Auditor pattern #1 states `paymentStatus` is ALWAYS `'captured'` immediately at checkout, never AUTHORIZED. This is unreachable code under auto-capture that masks the real flow and would silently misbehave if the flag ever changes.
FIX: Remove the AUTHORIZED branch or replace with an explicit guard:
```python
elif payment_status == PaymentStatusValues.AUTHORIZED:
    raise https_fn.HttpsError("internal", "Unexpected AUTHORIZED status in auto-capture mode — manual review required")
```

[HIGH] functions/handlers/orders.py:1166
PROBLEM: `actor_type="admin"` is hardcoded in `refund_order_item` `OrderEvent.write` call. Item sellers can also call this function (`is_item_seller` path at line 930), so the audit trail lies — seller refunds are logged as admin actions.
FIX: `actor_type = "admin" if is_admin else "seller"` and pass it dynamically.

[HIGH] origna_gta/lib/screens/checkout_screen.dart:735
PROBLEM: Total price calculation (`getTaxRate(state) * (effective + shippingCost) + shippingCost`) is inside `_OrderSummary` StatelessWidget `build()` — business logic in UI, violates MVVM. Also diverges from `checkout_provider.dart:calculateDetailedTaxes` (uses `calculateDetailedTaxes`, not `getTaxRate`), creating UI/backend tax inconsistency before checkout.
FIX: Remove inline total calc from widget; replace with `ref.watch(checkoutTotalProvider)` which reads the authoritative total from the notifier.

[HIGH] origna_gta/lib/screens/checkout_screen.dart:778
PROBLEM: `taxConfig[province] ?? {'HST': 0.13}` — hardcoded magic values for tax names and rates. Not sourced from `BusinessRules.TAX_RATES` or schema_constants. A rate change in schema_constants won't be reflected here, causing UI/backend tax display divergence.
FIX: Replace `taxConfig` reference with `BusinessRules.taxRates[province] ?? BusinessRules.taxRates[BusinessRules.defaultProvince]` (matching whatever constant name is in schema_constants.dart).

[HIGH] functions/handlers/payment_stripe.py:395
PROBLEM: `calculate_tax_with_stripe` calls `stripe.tax.Calculation.create(...)` on every invocation with no caching. Per Cost Monitor pattern #3, this costs $0.50/call. Called at every checkout — at scale this is a direct operating cost issue.
FIX: Cache by `(province_code, tax_code_set_hash)` in a module-level dict (TTL ~1h): `_tax_cache: dict[str, tuple[int, dict, list, bool]] = {}`. Key = `f"{state}:{sorted_item_tax_codes}"`. Return cached result if fresh.

[HIGH] functions/handlers/orders.py:966-988
PROBLEM: `refund_order_item` duplicates the return-window check inline instead of calling the shared helper `_assert_within_return_window` defined at line 1660. These two implementations have diverged — the inline version at line 969 checks `hasattr(delivered_at, "timestamp")` (Firestore Timestamp object); the helper version at line 1664 checks `isinstance(delivered_at, str)`. Different code paths for the same logic = future drift bugs.
FIX: Remove inline check (lines 966-988), call `_assert_within_return_window(item_data)` instead.

[MEDIUM] functions/handlers/orders.py:810-827 and 1460-1479
PROBLEM: Stock restore logic (iterate items, build stock_patch, handle warehouse and inventoryLevels) is copy-pasted verbatim between `cancel_order` and the shipping rejection path of `approve_shipping_cost`. Any fix to one is likely to miss the other.
FIX: Extract to `_restore_stock_to_batch(items: list, batch, skip_digital: bool = False)` helper and call it from both locations.

[MEDIUM] functions/handlers/orders.py:61-89, admin.py:46-84, products.py:74-93, payment_stripe.py:104-153
PROBLEM: `get_db()`, `get_server_timestamp()`, `get_firestore()` are copy-pasted across all 4 handler files with identical implementation. A bug fix in one won't propagate to others.
FIX: Move all 3 helpers to `utils/db.py` and import from there: `from utils.db import get_db, get_server_timestamp, get_firestore`.

[MEDIUM] origna_gta/lib/screens/checkout_screen.dart:873
PROBLEM: `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` inside coupon apply button — raw `CircularProgressIndicator` is banned by Frontend Auditor pattern #8. Should use `ModernLoadingIndicator`.
FIX: Replace with `ModernLoadingIndicator(size: 18, strokeWidth: 2, color: Colors.white, centered: false)`.

[MEDIUM] origna_gta/lib/features/seller/seller_orders_viewmodel.dart:14
PROBLEM: Method `updateShippingAndCapture` does not capture anything — it updates shipping cost and tracking number. Misleading name creates dangerous confusion; a caller might expect Stripe capture to have occurred after calling it.
FIX: Rename to `updateShippingAndTracking` throughout (viewmodel + all call sites).

[MEDIUM] origna_gta/lib/screens/orders_screen.dart:50,52
PROBLEM: Hardcoded colors `const Color(0xFF06B6D4)` for `shipped` and `const Color(0xFF14B8A6)` for `inTransit` statuses — not from `DesignTokens`. Violates UI/UX Expert pattern #1 and will be missed in theme changes.
FIX: Add `DesignTokens.statusShipped` and `DesignTokens.statusInTransit` tokens, replace all 4 occurrences (lines 50, 52, 77, 79, 601, 603).

[LOW] functions/handlers/payment_stripe.py:457 and 472
PROBLEM: `tax_amount_cents = calculation.tax_amount_exclusive` assigned at line 457, then overwritten at line 472 with the same expression. Dead assignment at line 457.
FIX: Remove line 457 (`tax_amount_cents = calculation.tax_amount_exclusive`), keep only line 472.

[LOW] functions/handlers/orders.py:1210
PROBLEM: `data.get("expectedCostCents")` — magic string `"expectedCostCents"` not using a constant from `ApiKeys` or `Fields`.
FIX: Add `EXPECTED_COST_CENTS = "expectedCostCents"` to `ApiKeys` in schema_constants and use `data.get(ApiKeys.EXPECTED_COST_CENTS)`.

[BONUS] functions/handlers/orders.py:1808
PROBLEM: `action` parameter in `approve_return_request` is `data.get("action", "approve")` — magic string `"action"` not from schema_constants. Two valid values `"approve"` and `"mark_received"` are also undeclared magic strings.
FIX: Add `ApiKeys.ACTION = "action"` and `ReturnActionValues.APPROVE = "approve"`, `ReturnActionValues.MARK_RECEIVED = "mark_received"` to schema_constants.

[BONUS] functions/handlers/payment_stripe.py:3885
PROBLEM: `payment_intent_id.startswith("pi_3")` — hardcoded Stripe ID prefix used to detect emulator fake PIs. Fragile; Stripe could change the format, and this silently breaks emulator mode.
FIX: Use a dedicated emulator flag field on the order (`Fields.IS_EMULATOR_ORDER = True`) set at checkout creation time, then check `order_data.get(Fields.IS_EMULATOR_ORDER, False)` instead.

[BONUS] origna_gta/lib/screens/orders_screen.dart:276-921
PROBLEM: `_BuyerOrderCardState` tracks `_isConfirming` / `_confirmingItemId` as local widget state — this is business/async state that belongs in a ViewModel (`BuyerOrdersViewModel`). If widget rebuilds (e.g., stream update) during confirmation, state is lost and UI shows wrong loading indicator.
FIX: Move confirmation loading state into `BuyerOrdersViewModel` with `(isConfirming: bool, confirmingItemId: String?)` fields, watch it in the widget.

[BONUS] functions/handlers/payment_stripe.py:74-77
PROBLEM: `_check_premium_from_sub` function is defined but appears unused anywhere in the provided codebase. Dead code increases maintenance surface.
FIX: Search all handlers for callers; if none exist, delete the function.

[BONUS] functions/handlers/orders.py:92-171
PROBLEM: `send_push_notification` is defined in `orders.py` but is a cross-cutting infrastructure concern called from multiple places in orders.py (including return request handlers). Belongs in `services/push_service.py` for reuse without creating import cycles.
FIX: Move to `services/push_service.py`, import in orders.py: `from services.push_service import send_push_notification`.

[BONUS] functions/handlers/orders.py:1810 (approve_return_request)
PROBLEM: No rate limiting on `approve_return_request` and `reject_return_request` handlers — every other mutation handler has a rate limiter, but these two are missing it. A compromised seller account could flood approvals.
FIX: Add `RateLimiter.check_rate_limit(user_id, "approve_return_request", max_requests=20, window_minutes=5)` at the top of both handlers (matching the pattern from `create_return_request`).

[BONUS] origna_gta/lib/screens/checkout_screen.dart:768
PROBLEM: `'Coupon ($couponCode)'` — hardcoded English string not wrapped in `.tr()` for i18n. All visible user text must use `easy_localization`.
FIX: Add `checkout.coupon_applied_label` translation key and use `'checkout.coupon_applied_label'.tr(namedArgs: {'code': couponCode})`.

[BONUS] functions/handlers/orders.py (approve_return_request ~line 1870-1875)
PROBLEM: Stock restore on `mark_received` (lines 1870-1875) is NOT atomic with the status update — `return_ref.update(status=received)` then `product_ref.update(stock++)` are separate operations. A crash between them leaves stock unrestored with status=received.
FIX: Use a Firestore batch: `batch = get_db().batch(); batch.update(return_ref, ...); batch.update(product_ref, ...); batch.commit()`.
```
Now I have enough context. Let me compile all findings:```
[CRITICAL] order_repository.dart:53-54
PROBLEM: `?trackingNumber` and `?carrier` are invalid Dart syntax — this file will not compile and updateItemStatus will be dead code.
FIX: Replace null-conditional map entries with conditional spread:
  ...(trackingNumber != null ? {Fields.trackingNumber: trackingNumber} : {}),
  ...(carrier != null ? {Fields.carrier: carrier} : {}),

[HIGH] modern_product_card.dart:94-101
PROBLEM: `Image.network` loads full-resolution images on every card render with no disk cache or memory cache, causing redundant network fetches and high memory usage on a grid of 20+ cards.
FIX: Replace `Image.network(widget.imageUrl, ...)` with `CachedNetworkImage(imageUrl: widget.imageUrl, memCacheWidth: 400, memCacheHeight: 400, ...)` from `cached_network_image`.

[HIGH] products.py:374 + 634
PROBLEM: `user_doc.to_dict().get(Fields.IS_PREMIUM, False)` checks the stale cached boolean on the users doc instead of the authoritative subscriptions doc — a lapsed subscriber can still get premium features.
FIX: Replace both occurrences with `_check_premium_from_sub(user_id)` (already defined at line 74 for this exact purpose). Same fix applies at line 634 inside `submit_product_rating`.

[HIGH] algolia_service.py:472-474
PROBLEM: `delete_products_from_algolia` calls `delete_product` N times sequentially with separate HTTP roundtrips — for a GDPR account deletion of a prolific seller this blocks and risks Cloud Function timeout.
FIX: Replace the loop with a single batch call:
```python
def delete_products_from_algolia(product_ids: list[str]) -> int:
    if not product_ids:
        return 0
    try:
        client = _get_algolia_client()
        _run_async(client.delete_objects(index_name=_get_index_name(), object_ids=product_ids))
        return len(product_ids)
    except Exception as e:
        for pid in product_ids:
            _log_sync_failure(pid, "delete", str(e), 1)
        return 0
```

[HIGH] products.py:1641
PROBLEM: `_notify_premium_users_new_product` reads only the legacy `Fields.FCM_TOKEN` top-level field per user, skipping users who have migrated to the `fcm_tokens` subcollection for multi-device support — those users receive no new-product push.
FIX: After collecting `tokens` from the user doc field (line 1641), fan out to the subcollection exactly as `send_push_notification` in orders.py does (lines 119–130), or extract the shared logic into a helper.

[MEDIUM] home_screen.dart:613
PROBLEM: `_searchController.addListener(() => setState(() {}))` triggers a full `_HomeScreenState` rebuild on every keystroke just to toggle the clear-button icon — this rebuilds the entire scaffold including category bar and product grid.
FIX: Extract the clear-button into its own `StatefulWidget` (or `ValueListenableBuilder<TextEditingController>`) so only that widget rebuilds:
```dart
ValueListenableBuilder<TextEditingController>(
  valueListenable: _searchController,
  builder: (_, ctrl, __) => ctrl.text.isNotEmpty ? IconButton(...) : const SizedBox.shrink(),
)
```
Remove the `addListener` from `initState`.

[MEDIUM] products.py:159-165 (also 473-476, 602-606)
PROBLEM: `RateLimiter(get_db())` is instantiated inside each Cloud Function handler body — on warm instances this wastes an object allocation per invocation; on cold starts the cost is minimal but the pattern is incorrect.
FIX: Move to module-level lazy singleton mirroring `_rate_limiter` in `payment_stripe.py`:
```python
_rate_limiter: RateLimiter | None = None
def get_rate_limiter():
    global _rate_limiter
    if _rate_limiter is None:
        from services.rate_limiter import RateLimiter
        _rate_limiter = RateLimiter(get_db())
    return _rate_limiter
```

[MEDIUM] algolia_service.py:152-155
PROBLEM: `_log_sync_failure` calls `fs.client()` every invocation instead of reusing the shared `get_db()` — creates a new Firestore client on each DLQ write, bypassing the module-level cache.
FIX: Replace `db = fs.client()` with `from firebase_admin import firestore as fs; db = fs.client()` → instead just call the already-defined `get_db()` from `products.py` or pass db as a parameter.
ALSO: algolia_service.py has no `get_db()` helper — add `from firebase_admin import firestore as _fs; _db = _fs.client()` lazy singleton and use it in `_log_sync_failure`.

[BONUS] home_screen.dart:944
PROBLEM: `key: Key('product_card_${product.name}')` uses mutable `name` as the key — if a seller renames a product while the user is browsing, Flutter sees two different keys and unmounts/remounts the widget, losing animation state and causing layout jank.
FIX: `key: Key('product_card_${product.productId}')` — productId is immutable and unique.

[BONUS] home_screen.dart:55-57
PROBLEM: Three `debugPrint` calls in `_AddProductButton.build()` are unconditional — they fire on every rebuild in production, polluting logs and adding overhead.
FIX: Wrap with `if (kDebugMode)` or remove entirely before launch.

[BONUS] products.py:1532
PROBLEM: `_notify_admins_new_product` queries all admin users with no `.limit()` — a future multi-admin configuration (e.g. 100+ support admins) will read and email all of them on every product submission, potentially exhausting the Mailjet free-tier 200/day limit in one batch.
FIX: Add `.limit(20)` to the query and document the admin count expectation, or introduce an `adminNotificationEmails` config list.

[BONUS] products.py:1553
PROBLEM: Admin notification email hardcodes `https://orignagta.ca/admin` — the correct production domain per `CLAUDE.md` is `www.orignagta.ca`, and this string bypasses the `BASE_URL` config constant.
FIX: Replace with `f"{BASE_URL}/admin"` using the imported `BASE_URL` from `config`.

[BONUS] algolia_service.py:171-212
PROBLEM: `index_product` calls `time.sleep(wait)` inside a Cloud Function trigger — blocking sleep in a Cloud Function wastes billed compute time while doing nothing; exponential backoff sleep of up to 4 seconds per retry can accumulate across retries.
FIX: Use Algolia's built-in retry logic (`algoliasearch` client already has automatic retry with backoff); remove the manual `time.sleep` loop and rely on the client's `max_retries` configuration, or push failed items immediately to the DLQ and retry via a separate cron.

[BONUS] order_repository.dart:77-93
PROBLEM: `watchBuyerOrders` uses a `whereIn` on `paymentStatus` with 6 values but omits `orderStatus` filter — a buyer will see expired/failed orders that were already hidden in the previous implementation, degrading UX.
FIX: Confirm with product requirements whether `authorizationExpired` and `cancelled` orders should be visible to buyers; if not, remove them from the `whereIn` list and update the index accordingly.
```

Now let me read the remaining key files:---

**AUDIT FINDINGS**

---

```
[CRITICAL] functions/handlers/payment_stripe.py:2006
PROBLEM: process_checkout_session_completed reads order status then updates outside a Firestore transaction — Stripe's guaranteed-at-least-once webhook delivery means two concurrent retries both read PENDING, both proceed to _execute_seller_payouts, resulting in double payout (idempotency key on Transfer saves Stripe, but payout Firestore records can be duplicated and order_ref.update is not atomic).
FIX: Wrap the status check + order_ref.update in a @firestore.transactional block:
```python
@get_transactional()
def _confirm_in_txn(txn):
    snap = order_ref.get(transaction=txn)
    if snap.to_dict().get(Fields.ORDER_STATUS) != OrderStatusValues.PENDING:
        return False
    txn.update(order_ref, update_data)
    return True
if not _confirm_in_txn(get_db().transaction()):
    return f"Order {order_id} already processed"
```

```
[CRITICAL] functions/handlers/payment_stripe.py:919
PROBLEM: Coupon usage limit check (_coupon_within_limits) and the actual usage increment are not in the same Firestore transaction — two simultaneous checkouts with the same last-use coupon both pass validation before either increments the counter.
FIX: After coupon validation, atomically claim the coupon slot with a transaction:
```python
@get_transactional()
def _claim_coupon(txn):
    snap = get_db().collection(Collections.COUPONS).document(code).get(transaction=txn)
    d = snap.to_dict() or {}
    if d.get(Fields.USAGE_COUNT, 0) >= d.get(Fields.MAX_USES, float('inf')):
        return False
    txn.update(snap.reference, {Fields.USAGE_COUNT: get_firestore().Increment(1)})
    return True
coupon_claimed = _claim_coupon(get_db().transaction())
if not coupon_claimed:
    coupon_code = None; discount_amount_cents = 0
```

```
[CRITICAL] functions/handlers/orders.py:745
PROBLEM: cancel_order acquires a CANCELLING lock in a transaction (line 720-743) but stock restore + final status update is a separate batch (line 808-841). A process crash between lock and batch leaves the order permanently stuck in CANCELLING state — no cleanup cron, no timeout, no recovery path.
FIX: Use a single @firestore.transactional for the lock + stock restore + status update, or add a cron that detects CANCELLING orders older than 5 minutes and resets them to AUTHORIZED/CAPTURED.
```

```
[HIGH] functions/handlers/payment_stripe.py:714
PROBLEM: create_checkout_session fetches each product individually in a loop (N+1 reads) before the reserve_stock_transaction, then the transaction re-reads them. At cart size 10 = 20 Firestore reads instead of 10. At 100M orders/year this costs roughly $12k/year in extra reads.
FIX: Replace the per-item get() with a batch read before the loop:
```python
product_refs = [get_db().collection(Collections.PRODUCTS).document(i[Fields.PRODUCT_ID]) for i in items]
product_docs = {doc.id: doc for doc in get_db().get_all(product_refs)}
# then: product_doc = product_docs.get(item[Fields.PRODUCT_ID])
```

```
[HIGH] functions/handlers/payment_stripe.py:2062
PROBLEM: process_checkout_session_completed re-validates products with individual get() per item and individual get() per seller (N+1) inside a webhook handler — for a 20-item multi-seller order that's 40 reads per webhook.
FIX: Batch all product and seller reads before the loop using get_all():
```python
prod_refs = [get_db().collection(Collections.PRODUCTS).document(i[Fields.PRODUCT_ID]) for i in items]
sel_refs  = [get_db().collection(Collections.USERS).document(i[Fields.SELLER_ID]) for i in items]
all_docs  = {d.id: d for d in get_db().get_all(prod_refs + sel_refs)}
```

```
[HIGH] functions/models/order.py:294
PROBLEM: actualCost: float | None violates the schema rule "money fields must be int cents". Field name doesn't end in Cents and stores a float dollar value — inconsistent with the rest of the schema (actualShippingCents is int).
FIX: Rename to actualCostCents: int | None = None and update every write site + Dart model (order_models.dart:216 double? actualCost → int? actualCostCents).
ALSO: order_models.dart:216
```

```
[HIGH] functions/handlers/orders.py:376
PROBLEM: cron_jobs.py reads CHARGES_ENABLED from users/{uid} (seller_data.get(Fields.CHARGES_ENABLED)) but per CLAUDE.md schema, CHARGES_ENABLED lives in seller_profiles/{uid}. This means a seller can have charges_enabled=False in seller_profiles (Stripe revoked) but pass the payout check if the users doc cached True.
FIX: Fetch seller_profiles/{uid} for the chargesEnabled check in cron:
```python
sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(seller_id).get()
seller_charges_ok = (sp_doc.to_dict() or {}).get(Fields.CHARGES_ENABLED, False) if sp_doc.exists else False
```
ALSO: functions/handlers/cron_jobs.py:376

```
[HIGH] lib/features/checkout/checkout_provider.dart:226
PROBLEM: Email verification is enforced only on the frontend (authRepository.isEmailVerified()). The backend create_checkout_session handler has no equivalent check — a malicious actor calling the Cloud Function directly bypasses it and creates orders without a verified email.
FIX: Add to the top of create_checkout_session handler:
```python
user_record = auth.get_user(user_id)
if not user_record.email_verified:
    raise https_fn.HttpsError("failed-precondition", "Email address must be verified before checkout")
```

```
[MEDIUM] lib/models/generated/order_models.dart:383
PROBLEM: refundAmountCents is parsed as _safeInt(data[Fields.orderRefundCents]) but Python Order model writes the field as refundAmountCents. If Fields.orderRefundCents != Fields.refundAmountCents, refund amount always reads as 0 on frontend.
FIX: Change to _safeInt(data[Fields.refundAmountCents]) and verify Fields.orderRefundCents is removed from schema_constants.dart.
```

```
[MEDIUM] functions/handlers/cron_jobs.py:301
PROBLEM: Auto-confirming SHIPPED → DELIVERED modifies items list in Python memory and writes it back without a Firestore transaction. If two Cloud Function instances escape the cron lock (lock TTL expiry race), both could write conflicting items arrays, corrupting per-item status/timestamps.
FIX: Wrap the SHIPPED auto-confirm write in a @firestore.transactional block reading fresh items before writing.
```

```
[MEDIUM] functions/handlers/orders.py:255
PROBLEM: order_data[Fields.ORDER_STATUS] at line 255 and order_data[Fields.ITEMS] at line 272 use direct dict access — KeyError crash if Firestore doc is missing these fields (data corruption or schema evolution).
FIX: Replace with order_data.get(Fields.ORDER_STATUS, OrderStatusValues.PENDING) and order_data.get(Fields.ITEMS, []).
```

```
[BONUS] functions/handlers/cron_jobs.py:1753
PROBLEM: _notify_trending_products reads single-device Fields.FCM_TOKEN field from user docs, ignoring the multi-device fcm_tokens subcollection used everywhere else (orders.py:119). Premium users with multiple devices only get notified on their first-registered device.
FIX: Use the same send_push_notification() helper from orders.py that already handles multi-device.
```

```
[BONUS] lib/features/checkout/checkout_provider.dart:382
PROBLEM: _checkLocalDelivery silently continues (skips item) when seller geo coords are missing — the function returns true (local delivery available) even if only 0 out of N sellers have coordinates. This can expose express/same-day delivery options to buyers when actual shipping distance is unknown.
FIX: Count missing-coords items separately; if any seller has no coords, return false (fail-safe):
```dart
if (sellerAddr.latitude == null || sellerAddr.longitude == null) {
  return false; // unknown distance = not local
}
```

```
[BONUS] functions/handlers/payment_stripe.py:741
PROBLEM: Price integrity check uses float subtraction (abs(db_price - client_price) > 0.01) where both values are floats loaded from Firestore. Floating-point representation errors can cause legitimate prices like $9.99 to fail the check (e.g., 9.99 - 9.99 = 2.2e-16 ≠ 0 but passes; however 3 * $3.33 = 9.99 vs 9.990000000000001 could fail).
FIX: Compare in integer cents: abs(round(db_price * 100) - round(client_price * 100)) > 1.
```

```
[BONUS] functions/handlers/orders.py:383
PROBLEM: refundAmountCents field in Order.py is named refundAmountCents but order_models.dart line 207 stores it as `refundAmountCents` and reads it using Fields.orderRefundCents — cross-stack field name discrepancy confirmed (see MEDIUM finding above; schema_constants needs to reconcile which constant maps to which Firestore field name).
```

```
[BONUS] functions/handlers/payment_stripe.py:74
PROBLEM: _check_premium_from_sub() is defined but only called in specific handlers — the pattern of checking premium from the authoritative subscriptions doc is not enforced uniformly across all premium-gated handlers. Any handler that instead reads user.isPremium from the users doc is stale-cache vulnerable.
FIX: Replace all user_data.get(Fields.IS_PREMIUM) checks in payment handlers with _check_premium_from_sub(uid).
```

```
[BONUS] lib/features/seller_orders/seller_orders_viewmodel.dart:33
PROBLEM: updateShippingAndCapture calls repository.updateItemStatus with OrderItemIdValues.all as itemId — if this is a sentinel value processed server-side to update ALL items, it may bypass per-item authorization (item_seller_id == user_id check in update_item_status handler). Verify backend handles 'all' sentinel with the same auth rules as individual item updates.
FIX: Confirm backend update_item_status explicitly handles OrderItemIdValues.all with seller ownership checks across ALL matching items, not just a single item lookup.
```

Now I have enough context. Let me also check the schema_constants and database_schema briefly.Based on my thorough review of all files, here are the findings:

---

```
[CRITICAL] orders.py:1779 + 1853 + 1946
PROBLEM: submit_return_request, approve_return_request, and reject_return_request each send a push notification directly via send_push_notification(), THEN their Firestore write triggers on_return_request_status_changed, which claims the slot via _claim_return_notification() and sends a SECOND push — the handler never writes to notifications_sent before its own push, so the trigger's dedup never fires.
FIX: Remove the inline send_push_notification() calls from all three handlers and rely exclusively on the Firestore trigger, OR atomically mark notifications_sent BEFORE sending in each handler:
    return_ref.update({
        Fields.RETURN_STATUS: ...,
        Fields.NOTIFICATIONS_SENT: firestore.ArrayUnion([new_status]),
    })
    send_push_notification(...)  # trigger will now skip this status
ALSO: orders.py:2334 (trigger sends 2nd push for REQUESTED), :2344 (APPROVED), :2351 (REJECTED)
```

```
[HIGH] orders.py:2056
PROBLEM: on_order_status_changed sends buyer email+push for CONFIRMED but never notifies sellers — sellers have no idea a new order came in until the buyer or another event fires.
FIX: After the buyer notification block for CONFIRMED, batch-read seller docs and send push:
    seller_ids = set(item.get(Fields.SELLER_ID) for item in after_data.get(Fields.ITEMS, []))
    seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]
    for doc in get_db().get_all(seller_refs):
        if doc.exists:
            send_push_notification(doc.id, "New Order!", f"You have a new order #{oid_short}",
                data={"type": "new_order", "orderId": order_id})
```

```
[HIGH] orders.py:2056 + 2108
PROBLEM: on_order_status_changed has no handler for OrderStatusValues.FAILED or OrderStatusValues.EXPIRED — buyers whose orders fail or expire receive zero notification.
FIX: Add elif blocks for both terminal states:
    elif new_status == OrderStatusValues.FAILED:
        send_push_notification(user_id, "Order Failed", f"Order #{oid_short} could not be processed",
            data={"type": "order_status", "orderId": order_id, "status": new_status})
    elif new_status == OrderStatusValues.EXPIRED:
        send_push_notification(user_id, "Order Expired", f"Order #{oid_short} has expired",
            data={"type": "order_status", "orderId": order_id, "status": new_status})
```

```
[HIGH] orders.py — no file for firestore.rules
PROBLEM: Firestore rules for users/{uid}/notifications subcollection are not in the uploaded files; the audit checklist requires verifying that users can only read their own notifications and cannot write notification docs directly.
FIX: Ensure firestore.rules contains:
    match /users/{uid}/notifications/{notifId} {
      allow read: if request.auth.uid == uid;
      allow write: if false;  // backend-only writes
    }
```

```
[MEDIUM] orders.py:2006
PROBLEM: When paymentStatus changes (REFUNDED / PARTIALLY_REFUNDED) without orderStatus changing, _handle_payment_status_email sends only an email — no push notification — creating an asymmetric experience vs. the orderStatus path which sends both.
FIX: In _handle_payment_status_email, add push after each send_email() call:
    send_push_notification(user_id, "Refund Processed", f"Your refund for order #{oid_short} has been processed",
        data={"type": "payment_status", "orderId": order_id, "status": payment_status})
```

```
[MEDIUM] orders.py:121,123
PROBLEM: FCM token subcollection docs are accessed via magic string "token" instead of a schema constant — breaks the no-magic-strings rule and causes silent drift if the field is renamed.
FIX: Add to Fields class in schema_constants.py: FCM_TOKEN_VALUE = "token", then use Fields.FCM_TOKEN_VALUE:
    (d.to_dict().get(Fields.FCM_TOKEN_VALUE, ""), d.reference)
ALSO: notification_service.dart:170 uses 'token': fcmToken — change to Fields.fcmTokenValue
ALSO: schema_constants.dart needs: static const fcmTokenValue = 'token';
```

```
[MEDIUM] notification_service.dart:161
PROBLEM: Token dedup key is base64 of the first 60 bytes of the FCM token — two distinct tokens sharing the same 60-char prefix silently overwrite each other in the fcm_tokens subcollection, killing one device's notifications with no error.
FIX: Use a proper hash (crypto package is already available in Flutter):
    import 'package:crypto/crypto.dart';
    final tokenHash = sha256.convert(utf8.encode(fcmToken)).toString();
```

```
[MEDIUM] orders.py:1808
PROBLEM: action parameter in approve_return_request uses magic string "action" and "approve"/"mark_received" with no constant — violates no-magic-strings rule and is prone to typo drift between caller and handler.
FIX: Add to ApiKeys in schema_constants.py: ACTION = "action"; APPROVE = "approve"; MARK_RECEIVED = "mark_received", then use ApiKeys.ACTION, ApiKeys.APPROVE, etc.
```

```
[LOW] notification_service.dart:73
PROBLEM: _initialized guard prevents re-initialization after hot-reload but _container is only set during initialize() — if initialize() is never called (e.g., in tests), _container is an uninitialized late variable, causing a LateInitializationError on any saveTokenToFirestore() call.
FIX: Change _container declaration to ProviderContainer? _container; and add a null guard:
    if (_container == null) return;
```

```
[LOW] notification_provider.dart:8
PROBLEM: StateNotifier is soft-deprecated in Riverpod 2.x; new code should use Notifier<bool> for consistency with the rest of the codebase (MVVM rule in CLAUDE.md says Riverpod only, and Riverpod 2 prefers code-gen Notifier).
FIX: Migrate to:
    class NotificationPermissionNotifier extends Notifier<bool> {
      @override bool build() => false;
      void setGranted(bool granted) => state = granted;
    }
    final notificationPermissionProvider = NotifierProvider<NotificationPermissionNotifier, bool>(NotificationPermissionNotifier.new);
```

```
[BONUS] notification_service.dart:129
PROBLEM: SnackBar is used for foreground FCM messages with no navigation action — for order updates the user cannot tap-to-open the relevant screen, which is standard UX on every major e-commerce app and is not accessible (no semantics label).
FIX: Show a tappable notification card via the ScaffoldMessenger with a SnackBarAction:
    SnackBar(
      content: Text('${notification.title}: ${notification.body}'),
      action: SnackBarAction(label: 'View', onPressed: () => _navigateFromData(message.data)),
    )
    and add a _navigateFromData() helper that routes based on data["type"] and data["orderId"].
```

```
[BONUS] orders.py:92 — send_push_notification
PROBLEM: No per-user notification rate limiting exists anywhere — a single Firestore trigger retried 3× by Cloud Functions (e.g., network transient error after the push sends but before the function returns) will send 3 pushes to the user despite the order-level dedup, because dedup is on the Firestore transaction which already committed.
FIX: Add a rate-limit check at the start of send_push_notification using the existing RateLimiter service:
    allowed, _ = RateLimiter(get_db()).check_rate_limit(
        identifier=f"push_{user_id}", action="push", max_requests=20, window_minutes=60, fail_closed=False)
    if not allowed:
        logger.warning(f"Push rate limit exceeded for {user_id}")
        return False
```

```
[BONUS] notification_service.dart:84
PROBLEM: alreadyGranted is computed at line 75 but never used (the comment at line 77 explicitly skips calling setGranted) — dead code that misleads future developers into thinking permission state is restored on app launch.
FIX: Remove the unused alreadyGranted variable and comment, or actually restore state:
    ref.read(notificationPermissionProvider.notifier).setGranted(alreadyGranted);
    // then requestPermission() will update it again if status changed
```

```
[BONUS] orders.py:2129
PROBLEM: get_db().get_all(seller_refs) is called once for SHIPPED notification but the DELIVERED seller notification (line 2185-2193) uses a per-seller loop calling send_push_notification without batching the seller doc reads — inconsistent and causes N reads for DELIVERED.
FIX: Apply the same get_all() batch read pattern to the DELIVERED block:
    seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]
    # Only push needed here, no email fetch needed — send_push_notification handles opt-out internally
    for sid in seller_ids:
        send_push_notification(sid, "Receipt Confirmed", ...)
```

```
[BONUS] orders.py:2309
PROBLEM: on_return_request_status_changed imports firebase_admin.firestore and google.cloud.firestore_v1.transaction inside the function body on every trigger invocation — repeated module imports inside hot paths at 100M+ scale waste cold-start time.
FIX: Move imports to module top-level (already imported elsewhere in the file as _fs_dedup/etc.); use the already-imported get_firestore() helper instead of fresh imports.
```
---

```
[CRITICAL] orders_screen.dart:1312
PROBLEM: `_SoftwareDownloadLinksState._download()` calls `FirebaseFunctions.instanceFor(region: 'us-central1')` directly in the screen widget — business logic in the view (MVVM violation). Also bypasses the app-wide `firebaseFunctionsProvider` that configures the emulator, so emulator builds silently hit production.
FIX: Extract download logic to a viewmodel/repository method; inject `FirebaseFunctions` via `ref.read(firebaseFunctionsProvider)`.
```

```
[CRITICAL] orders_screen.dart:1383
PROBLEM: `_BookDownloadButtonState._download()` has the same direct `FirebaseFunctions.instanceFor()` call — same MVVM violation and emulator-bypass as above.
FIX: Same as above — delegate to a shared `DigitalDownloadRepository` or extend the existing order viewmodel.
```

```
[HIGH] orders_screen.dart:1314
PROBLEM: Magic string `'generate_software_download_session'` — not using `CloudFunctionEndpoints` constant; typo at launch = silent 404.
FIX: Add `static const generateSoftwareDownloadSession = 'generate_software_download_session';` to `CloudFunctionEndpoints`, then use `CloudFunctionEndpoints.generateSoftwareDownloadSession`.
ALSO: orders_screen.dart:1385 — `'generate_book_download_session'` has the same issue.
```

```
[HIGH] checkout_screen.dart:873
PROBLEM: `CircularProgressIndicator` used in the coupon button's loading state — banned by design system (breaks visual consistency); rule requires `ModernLoadingIndicator`.
FIX: Replace with `ModernLoadingIndicator(size: 18, strokeWidth: 2, color: Colors.white, centered: false)`.
```

```
[HIGH] checkout_provider.dart:381-390
PROBLEM: `_checkLocalDelivery` uses `continue` when a seller has no geo coordinates, silently treating them as "within local range." A cart mixing a geo-less seller with a near seller returns `true` for local delivery, offering same-day to a buyer who may not qualify.
FIX: Return `false` immediately when any seller's geo coordinates are null:
```dart
if (sellerAddr.latitude == null || sellerAddr.longitude == null) return false;
```

```
[MEDIUM] orders_screen.dart:50,52,77,79
PROBLEM: `const Color(0xFF06B6D4)` and `const Color(0xFF14B8A6)` are hardcoded hex colors not sourced from `DesignTokens` — breaks theme consistency; impossible to update across breakpoints.
FIX: Add `static const Color statusShipped = Color(0xFF06B6D4);` and `static const Color statusInTransit = Color(0xFF14B8A6);` to `DesignTokens`, then reference them.
```

```
[MEDIUM] productdetails_screen.dart:1378
PROBLEM: Subscription price `'only CAD \$7.86/month'` is hardcoded in the paywall dialog description — if pricing changes, this silently stays wrong in the UI.
FIX: Move price to a constant (e.g., `AppConstants.subscriptionPriceMonthly = 'CAD \$7.86'`) or a localization key `subscription.price_per_month`, then use it here.
```

```
[MEDIUM] productdetails_screen.dart:1284,1350
PROBLEM: `'Premium'` badge label is hardcoded English text — breaks localization for French Canadian buyers.
FIX: Replace with `'subscription.premium_label'.tr()`.
```

```
[LOW] productdetails_screen.dart:278
PROBLEM: Error widget renders `Text('Error: $e')` — exposes raw Dart exception strings to users (poor UX, potential internal details leak).
FIX: Replace with `Text(AppError.getMessage(e), style: ...)`.
```

```
[LOW] productdetails_screen.dart:1307
PROBLEM: `Text('Error loading Q&A: $e')` exposes raw exception to users in the Q&A section.
FIX: Replace with `Text(AppError.getMessage(e), style: const TextStyle(color: DesignTokens.error))`.
```

```
[BONUS] orders_screen.dart:1256,1343,1407
PROBLEM: Multiple hardcoded English strings not routed through `easy_localization`: `'License Key'` (line 1256), `'Download'` (line 1343), `'Download Book'` (line 1407) — invisible to French translation pipeline.
FIX: Add keys `orders.license_key`, `orders.download`, `orders.download_book` to translation files and use `.tr()`.
```

```
[BONUS] productdetails_screen.dart:449
PROBLEM: `'Please select all options'` is a hardcoded English string in the variant selector — missing localization.
FIX: Add key `product.please_select_all_options` and use `.tr()`.
```

```
[BONUS] checkout_provider.dart:153
PROBLEM: Comment reads `// Fallback to legacy address` — CLAUDE.md rule 2 explicitly forbids the word "legacy" in the codebase.
FIX: Replace comment with `// Fallback: read address from user profile (addresses subcollection was empty)`.
```

```
[BONUS] orders_screen.dart:1312,1383
PROBLEM: Hardcoded region string `'us-central1'` — if Cloud Functions region changes, these silent misses won't be caught by any constant check.
FIX: Add `static const String functionsRegion = 'us-central1';` to schema constants or `AppConstants`, and reference it when `instanceFor()` is still needed (post-MVVM fix).
```

```
[BONUS] home_screen.dart:55-62
PROBLEM: `debugPrint` calls left in production `_AddProductButton.build()` — logs sensitive role data (`isSeller`, `isAdmin`, `canAddProducts`) to the console in release builds (release strips asserts but not debugPrint).
FIX: Remove or gate with `assert(() { debugPrint(...); return true; }());`.
```

```
[BONUS] orders_screen.dart:124-133
PROBLEM: Unauthenticated users see the orders screen body (empty state widget) before being guided to sign in — a soft guard instead of a hard redirect. A flash of the orders screen occurs before the empty state renders.
FIX: Redirect unauthenticated users immediately: `WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, AppRoutes.login))` or guard at the route level.
```

```
[BONUS] premium_paywall_widget.dart:4
PROBLEM: `PremiumPaywallWidget` uses `Navigator.pushNamed(context, AppRoutes.subscription)` — if user cancels and returns, the paywall dialog remains open behind the subscription screen, causing navigation stack pollution on some platforms.
FIX: Pop the dialog before navigating: `Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.subscription);`.
```

```
[BONUS] subscription_provider.dart:62-65
PROBLEM: `updateNotificationPreferences` writes directly to `Collections.users/{uid}` from the client — bypasses any backend validation. A malicious client can write arbitrary fields to their user doc in the same call if Firestore rules don't restrict to exactly these two fields.
FIX: Route through a Cloud Function `update_notification_preferences` that whitelists only `notifyNewProducts`/`notifyTrending`, or tighten Firestore rules to `allow update: if request.resource.data.diff(resource.data).affectedKeys().hasOnly(['notifyNewProducts', 'notifyTrending'])`.
```
Now I have enough context. Here are the audit findings:

---

```
[CRITICAL] order_repository.dart:44
PROBLEM: `Fields.trackingNumber: ?trackingNumber` is invalid Dart syntax — the null-conditional operator cannot be used as a map value; this will fail to compile.
FIX: Replace with conditional entries:
  ...(trackingNumber != null ? {Fields.trackingNumber: trackingNumber} : {}),
  ...(carrier != null ? {Fields.carrier: carrier} : {}),
```

---

```
[HIGH] orders.py:126–130
PROBLEM: Comment says "Fallback to legacy single-token field" — the word "legacy" is banned (CLAUDE.md rule 2); more importantly, this FCM fallback path is also used in production for new users who only have the old field, creating a silent inconsistency with the subcollection-first approach.
FIX: Remove word "legacy"; add comment: `# Pre-subcollection FCM path: present on accounts created before fcm_tokens subcollection was introduced; safe to read but new tokens must write to subcollection only.`
```

---

```
[HIGH] checkout_provider.dart:152
PROBLEM: Comment "Fallback to legacy address if addresses subcollection is empty" — uses the banned word "legacy" and misleads; this path runs for all users who haven't migrated to the subcollection, including new ones.
FIX: Replace comment with: `// User has no saved addresses yet; fall back to address on user document (written during onboarding).`
```

---

```
[HIGH] product_repository.dart:21–42
PROBLEM: `addProduct()` and `addProductWithId()` are annotated `@Deprecated` with "Will be removed before launch" but launch is in 10–25 days — these dead code paths still occupy the interface and can cause confusion.
FIX: Remove both methods and their abstract declarations from `ProductRepository`; the Dart compiler enforces callers migrate to `createProductAtomic()`.
```

---

```
[HIGH] cron_jobs.py:1753–1757
PROBLEM: `_notify_trending_products` reads `Fields.FCM_TOKEN` (single top-level field) instead of the fcm_tokens subcollection, inconsistent with `send_push_notification()` in orders.py (which uses subcollection + single-token fallback). Users who only have subcollection tokens are silently missed.
FIX: Replace inline token collection with a call to `send_push_notification()` per user, or replicate the subcollection + fallback pattern from orders.py:send_push_notification.
```

---

```
[MEDIUM] cron_jobs.py:132–157 (auto_capture_confirmed_receipts)
PROBLEM: Missing `trigger_frequency` in header docstring — the schedule decorator uses `"every 24 hours"` but the docstring says "Runs: Daily at 01:00 UTC", which is incorrect; Cloud Scheduler `every 24 hours` starts from deploy time, not 01:00 UTC.
FIX: Either pin the schedule to `"0 1 * * *"` (cron syntax) or update the docstring to "Runs: every 24 hours from first deploy (non-deterministic wall-clock time)".
```

---

```
[MEDIUM] cron_jobs.py:1779–1845 (sync_expired_subscriptions)
PROBLEM: Docstring reads "Hourly: detect and fix subscription-user cache mismatches" — missing trigger frequency in the standard header format used by all other cron jobs in this file (Runs, Flow, Idempotency contract).
FIX: Add full header:
  """
  Hourly: sync Stripe subscription status → user.isPremium cache.
  Runs: Every 1 hour.
  Purpose: Catches missed webhooks; prevents users retaining premium after expiry.
  Idempotency: each _sync_subscription call is idempotent via Stripe sub ID.
  """
```

---

```
[MEDIUM] cron_jobs.py:1848–1862 (escalate_stale_return_requests)
PROBLEM: Docstring says "every 24 hours" but `schedule="every 24 hours"` (same problem as above) and the docstring uses `_RETURN_ESCALATION_DAYS` which is not a real symbol — the actual constant is `BusinessRules.RETURN_ESCALATION_DAYS`.
FIX: Replace `_RETURN_ESCALATION_DAYS` with `BusinessRules.RETURN_ESCALATION_DAYS` in the docstring.
```

---

```
[MEDIUM] orders.py:56–57
PROBLEM: Commented-out dead code `# stripe.api_key = STRIPE_SECRET_KEY  # Removed global assignment` left as an artifact; also present in cron_jobs.py:46. Dead commented-out code should not ship.
FIX: Delete both lines entirely. The reason (lazy init to avoid deploy crash) is documented in `get_stripe_secret_key()` callers.
ALSO: cron_jobs.py:46
```

---

```
[MEDIUM] seller_orders_viewmodel.dart:28
PROBLEM: Comment "Update the first item with tracking info (seller ships entire order)" contradicts code that passes `OrderItemIdValues.all`, which updates ALL items, not the first.
FIX: Change comment to: `// Update ALL items with tracking info — seller ships the entire order as one shipment.`
```

---

```
[MEDIUM] add_product_viewmodel.dart:71
PROBLEM: Comment "Bug #27: Prevent double-submit" is a stale ticket reference — per CLAUDE.md, comments must explain *why*, not reference an internal issue tracker. Same issue at line 121 "Bug #4".
FIX: Replace with: `// Guard: StateNotifier already processing — reject duplicate submit while async in flight.` and at line 121: `// Digital/warehouse products don't have a pickup address; skip street validation for those.`
```

---

```
[MEDIUM] add_product_viewmodel.dart:104
PROBLEM: Magic number `0.50` (minimum gap between compareAtPrice and price) has no comment explaining the business rule origin.
FIX: Add inline comment: `// Enforce minimum $0.50 gap to prevent trivially misleading "sale" labels (e.g. $9.99 vs $10.00).`
```

---

```
[MEDIUM] checkout_provider.dart:389
PROBLEM: Magic number `50` (local delivery km radius) has no constant or comment explaining origin. Appears in two places (`_checkLocalDelivery` line 389 and calculateShipping docstring line 101 as `~50km`).
FIX: Extract to constant `static const _localDeliveryRadiusKm = 50.0; // Max distance for local delivery option — aligns with seller onboarding radius agreement.` and reference it.
```

---

```
[MEDIUM] orders.py:122
PROBLEM: Magic string `"token"` in `d.to_dict().get("token", "")` — violates no-magic-strings rule; should use a schema constant.
FIX: Add `FCM_TOKEN_KEY = "token"` to `schema_constants.py` (or reuse `Fields.FCM_TOKEN` if that resolves to `"token"`) and replace the literal.
```

---

```
[LOW] orders.py:193–199 (confirm_order_receipt docstring)
PROBLEM: Comment says "Backward-compatible wrapper" — implies this is a compatibility shim, but per CLAUDE.md there is no backward compatibility needed (production DB is empty). The comment is misleading and also violates the spirit of "no legacy code".
FIX: Replace comment with: `# Delegates to _capture_payment_impl. The Flutter app calls confirm_order_receipt; direct API callers may call capture_payment. Both invoke the same implementation.`
```

---

```
[LOW] products.py:54–56
PROBLEM: `DEFAULT_PAGE_SIZE = 20`, `MAX_PAGE_SIZE = 100`, and `CDN_BASE_URL = "https://cdn.origna.ca"` are module-level magic constants without comments. `CDN_BASE_URL` should come from `schema_constants` or config, not be hardcoded in a handler file.
FIX: Move `CDN_BASE_URL` to `config.py` or `schema_constants.py` (AppConfig class). Add `# Max items per paginated response — increase requires composite index update` comment on the page size constants.
```

---

```
[LOW] admin.py:113
PROBLEM: Magic number `BusinessRules.MFA_VERIFICATION_VALIDITY_MINUTES` is referenced but the docstring on line 88–96 says "5 minutes" — if the constant changes, the docstring becomes stale.
FIX: Remove hardcoded "5 minutes" from docstring; replace with: `# Requires recent MFA within BusinessRules.MFA_VERIFICATION_VALIDITY_MINUTES minutes.`
```

---

```
[BONUS] order_repository.dart:84–97 (watchBuyerOrders / watchSellerOrders)
PROBLEM: `limit(BusinessRules.ordersPageSize)` is applied without cursor-based pagination; at 100M+ users, sellers with thousands of orders will silently miss older ones. No comment on how to paginate further.
FIX: Add comment: `// Pagination: initial load only. Implement cursor-based pagination (startAfterDocument) for "load more". See docs/WORKFLOW_INDEX.md.`
```

---

```
[BONUS] checkout_provider.dart:267–270
PROBLEM: `Fields.price: item.price` and `Fields.quantity: item.quantity` send client-side price and quantity to backend — per security auditor patterns, backend must never trust client-sent price. If the backend accepts and stores this price without re-fetching from Firestore, this is a price-tampering vector.
FIX: Add comment: `// WARNING: Backend MUST discard client-sent price and re-fetch from Firestore (priceCents). Kept for display-only logging only.` — then verify create_checkout_session.py ignores item.price and fetches from DB.
```

---

```
[BONUS] orders.py:324–325
PROBLEM: `get_server_timestamp()` is called inside a `@transactional` function, which is safe only if it returns the sentinel (not a real read). But it lazily imports `_firestore` — if the lazy init happens inside a transaction it could add a read operation to the transaction unexpectedly.
FIX: Ensure `get_firestore()` (and therefore `_firestore`) is warmed up before the transaction is created. Call `get_server_timestamp()` once outside the transaction to trigger initialization: `_ = get_server_timestamp()` before `@get_firestore().transactional`.
```

---

```
[BONUS] cron_jobs.py:1818
PROBLEM: `db.collection(Collections.USERS).where(Fields.IS_PREMIUM, "==", True).limit(100).stream()` — hard limit of 100 premium users per cron run. At 100M+ users with even 0.1% premium rate = 100,000 premium users; the orphan cleanup will only process 100 per hour, falling catastrophically behind.
FIX: Paginate with cursor: process in batches using `start_after(last_doc)` loop, or switch to a dedicated `premiumExpiresAt < now` index query rather than scanning all premium users.
```

---

```
[BONUS] seller_orders_viewmodel.dart:22–24 (catch block)
PROBLEM: Exception from `updateItemStatus` (tracking step) is silently swallowed with `// Non-critical`; if the tracking write fails due to a permissions error or schema mismatch, it will be invisible — no log, no Sentry event.
FIX: Add `AppError.log(e, context: 'sellerOrders_updateItemStatus_tracking');` inside the catch block before the comment, so silent failures appear in Sentry.
```

Here is the full audit:

---

```
[CRITICAL] auth_repository.dart:190-195
PROBLEM: Client directly writes the `roles` field to Firestore via `userDoc.update({Fields.roles: FieldValue.arrayUnion([UserRoles.buyer])})`, bypassing `create_user_profile` CF. If Firestore rules for users/{uid} permit the owner to arrayUnion any value into roles, a malicious client can escalate to seller/admin by intercepting and modifying this call.
FIX: Remove the direct client update entirely; delegate to the CF:
  // REPLACE lines 190-195 with:
  await _functions.httpsCallable('create_user_profile').call({
    Fields.name: user.displayName ?? 'User',
    Fields.preferredLanguage: _deviceLanguage(),
    Fields.marketingOptIn: false,
  });
```

```
[CRITICAL] admin.py:1198
PROBLEM: `stripe_account_id = user_data.get(Fields.STRIPE_ACCOUNT_ID)` reads from `users/{uid}`, but per schema `stripeAccountId` lives in `seller_profiles/{uid}`. This returns `None` every time → Stripe Connect account is NEVER deleted during GDPR deletion, violating PIPEDA and leaving the seller able to receive payouts after deletion.
FIX: Read from seller_profiles before attempting Stripe deletion:
  sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(user_id).get()
  stripe_account_id = sp_doc.to_dict().get(Fields.STRIPE_ACCOUNT_ID) if sp_doc.exists else None
```

```
[CRITICAL] admin.py:1231-1257
PROBLEM: `delete_account` never deletes `seller_profiles/{user_id}` document. It only no-op deletes seller fields from `users` doc (those fields don't live there). Seller PII (business name, bank details, Stripe account ID, SIN-linked data) persists in Firestore after account deletion — GDPR/PIPEDA violation.
FIX: Add after the user_ref.update() block:
  sp_ref = get_db().collection(Collections.SELLER_PROFILES).document(user_id)
  if sp_ref.get().exists:
      sp_ref.delete()
  logger.info(f"GDPR: Deleted seller_profiles/{user_id}")
```

```
[HIGH] user_repository.dart:60-64
PROBLEM: `_parseSellerStatus` reads `chargesEnabled`, `payoutsEnabled`, `onboardingCompleted`, and `pendingRequirements` from `users/{uid}`, but per schema and `_assert_seller_active` in payment_stripe.py these fields live in `seller_profiles/{uid}`. Result: seller status is always `isSeller=false / chargesEnabled=false` in the UI even after completed onboarding.
FIX: Fetch seller_profiles in the method:
  SellerAccountStatus _parseSellerStatus(Map<String, dynamic>? userData, Map<String, dynamic>? spData) {
    final roles = List<String>.from(userData?[Fields.roles] ?? []);
    final isSeller = roles.contains(UserRoles.seller) || roles.contains(UserRoles.admin);
    final chargesEnabled = spData?[Fields.chargesEnabled] == true;
    ...
  }
  // And in watchSellerAccountStatus, combine both streams with Rx combineLatest or fetch sp in map().
ALSO: seller_account_status_viewmodel.dart:19 (StreamProvider watches users/{uid} only — misses seller_profiles updates)
```

```
[HIGH] admin.py:1727-1786 (admin_refund_order)
PROBLEM: admin_refund_order issues a Stripe refund and cancels the order but never restores stock for order items. A cancelled-and-refunded order leaves products with permanently depleted inventory, causing phantom stock-outs.
FIX: After order_ref.update(), add a transactional stock restore identical to the pattern in suspend_seller:
  for item in order_data.get(Fields.ITEMS, []):
      product_updates[item[Fields.PRODUCT_ID]] = product_updates.get(item[Fields.PRODUCT_ID], 0) + item[Fields.QUANTITY]
  # then run restore_stock_batch transaction
```

```
[HIGH] admin.py:1757
PROBLEM: `stripe.Refund.create(payment_intent=payment_intent_id, ...)` has no `idempotency_key`. If the admin accidentally clicks twice or the CF retries, a duplicate refund is issued, costing the platform twice the order amount.
FIX: Add idempotency_key:
  refund = stripe.Refund.create(
      payment_intent=payment_intent_id,
      reason="requested_by_customer",
      idempotency_key=f"admin_refund_{order_id}",
      metadata={...},
  )
```

```
[HIGH] admin.py:1244-1248
PROBLEM: `delete_account` tries to delete `Fields.MFA_SECRET`, `Fields.MFA_BACKUP_CODES`, etc. from `users/{uid}` doc. These fields only exist in `user_security/{uid}` (backend-only). These deletes are no-ops and give false assurance that MFA secrets were wiped. `user_security/{uid}` IS deleted at line 1255, so the actual secrets are cleaned up — but the redundant deletes from `users` imply a misunderstanding of the schema that could lead to future bugs.
FIX: Remove lines 1244-1248 from the users update dict; they are no-ops and misleading.
```

```
[MEDIUM] admin.py:292-294
PROBLEM: `fail_closed=False` on `suspend_seller` rate limit. If the Firestore rate_limits collection is temporarily unavailable, an admin (or compromised admin token) can call suspend_seller unlimited times, bulk-suspending all sellers in seconds.
FIX: Change to fail_closed=True for destructive admin operations:
  allowed, msg = _limiter.check_rate_limit(
      identifier=admin_id, action="suspend_seller", max_requests=10, window_minutes=1, fail_closed=True
  )
```

```
[MEDIUM] auth_repository.dart:51, 173
PROBLEM: `static final Map<String, bool> _pendingMarketingOptIn = {}` is an unbounded in-memory map. If many users register without verifying email, this map grows forever. Worse, on app restart the map is lost, silently dropping the user's CASL marketing opt-in — they consented but the flag is never stored, violating CASL audit requirements.
FIX: Persist marketingOptIn in Firebase Auth custom claims or as a Firestore `pending_profiles/{uid}` doc (TTL-cleaned after verification):
  // In registerWithEmail, after updateDisplayName:
  await user.updatePhotoURL('mktg:${marketingOptIn ? "1" : "0"}'); // temp workaround
  // Or use a Firestore pending_profiles/{uid} doc with TTL
```

```
[MEDIUM] login_viewmodel.dart:37-48
PROBLEM: Client-side failed-attempt counter and lockout (`failedAttempts`, `lockoutUntil`) live in `StateNotifier` state (RAM only). A user can bypass the 5-attempt lockout by refreshing the page or restarting the app. This provides false security — the real protection is Firebase Auth's server-side `too-many-requests`, but UX shows a lockout that doesn't actually hold.
FIX: Remove client-side lockout entirely and rely on Firebase Auth's `too-many-requests` error code, which is already handled in `_friendlyAuthError`. Simplify state by removing `failedAttempts` and `lockoutUntil` from LoginState.
ALSO: login_state.dart:10-11 (remove these fields)
```

```
[MEDIUM] authwrapper_screen.dart:15-16
PROBLEM: `ref.watch(authStateProvider)` result is discarded. If `authStateProvider` emits an error (network failure during auth state load), the error is silently swallowed and `MainScreen()` is rendered unconditionally with no error state or retry mechanism.
FIX: Use the watched value:
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (_) => const MainScreen(),
    loading: () => const SplashScreen(),
    error: (e, _) => const MainScreen(), // still safe — MainScreen handles unauthenticated
  );
```

```
[BONUS] admin.py:789
PROBLEM: `admin_mfa_enroll` returns the raw TOTP `secret` in the response: `ApiKeys.SECRET: secret`. The secret is transmitted over HTTPS to the client but should only be used to render the QR code once — storing or logging it anywhere is a security risk. The `qrCodeUrl` alone is sufficient for the client.
FIX: Remove `ApiKeys.SECRET: secret` from the response; return only `ApiKeys.QR_CODE_URL` and `ApiKeys.BACKUP_CODES`.
```

```
[BONUS] auth_repository.dart:107-113
PROBLEM: `registerWithEmail` catches `sendEmailVerification` failures silently with an empty `catch (e) {}` block. The user is registered, logged in briefly, then logged out — but if the verification email was never sent, the user is stuck with an unverifiable account and no way to resend without logging in again (which fails because email isn't verified).
FIX: At minimum log the failure to Sentry/logger; ideally surface a resend option:
  } catch (e) {
    logger.error('Failed to send verification email during registration: $e');
    // Do NOT rethrow — registration still succeeded; user can resend from login screen
  }
```

```
[BONUS] admin.py:470 (unsuspend_seller → reactivated products)
PROBLEM: `unsuspend_seller` reactivates all products that have `suspendedAt` set, but does NOT validate that products still have valid stock > 0, a set price, or required images. Ghost/invalid listings can go live immediately upon unsuspension.
FIX: Add a status guard when reactivating:
  batch.update(product_doc.reference, {
      Fields.IS_ACTIVE: True,
      Fields.SUSPENDED_AT: get_delete_field(),
      Fields.UPDATED_AT: get_server_timestamp(),
  })
  # Only reactivate if stock > 0 AND price > 0:
  .where(Fields.STOCK_QUANTITY, ">", 0).where(Fields.PRICE_CENTS, ">", 0)
```

```
[BONUS] auth_repository.dart:269-274
PROBLEM: `validateCurrentUser` checks Firestore profile existence only for email-verified users, but Google Sign-In users (always considered verified) whose Firestore doc was manually deleted will hit the "stale session" path and be signed out. This is correct — but `signInWithGoogle` at line 216 calls `_createUserDocumentIfNeeded` without checking if email is verified (it's always true for Google), so deletion can't happen normally. Edge case but the recovery is jarring with no user-facing explanation.
FIX: Add a specific error message before signOut in the stale-session path:
  // Show toast or set state before signing out
  if (kDebugMode) debugPrint('⚠️ Signing out stale session — profile not found');
  await signOut();
```

```
[BONUS] payment_stripe.py:94
PROBLEM: Comment says "CRITICAL: Set timeout to 30s to prevent Cloud Function timeout (default is 80s)" but `stripe.max_network_retries` is not a timeout — it sets retry count. The actual per-request timeout is not set here. If a Stripe API call hangs, it can cause the Cloud Function to timeout after 60s with no graceful handling.
FIX: Set a per-request timeout explicitly where Stripe is called, or use:
  stripe.default_http_client = stripe.HTTPXClient(timeout=httpx.Timeout(25.0))
```

```
[BONUS] seller_registration_view_model.dart:66 (openStripeDashboard)
PROBLEM: `ExternalUrls.stripeDashboard` is a hardcoded dashboard URL. For Express accounts, the dashboard URL must be dynamically generated via Stripe's `stripe.Account.create_login_link(account_id)` — a static URL doesn't give the seller access to their specific Express dashboard.
FIX: Call a CF that generates a Stripe login link:
  final result = await functions.httpsCallable('create_stripe_login_link').call();
  final url = result.data['url'] as String;
  await launchUrl(Uri.parse(url), ...);
```

Now let me read the remaining files:Let me check the secret caching part of config.py:Now I have enough context. Here are the findings:

---

**Checklist findings:**

[HIGH] services/algolia_service.py:461–475
PROBLEM: `delete_products_from_algolia` calls `delete_product()` one by one in a serial loop — for GDPR account deletion with many products this serializes N Algolia API round-trips when Algolia's `delete_objects` batch endpoint exists.
FIX: Replace the loop with `_run_async(client.delete_objects(index_name=_get_index_name(), object_ids=product_ids))` in a single call.

[HIGH] handlers/payment_stripe.py:395–500
PROBLEM: `calculate_tax_with_stripe` makes a live Stripe Tax API call ($0.50/call at scale) on every checkout with no caching — province and product tax codes are stable for months.
FIX: Cache result in a module-level dict keyed by `(state, frozenset(tax_codes))` with a TTL of 24 hours:
```python
_tax_cache: dict = {}  # module-level
cache_key = (state, frozenset(tc for tc in line_item_tax_codes))
if cache_key in _tax_cache and _tax_cache[cache_key]["expires"] > time.time():
    return _tax_cache[cache_key]["result"]
```

[HIGH] handlers/cron_jobs.py:1655
PROBLEM: `compute_trending_products` has no `acquire_cron_lock` guard — concurrent executions (scheduler over-trigger) will double-flip `isTrending` flags and send duplicate FCM pushes to premium users.
FIX: Add at function start:
```python
if not acquire_cron_lock("compute_trending_products"):
    logger.info("compute_trending_products: already running, skipping")
    return
```
And wrap body in `try/finally: release_cron_lock(...)`.

[HIGH] handlers/cron_jobs.py:1670–1674
PROBLEM: `compute_trending_products` queries Firestore with `Fields.IS_ACTIVE == True`, but the canonical Firestore field is `lifecycleStatus` (a string), not `isActive` (boolean, stored only on Algolia). This query silently returns 0 results in Firestore (field doesn't exist on documents), making trending computation a no-op.
FIX: Replace:
```python
.where(Fields.IS_ACTIVE, "==", True)
.where(Fields.APPROVAL_STATUS, "==", ProductApprovalStatusValues.APPROVED)
```
with:
```python
.where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.ACTIVE)
```

[HIGH] handlers/cron_jobs.py:1670–1688
PROBLEM: `compute_trending_products` fetches full product documents to read only 4 fields (`viewCount`, `purchaseCount`, `name`, `imageUrls`) — at 100M+ product scale this reads massive documents unnecessarily.
FIX: Add `.select([Fields.VIEW_COUNT, Fields.PURCHASE_COUNT, Fields.NAME, Fields.IMAGE_URLS])` before `.stream()`.

[MEDIUM] services/email_service.py:1816–1817
PROBLEM: `mailjet = Client(auth=(...), version=...)` is instantiated on every `send_email` call — creates a new HTTP client + auth object per email at Mailjet free tier (200/day), wasting cold-start memory and adding latency.
FIX: Cache as module-level singleton:
```python
_mailjet_client: Client | None = None
def _get_mailjet():
    global _mailjet_client
    if _mailjet_client is None:
        _mailjet_client = Client(auth=(get_mailjet_api_key(), get_mailjet_secret_key()), version=EmailConfig.MAILJET_API_VERSION)
    return _mailjet_client
```

[MEDIUM] handlers/cron_jobs.py:1233–1238
PROBLEM: `check_low_stock_alerts` fetches full product documents (500 docs) to read only `inventory`, `stockQuantity`, `lastLowStockAlertAt`, `sellerId`, `name` — wastes reads on large product docs with images/descriptions.
FIX: Add `.select([Fields.INVENTORY, Fields.STOCK_QUANTITY, Fields.LAST_LOW_STOCK_ALERT_AT, Fields.SELLER_ID, Fields.NAME])` to the query.

[MEDIUM] handlers/cron_jobs.py:1359–1362
PROBLEM: `send_abandoned_cart_emails` fetches all users with `marketingOptIn=True` (up to 500) then filters the 72-hour cooldown client-side — reads and deserializes hundreds of user docs that will be skipped immediately.
FIX: Add a compound index on `(marketingOptIn, lastCartAbandonEmailAt)` and add server-side filter: `.where(Fields.LAST_CART_ABANDON_EMAIL_AT, "<", cooldown_cutoff)` (handle null values by also querying users with no `lastCartAbandonEmailAt` field in a separate query or by using a sentinel epoch timestamp on registration).

[MEDIUM] handlers/cron_jobs.py:1407
PROBLEM: Abandoned cart active-product check uses `pd.get(Fields.IS_ACTIVE)` — `isActive` is not a canonical Firestore field (it's derived at Algolia-index time); the field is always falsy in Firestore so no abandoned cart emails are ever sent.
FIX: Replace with `pd.get(Fields.LIFECYCLE_STATUS) == ProductLifecycleStatusValues.ACTIVE`.

---

**Bonus findings:**

[BONUS] handlers/cron_jobs.py:1913–1928
PROBLEM: Admin user FCM token query runs inside the per-return-request loop — N queries for admins for N stale returns (N+1).
FIX: Fetch admin docs once before the loop, reuse in every iteration:
```python
admin_docs = list(db.collection(Collections.USERS).where(Fields.ROLES, "array_contains", UserRoleValues.ADMIN).limit(10).stream())
for doc in stale_returns:
    ...  # use admin_docs directly
```

[BONUS] handlers/cron_jobs.py:1435,1441
PROBLEM: Abandoned cart email has hardcoded `https://orignagta.ca/cart` and `https://orignagta.ca/settings/notifications` — these URLs break in dev/staging environments.
FIX: Replace with `f"{APP_BASE_URL}/cart"` and `f"{APP_BASE_URL}/settings/notifications"` using the `APP_BASE_URL` already imported in `email_service.py`.
ALSO: handlers/cron_jobs.py:1315 has same hardcoded domain for the low-stock alert CTA.

[BONUS] handlers/cron_jobs.py:1403
PROBLEM: `get_db().get_all(product_refs)` is called but `get_db()` is also called again inside each `get_db().collection(Collections.PRODUCTS).document(pid)` ref construction in the list comprehension at line 1402 — `get_db()` is called N+1 times per user; should be called once.
FIX:
```python
db = get_db()
product_refs = [db.collection(Collections.PRODUCTS).document(pid) for pid in product_ids]
product_docs = db.get_all(product_refs)
```

[BONUS] handlers/cron_jobs.py:1360
PROBLEM: `send_abandoned_cart_emails` has no `acquire_cron_lock` — concurrent invocations send duplicate emails to the same users and hit the Mailjet free tier limit (200/day) twice as fast.
FIX: Add `acquire_cron_lock("send_abandoned_cart_emails")` guard at function start (same pattern as other crons).

[BONUS] services/algolia_service.py:153
PROBLEM: `_log_sync_failure` calls `fs.client()` on every failure instead of reusing a module-level cached Firestore client — creates new client per DLQ write on retry storms.
FIX: Replace `fs.client()` with the module-level `_get_algolia_client()` pattern (lazy global) or import a shared `get_db()` helper.

[BONUS] handlers/payment_stripe.py:504–506
PROBLEM: `ensure_stripe_key()` checks `if not stripe.api_key` and re-fetches from Secret Manager on every call if key is empty — the key is a module-level global and can remain unset between cold starts if initialization failed silently; should raise a hard error instead of silently re-fetching every call.
FIX: Set `stripe.api_key` once at module cold-start (not lazily per call) and raise `RuntimeError` if missing at startup. Current lazy pattern allows the first failed checkout to re-initialize silently on retry, which is fine, but the per-call check creates overhead on every Stripe operation.

[BONUS] handlers/cron_jobs.py:1715
PROBLEM: `compute_trending_products` performs a second full scan of all products with `isTrending==True` to clear old trending — this is a redundant scan after already reading all products. Store the previously trending IDs in the first scan.
FIX: During the first scan, collect `old_trending_ids = {prod_snap.id for prod_snap in products_query if data.get(Fields.IS_TRENDING)}` and use that set to clear, avoiding the second `.stream()`.

[BONUS] algolia_product_repository.dart:81
PROBLEM: `fetchProductsByIds` filters by `lifecycleStatus == active` AFTER fetching by ID — documents that have been deactivated since the IDs were cached will silently disappear from results with no error surfaced to the caller.
FIX: Remove the `lifecycleStatus` filter and handle inactive products gracefully in the UI layer (show "no longer available" instead of silently empty).

Now let me read the remaining files:Here is the full audit output:

---

```
[CRITICAL] functions/handlers/products.py:153
PROBLEM: `upload_product_images` reads `ONBOARDING_COMPLETED` from `users/{uid}` doc, but per the architecture (CLAUDE.md) seller Stripe onboarding fields live in `seller_profiles/{uid}`. This check always evaluates False for any seller, blocking all image uploads.
FIX: mirror the pattern from `payment_stripe.py:183-188` — fetch `seller_profiles/{uid}` and check `sp_data.get(Fields.ONBOARDING_COMPLETED, False)`.
```

```
[CRITICAL] origna_gta/lib/models/generated/order_models.dart:169-170
PROBLEM: `customerId` and `customerEmail` are `required String` in Dart but `str | None` in Python `Order`. Orders created before Stripe assigns a customer (race between session creation and webhook) will crash `fromFirestore` / `fromJson` with a null-dereference.
FIX: change to nullable with default:
`String? customerId,` and `String? customerEmail,`
ALSO: order.py:Order — fields are already nullable; Dart just needs to match.
```

```
[CRITICAL] origna_gta/lib/models/generated/order_models.dart:184
PROBLEM: `stripeSessionId` is `required String` in Dart but `str | None` in Python `Order`. Admin-created orders, refund-only records, or webhook-created docs that lack a session ID will throw on parse.
FIX: `String? stripeSessionId,` (nullable, matching Python `stripeSessionId: str | None`).
```

```
[CRITICAL] origna_gta/lib/models/generated/order_models.dart:~190 (shippingAddress)
PROBLEM: `shippingAddress` is `required Address` in Dart but `Address | None` in Python `Order`. A Firestore document without the field (e.g., admin-created test order) will crash `fromFirestore`.
FIX: `Address? shippingAddress,` — callers that need it non-null add a local assertion.
```

```
[HIGH] functions/handlers/products.py:115
PROBLEM: `upload_product_images` is decorated with `@https_fn.on_call(secrets=[APP_SECRETS_PARAM])` without spreading `**DEFAULT_OPTIONS`. Every other handler uses `**DEFAULT_OPTIONS` which includes CORS configuration. Web clients will fail the CORS preflight for this endpoint.
FIX: Change decorator to `@https_fn.on_call(secrets=[APP_SECRETS_PARAM], **DEFAULT_OPTIONS)` (merge the secrets param into DEFAULT_OPTIONS or pass both).
```

```
[HIGH] origna_gta/lib/features/orders/seller_orders_viewmodel.dart:29
PROBLEM: `OrderStatusValues.shipped` is passed as the item-level status to `updateItemStatus`, but `OrderItem.status` uses `DeliveryStatusValues`. These are different enum classes; if their string values differ the backend will reject the transition.
FIX: Replace `OrderStatusValues.shipped` with `DeliveryStatusValues.shipped`.
```

```
[HIGH] origna_gta/lib/features/orders/seller_orders_viewmodel.dart:25
PROBLEM: `OrderItemIdValues.all` is referenced but this constant is not present in the visible `schema_constants.dart`. If undefined, this is a compile-time error; if it is defined elsewhere as a magic string it violates the no-magic-strings rule.
FIX: Define `abstract final class OrderItemIdValues { static const all = 'all'; }` in `schema_constants.dart` and add `OrderItemIdValues.ALL = 'all'` in `schema_constants.py`.
```

```
[HIGH] origna_gta/lib/features/checkout/checkout_provider.dart:265-270
PROBLEM: Checkout payload includes `Fields.price: item.price` (client-supplied price). Per Payment Auditor Rule 4, backend must re-fetch `priceCents` from Firestore; client-sent price must never be trusted. If the handler uses this value directly, a buyer can send a lower price.
FIX: Verify that the backend `create_checkout_session` handler re-fetches each product's price from Firestore and discards `req.data['price']`. Remove `Fields.price` from the Dart payload to make the attack surface explicit.
```

```
[HIGH] origna_gta/lib/models/generated/order_models.dart:470
PROBLEM: Dart `OrderItem.sellerAddress` is `required Address sellerAddress` (non-nullable), but Python `OrderItem.sellerAddress` is `Address | None`. `_parseOrderItem` returns a synthesised empty `Address()` on null, silently masking missing seller addresses; downstream distance calculations will produce incorrect results.
FIX: Change Dart field to `Address? sellerAddress,` and update all callsites to handle null.
```

```
[MEDIUM] origna_gta/lib/features/checkout/checkout_provider.dart:152-155
PROBLEM: Fallback reads `user.address` from the `users` doc — a field that the architecture places in the `addresses` subcollection (`users/{userId}/addresses`). This silently returns stale/wrong address data for sellers and violates the "no stale schema fields" principle.
FIX: Remove the fallback entirely or redirect it to `addresses` subcollection:
`final defaultAddr = await _ref.read(userAddressesProvider.future).then((list) => list.firstOrNull);`
```

```
[MEDIUM] origna_gta/lib/models/generated/order_models.dart:587-598
PROBLEM: `Taxes.fromJson` has a dual-key lookup (`json[Fields.gst] ?? json[Fields.GST]`) suggesting `Fields.gst` and `Fields.GST` differ in Dart, while Python `Taxes` writes uppercase keys (`GST`, `PST`, `HST`, `QST`) as field names. If `Fields.gst` evaluates before `Fields.GST` and returns 0.0 (wrong key matches), taxes are zeroed silently.
FIX: Remove the lowercase fallback; standardise to `json[Fields.GST]` only (uppercase, matching the Python serialised key). Verify `Fields.GST = 'GST'` in `schema_constants.dart`.
ALSO: schema_constants.dart:Fields — confirm `Fields.GST = 'GST'` (not `'gst'`).
```

```
[BONUS] functions/handlers/products.py:3706-3720
PROBLEM: `bulk_update_products` writes `Fields.UPDATED_AT: datetime.now(UTC)` (Python client clock) instead of `get_server_timestamp()`. Every other write in the codebase uses server timestamps; client timestamps diverge under cold-start latency and should not be used.
FIX: `Fields.UPDATED_AT: get_server_timestamp()`
```

```
[BONUS] origna_gta/lib/features/orders/seller_orders_viewmodel.dart:31-36
PROBLEM: Tracking-number update failure is caught and silently swallowed with no log. Operations teams have no visibility into why tracking numbers are missing from orders.
FIX: Replace `catch (_) {}` with `catch (e) { AppError.log(e, context: 'seller_updateTracking'); }`.
```

```
[BONUS] origna_gta/lib/features/add_product/add_product_viewmodel.dart:100
PROBLEM: `price > 100000` uses a hardcoded magic number. `ValidationLimits` should define `MAX_PRICE_CAD` (matches Python `ValidationLimits.MAX_PRICE_CAD`).
FIX: `if (price > ValidationLimits.maxPriceCad)` — define `maxPriceCad = 100000` in both `schema_constants.dart` and `schema_constants.py`.
```

```
[BONUS] functions/handlers/orders.py:send_push_notification
PROBLEM: Every call reads the `users` doc then streams the entire `fcm_tokens` subcollection. At scale (N notifications = 2N+ Firestore reads), this is expensive. The user doc read is redundant if `PUSH_ENABLED` defaults to `True` — it only matters when False.
FIX: Query `fcm_tokens` subcollection first; only fetch the user doc if a `PUSH_ENABLED` field is present (lazy read). At 100M users/year this saves millions of reads.
```

```
[BONUS] functions/handlers/payment_stripe.py:4141
PROBLEM: Security alert for stuck payout uses a string literal `"note"` instead of a `Fields` constant. Violates no-magic-strings rule and makes querying/filtering alerts unreliable.
FIX: Add `Fields.NOTE = 'note'` to `schema_constants.py` and `schema_constants.dart`, then use `Fields.NOTE`.
```

```
[BONUS] functions/handlers/products.py:3785
PROBLEM: Firestore query uses hardcoded string `"supplier.type"` (dot-notation path) instead of a constant. If the nested field name changes, this silently matches nothing.
FIX: Define `Fields.SUPPLIER_TYPE_PATH = 'supplier.type'` in `schema_constants.py` and use it here.
```

```
[BONUS] origna_gta/lib/features/checkout/checkout_provider.dart:404
PROBLEM: Idempotency key embeds `DateTime.now().millisecondsSinceEpoch` on the client. A user's device clock can be wrong or manipulated, producing collisions with past keys or gaps that bypass duplicate-detection.
FIX: Generate the idempotency key server-side (returned in the checkout session response) or use `Uuid.v4()` instead of a timestamp-dependent nonce.
```
Here is the full audit:

---

```
[CRITICAL] functions/users.py — missing handler
PROBLEM: No `delete_user_data` endpoint exists; PIPEDA s.4.3.6 and Quebec Law 25 (Art. 28) require a path for users to request erasure of their personal data — absence blocks legal launch.
FIX: Add a Cloud Function that anonymizes PII in `users/{uid}`, deletes `addresses` subcollection, queues `user_security/{uid}` deletion, and replaces name/email in orders with "Deleted User":
  user_ref.update({Fields.NAME: "[Deleted]", Fields.EMAIL: "", Fields.DELETED_AT: server_ts, Fields.IS_DELETED: True})
```

```
[CRITICAL] functions/email_service.py — no marketingOptIn gate
PROBLEM: No function in email_service.py checks `Fields.MARKETING_OPT_IN` before sending marketing emails; CASL §6 requires express consent for every commercial electronic message — opted-out users can receive promotional emails.
FIX: Add a guard in every non-transactional send function:
  user_data = db.collection(Collections.USERS).document(uid).get().to_dict()
  if not user_data.get(Fields.MARKETING_OPT_IN, False): return
  (Transactional emails: order confirmation, shipping, refund — exempt, no gate needed.)
```

```
[HIGH] lib/screens/login_screen.dart:315
PROBLEM: `handleGoogleSignIn` bypasses the `state.acceptedTerms` guard that email/password flow checks at line 258; Google sign-up users never have terms/privacy consent recorded.
FIX: In `loginViewModelProvider.notifier.handleGoogleSignIn()`, check accepted terms before signing in and pass marketingOptIn to create_user_profile:
  if (!state.acceptedTerms) { throw Exception('terms_required'); }
  // then pass marketingOptIn: state.marketingOptIn in the create_user_profile call
```

```
[HIGH] lib/screens/login_screen.dart:219-242
PROBLEM: Marketing opt-in checkbox is rendered unconditionally (no `if (!state.isLogin)` guard), making it visible and interactive during sign-in flow — confusing users and polluting consent records.
FIX: Wrap the entire marketing opt-in Row with `if (!state.isLogin)` identical to the terms checkbox guard at line 168:
  if (!state.isLogin) ...[
    const SizedBox(height: 8),
    Row(children: [Checkbox(value: state.marketingOptIn, ...), ...]),
  ],
```

```
[HIGH] lib/screens/login_screen.dart — missing minor protection
PROBLEM: No age confirmation at signup; PIPEDA and Quebec Law 25 (Art. 17) require parental consent for minors under 14; registering minors without this is a compliance violation.
FIX: Add a date-of-birth field or an "I confirm I am 18 or older" checkbox in the signup form. Backend `create_user_profile` should reject if `dateOfBirth` indicates under 14 (Quebec) or store `ageConfirmed: true` with server timestamp:
  if not data.get('ageConfirmed', False):
      raise https_fn.HttpsError("failed-precondition", "Age confirmation required")
  user_ref.set({..., Fields.AGE_CONFIRMED: True, Fields.AGE_CONFIRMED_AT: server_ts})
```

```
[HIGH] lib/widgets/terms_of_service_screen.dart + lib/widgets/privacy_policy_screen.dart
PROBLEM: Both screens render content from static translation strings (`legal.terms_of_service_content`, `legal.privacy_policy_content`) — hardcoded in .arb files, NOT from Remote Config. If terms change, an app update is required; compliance versions cannot be pushed OTA.
FIX: Replace static `.tr()` content with a Remote Config provider identical to `termsProvider`:
  final privacyProvider = FutureProvider<String>((ref) async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.fetchAndActivate();
    final content = rc.getString('privacy_policy');
    return content.isNotEmpty ? content : _defaultPrivacyContent;
  });
ALSO: lib/widgets/legal_screen_body.dart:106 — no version number displayed to user.
```

```
[MEDIUM] lib/screens/terms_screen.dart:~line with "Last updated February 2026"
PROBLEM: "Last updated February 2026" is a hardcoded magic string; when Remote Config serves updated terms, the date label will be stale and misleading to users.
FIX: Add a `lastUpdated` key to the Remote Config payload and expose it via `termsProvider`, then render it dynamically:
  Text('Last updated ${termsMetadata.lastUpdated}  •  ${_sections.length} sections')
```

```
[MEDIUM] functions/schema_constants.py:1053 (PolicyVersionValues)
PROBLEM: `PolicyVersionValues.DEFAULT = "1.0"` with no `CURRENT` constant or version bump mechanism; when terms/policy are updated, backend cannot detect which users have stale consent without a separate config update and redeploy.
FIX: Add a `CURRENT` constant loaded from Remote Config or env at startup, and compare on each protected action:
  class PolicyVersionValues:
      DEFAULT = "1.0"
      CURRENT = os.environ.get("CURRENT_TERMS_VERSION", "1.0")  # bump per release
  # In checkout: if user.terms_version != PolicyVersionValues.CURRENT: raise re-acceptance error
```

```
[MEDIUM] lib/screens/terms_screen.dart — duplicate of legal_screen_body.dart
PROBLEM: `TermsScreen` duplicates the entire section-parsing + rendering logic already in `LegalScreenBody`; `TermsOfServiceScreen` also exists as a third screen — three screens rendering terms with inconsistent sources (Remote Config vs. .arb vs. termsProvider). Any UI fix must be applied in three places.
FIX: Delete `TermsScreen` custom rendering; route to `TermsOfServiceScreen` using the Remote Config `termsProvider` via `LegalScreenBody` — single source, single component.
```

```
[BONUS] lib/screens/terms_screen.dart (Positioned decorative circles, ~line 400-420)
PROBLEM: Decorative background circles inside `FlexibleSpaceBar` are NOT wrapped in `ExcludeSemantics`, unlike `legal_screen_body.dart` which correctly excludes them (lines 198, 212). Screen readers will announce these invisible decorative elements.
FIX: Wrap each decorative Positioned in ExcludeSemantics:
  ExcludeSemantics(child: Positioned(top: -40, right: -30, child: Container(...)))
```

```
[BONUS] lib/widgets/legal_screen_body.dart:535 + terms_screen.dart
PROBLEM: Hardcoded color `const Color(0xFF4A4A5A)` used for section body text in both files — violates DesignTokens-only rule.
FIX: Replace with `DesignTokens.textSecondary` or add `DesignTokens.policyBodyText = const Color(0xFF4A4A5A)` and reference from there.
```

```
[BONUS] lib/screens/terms_screen.dart:_parseSections regex
PROBLEM: `RegExp(r'(\d+)\.\s+([A-Z][A-Z &/]+)\n')` requires ALL-CAPS section titles; if Remote Config serves mixed-case terms (likely for FR locale), parsing silently returns 0 sections — screen shows blank.
ALSO: legal_screen_body.dart uses looser regex `r'(\d+)\.\s+(.+)\n'` — inconsistent between the two parsers.
FIX: Unify on the looser pattern and add a fallback:
  final pattern = RegExp(r'(\d+)\.\s+(.+)\n');
  if (matches.isEmpty) { /* show rawContent as plain text fallback */ }
```

```
[BONUS] functions/email_service.py:1829 (List-Unsubscribe header)
PROBLEM: `List-Unsubscribe` header is added to ALL emails including purely transactional ones (order confirmation, shipping). Email clients may show a misleading "unsubscribe" button on receipts, causing users to accidentally opt out of transactional notifications.
FIX: Add an `is_transactional` parameter to `send_email()`; only inject `List-Unsubscribe` when `is_transactional=False`:
  if not is_transactional:
      message["Headers"] = {"List-Unsubscribe": ..., "List-Unsubscribe-Post": ...}
```
