---
name: test-all
description: "Run ALL tests across the entire origna_gta monorepo — Flutter unit/widget/live, ALL 14 Rust crates (unit + integration + ignored + proptest + snapshots), SDK, E2E, benchmarks. Outputs results to /tmp/ files. Kills zombies first, monitors RAM. Use when asked to 'run all tests', 'test everything', 'full test suite', 'verify all', or before commits/deploys."
---

# Test All — Complete Monorepo Test Suite

Runs every test in the origna_gta monorepo sequentially (8GB RAM constraint). Kills zombie processes first, outputs all results to /tmp/ files, and reports a final summary.

## Complete Test Inventory

### Flutter (origna_gta/)

| Suite | Location | Count | Command |
|-------|----------|-------|---------|
| Unit + Widget | `origna_gta/test/unit/`, `test/widget/`, `test/screens/` | ~5,200+ | `flutter test --exclude-tags golden` |
| Live integration | `origna_gta/test/live/` (32 files) | ~190+ | `flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev test/live/` |
| Golden (visual) | `origna_gta/test/` (tagged) | ~23 | `flutter test --tags golden` (macOS only, skip in CI) |

### Rust — 14 Crates with Unit Tests

| Crate | Source | What it tests |
|-------|--------|---------------|
| `ob-core` | `src/*.rs` mod tests | Config, validation, error types, field values |
| `ob-database` | `src/*.rs` mod tests | CRUD, query translation, transactions, batch ops |
| `ob-auth` | `src/*.rs` mod tests | JWT, password hashing, TOTP, email, rate limiting |
| `ob-graphql` | `src/*.rs` mod tests | Schema builder, resolvers, batch mutations |
| `ob-security` | `src/*.rs` mod tests | Rules parser, evaluator, permission checks |
| `ob-handlers` | `src/**/*.rs` mod tests | All API handlers (payments, orders, products, users, chat, shipping) |
| `ob-mcp` | `src/*.rs` mod tests | MCP tools, safeguards, auth, transport |
| `ob-storage` | `src/*.rs` mod tests | Local storage, S3/R2, signed URLs, resumable uploads |
| `ob-search` | `src/*.rs` mod tests | Meilisearch client, search syncer |
| `ob-realtime` | `src/*.rs` mod tests | WebSocket handler, subscriptions, presence |
| `ob-notifications` | `src/*.rs` mod tests | FCM push, device tokens, topics |
| `ob-functions` | `src/*.rs` mod tests | WASM runtime, function registry |
| `ob-analytics` | `src/*.rs` mod tests | Event tracking, IP hashing |
| `ob-admin` | `src/*.rs` mod tests | Schema management, dashboard, user admin |

**Command:** `cd orignabase && cargo test --workspace`

### Rust — Integration Tests (crate-level `tests/` dirs)

| Crate | Files | What they test | Needs server? |
|-------|-------|----------------|---------------|
| `orignabase` | 32 files | Auth, orders, products, cart, payments, shipping, search, realtime, MCP, security, stress, reliability, concurrency, pentest | Most need `#[ignore]` + `OB_TEST_URL` |
| `ob-handlers` | 2 files | Snapshot tests, proptest validation | No |
| `ob-auth` | 1 file | Comprehensive auth (register, login, MFA, refresh) | No |
| `ob-core` | 1 file | Extended validation | No |
| `ob-database` | 1 file | Comprehensive DB operations | No |
| `ob-security` | 1 file | Evaluator comprehensive tests | No |

**Commands:**
```bash
# Unit-only (no server needed, fast)
cargo test --workspace

# Integration tests that DON'T need a server
cargo test -p ob-handlers --test snapshot_tests --test proptest_validation
cargo test -p ob-auth --test comprehensive_auth_tests
cargo test -p ob-core --test validation_extended
cargo test -p ob-database --test comprehensive_db_tests
cargo test -p ob-security --test evaluator_comprehensive_tests

# Integration tests that DO need a running server
OB_TEST_URL=https://api.dev.orignagta.ca cargo test -p orignabase -- --ignored
```

### Rust — Specific Integration Test Files (orignabase/crates/orignabase/tests/)

