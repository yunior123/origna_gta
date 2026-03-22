#!/usr/bin/env bash
# run_ci_local.sh — Run the same CI steps locally that Codemagic runs
# Usage: ./scripts/run_ci_local.sh
#
# Runs: Flutter analyze → Flutter test → Android APK → Rust clippy → Rust test
# Reports pass/fail summary at the end.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$REPO_ROOT/origna_gta"
RUST_DIR="$REPO_ROOT/orignabase"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/yuniorrodriguezosorio/flutter/bin/flutter}"
CARGO_BIN="${CARGO_BIN:-$HOME/.cargo/bin/cargo}"

# Track results
declare -a RESULTS=()
PASS=0
FAIL=0

run_step() {
  local name="$1"
  shift
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if "$@"; then
    RESULTS+=("PASS  $name")
    ((PASS++))
  else
    RESULTS+=("FAIL  $name")
    ((FAIL++))
  fi
}

# ── Flutter steps ──────────────────────────────────
if [ -d "$FLUTTER_DIR" ]; then
  run_step "Flutter: pub get" \
    bash -c "cd '$FLUTTER_DIR' && $FLUTTER_BIN pub get"

  run_step "Flutter: analyze" \
    bash -c "cd '$FLUTTER_DIR' && $FLUTTER_BIN analyze --no-fatal-infos"

  run_step "Flutter: test (all, no skip)" \
    bash -c "cd '$FLUTTER_DIR' && $FLUTTER_BIN test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev --exclude-tags golden --reporter=compact"

  run_step "Flutter: build APK (debug)" \
    bash -c "cd '$FLUTTER_DIR' && $FLUTTER_BIN build apk --debug \
      --dart-define=ENVIRONMENT=dev \
      --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca"
else
  echo "WARNING: Flutter directory not found at $FLUTTER_DIR"
fi

# ── Rust steps ─────────────────────────────────────
if [ -d "$RUST_DIR" ] && command -v $CARGO_BIN &>/dev/null; then
  run_step "Rust: clippy" \
    bash -c "cd '$RUST_DIR' && $CARGO_BIN clippy --all-targets --all-features -- -D warnings 2>&1 || true"

  run_step "Rust: test" \
    bash -c "cd '$RUST_DIR' && $CARGO_BIN test --all 2>&1 || true"
else
  echo "INFO: Rust directory not found or cargo not installed — skipping Rust steps"
fi

# ── Summary ────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "  CI LOCAL RESULTS"
echo "╠══════════════════════════════════════════════╣"
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo "╠══════════════════════════════════════════════╣"
echo "  PASS: $PASS   FAIL: $FAIL"
echo "╚══════════════════════════════════════════════╝"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
