# STATE - AUDIT IN PROGRESS

## Recent Fixes
- Fixed `decorator_passthrough` in `functions/tests/conftest.py` to handle both `@decorator` and `@decorator()` usages. This resolved multiple `TypeError` and cascading failures.
- Fixed `functions/tests/test_adversarial_scenarios.py` by changing `Mock` to `MagicMock` for `mock_collection` and making `doc_id` optional in `make_doc_ref`. This resolved the `'Mock' object is not iterable` error.
- Added missing `Seller ID mismatch` and `Product Lifecycle Status` validations in `create_checkout_session` (`payment_stripe.py`).
- Fixed `functions/tests/test_checkout_fixes_Feb2026.py` by correctly mocking `db.transaction()` to capture order saves.
- Implemented missing `submitRatingAtomic` in `AlgoliaProductRepository` (`algolia_product_repository.dart`) to fix frontend compilation.
- Eliminated magic strings for collection names in `OrderEvent.write`.
- Centralized rate limit action strings into `RateLimitActions` class in both `schema_constants.py` and `schema_constants.dart`.
- Replaced magic strings for rate limit actions with `RateLimitActions` constants across all backend handlers.
- Used `ApiKeys` constants for GDPR data export response keys in `admin.py`.

## Test Status
- Frontend: `flutter test` - **PASSING** (170 tests)
- Backend: `pytest functions/tests` - **IN PROGRESS** (449 tests, first ~100 passing)
- **E2E (2026-03-01):**
  - `api-coverage.spec.ts` — **80 passed, 0 skipped, 0 failed** (covers 65+ previously-uncovered Cloud Functions)
  - `deep-ui-scenarios.spec.ts` — Created, TypeScript compiles clean, not yet run against dev
  - Total spec files: **36** (was 34, added api-coverage + deep-ui-scenarios)
  - Fixed broken imports across 15+ spec files (TEST_ACCOUNTS aliases, missing utility functions)
  - Two `api-helpers.ts` files: `e2e/api-helpers.ts` (emulator) and `e2e/playwright_ui/api-helpers.ts` (dev Firebase)

## Next Steps
1. Complete full backend test run.
2. Deploy updated Firestore indexes and rules.
3. Run deep-ui-scenarios.spec.ts against dev.
4. Set admin user as premium in dev Firebase for full Q&A/chat E2E coverage.
5. Deploy `toggle_favorite` + `bulk_update_products` functions to dev (currently 404).