| File | Tests | Category |
|------|-------|----------|
| `integration_test.rs` | 50+ | Core CRUD, auth, GraphQL |
| `handlers_integration_test.rs` | 30+ | REST API handlers |
| `extended_handlers_test.rs` | 20+ | Edge cases |
| `security_test.rs` | 15+ | Injection, auth bypass, IDOR |
| `security_fixes_test.rs` | 10+ | Verified security patches |
| `payment_fixes_test.rs` | 10+ | Payment integrity |
| `order_lifecycle_test.rs` | 10+ | State machine transitions |
| `shipping_test.rs` | 8+ | Shipping calc, free threshold |
| `product_questions_test.rs` | 8+ | Q&A features |
| `product_ratings_test.rs` | 8+ | Rating system |
| `returns_refunds_test.rs` | 8+ | Return window, refund flow |
| `stock_notifications_test.rs` | 5+ | Stock alerts |
| `new_features_test.rs` | 10+ | Subscriptions, coupons, digital |
| `miscellaneous_handlers_test.rs` | 10+ | Edge cases, idempotency |
| `cross_service_test.rs` | 12 | SurrealDB+Meilisearch+Auth+WS |
| `smoke_test.rs` | 5+ | Health, config, startup |
| `stress_test.rs` | 9 | Concurrent writes, bursts, large docs |
| `reliability_test.rs` | 15 | Pool exhaustion, graceful shutdown, recovery |
| `concurrency_tests.rs` | varies | Race conditions, TOCTOU |
| `search_integration_test.rs` | 5+ | Meilisearch sync |
| `realtime_integration_test.rs` | 5+ | WebSocket events |
| `storage_integration_test.rs` | 5+ | File upload/download |
| `push_notifications_integration_test.rs` | 3+ | FCM push |
| `mcp_integration_test.rs` | 5+ | MCP tool execution |
| `pentest.rs` | varies | Automated pentest probes |
| `functional_gaps_test.rs` | varies | Coverage gap fillers |
| `*_repository_test.rs` | 4 files | auth, cart, order, product, user repos |

### Rust — Benchmarks (3 files)

| File | Benchmarks | What it measures |
|------|-----------|-----------------|
| `core_benchmarks.rs` | 16 | Query translation, JWT, argon2, signed URLs, analytics |
| `comprehensive_bench.rs` | 21 | Auth, CRUD at scale, queries, concurrency, sustained load |
| `throughput_bench.rs` | varies | Raw throughput under load |

**Command:** `cd orignabase && cargo bench` (core only, no server) or `cargo bench -- --ignored` (all, needs server)

### SDK (orignabase/sdks/flutter/orignabase/)

| Suite | Count | Command |
|-------|-------|---------|
| Unit (mocked) | ~530+ | `flutter test` |
| Live integration | varies | `flutter test --tags live --dart-define=ENVIRONMENT=dev` |

### E2E (e2e/)

| Suite | Count | Command |
|-------|-------|---------|
| Phase 1-6 | ~114 | `bun test` |

## Execution Order (14 phases, sequential, RAM-safe)

```
Phase 0:  Kill zombies + check disk space
Phase 1:  Flutter analyze --no-fatal-infos
Phase 2:  Cargo clippy --workspace -- -D warnings
Phase 3:  Flutter unit+widget tests (--exclude-tags golden)
Phase 4:  Rust unit tests (cargo test --workspace) — ALL 14 crates
Phase 5:  Rust crate-level integration tests (no server needed)
Phase 6:  SDK unit tests
Phase 7:  Flutter live tests (needs dev server)
Phase 8:  Rust ignored integration tests (needs dev server)
Phase 9:  SDK live tests (needs dev server)
Phase 10: E2E tests (needs deployed web app)
Phase 11: Rust stress + reliability tests (needs dev server)
Phase 12: Rust benchmarks (optional, slow)
Phase 13: Summary report
```

## Execution Script

