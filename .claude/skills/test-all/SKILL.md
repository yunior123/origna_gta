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

**ZERO SKIP POLICY: Every phase runs. Every failure is recorded. Nothing is silenced.**

```bash
#!/bin/bash
# ZERO SKIP — run ALL tests, record ALL failures, never || true
FLUTTER=/Users/yuniorrodriguezosorio/flutter/bin/flutter
PROJECT=/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
RESULTS=/tmp/test-all-$(date +%Y%m%d-%H%M%S)
OB_URL=${OB_TEST_URL:-https://api.dev.orignagta.ca}
mkdir -p $RESULTS
TOTAL_PASS=0; TOTAL_FAIL=0; PHASE_RESULTS=""

run_phase() {
  local phase="$1" cmd="$2" outfile="$3"
  echo "=== $phase ==="
  eval "$cmd" 2>&1 | tee "$RESULTS/$outfile"
  local exit_code=${PIPESTATUS[0]}
  if [ $exit_code -ne 0 ]; then
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    PHASE_RESULTS="$PHASE_RESULTS\n| $outfile | FAIL (exit $exit_code) |"
    echo "!!! $phase FAILED (exit $exit_code) !!!"
  else
    TOTAL_PASS=$((TOTAL_PASS + 1))
    PHASE_RESULTS="$PHASE_RESULTS\n| $outfile | PASS |"
  fi
  echo ""
}

echo "=== PHASE 0: Kill zombies + system check ==="
pkill -f flutter_tester 2>/dev/null; pkill -f "dart.*test" 2>/dev/null; sleep 1
# Kill orphan Chrome processes from previous E2E runs
pkill -f "chrome.*headless" 2>/dev/null; pkill -f chromium 2>/dev/null
echo "Disk: $(df -h / | tail -1 | awk '{print $4}') free"
echo "RAM: $(vm_stat 2>/dev/null | awk '/Pages free/ {printf "%.0f MB free\n", $3*4096/1048576}')"
echo ""

# === LOCAL SERVICES MANAGEMENT ===
# Start SurrealDB, Meilisearch, OrignaBase, Stripe CLI if not running
# These are needed for live/integration/E2E tests (Phases 7-12)

echo "=== PHASE 0b: Local services ==="
USE_LOCALHOST=${USE_LOCALHOST:-0}

if [ "$USE_LOCALHOST" = "1" ]; then
  echo "Starting local services (localhost mode)..."

  # Check colima/docker
  if ! docker info &>/dev/null; then
    echo "Starting colima..."
    colima start --memory 4 --cpu 2 2>/dev/null
    sleep 3
  fi

  # Start SurrealDB + Meilisearch via docker-compose
  if ! curl -s http://localhost:8000/health &>/dev/null; then
    echo "Starting SurrealDB + Meilisearch..."
    cd $PROJECT/orignabase/docker
    docker compose up -d surrealdb meilisearch 2>&1
    echo "Waiting for SurrealDB..."
    for i in $(seq 1 30); do
      curl -s http://localhost:8000/health &>/dev/null && break
      sleep 1
    done
  fi
  echo "  SurrealDB: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/health)"
  echo "  Meilisearch: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:7700/health)"

  # Start OrignaBase
  if ! curl -s http://localhost:8080/health &>/dev/null; then
    echo "Starting OrignaBase..."
    cd $PROJECT/orignabase
    OB_TEST_MODE=1 cargo run --release &>/dev/null &
    ORIGNABASE_PID=$!
    echo "  OrignaBase PID: $ORIGNABASE_PID"
    for i in $(seq 1 60); do
      curl -s http://localhost:8080/health &>/dev/null && break
      sleep 1
    done
  fi
  echo "  OrignaBase: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health)"

  # Start Stripe CLI webhook forwarding
  if command -v stripe &>/dev/null; then
    if ! pgrep -f "stripe listen" &>/dev/null; then
      echo "Starting Stripe CLI webhook forwarding..."
      stripe listen --forward-to localhost:8080/api/webhooks/stripe &>/dev/null &
      STRIPE_PID=$!
      echo "  Stripe CLI PID: $STRIPE_PID"
      sleep 3
    fi
    echo "  Stripe CLI: running ($(pgrep -f 'stripe listen' | head -1))"
  else
    echo "  Stripe CLI: NOT INSTALLED (brew install stripe/stripe-cli/stripe)"
  fi

  # Seed DB if empty
  USER_COUNT=$(curl -s http://localhost:8080/graphql \
    -H "Content-Type: application/json" \
    -d '{"query":"{ list(collection: \"users\", limit: 1) }"}' 2>/dev/null | grep -c "data" || echo "0")
  if [ "$USER_COUNT" = "0" ]; then
    echo "  Seeding database..."
    cd $PROJECT/e2e && ORIGNABASE_URL=http://localhost:8080 bun run lib/seed-dev.ts 2>&1 | tail -3
  fi

  # Override URL for localhost
  OB_URL=http://localhost:8080
  echo ""
  echo "  Local services ready. Using OB_URL=$OB_URL"

  # RAM check after services start (8GB constraint)
  FREE_MB=$(vm_stat 2>/dev/null | awk '/Pages free/ {printf "%.0f", $3*4096/1048576}')
  echo "  RAM after services: ${FREE_MB}MB free"
  if [ "${FREE_MB:-0}" -lt 500 ]; then
    echo "  WARNING: <500MB free RAM. Tests may OOM. Consider stopping other apps."
  fi
else
  echo "Using remote dev server: $OB_URL"
  echo "(Set USE_LOCALHOST=1 to start local SurrealDB/Meilisearch/OrignaBase/Stripe)"
fi
echo ""

# Phase 1: Static analysis (catches compile errors before wasting time on tests)
run_phase "PHASE 1: Flutter analyze" \
  "cd $PROJECT/origna_gta && $FLUTTER analyze --no-fatal-infos" \
  "01-flutter-analyze.txt"

# Phase 2: Rust lint (catches warnings treated as errors)
run_phase "PHASE 2: Cargo clippy (14 crates)" \
  "cd $PROJECT/orignabase && cargo clippy --workspace -- -D warnings" \
  "02-cargo-clippy.txt"

# Phase 3: Flutter unit + widget (no golden — renderer differs on CI)
run_phase "PHASE 3: Flutter unit+widget" \
  "cd $PROJECT/origna_gta && $FLUTTER test --exclude-tags golden" \
  "03-flutter-unit.txt"

# Phase 4: Rust unit tests — ALL 14 crates, every mod tests block
run_phase "PHASE 4: Rust unit (14 crates)" \
  "cd $PROJECT/orignabase && cargo test --workspace" \
  "04-rust-unit.txt"

# Phase 5: Rust crate-level integration tests (no server needed)
run_phase "PHASE 5a: ob-handlers snapshots+proptest" \
  "cd $PROJECT/orignabase && cargo test -p ob-handlers --test snapshot_tests --test proptest_validation" \
  "05a-handlers-integration.txt"

run_phase "PHASE 5b: ob-auth comprehensive" \
  "cd $PROJECT/orignabase && cargo test -p ob-auth --test comprehensive_auth_tests" \
  "05b-auth-integration.txt"

run_phase "PHASE 5c: ob-core validation" \
  "cd $PROJECT/orignabase && cargo test -p ob-core --test validation_extended" \
  "05c-core-integration.txt"

run_phase "PHASE 5d: ob-database comprehensive" \
  "cd $PROJECT/orignabase && cargo test -p ob-database --test comprehensive_db_tests" \
  "05d-db-integration.txt"

run_phase "PHASE 5e: ob-security evaluator" \
  "cd $PROJECT/orignabase && cargo test -p ob-security --test evaluator_comprehensive_tests" \
  "05e-security-integration.txt"

# Phase 6: SDK unit tests
run_phase "PHASE 6: SDK unit" \
  "cd $PROJECT/orignabase/sdks/flutter/orignabase && $FLUTTER test" \
  "06-sdk-unit.txt"

# Phase 7: Flutter live tests (needs dev server at api.dev.orignagta.ca)
run_phase "PHASE 7: Flutter live" \
  "cd $PROJECT/origna_gta && $FLUTTER test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev test/live/" \
  "07-flutter-live.txt"

# Phase 8: ALL Rust #[ignore] integration tests (needs dev server)
# This runs ALL 31 files with #[ignore] tests — auth, orders, products, cart,
# payments, shipping, search, realtime, MCP, security, cross-service, pentest
run_phase "PHASE 8: Rust integration (31 ignored files)" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo test -p orignabase -- --ignored" \
  "08-rust-ignored.txt"

# Phase 9: SDK live tests
run_phase "PHASE 9: SDK live" \
  "cd $PROJECT/orignabase/sdks/flutter/orignabase && $FLUTTER test --tags live --dart-define=ENVIRONMENT=dev" \
  "09-sdk-live.txt"

# Phase 10: E2E tests (needs deployed web app at dev.orignagta.ca)
run_phase "PHASE 10: E2E (bun)" \
  "cd $PROJECT/e2e && bun test" \
  "10-e2e.txt"

# Phase 11: Rust stress + reliability (needs dev server)
run_phase "PHASE 11a: Stress tests" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo test -p orignabase --test stress_test -- --ignored" \
  "11a-stress.txt"

run_phase "PHASE 11b: Reliability tests" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo test -p orignabase --test reliability_test -- --ignored" \
  "11b-reliability.txt"

run_phase "PHASE 11c: Concurrency tests" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo test -p orignabase --test concurrency_tests -- --ignored" \
  "11c-concurrency.txt"

run_phase "PHASE 11d: Pentest probes" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo test -p orignabase --test pentest -- --ignored" \
  "11d-pentest.txt"

# Phase 12: ALL Rust benchmarks (all 3 bench files)
run_phase "PHASE 12a: Core benchmarks" \
  "cd $PROJECT/orignabase && cargo bench --bench core_benchmarks" \
  "12a-bench-core.txt"

run_phase "PHASE 12b: Comprehensive benchmarks" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo bench --bench comprehensive_bench" \
  "12b-bench-comprehensive.txt"

run_phase "PHASE 12c: Throughput benchmarks" \
  "cd $PROJECT/orignabase && OB_TEST_URL=$OB_URL cargo bench --bench throughput_bench" \
  "12c-bench-throughput.txt"

# Phase 13: Flutter golden tests (macOS only — skip on Linux CI)
run_phase "PHASE 13: Flutter golden" \
  "cd $PROJECT/origna_gta && $FLUTTER test --tags golden" \
  "13-flutter-golden.txt"

# === CLEANUP: Stop localhost services if we started them ===
if [ "$USE_LOCALHOST" = "1" ]; then
  echo "=== Stopping local services ==="
  [ -n "${ORIGNABASE_PID:-}" ] && kill $ORIGNABASE_PID 2>/dev/null && echo "  Stopped OrignaBase ($ORIGNABASE_PID)"
  [ -n "${STRIPE_PID:-}" ] && kill $STRIPE_PID 2>/dev/null && echo "  Stopped Stripe CLI ($STRIPE_PID)"
  cd $PROJECT/orignabase/docker && docker compose down 2>/dev/null && echo "  Stopped SurrealDB + Meilisearch"
fi

# Clean Rust build artifacts to free disk
echo "=== Cleanup ==="
cd $PROJECT/orignabase && bash scripts/clean_rust_artifacts.sh 2>/dev/null
echo ""

# === SUMMARY ===
echo ""
echo "============================================="
echo "  TEST-ALL SUMMARY — $(date)"
echo "============================================="
echo "Results: $RESULTS/"
echo ""
echo "| Phase | Result |"
echo "|-------|--------|"
echo -e "$PHASE_RESULTS"
echo ""
echo "Phases passed: $TOTAL_PASS"
echo "Phases failed: $TOTAL_FAIL"
echo ""
if [ $TOTAL_FAIL -gt 0 ]; then
  echo "!!! $TOTAL_FAIL PHASE(S) FAILED — CHECK OUTPUT FILES !!!"
  exit 1
else
  echo "ALL PHASES PASSED"
  exit 0
fi
```

## Run Modes

All modes run every phase — no skipping. The difference is which phases REQUIRE a server:

```bash
# Offline (no server): Phases 0-6, 13
# These always work without any external services

# Online (needs dev server): Phases 7-12
# Require api.dev.orignagta.ca to be running
# Set OB_TEST_URL if using a different server

# Full run: ALL phases 0-13
# Needs: dev server + deployed web app + macOS (for golden)
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
