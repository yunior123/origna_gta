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
