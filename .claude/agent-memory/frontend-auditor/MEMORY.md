# Frontend Auditor Memory — OrignaGTA

## Architecture Facts
- State management: Riverpod (StateNotifier pattern throughout, no NotifierProvider/AsyncNotifier used)
- Premium gate canonical provider: `subscriptionStreamProvider` (StreamProvider.autoDispose in subscription_provider.dart)
- User profile canonical provider: `userProfileProvider` (StreamProvider.autoDispose in auth_provider.dart)
- All screens use ConsumerWidget or ConsumerStatefulWidget
- Router: Named routes via Navigator.pushNamed, all registered in origna_app.dart onGenerateRoute
- i18n: easy_localization with en.json / fr.json translation files

## Key Provider Locations
- `subscriptionStreamProvider` → lib/features/subscription/subscription_provider.dart:14
- `userProfileProvider` → lib/features/auth/auth_provider.dart:10
- `qaControllerProvider` → lib/features/qa/qa_provider.dart:7 (MISSING autoDispose)
- `notificationPermissionProvider` → lib/features/notifications/notification_provider.dart:11 (MISSING autoDispose)
- `sellerUnansweredQaProvider` → lib/features/products/products_provider.dart:99
- `unansweredQaCountProvider` → lib/features/qa/qa_provider.dart:17

## Known Issues (from 2026-02-27 audit)
See patterns.md for full details. Key findings:
1. `qaControllerProvider` missing autoDispose — leaks across product detail visits
2. `notificationPermissionProvider` missing autoDispose — lives for app lifetime (may be intentional)
3. Badge widgets use `.valueOrNull ?? 0` (silently hides errors) — acceptable tradeoff confirmed
4. Hardcoded strings in productdetails_screen.dart and product_card_screen.dart
5. Hardcoded price constant `_subscriptionPrice = 'CAD $7.86/month'` in productdetails_screen.dart
6. Paywall description hardcoded in _showPremiumPaywall method

## Deferred UI Status (as of 2026-02-27)
- Photo reviews: COMPLETE — RatingDialog has photo picker for premium users (up to 3 photos)
- Product Q&A: COMPLETE — _QASection fully wired in productdetails_screen.dart
- Back-in-stock: COMPLETE — stockNotificationNotifierProvider + UI in _AddToCartButton
- Seller Q&A badge: PARTIAL — badge exists on seller_orders_screen.dart but NOT on seller_products_screen.dart (the screen where it's most useful)
