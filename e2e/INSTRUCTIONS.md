# E2E Playwright — Quick Instructions

Full docs: `e2e/README.md`

---

## 1. Prerequisites

```bash
cd e2e && npm install
npx playwright install chromium
```

Node.js LTS required. No Firebase. Tests run against OrignaBase backend on VPS.

---

## 2. Build Flutter app before running tests

Always deploy a fresh Flutter web build to the dev VPS before running E2E tests.

```bash
# Build with semantics enabled (required for Playwright selectors)
cd origna_gta
flutter build web --debug \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=FORCE_SEMANTICS=true

# Deploy to VPS
cd ..
VPS_HOST=root@204.168.137.16 ./scripts/deploy_web.sh dev
```

---

## 3. Run tests

```bash
cd e2e

# All tests against dev
E2E_TARGET_URL=https://dev.orignagta.ca \
ORIGNABASE_URL=https://api.dev.orignagta.ca \
E2E_AUTH_PROVIDER=orignabase \
npx playwright test --config=playwright.config.dev.ts --workers=2

# Single spec
npx playwright test playwright_ui/buyer-flow.spec.ts \
  --config=playwright.config.dev.ts

# Coverage gate only
npx playwright test playwright_ui/coverage-gate.spec.ts \
  --config=playwright.config.dev.ts \
  --project=chromium \
  --workers=1
```

Keep `--workers` at 2 or less on the local 8 GB machine.

---

## 4. Test accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | `yr62813@gmail.com` | `REDACTED_TEST_PASSWORD` |
| Seller 1 | `seller1@test.origna.ca` | `REDACTED_TEST_PASSWORD` |
| Seller 2 | `seller2@test.origna.ca` | `REDACTED_TEST_PASSWORD` |
| Buyer 1 | `buyer1@test.origna.ca` | `REDACTED_TEST_PASSWORD` |
| Buyer 2 | `buyer2@test.origna.ca` | `REDACTED_TEST_PASSWORD` |
| Buyer 3 | `buyer3@test.origna.ca` | `REDACTED_TEST_PASSWORD` |
| Suspended | `suspended@test.origna.ca` | `REDACTED_TEST_PASSWORD` |
| Non-onboarded seller | `seller9@test.origna.ca` | `REDACTED_TEST_PASSWORD` |

---

## 5. Seed test data

```bash
python ../scripts/seed_orignabase.py --url https://api.dev.orignagta.ca
```

For 2000 products (bulk load):
```bash
python ../e2e/scripts/seed/seed_orignabase_2000.py
```

---

## 6. View reports

```bash
# HTML report (after a run)
cd e2e && npx playwright show-report

# Traces on failure
npx playwright show-trace test-results/<run>/trace.zip
```

Screenshots on failure: `~/Desktop/origna-screenshots/dev/`

---

## 7. CI

GitHub Actions: `.github/workflows/strict-quality-audit.yml`
- Runs full Playwright suite remotely
- Do NOT run heavy parallel tests locally on the 8 GB machine
