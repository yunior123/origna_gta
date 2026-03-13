# OrignaGTA Monorepo

This repo contains:
- Flutter app: origna_gta
- Hosting/config artifacts at the repo root
- Legacy backend/tests under `functions/` are not part of the active Flutter runtime path

## Backend contract
- `orignabaseUrl` is the only primary backend for auth, data, and business logic in the active app path.
- `baseUrl` is the public web host used for browser routes and share links.
- No Firebase hosting; all web hosting on Hetzner VPS with Caddy. Firebase not used for hosting.

## Architecture overview
- MVVM in Flutter
- OrignaBase owns auth/data/service calls for the active app path
- Idempotent payment and webhook processing
- Product ratings are submitted through server-side validation

**New Collections**:
- `security_alerts`: Immutable audit log for fraud/suspension events (admin read-only)

**New Order Fields**:
- `sellerCaptures`: Per-seller capture tracking
- `captureAttempts`: Auto-capture failure counter
- `requiresManualReview`: Admin intervention flag
- `fraudScore`: Dispute risk score (0-100)

**Cronjobs**:
- `check_expired_authorizations_scheduled`: Daily 2 AM UTC (cancels expired payment holds)

## End-to-end flow (payments)
```mermaid
sequenceDiagram
  participant U as User
  participant App as Flutter App
  participant API as OrignaBase API
  participant Stripe as Stripe
  participant DB as OrignaBase DB

  U->>App: Start checkout
  App->>API: create_checkout_session (idempotencyKey)
  API->>DB: Validate stock, reserve, create order
  API->>Stripe: Create Checkout Session (manual capture, tax)
  Stripe-->>App: Hosted checkout URL
  Stripe-->>API: Webhooks (session completed / PI status)
  API->>DB: Update order totals, taxes, status
  App->>API: confirm_order_receipt
  API->>Stripe: Capture payment
```

## Quick commands
- Run all tests: scripts/run_all_tests.sh
- Run strict quality gate locally in safe mode: ./scripts/run_quality_gate.sh
- Force full local strict gate (not recommended on 8GB RAM): ./scripts/run_quality_gate.sh --allow-local-heavy --backend-gate-mode strict
- Strict quality gate (100% + real E2E): scripts/run_quality_gate.sh
- Real browser E2E smoke: scripts/run_real_e2e_smoke.sh
- Deploy web to VPS using scripts/deploy_web.sh (no Firebase hosting)
- Hetzner web deploys use staged releases under `/var/www/orignagta/releases/<timestamp>` with an atomic switch of `/var/www/orignagta/current`
- Install pre-push hook (safe local checks by default): scripts/install_git_hooks.sh
- Flutter analyze: (cd origna_gta) flutter analyze
- Flutter tests: (cd origna_gta) flutter test
- Playwright coverage target: (cd e2e) E2E_SKIP_GLOBAL_SETUP=true npx playwright test playwright_ui/coverage-gate.spec.ts --config=playwright.config.dev.ts --project=chromium
- Functions tests: (cd functions) pytest
- Configure Algolia index: Call `configure_algolia` Cloud Function (admin only)

## Flutter integration tests
```bash
# Lightweight local command
cd origna_gta
flutter test integration_test/coverage_gate_integration_test.dart
```

- The enforced 100% integration coverage gate runs remotely in GitHub Actions on Linux desktop and in Codemagic on macOS.
- Local heavy integration/device runs are intentionally not the default because this repository targets an 8GB developer machine.

## Quality gates and CI
- GitHub Actions workflow: `.github/workflows/strict-quality-audit.yml`
  - Enforces backend coverage at 100%
  - Enforces Flutter unit coverage at 100%
  - Enforces Flutter integration coverage at 100%
  - Runs the real Playwright buyer/seller/order flows
  - Enforces Playwright coverage at 100%
- Codemagic workflow: `origna_gta/codemagic.yaml` → `quality-gate-remote`
- Local `./scripts/run_quality_gate.sh` defaults to backend-only safe mode unless `--allow-local-heavy` is set.
- Installed pre-push hook defaults to lightweight local checks only.
  - Force heavy local pre-push validation: `ALLOW_LOCAL_HEAVY_PRE_PUSH=1 git push`
  - Force local deploy from the hook: `RUN_PRE_PUSH_DEPLOY=1 git push`
  - Default expectation: use GitHub Actions / Codemagic for heavy gates and deploy verification.

## CI / E2E
- GitHub Actions runs backend + Flutter tests and the strict real-flow Playwright suite remotely.
- Local E2E stack:
  - Start: `./scripts/start-e2e-services.sh`
  - Run: `(cd e2e && E2E_WORKERS=2 ./run-e2e-tests.sh flutter)`
  - Stop: `./scripts/stop-e2e-services.sh`
- Flutter web integration test:
  - Run: `./scripts/run_flutter_integration_tests_web.sh integration_test/app_test.dart`
- Playwright parallelism:
  - `E2E_WORKERS` overrides the worker count (CI uses a conservative default).
  - `E2E_PROJECT` can force a single browser project (e.g. `chromium`).
- Screenshots auto-saved to `~/Desktop/origna-screenshots/<env>/` after each run.

### Key real-flow specs — `e2e/playwright_ui/`

