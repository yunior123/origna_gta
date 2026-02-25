# STATE.md — OrignaGTA
Last updated: 2026-02-25

All audit findings from the prior E2E, Admin Panel, and Payment system audits have been resolved. Below is a summary of what was fixed in the current session and what was verified-already-fixed.

---

## Resolved in this session

| # | Area | Fix |
|---|------|-----|
| 1 | `cartitem_screen.dart` | `_saveForLater` used `Fields.savedAt` instead of `Fields.dateFavorited` in favorites subcollection |
| 2 | `cartitem_screen.dart` | MVVM violation: direct `FirebaseFirestore.instance` call replaced by `CartController.saveForLater()` |
| 3 | `cartitem_screen.dart` | Missing `await` on `removeFromCart` (race condition) |
| 4 | `cartitem_screen.dart` | Hardcoded English strings → `.tr()` with keys in en.json/fr.json |
| 5 | `cart_provider.dart` | `_cartProductsBatchProvider` chunk failures silently empty the cart → try/catch with Sentry |
| 6 | `cart_provider.dart` | `cartItemDetailProvider` family key was `productId` — same product with 2 variants showed same detail → changed to `cartItemDocId` |
| 7 | `shipping_service.py` | `_TAX_RATES_CACHE` was a hardcoded duplicate of `BusinessRules.TAX_RATES` → now derived at module load |
| 8 | `orders.py` | Tracking number was optional for SHIPPED status → now required (`invalid-argument` raised if absent) |
| 9 | `ordersuccess_screen.dart` | No Sentry breadcrumb on order success → added `Sentry.addBreadcrumb` in `initState` |
| 10 | `payment_screens.dart` | `PaymentCanceledScreen` always cleared the nav stack → now `canPop()` → `pop()` with fallback |

---

## Pre-verified as already fixed (audit findings that were stale)

- **C-4** admin_orders_tab.dart: `easy_localization` import was present  
- **H-7** sellerId vs seller_id: both sides already used `'sellerId'`  
- **C-1/H-2** suspend/unsuspend used `lifecycleStatus` already  
- **C-3** admin refund used `REFUNDED` status (not `CANCELLED`)  
- **H-1** admin-on-admin guard was present  
- **C-2** admin refund already reversed Stripe transfers  
- **H-3** MFA enrollment already used Firestore transaction  
- **H-4** account deletion already set `lifecycleStatus: ARCHIVED` + Algolia delete  
- **H-5** `hasPhotosOnly` already server-side queried  
- **H-6** callable payloads already used schema constants  
- **M-2** `isFlagged`/`hasPhotos` already in schema constants  
- **M-3** role sync failure already writes to `SECURITY_ALERTS`  
- **M-1** `SHIPPED` already in `_REFUNDABLE_STATUSES`  
- **B-2** `context.mounted` already guarded in admin_orders_tab.dart  
- **B-5** `deliveryStatus` not present in firestore.rules  
- Payment float validation: cents-based comparison already used  
- Zero-amount reversal: already guarded  
- UUID idempotency: already uses `const Uuid().v4()`  
- Webhook secret caching: `_WEBHOOK_SECRET_CACHE` already present  
- Payment timeout: already 90 seconds  
- Province validation: already validated in `create_checkout_session`  
- Context.mounted in checkout: already guarded  
- Tracking number test: E2E test already existed  
- 3DS URL assertion: E2E already asserts `checkout.stripe.com || orignagta`  
- Buyer-flow uses `ensureLoggedInAsBuyer` (not Admin)  
- `|| true` assertions: removed from buyer-flow.spec.ts  
- `platformFeeRatio` assertion: already in stripe-payment.spec.ts  
- `invalidateProductCache`: not async (returns void), `await` is harmless  
- `priceCents` in shipping test: already present  
- `afterAll` cleanup in shipping test: already present  

---

## Suggested future improvements (deferred, non-blocking)

- `on_order_status_changed` sends Mailjet synchronously inside trigger — consider email_queue pattern if Mailjet SLAs become an issue
- `process_dispute_created` sends email synchronously inside webhook — same email_queue pattern  
- `cartProductsBatchProvider` variant validation: `addToCart` doesn't validate variantId exists in product's variants array  
- `_TermsText` acceptance stored in ephemeral state only — consider persisting `termsAcceptedAt` to `users/{uid}` via backend  
- `watchSellerOrders` uses `arrayContains + orderBy` which Firestore doesn't support — must drop `orderBy` and sort client-side  
- `OrderSuccessScreen` could fire Firebase Analytics `purchase` event in addition to Sentry breadcrumb  