```bash
#!/bin/bash
set -euo pipefail
FLUTTER=/Users/yuniorrodriguezosorio/flutter/bin/flutter
PROJECT=/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
RESULTS=/tmp/test-all-$(date +%Y%m%d-%H%M%S)
OB_URL=${OB_TEST_URL:-https://api.dev.orignagta.ca}
mkdir -p $RESULTS
PASS=0; FAIL=0; SKIP=0

echo "=== PHASE 0: Kill zombies + disk check ==="
pkill -f flutter_tester 2>/dev/null || true
pkill -f "dart.*test" 2>/dev/null || true
sleep 1
echo "Disk: $(df -h / | tail -1 | awk '{print $4}') free"
echo "RAM: $(vm_stat | awk '/Pages free/ {print $3*4096/1048576 " MB free"}')"
echo ""

echo "=== PHASE 1: Flutter analyze ==="
cd $PROJECT/origna_gta
$FLUTTER analyze --no-fatal-infos 2>&1 | tee $RESULTS/01-flutter-analyze.txt
echo ""

echo "=== PHASE 2: Cargo clippy (all 14 crates) ==="
cd $PROJECT/orignabase
cargo clippy --workspace -- -D warnings 2>&1 | tee $RESULTS/02-cargo-clippy.txt
echo ""

echo "=== PHASE 3: Flutter unit+widget ==="
cd $PROJECT/origna_gta
$FLUTTER test --exclude-tags golden 2>&1 | tee $RESULTS/03-flutter-unit.txt
echo ""

echo "=== PHASE 4: Rust unit tests (all 14 crates) ==="
cd $PROJECT/orignabase
cargo test --workspace 2>&1 | tee $RESULTS/04-rust-unit.txt
echo ""

echo "=== PHASE 5: Rust crate integration tests (no server) ==="
cd $PROJECT/orignabase
cargo test -p ob-handlers --test snapshot_tests --test proptest_validation 2>&1 | tee $RESULTS/05a-handlers-integration.txt
cargo test -p ob-auth --test comprehensive_auth_tests 2>&1 | tee -a $RESULTS/05b-auth-integration.txt
cargo test -p ob-core --test validation_extended 2>&1 | tee -a $RESULTS/05c-core-integration.txt
cargo test -p ob-database --test comprehensive_db_tests 2>&1 | tee -a $RESULTS/05d-db-integration.txt
cargo test -p ob-security --test evaluator_comprehensive_tests 2>&1 | tee -a $RESULTS/05e-security-integration.txt
echo ""

echo "=== PHASE 6: SDK unit tests ==="
cd $PROJECT/orignabase/sdks/flutter/orignabase
$FLUTTER test 2>&1 | tee $RESULTS/06-sdk-unit.txt
echo ""

echo "=== PHASE 7: Flutter live tests ==="
cd $PROJECT/origna_gta
$FLUTTER test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=dev test/live/ 2>&1 | tee $RESULTS/07-flutter-live.txt
echo ""

echo "=== PHASE 8: Rust integration tests (needs server) ==="
cd $PROJECT/orignabase
OB_TEST_URL=$OB_URL cargo test -p orignabase -- --ignored 2>&1 | tee $RESULTS/08-rust-ignored.txt
echo ""

echo "=== PHASE 9: SDK live tests ==="
cd $PROJECT/orignabase/sdks/flutter/orignabase
$FLUTTER test --tags live --dart-define=ENVIRONMENT=dev 2>&1 | tee $RESULTS/09-sdk-live.txt || echo "SDK live: skipped or no tagged tests"
echo ""

echo "=== PHASE 10: E2E tests ==="
cd $PROJECT/e2e
bun test 2>&1 | tee $RESULTS/10-e2e.txt || echo "E2E skipped"
echo ""

echo "=== PHASE 11: Rust stress + reliability ==="
cd $PROJECT/orignabase
OB_TEST_URL=$OB_URL cargo test -p orignabase --test stress_test -- --ignored 2>&1 | tee $RESULTS/11a-stress.txt || true
OB_TEST_URL=$OB_URL cargo test -p orignabase --test reliability_test -- --ignored 2>&1 | tee $RESULTS/11b-reliability.txt || true
echo ""

echo "=== PHASE 12: Rust benchmarks (optional) ==="
cd $PROJECT/orignabase
cargo bench --bench core_benchmarks 2>&1 | tee $RESULTS/12-bench.txt || echo "Benchmarks skipped"
echo ""

echo "=== PHASE 13: Summary ==="
echo "Results saved to: $RESULTS/"
echo ""
echo "| Phase | Suite | Result |"
echo "|-------|-------|--------|"
for f in $RESULTS/*.txt; do
  name=$(basename $f .txt)
  if grep -q "All tests passed\|test result: ok" "$f" 2>/dev/null; then
    echo "| $name | PASS |"
  elif grep -q "FAILED\|Some tests failed" "$f" 2>/dev/null; then
    fails=$(grep -c "FAILED" "$f" 2>/dev/null || echo "?")
    echo "| $name | FAIL ($fails) |"
  else
    echo "| $name | CHECK |"
  fi
done
echo ""
echo "Done. $(date)"
```

## Quick Run Modes

```bash
# Pre-commit (fast, ~3 min): analyze + clippy + unit tests only
Phases: 0-6

# Pre-deploy (medium, ~10 min): everything except benchmarks
Phases: 0-11

# Full release (slow, ~20 min): everything including benchmarks
Phases: 0-13

# Security check (focused): analyze + clippy + unit + live + integration
Phases: 0-2, 4-5, 7-8
```

## RAM Safety

- Kill all zombie `flutter_tester`/`dart`/`cargo` processes before starting
- Sequential execution only — never parallel builds
- Monitor: `ps aux | grep -E "flutter|cargo|dart" | grep -v grep`
- If RAM <1GB free, run `flutter clean` and/or `cargo clean` before proceeding
- Clean Rust artifacts after: `bash orignabase/scripts/clean_rust_artifacts.sh`

## Output Files

All results saved to `/tmp/test-all-YYYYMMDD-HHMMSS/`:
```
01-flutter-analyze.txt
02-cargo-clippy.txt
03-flutter-unit.txt
04-rust-unit.txt
05a-handlers-integration.txt
05b-auth-integration.txt
05c-core-integration.txt
05d-db-integration.txt
05e-security-integration.txt
06-sdk-unit.txt
07-flutter-live.txt
08-rust-ignored.txt
09-sdk-live.txt
10-e2e.txt
11a-stress.txt
11b-reliability.txt
12-bench.txt
```

## Integration with CI

| CI Workflow | Phases Covered |
|-------------|---------------|
| `ci-flutter-web.yml` | 1 + 3 |
| `ci-rust.yml` | 2 + 4 + 5 |
| `cd-e2e.yml` | 10 (on merge to main) |
