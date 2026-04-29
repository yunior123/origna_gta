# OrignaGTA Monorepo

Origna GTA is a Canada-first multi-vendor e-commerce platform where buyers browse, and local sellers list physical, digital, and perishable products with integrated shipping, payments, and seller payouts.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.41.5 + Dart 3.11.0, Riverpod, Freezed |
| Backend API | OrignaBase (Rust, VPS `204.168.137.16`) |
| Database | PostgreSQL 18 (via OrignaBase) |
| Search | Meilisearch v1.12 (via OrignaBase) |
| Payments | Stripe Checkout + Connect + webhooks |
| Bot protection | Cloudflare Turnstile |
| Error tracking | Self-hosted GlitchTip 6.1.6, using the Sentry-compatible Flutter SDK |
| Web proxy | Caddy (on VPS) |
| E2E tests | agent-browser (TypeScript) |

No Firebase. No Cloud Functions. No Firestore.

This repo contains:
- Flutter app: `origna_gta/`
- agent-browser E2E suite: `e2e/`
- Ventures frontend/backend: `origna_ventures/`
- OrignaBase Rust backend workspace: `orignabase/`
- VPS deploy scripts: `scripts/`

## Core Docs For Humans And Agents

- Repo map: `docs/REPO_MAP.md`
- Agent rules: `AGENTS.md`
- Routing/context file: `CLAUDE.md`
- Error codes and support-event model: `docs/ERROR_CODES.md`
- AI skills inventory: `docs/AI_SKILLS_CATALOG.md`

## External References In Active Use

- Flutter: https://docs.flutter.dev/
- Rust: https://doc.rust-lang.org/stable/book/
- Stripe Checkout Sessions: https://docs.stripe.com/api/checkout/sessions
- Postal Send API v3.1: https://documentation.postal.com/hc/en-us/articles/16886347025947-Postal-Templating-Language
- PostgreSQL current docs: https://www.postgresql.org/docs/current/
- GlitchTip Flutter SDK: https://glitchtip.com/sdkdocs/dart-flutter/

## Backend contract
- `orignabaseUrl` is the only primary backend for auth, data, and business logic in the active app path.
- `baseUrl` is the public web host used for browser routes and share links.
- All web hosting on VPS with Caddy (staged releases).

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
- agent-browser coverage target: (cd e2e) E2E_SKIP_GLOBAL_SETUP=true npx agent-browser test agent-browser_ui/coverage-gate.spec.ts --config=agent-browser.config.dev.ts --project=chromium

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
  - Runs the real agent-browser buyer/seller/order flows
  - Enforces agent-browser coverage at 100%
- Codemagic workflow: `origna_gta/codemagic.yaml` → `quality-gate-remote`
- Local `./scripts/run_quality_gate.sh` defaults to backend-only safe mode unless `--allow-local-heavy` is set.
- Installed pre-push hook defaults to lightweight local checks only.
  - Force heavy local pre-push validation: `ALLOW_LOCAL_HEAVY_PRE_PUSH=1 git push`
  - Force local deploy from the hook: `RUN_PRE_PUSH_DEPLOY=1 git push`
  - Default expectation: use GitHub Actions / Codemagic for heavy gates and deploy verification.

## CI / E2E
- GitHub Actions runs backend + Flutter tests and the strict real-flow agent-browser suite remotely.
- Local E2E stack:
  - Start: `./scripts/start-e2e-services.sh`
  - Run: `(cd e2e && E2E_WORKERS=2 ./run-e2e-tests.sh flutter)`
  - Stop: `./scripts/stop-e2e-services.sh`
- Flutter web integration test:
  - Run: `./scripts/run_flutter_integration_tests_web.sh integration_test/app_test.dart`
- agent-browser parallelism:
  - `E2E_WORKERS` overrides the worker count (CI uses a conservative default).
  - `E2E_PROJECT` can force a single browser project (e.g. `chromium`).
- Screenshots auto-saved to `~/Desktop/origna-screenshots/<env>/` after each run.

### Key real-flow specs — `e2e/agent-browser_ui/`

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
- `e2e/agent-browser_ui/coverage-gate.spec.ts`
- `e2e/agent-browser_ui/coverage_gate.ts`
- `e2e/agent-browser.config.dev.ts` skips `global-setup.ts` when `E2E_SKIP_GLOBAL_SETUP=true`, which keeps the coverage-only agent-browser gate off the auth prewarm path.


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

## Search Architecture 


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
