#!/bin/bash
# run_quality_gate.sh — Quality gate for origna_gta
# Used by strict-quality-audit.yml CI workflow
set -euo pipefail

FLUTTER_THRESHOLD="${FLUTTER_THRESHOLD:-80}"
FLUTTER_INTEGRATION_THRESHOLD="${FLUTTER_INTEGRATION_THRESHOLD:-70}"
E2E_SPECS="${E2E_SPECS:-specs/phase1-api/}"
RUN_FLUTTER_INTEGRATION_COVERAGE="${RUN_FLUTTER_INTEGRATION_COVERAGE:-false}"
FLUTTER_INTEGRATION_DEVICE="${FLUTTER_INTEGRATION_DEVICE:-linux}"
FLUTTER_INTEGRATION_USE_XVFB="${FLUTTER_INTEGRATION_USE_XVFB:-false}"
SKIP_BACKEND=false
E2E_RANDOM_COUNT=1

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-backend) SKIP_BACKEND=true; shift ;;
    --e2e-random-count) E2E_RANDOM_COUNT="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

PASS=true

# ── Flutter unit/widget coverage ─────────────────────────────────────────────
echo "=== Flutter unit/widget tests + coverage ==="
cd origna_gta
flutter test --coverage --reporter=compact --exclude-tags golden || { echo "FAIL: flutter test"; PASS=false; }

if command -v lcov &>/dev/null; then
  COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oE "[0-9]+\.[0-9]+" | head -1)
  echo "Flutter coverage: ${COVERAGE}% (threshold: ${FLUTTER_THRESHOLD}%)"
  if (( $(echo "$COVERAGE < $FLUTTER_THRESHOLD" | bc -l) )); then
    echo "FAIL: Flutter coverage ${COVERAGE}% < ${FLUTTER_THRESHOLD}%"
    PASS=false
  fi
  cp coverage/lcov.info coverage_unit.info
else
  echo "lcov not installed — skipping coverage threshold check"
  cp coverage/lcov.info coverage_unit.info 2>/dev/null || true
fi
cd ..

# ── Flutter integration coverage (optional) ──────────────────────────────────
if [[ "$RUN_FLUTTER_INTEGRATION_COVERAGE" == "true" ]]; then
  echo "=== Flutter integration tests (device: ${FLUTTER_INTEGRATION_DEVICE}) ==="
  FLOWS=(origna_gta/integration_test/flows/*_test.dart)
  if [[ "${#FLOWS[@]}" -gt 0 && -f "${FLOWS[0]}" ]]; then
    # Run a random sample
    SAMPLED=$(shuf -e "${FLOWS[@]}" | head -n "$E2E_RANDOM_COUNT")
    for FLOW in $SAMPLED; do
      echo "Running integration flow: $FLOW"
      if [[ "$FLUTTER_INTEGRATION_USE_XVFB" == "true" ]]; then
        xvfb-run -a flutter test -d "$FLUTTER_INTEGRATION_DEVICE" \
          --dart-define=ENVIRONMENT=dev \
          --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
          "$FLOW" || echo "WARN: integration flow failed: $FLOW"
      else
        flutter test -d "$FLUTTER_INTEGRATION_DEVICE" \
          --dart-define=ENVIRONMENT=dev \
          --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
          "$FLOW" || echo "WARN: integration flow failed: $FLOW"
      fi
    done
  else
    echo "No integration test flows found — skipping"
  fi
fi

# ── E2E (Bun + agent-browser) ────────────────────────────────────────────────
echo "=== E2E tests (specs: ${E2E_SPECS}) ==="

cd e2e-agent-browser
bun test "$E2E_SPECS" || { echo "FAIL: E2E tests"; PASS=false; }
cd ..

# ── Result ────────────────────────────────────────────────────────────────────
if [[ "$PASS" == "true" ]]; then
  echo "=== Quality gate PASSED ==="
  exit 0
else
  echo "=== Quality gate FAILED ==="
  exit 1
fi
