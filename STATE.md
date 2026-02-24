# STATE.md

All audit findings resolved as of 2026-02-24. See commit `5871a3f`.

## Remaining / Future Work
- Playwright E2E tests: run against dev environment to find any broken tests post-changes
- Add more E2E test coverage for:
  - Stock notification subscribe/unsubscribe with variantKey
  - Digital product purchase → license generation flow
  - Async payment (Interac) confirmation flow
  - Multi-seller cart → per-seller payout verification
- `AVG_RESPONSE_TIME_HOURS` tracking: implement actual response time calculation (currently always 0.0)
- Image upload atomicity: move product image uploads inside a single atomic backend function (currently client uploads then passes URLs)

## Agent Notes
- 3 new agents added: `performance-auditor`, `refactor-auditor`, `code-comments-auditor`
- `payment-auditor` checklist updated with auto-capture + seller_profiles invariants
- `logic-auditor` updated with known architecture rules
