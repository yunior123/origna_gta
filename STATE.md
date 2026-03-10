# Project State - OrignaGTA

## Current Progress (2026-03-06)

### Frontend (Flutter)
- **Coverage:** 90.2% (3551/3938 lines) ✅ TARGET MET
- **Tests Passed:** 2211+
- **Patrol Workflows:** 60 Human Workflows implemented (WF1-WF60)
- **Integration Tests:** Passing against Dev Firebase (verified via OrignaApp tests and manual fixes)

### Backend (Firebase Functions)
- **Coverage:** [Pending Check]
- **Tests Passed:** [Pending Check]

## Recent Fixes
- Added comprehensive translations for all 26 Supplier Platforms in EN and FR.
- Added translations for all Delivery Speed options in EN and FR.
- Fixed missing translation keys in production JSON files.
- Silenced "bizarre" EasyLocalization console warnings globally in tests using `flutter_test_config.dart`.
- Updated `MockAssetLoader` with all missing keys to support proper widget testing.
- Added unit tests for:
  - ChatViewModel
  - AdminActionsViewModel
  - BuyerOrdersViewModel
  - ProductDetailViewModel
  - CheckoutNotifier (expanded)

## Pending Issues
- Continue increasing coverage towards 90% by adding more unit/widget tests.
- Complete remaining human workflows in Patrol.

## Verification Log (2026-03-10)
- `flutter test` in `origna_gta/origna_gta`: 2184 tests passed locally in ~71 minutes.
- `flutter analyze` in `origna_gta/origna_gta`: existing repo-wide warnings remain, but targeted analysis on the OrignaBase migration files passed with no issues after fixes.
- `bash -n scripts/deploy_web.sh`: passed after switching Hetzner web deploy to staged releases + atomic cutover.
- `flutter analyze` on OrignaBase migration files: passed with no issues.
- `flutter test` on migration-focused suite (`address_viewmodel`, `checkout_provider`, `profile_viewmodel`, `seller_registration_viewmodel`, `subscription_provider`, `user_repository`): 40 tests passed.

## Migration Progress (2026-03-10)
- Fixed OrignaBase repository routing to match the Rust handler paths:
  - checkout `/api/checkout/session`
  - capture `/api/payments/capture`
  - order shipping/status routes under `/api/orders/*`
  - subscriptions under `/api/subscriptions/*`
  - seller connect onboarding under `/api/connect/*`
  - stock notifications under `/api/products/stock-notify/*`
- Replaced OrignaBase user address CRUD calls that still targeted removed Cloud Functions with direct document/subcollection operations.
- Switched `locationRepositoryProvider` to `OrignaBaseLocationRepository` so address suggestions no longer depend on Firebase Functions in the default provider wiring.

## Deploy Hardening (2026-03-10)
- Updated Hetzner web deploy to stage each build into `/var/www/orignagta/releases/<timestamp>` and only switch live traffic by atomically replacing `/var/www/orignagta/current`.
- Updated Caddy to serve from `/var/www/orignagta/current`, preventing partial-file exposure during deploy and aligning cutover with a professional release swap model.
- Replaced stale `profile_viewmodel` unit coverage that still expected removed auth repository calls; tests now validate the active OrignaBase auth/API contract.
