# STATE.md — Current Verified State

## Snapshot
- Date: `2026-04-03`
- Critical path: backend live -> Flutter live -> E2E/design

## VPS / Runtime
- SSH intermittent (connection refused on rapid reconnects), HTTP endpoints healthy
- Health: dev=200 ok, staging=200 ok, prod=200 ok
- VPS: 7.5GB RAM (677MB used), 42GB disk free (58%), 6 containers running
- Dev image: `2026-04-02 08:18:25 UTC`

## Backend Live — Verified 2026-04-03

| Suite | Result | Notes |
|-------|--------|-------|
| smoke | 12/12 | |
| security_fixes | 15/15 | |
| payment_fixes | 10/10 | |
| search | 19/19 | |
| shipping | 3/3 | |
| order_lifecycle | 5/5 | |
| returns_refunds | 4/4 | |
| reliability | 15/15 | |
| stress | 9/9 | |
| push_notifications | 23/23 | |
| realtime | 8/9 | `test_ws_unsubscribe` — race condition (fixed locally, needs deploy) |
| cross_service | 12/12 | |
| mcp | 9/9 | |
| product_repo | 17/17 | |
| cart_repo | 9/9 | |
| order_repo | 7/7 | |
| new_features | 10/10 | |
| coupon | 3/3 | |
| logout | 3/3 | |
| user_repo | 12/12 | |
| admin | 3/4 | stale deploy |
| auth_repo | 19/20 | logout test fixed locally |
| handlers | 167/168 | subscription interval validation fixed locally |
| pentest | 30/30 | |

## Backend Unit Tests — 2026-04-03
- `cargo clippy -- -D warnings`: clean (all crates)
- `cargo test -p ob-auth --lib`: 285 passed, 0 failed
- `cargo test -p ob-handlers --lib`: 1783 passed; 0 failed when run sequentially (`--test-threads=1`)
  - Parallel failures (7) are shared PostgreSQL interference, not code bugs
- `cargo test -p ob-database`: 85 passed, 0 failed

## Flutter — 2026-04-03
- `flutter analyze --no-fatal-infos`: 0 issues
- `flutter test --exclude-tags golden`: 4,691 passed, 0 failed

## E2E API Tests — 2026-04-03
- New: `api-contract-edge-cases.spec.ts` — 56 tests added
- Results: 55/56 pass, 1 fail (CORS origin reflection — source code correct, stale deploy)

## Fixes Applied This Session

23. **`subscriptions.rs` (ob-handlers)** — Added `interval`, `product_id`, `quantity` fields to `CreateSubscriptionRequest` with validation. Invalid intervals now return 400. Clippy clean.

24. **`revocation.rs` (ob-auth)** — Added missing `acquire_refresh_rotation_lock` function with `RotationLockTx` type using PostgreSQL advisory locks. Added `rotation_lock_key` derivation. Test uses unique token to avoid parallel interference.

25. **`schema.rs` (ob-handlers)** — Removed duplicate `PENDING_SENT_AT` and `PENDING_UPDATED_AT` constants.

26. **`cron/mod.rs` (ob-handlers)** — Payout update error handling: replaced `let _ =` with `match` that logs failures via `warn!` and increments `failed_count`.

27. **`login_tracking.rs` (ob-auth)** — Added test guard (`ob_test_mode_guard()`) and database verification assertion to `test_check_suspicious_known_device` to prevent parallel test interference.

28. **`auth_repository_test.rs`** — Fixed `test_auth_logout` to capture and send `refresh_token` in body instead of access token in header.

29. **`realtime_integration_test.rs`** — Fixed `test_ws_unsubscribe` race condition by draining messages until expected response type found.

30. **`product_image_helpers.dart`** — Removed duplicate/unused imports.

31. **E2E API test expansion** — Added `api-contract-edge-cases.spec.ts` with 56 new tests.

## Active Blockers
- **CORS security**: Deploy needed (source code correct with explicit whitelisting)
- **Admin test**: Stale deploy — `/admin/users` omits `email` (source fixed)
- **Subscription interval test**: Fix applied locally, needs deploy
- **Realtime unsubscribe**: Fix applied locally, needs deploy
- **Auth logout test**: Fix applied locally, needs deploy
- **Production health route**: Caddyfile deploy pending
- **Flutter live**: Broader live wave still has failures in admin/product/chat areas
- **Parallel test interference**: 7 ob-handlers tests fail in parallel due to shared PostgreSQL — pass sequentially (infrastructure issue, not code bug)