| Spec | Coverage |
|------|----------|
| `stripe-payment.spec.ts` | Stripe hosted checkout |
| `buyer-flow.spec.ts` | Browse → cart → checkout → order |
| `seller-flow.spec.ts` | List product → ship → payout |
| `order-lifecycle.spec.ts` | Full order state machine |
| `order-cancellation-refund.spec.ts` | Cancel + return + refund |
| `shipping-approval.spec.ts` | Shipping cost approval |
| `shipping-calculation.spec.ts` | Province/distance/weight pricing |
| `checkout-validation.spec.ts` | Form validation + coupons |
| `payment-edge-cases.spec.ts` | Declined card, 3DS |
| `multi-seller-orders.spec.ts` | Cross-seller cart + auth |
| `add-product-e2e.spec.ts` | Add product + images + warehouse |
| `seller-product-management.spec.ts` | Edit/pause/archive products |
| `seller-registration.spec.ts` | Stripe Connect onboarding |
| `warehouse-multi-location.spec.ts` | Warehouse CRUD |
| `digital-product-e2e.spec.ts` | Buy digital + license |
| `premium-subscription.spec.ts` | Subscribe + paywall + cancel |
| `favorites.spec.ts` | Toggle + list favorites |
| `profile-management.spec.ts` | Profile + address CRUD |
| `search-products.spec.ts` | Algolia search + filters |
| `trending-products.spec.ts` | Trending section |
| `admin-actions.spec.ts` | Admin product/user actions |
| `admin-panel.spec.ts` | Admin panel tabs |
| `admin-security.spec.ts` | Role enforcement |
| `edge-cases-security.spec.ts` | Self-purchase, price tamper, race |
| `rate-limiting.spec.ts` | Rate limit enforcement |
| `new-coverage-e2e.spec.ts` | Additional subscription + stock notification coverage |
| `smoke-home-profile.spec.ts` | App smoke tests |

Coverage-specific gate files:
- `origna_gta/test/coverage_gate_test.dart`
- `origna_gta/integration_test/coverage_gate_integration_test.dart`
- `e2e/playwright_ui/coverage-gate.spec.ts`
- `e2e/playwright_ui/coverage_gate.ts`
- `e2e/playwright.config.dev.ts` skips `global-setup.ts` when `E2E_SKIP_GLOBAL_SETUP=true`, which keeps the coverage-only Playwright gate off the legacy Firebase-auth prewarm path.

## origna_flows/ — AI Flow Context Bundles

Source and test files bundled for Claude.ai per-flow auditing.

```bash
python3 scripts/collect_flow_files.py
# → ~/Desktop/origna_flows/<flow_name>/  (62 flows, ≤20 files each)
```

| Type | Count | Purpose |
|------|-------|---------|
| Audit flows (`checkout_payment`, `security`, …) | 35 | Drop into Claude.ai → audit source code |
| Test flows (`test_stripe_payment`, …) | 27 | Drop into Claude.ai → audit/extend E2E tests |

Each test flow: spec file + `api-helpers.ts` + `flutter-helpers.ts` + `origna_flows/SEMANTICS.md` + supporting source.

Repo docs (`origna_flows/`):
- `SEMANTICS.md` — Flutter Key/label/role map for every screen
- `FLOWS.md` — 15 user journeys with step-by-step test assertions
- `INSTRUCTIONS.md` — Playwright patterns, selectors, coverage gaps, environments


## Flutter Web performance (release checklist)
- Measure in profile mode:
  - `cd origna_gta && flutter run -d chrome --profile`
- Capture a trace in Chrome DevTools (Performance tab) on:
  - cold start (first meaningful paint)
  - home feed scroll
  - add-to-cart → checkout navigation
- Keep an eye on:
  - excessive rebuilds (Flutter DevTools)
  - large images (ensure resize/compress, cache headers)
  - expensive JSON parsing on UI thread (move to isolates if needed)

## Search Architecture (Algolia)
- **Primary Search**: Algolia for fast, typo-tolerant product search
- **Fallback**: OrignaBase-backed keyword search if Algolia is unavailable
- **Auto-Indexing**: Products are synced by backend services, not by the Flutter runtime
- **Credentials**: Stored in backend-managed secrets/config, not in the Flutter runtime
  - `ALGOLIA_APP_ID` (public)
  - `ALGOLIA_SEARCH_API_KEY` (search-only, frontend-safe)
  - `ALGOLIA_WRITE_API_KEY` (backend-only)

**Algolia Features**:
- Instant search with debouncing (500ms)
- Category filtering
- Searchable attributes: name, description, keywords
- Firestore field name: keywords (array) for both Algolia and fallback
- Custom ranking: rating → ratingCount → createdAt
- Highlighting enabled
- 20 results per page

**Setup**:
1. Add keys to the backend environment/config
2. Deploy the active backend services
3. Configure index settings through the backend admin path
4. Products auto-index on create/update/delete

## Docs
- App README: origna_gta/README.md
- Functions README: functions/Readme.md

## Environments
- **Development**: `flutter run -d chrome --dart-define=ENVIRONMENT=dev`
- **Staging**: `flutter run -d chrome --dart-define=ENVIRONMENT=staging`
- **Production**: `flutter run -d chrome --dart-define=ENVIRONMENT=production` (Default)
- **Emulators**: `flutter run -d chrome --dart-define=ENVIRONMENT=emulator`

### Deployment
Web hosting is now on Hetzner VPS (Caddy + staged releases in /var/www/orignagta/{env}/releases/<ts> with current symlink). Firebase hosting disabled.
```bash
# Web hosting to VPS (set VPS_HOST=user@ip)
VPS_HOST=youruser@your-vps-ip ./scripts/deploy_web.sh production
# Or for dev/staging subdomains
VPS_HOST=youruser@your-vps-ip ./scripts/deploy_web.sh dev
```
Backend remains on VPS (OrignaBase).

## Architecture Notes
- Canada-only delivery enforced in backend handlers (buyer/shipping addresses only; sellers can be worldwide).
