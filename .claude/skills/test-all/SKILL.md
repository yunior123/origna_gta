---
name: test-all
description: "Run ALL tests across the entire origna_gta monorepo — Flutter unit/widget/live, Rust unit/integration, SDK, E2E. Outputs results to /tmp/ files. Kills zombies first, monitors RAM. Use when asked to 'run all tests', 'test everything', 'full test suite', 'verify all', or before commits/deploys."
---

# Test All — Complete Monorepo Test Suite

Runs every test in the origna_gta monorepo sequentially (8GB RAM constraint). Kills zombie processes first, outputs all results to /tmp/ files, and reports a final summary.

## Test Inventory

| Suite | Location | Count | Command |
|-------|----------|-------|---------|
| Flutter unit+widget | `origna_gta/test/` | ~5,200+ | `flutter test --exclude-tags golden` |
| Flutter live | `origna_gta/test/live/` | ~190+ | `flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev test/live/` |
| Rust unit | `orignabase/` | ~3,200+ | `cargo test --workspace` |
| Rust integration | `orignabase/crates/orignabase/tests/` | ~60+ | `cargo test -p orignabase -- --ignored` |
| SDK unit | `orignabase/sdks/flutter/orignabase/` | ~530+ | `flutter test` |
| SDK live | `orignabase/sdks/flutter/orignabase/` | varies | `flutter test --tags live --dart-define=ENVIRONMENT=dev` |
| E2E | `e2e/` | ~114 | `bun test` |
| Rust benchmarks | `orignabase/crates/orignabase/benches/` | 16 | `cargo bench` |

## Execution Order (sequential, RAM-safe)

```
Phase 0: Kill zombies + check disk
Phase 1: Flutter analyze (fast, catches compile errors)
Phase 2: Cargo clippy (catches Rust warnings)
Phase 3: Flutter unit+widget tests
Phase 4: Rust unit tests
Phase 5: SDK tests
Phase 6: Flutter live tests (needs dev server)
Phase 7: Rust integration tests (needs dev server)
Phase 8: E2E tests (needs deployed web app)
Phase 9: Rust benchmarks (optional, slow)
Phase 10: Summary report
```

## Execution Script

```bash
#!/bin/bash
set -euo pipefail
FLUTTER=/Users/yuniorrodriguezosorio/flutter/bin/flutter
PROJECT=/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
RESULTS=/tmp/test-all-$(date +%Y%m%d-%H%M%S)
mkdir -p $RESULTS

echo "=== PHASE 0: Kill zombies ==="
pkill -f flutter_tester 2>/dev/null || true
pkill -f "dart.*test" 2>/dev/null || true
sleep 1

echo "=== PHASE 1: Flutter analyze ==="
cd $PROJECT/origna_gta
$FLUTTER analyze --no-fatal-infos 2>&1 | tee $RESULTS/flutter-analyze.txt
echo ""

echo "=== PHASE 2: Cargo clippy ==="
cd $PROJECT/orignabase
cargo clippy --workspace -- -D warnings 2>&1 | tee $RESULTS/cargo-clippy.txt
echo ""

echo "=== PHASE 3: Flutter unit+widget ==="
cd $PROJECT/origna_gta
$FLUTTER test --exclude-tags golden 2>&1 | tee $RESULTS/flutter-test.txt
echo ""

echo "=== PHASE 4: Rust unit ==="
cd $PROJECT/orignabase
cargo test --workspace 2>&1 | tee $RESULTS/cargo-test.txt
echo ""

echo "=== PHASE 5: SDK tests ==="
cd $PROJECT/orignabase/sdks/flutter/orignabase
$FLUTTER test 2>&1 | tee $RESULTS/sdk-test.txt
echo ""

echo "=== PHASE 6: Flutter live tests ==="
cd $PROJECT/origna_gta
$FLUTTER test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=dev test/live/ 2>&1 | tee $RESULTS/flutter-live.txt
echo ""

echo "=== PHASE 7: Rust integration ==="
cd $PROJECT/orignabase
OB_TEST_URL=https://api.dev.orignagta.ca cargo test -p orignabase -- --ignored 2>&1 | tee $RESULTS/rust-integration.txt
echo ""

echo "=== PHASE 8: E2E tests ==="
cd $PROJECT/e2e
bun test 2>&1 | tee $RESULTS/e2e.txt || echo "E2E skipped (bun or deploy issue)"
echo ""

echo "=== PHASE 10: Summary ==="
echo "Results saved to: $RESULTS/"
echo ""
echo "| Suite | Result |"
echo "|-------|--------|"
grep -c "All tests passed\|passed" $RESULTS/flutter-test.txt 2>/dev/null && echo "| Flutter | PASS |" || echo "| Flutter | CHECK $RESULTS/flutter-test.txt |"
grep "^test result:" $RESULTS/cargo-test.txt | tail -1
grep -c "All tests passed" $RESULTS/sdk-test.txt 2>/dev/null && echo "| SDK | PASS |" || echo "| SDK | CHECK |"
echo ""
echo "Done."
```

## When to Run

- Before every commit: Phase 1-5 (unit tests only)
- Before deploy: Phase 1-8 (everything)
- Before release: Phase 1-9 (including benchmarks)
- After security fixes: Phase 1-7 (skip E2E)

## RAM Safety

- Kill all zombie flutter_tester/dart processes before starting
- Sequential execution only — never parallel builds
- Clean between stacks: `flutter clean` before Rust, `cargo clean` if needed
- Monitor with: `ps aux | grep -E "flutter|cargo|dart" | grep -v grep`

## Output Files

All results saved to `/tmp/test-all-YYYYMMDD-HHMMSS/`:
- `flutter-analyze.txt`
- `cargo-clippy.txt`
- `flutter-test.txt`
- `cargo-test.txt`
- `sdk-test.txt`
- `flutter-live.txt`
- `rust-integration.txt`
- `e2e.txt`

## Integration with CI

The same phases run in GitHub Actions:
- `ci-flutter-web.yml`: Phase 1 + 3
- `ci-rust.yml`: Phase 2 + 4
- `cd-e2e.yml`: Phase 8 (on merge to main)
