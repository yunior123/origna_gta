# Testing Rules — origna_gta

## Core Commands
- Flutter unit/widget tests: `flutter test`
- Static analysis: `flutter analyze --no-fatal-infos`
- Both must pass with zero failures before any commit or PR.
- Run analysis before tests to catch compile errors fast.

## Local vs Remote Testing (8GB RAM constraint)
- Unit/widget tests run locally with mocked SDK — no services needed
- Live integration tests run against dev OrignaBase (`api.dev.orignagta.ca`)
- E2E tests run against dev web (`dev.orignagta.ca`)
- Local OrignaBase (`ENVIRONMENT=emulator`, localhost:8080) is supported but use cautiously — 8GB RAM means run one service at a time, never parallel builds
- No local Docker/colima required — all heavy services live on the VPS
- Dev test accounts: Admin `yr62813@gmail.com`, Seller `yuniorrodriguezo4601@yahoo.com`, Buyer `yuniorrodriguezo460@gmail.com` (password: `REDACTED_TEST_PASSWORD`)

## Unit Tests
- Every ViewModel and Service must have unit tests.
- Mock OrignaBase SDK responses — never make real API calls in unit tests.
- Test all order state transitions explicitly.
- Test money calculations: verify cents arithmetic, platform fee, free shipping threshold.
- Use `mocktail` or `mockito` for mocking — pick one and be consistent.
- Test file mirrors source: `lib/viewmodels/cart_viewmodel.dart` → `test/viewmodels/cart_viewmodel_test.dart`.

## Widget Tests
- Smoke test all screens: widget builds without overflow/exception.
- Test loading, error, and empty states for every list screen.
- Test form validation on: add product, checkout address, login, register.
- Use `pumpWidget` with `ProviderScope` and stubbed providers.

## E2E Tests (Playwright)
- Config: `e2e/playwright.config.dev.ts` — workers: 2 (8GB RAM), fullyParallel: false, timeout: 300s
- Base URL: `https://dev.orignagta.ca`
- API: `https://api.dev.orignagta.ca` (OrignaBase VPS — no Cloud Functions)
- Always deploy latest Flutter web build before running E2E
- Build: `flutter build web --debug --dart-define=ENVIRONMENT=dev --dart-define=FORCE_SEMANTICS=true`

## Stable E2E Products (always exist in dev)
| Product ID | Purpose |
|---|---|
| `e2e_product_admin_seller` | Adversarial tests (seller has no relationship) |
| `e2e_product_test_seller` | General seller product tests |
| `e2e_product_intl_seller` | China address — international shipping tests |

## Test Isolation
- E2E tests must clean up after themselves (delete created orders, products, etc.).
- Use seed scripts in `e2e/scripts/seed/` to set up required data before test runs.
- Never depend on test execution order — each test must be independently runnable.

## GitHub Actions CI
- CI runs on every PR: `flutter analyze --no-fatal-infos` + `flutter test`
- Failures → email notification to `support@orignagta.ca` (requires `MAIL_USERNAME` + `MAIL_PASSWORD` secrets)
- E2E tests run on merge to `main` only (too slow for every PR)
- Secrets: `STRIPE_TEST_KEY`, `MAIL_USERNAME`, `MAIL_PASSWORD`

## Coverage Targets
- ViewModels: ≥80% line coverage.
- Services: ≥70% line coverage.
- Screens: smoke tests required; full coverage not mandated.
- Payment-critical paths (checkout, webhook handling, refunds): 100% branch coverage.

## What NOT to Test
- Third-party SDK internals (OrignaBase SDK).
- Pure UI layout pixel measurements.
- Dart/Flutter framework internals.

## Forbidden in Tests
- `print()` or `debugPrint()` in test files.
- Real Stripe live-mode API calls.
- Running parallel heavy services locally (8GB RAM — one at a time).
- `sleep()` / `Future.delayed()` in tests — use `pumpAndSettle()` or proper async patterns.
- Hardcoded UIDs or tokens — use test account constants from a shared test helpers file.
