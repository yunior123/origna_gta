# STATE.md

## Status: All audit findings from prior sessions resolved in commit 9fd1fab

## Remaining / Deferred Items

### Features (not bugs — need product decision before building):
- `productdetails_screen.dart`: "Customers also bought" / Similar items section (Algolia query + horizontal ListView)
- `productdetails_screen.dart`: Verified purchase badge + photo reviews on ratings (needs schema field `verifiedPurchase: bool`)
- `productdetails_screen.dart`: Seller metrics row (avgResponseHours, avgShipDays, positiveRatePct from seller_metrics/{id})
- `checkout_screen.dart`: "Spend $X more for free shipping" threshold banner
- `checkout_screen.dart`: Buyer protection notice / dispute policy before payment
- `home_screen.dart`: Wishlist/heart button on product cards
- `orders_screen.dart`: Abandoned cart recovery (Cloud Function on cart write + Mailjet via Cloud Tasks)
- `checkout_screen.dart`: Order review step before Stripe external page

### Medium Code Quality (low risk, can tackle in next session):
- `cron_jobs.py:301-316`: Auto-confirm cron doesn't write OrderEvent audit trail
- `orders.py:2005-2009`: Payment-status email sends have no dedup (only orderStatus changes are deduped)
- `cron_jobs.py:654-655`: Stock restore in _run_expired_authorizations uses pre-transaction order_data items
- `orders.py:1168`: OrderEvent.write hardcodes actor_type="admin" for all refunds (sellers can also refund)
- `orders.py:810-827 + 1460-1479`: Copy-pasted stock restore logic — extract to _restore_stock_to_batch() helper
- `orders.py:61-89 / admin.py / products.py / payment_stripe.py`: get_db/get_server_timestamp duplicated — move to utils/db.py
- `subscription_provider.dart:60-65`: updateNotificationPreferences writes directly to Firestore instead of via UserRepository
- `products.py:1532`: _notify_admins_new_product has no .limit() on admin query
- `cron_jobs.py:1818`: sync_expired_subscriptions hard-limits 100 premium users per cron run — needs cursor pagination

### Low / Bonus (polish):
- `payment_stripe.py:457 + 472`: Dead assignment on tax_amount_cents (line 457)
- `cron_jobs.py:1913-1928`: N+1 admin FCM query inside per-return loop
- `cron_jobs.py:1435,1441`: Hardcoded orignagta.ca URLs in cron emails — use APP_BASE_URL
- `algolia_service.py:171-212`: time.sleep() in Cloud Function retry loop — use Algolia client retry
- `orders.py:92-171`: send_push_notification belongs in services/push_service.py
- `orders.py:1810`: Missing rate limit on approve_return_request / reject_return_request
- `orders.py:1870-1875`: Stock restore on mark_received is not atomic with status update — use batch
- `seller_orders_viewmodel.dart:22-24`: Silent tracking error catch — should log to Sentry
- `payment_stripe.py:74-77`: _check_premium_from_sub may be unused dead code — verify and remove
- `notification_service.dart`: sha256 FCM token hash (crypto package needed in pubspec.yaml first)
- `orders_screen.dart:276-921`: _BuyerOrderCardState confirmation loading state should move to BuyerOrdersViewModel
- `cron_jobs.py:301`: SHIPPED auto-confirm items write not transactional — could corrupt on concurrent cron escape
- `login_viewmodel.dart:37-48`: Client-side failed-attempt lockout is trivially bypassable — remove in favor of Firebase Auth's server-side too-many-requests
- `auth_repository.dart:51,173`: _pendingMarketingOptIn unbounded in-memory map — persist to Firestore pending_profiles
- `admin.py:789`: admin_mfa_enroll returns raw TOTP secret in response — return only qrCodeUrl + backupCodes
- `admin.py:470`: unsuspend_seller reactivates products without validating stock > 0 and price > 0
