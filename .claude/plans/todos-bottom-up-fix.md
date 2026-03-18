# Plan: Solve TODOS.md — Starting from Bottom

## Context
276 E2E Playwright test failures + 2 unchecked non-E2E items (31, 32). Attacking from the bottom of TODOS.md upward. Three root causes explain 80%+ of failures:

1. **[auth] root cause** — `create_product_atomic failed: Authentication error: Authentication required` — 60+ tests. `TEST_ACCOUNTS` in `api-helpers.ts` uses old Gmail accounts (`yr62813@gmail.com`, `yuniorrodriguezo4601@yahoo.com`) which may not have valid OrignaBase sessions. Fix: update to working dev accounts from MEMORY.md (`e2e-admin@test.origna.ca`, `e2e-seller@test.origna.ca`, `e2e-buyer@test.origna.ca`).

2. **[error-code-mismatch] root cause** — ~50 tests. `HTTP_TO_CODE` map in `api-helpers.ts` is missing codes (502, 504, 410, 405) and doesn't normalize OrignaBase-specific error body formats. Fix: expand the map + normalize `code` field from OrignaBase error payloads.

3. **[ui-semantics] root cause** — ~40 tests. Missing/wrong semantic labels on interactive elements. Key gaps: `nav-profile` in bottom nav, support category buttons using i18n translation keys instead of translated text.

---

## Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1: Auth Fix | ✅ DONE | commit 5ec0b0922 |
| Phase 2: Error Code Normalization | ✅ DONE | commit 5ec0b0922 |
| Phase 3: Semantics Fixes | ✅ DONE | nav-profile→btn-home-settings in support-agent.spec.ts |
| Phase 4: Bottom Spec Files | ⬜ TODO | warehouse, stock-notif, return-request |
| Phase 5: Items 31-32 | ✅ DONE (31) / ⬜ TODO (32) | error_messages.dart created |

---

## Phase 1: Auth Fix ✅ DONE

### File: `e2e/playwright_ui/api-helpers.ts`

Updated `TEST_ACCOUNTS` to use confirmed-working OrignaBase dev accounts:

```typescript
export const TEST_ACCOUNTS = {
  ADMIN_EMAIL: 'e2e-admin@test.origna.ca',
  ADMIN_PASS: 'REDACTED_TEST_PASSWORD',
  SELLER_EMAIL: 'e2e-seller@test.origna.ca',
  SELLER_PASS: 'REDACTED_TEST_PASSWORD',
  BUYER_EMAIL: 'e2e-buyer@test.origna.ca',
  BUYER_PASS: 'REDACTED_TEST_PASSWORD',
  // ...aliases
};

export const TEST_UIDS = {
  ADMIN: 'users:9w0xa6lkt9f4oglea65c',
  SELLER: 'users:lvoqmdam21bhaxd2fjgi',
  BUYER: 'users:itdb9cyp3nu45owy4bo1',
};
```

---

## Phase 2: Error Code Normalization ✅ DONE

### File: `e2e/playwright_ui/api-helpers.ts`

Expanded `HTTP_TO_CODE` map:
```typescript
405: 'unimplemented',
410: 'not-found',
502: 'unavailable',
504: 'deadline-exceeded',
```

Improved `normalizeErrorCode` to extract `code` field from OrignaBase Rust error body before falling back to HTTP status.

---

## Phase 3: Semantics Fixes ✅ DONE

### 3a. `e2e/playwright_ui/support-agent.spec.ts` — T05 nav-profile fix
- App has NO bottom tab bar — profile accessed via `btn-home-settings` gear icon
- Updated T05 to use `page.getByRole('button', { name: 'btn-home-settings' })` + `page.goto(TARGET_URL)` first

### 3b. `lib/features/support/support_screen.dart` — Category labels
- Already correct: `label: labelKey.tr()` emits translated text ✅

### 3c. `lib/screens/home_screen.dart` — Sort/price filter labels
- Already correct: `btn-home-sort` and `btn-home-price-filter` already present ✅

---

## Phase 4: Bottom Spec Files — Targeted Fixes ⬜ TODO

### 4a. `e2e/playwright_ui/warehouse-multi-location.spec.ts`
- T1 (missing-endpoint): `create_warehouse` returns null → verify `portedRequest` maps to `/api/warehouses`
- T3 (error-code-mismatch): duplicate sellerSku expects `already-exists`
- T4/T5 (db-parse-error): product null after warehouse creation

### 4b. `e2e/playwright_ui/visual-regression.spec.ts`
- Update snapshot baselines

### 4c. `e2e/playwright_ui/support-agent.spec.ts`
- T01: unauthenticated redirect — verify `/support` → `/login` redirect works
- T02-T05: depends on live support AI endpoint

### 4d. `e2e/playwright_ui/stock-notif.spec.ts`
- Auth failures (3.5, 3.10, 4.1): fixed by Phase 1
- UI semantics (1.1-1.6, 2.1): need OOS product `e2e_product_oos` seeded with `stockQuantity: 0`

### 4e. `e2e/playwright_ui/return-request.spec.ts`
- db-parse-error: `readDoc('products/product_001')` — product_001 may not exist in dev
- Fix: use `e2e_product_test_seller` or `e2e_product_admin_seller` instead

---

## Phase 5: Unchecked Non-E2E Items

### Item 31: Error Code Table for UX ✅ DONE
- Created `lib/utils/error_messages.dart` with `ErrorMessages.format(code)`
- Format: `Error [ORIGNA-XXX-NNN]: description`
- Wraps `ErrorCodes.describe()` from existing `error_codes.dart`

### Item 32: VPS Security Research ⬜ TODO
Research tasks (no code changes):
1. Enable `fail2ban` for SSH + HTTP rate limiting (5 failures/min → 10 min ban)
2. `ufw` rules (already done — `ufw limit 22/tcp`)
3. Enable `unattended-upgrades` for auto security patches
4. Disable root login in SSH (`PermitRootLogin no`)
5. Set `HSTS` header in Caddy config
6. Add `X-Frame-Options: DENY` and `X-Content-Type-Options: nosniff` headers in Caddy

---

## Critical Files

| File | Change | Status |
|------|--------|--------|
| `e2e/playwright_ui/api-helpers.ts` | TEST_ACCOUNTS + TEST_UIDS + HTTP_TO_CODE | ✅ DONE |
| `e2e/playwright_ui/support-agent.spec.ts` | nav-profile → btn-home-settings | ✅ DONE |
| `origna_gta/lib/utils/error_messages.dart` | ErrorMessages.format() utility | ✅ DONE |
| `e2e/playwright_ui/warehouse-multi-location.spec.ts` | portedRequest mappings | ⬜ TODO |
| `e2e/playwright_ui/stock-notif.spec.ts` | OOS stable product ID | ⬜ TODO |
| `e2e/playwright_ui/return-request.spec.ts` | Fix product_001 reference | ⬜ TODO |
| `e2e/playwright_ui/visual-regression.spec.ts` | Update screenshot baselines | ⬜ TODO |

---

## Verification Commands
```bash
# TypeScript check:
cd e2e && npx tsc --noEmit

# Flutter analysis:
cd origna_gta && /Users/yuniorrodriguezosorio/flutter/bin/flutter analyze --no-fatal-infos

# Full E2E run (against dev):
cd e2e && npx playwright test --config=playwright.config.dev.ts --reporter=list 2>&1 | tail -30
```
