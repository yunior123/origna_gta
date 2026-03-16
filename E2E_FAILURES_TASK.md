# Task: Fix 335 Failing E2E Tests

## Context
Pipeline infra is GREEN. The 335/451 E2E failures are test assertion failures —
tests expect behaviors that differ from what OrignaBase dev currently returns.

## Branch: main (always commit directly to main — no branches)

## Shard Results (run 23124459741 — 2026-03-16)
| Shard | Failed | Passed | Time |
|-------|--------|--------|------|
| 1/8   | 41     | 18     | 38m  |
| 2/8   | 57     | 14     | 27m  |
| 3/8   | 34     | 20     | 30m  |
| 4/8   | 43     | 17     | 38m  |
| 5/8   | 48     | 8      | 33m  |
| 6/8   | 33     | 24     | 22m  |
| 7/8   | 51     | 7      | 32m  |
| 8/8   | 28     | 8      | 40m  |

## Top Failing Spec Files (from logs)
- `adversarial-injection.spec.ts` — all security/validation tests fail (API returns wrong status codes or body shape)
- `api-coverage.spec.ts` — raw API call tests fail (auth, products, addresses, Q&A, ratings, admin, coupons, warehouses)
- Others: address-management, admin-panel, buyer-flow, seller-flow, checkout-validation, etc.

## Root Causes to Investigate
1. **API response shape mismatch** — tests assert on `response.data.xyz` but OrignaBase returns different structure
2. **Auth setup missing** — `global-setup.ts` is NOT run in CI (config.ci.ts has no globalSetup) → many tests fail immediately on auth
3. **Test accounts not seeded** — dev DB may lack required test data (products, orders, coupons)
4. **Status code mismatches** — tests expect 422/401/403 but OrignaBase returns 200 with error body, or vice versa

## Fix Strategy

### Step 1: Check if global-setup.ts is needed
```bash
head -30 e2e/playwright_ui/global-setup.ts
```
If it seeds auth state, add it back to `playwright.config.ci.ts`.

### Step 2: Run a single failing spec locally to understand errors
```bash
cd e2e && npx playwright test playwright_ui/adversarial-injection.spec.ts \
  --config=playwright.config.dev.ts --reporter=list --project=chromium 2>&1 | head -80
```

### Step 3: Check api-coverage failures (largest category)
```bash
cd e2e && npx playwright test playwright_ui/api-coverage.spec.ts \
  --config=playwright.config.dev.ts --reporter=list --project=chromium 2>&1 | head -80
```

### Step 4: Fix each spec file — either:
- Update assertions to match actual OrignaBase API behavior
- Fix OrignaBase API if behavior is genuinely wrong
- Skip tests that require unavailable infrastructure (Stripe webhooks, etc.)

### Step 5: Verify in CI
```bash
git add . && git commit -m "fix(e2e): fix failing test assertions" && git push origin main
# Watch: gh run list --limit 2
```

## Key Files
- `e2e/playwright_ui/global-setup.ts` — auth state setup
- `e2e/playwright.config.ci.ts` — CI config (no globalSetup currently)
- `e2e/playwright_ui/api-helpers.ts` — API helper functions
- `e2e/playwright_ui/flutter-helpers.ts` — Flutter app helpers
- Dev test accounts: admin=yr62813@gmail.com, seller=yuniorrodriguezo4601@yahoo.com, buyer=yuniorrodriguezo460@gmail.com (all REDACTED_TEST_PASSWORD)
- Dev API: https://api.dev.orignagta.ca
- Dev web: https://dev.orignagta.ca

## CI Pipeline (working)
- Push to main → CI (flutter analyze + unit tests, ~9min) + CD (deploy + 8 E2E shards in parallel)
- E2E shards complete in 22-40min each
- Shard job timeout: 60min
