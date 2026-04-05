#!/bin/bash
# e2e-agent-browser/run-tests.sh
# Optimized v3: TRUE PARALLEL — 4 concurrent browser files + API background
#
# BEFORE v1 (sequential waves):
#   API(bg) → Wave1(20 files) → Wave2(14) → Wave3(13) = ~22min wall
#   Problem: files run 1-at-a-time within each wave
#
# AFTER v3 (parallel within single wave):
#   API(bg, --concurrent, 10 parallel)  = ~2min
#   ALL browser files (47) with --max-concurrency=4 = ~12min
#   4 Chrome sessions × 700MB = 2.8GB, leaves 2.7GB headroom
#
# RAM budget: 8GB total, ~2.5GB OS, ~5.5GB for tests
# 4 parallel Chrome: 4 × 700MB = 2.8GB ✓
set -e

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

TIMEOUT="${E2E_TEST_TIMEOUT:-60000}"
PHASE="${1:-all}"
# Max parallel browser files — tune based on RAM
# 1 = safe for 8GB Mac (sequential, avoids timeout)
BROWSER_CONCURRENCY="${E2E_BROWSER_CONCURRENCY:-1}"
API_CONCURRENCY="${E2E_API_CONCURRENCY:-1}"

# API-only files (no Chrome needed) — scattered across UI phases
API_ONLY_FILES=(
  specs/phase4-product-flows/digital-product-e2e.spec.ts
  specs/phase4-product-flows/product-video-e2e.spec.ts
  specs/phase5-complex-flows/new-notification-features.spec.ts
  specs/phase5-complex-flows/order-notifications.spec.ts
  specs/phase6-stripe/stripe-connect.spec.ts
  specs/phase6-stripe/stripe-webhooks.spec.ts
)

# Collect all browser files (everything minus API-only)
collect_browser_files() {
  find specs/phase2-smoke/ specs/phase3-auth-nav/ \
       specs/phase4-product-flows/ specs/phase5-complex-flows/ \
       specs/phase6-stripe/ \
       -name '*.spec.ts' \
    ! -name 'digital-product-e2e.spec.ts' \
    ! -name 'product-video-e2e.spec.ts' \
    ! -name 'new-notification-features.spec.ts' \
    ! -name 'order-notifications.spec.ts' \
    ! -name 'stripe-connect.spec.ts' \
    ! -name 'stripe-webhooks.spec.ts' \
    | sort
}

run_phase() {
  local name="$1"; shift
  echo "▶ $name"
  local start=$(date +%s)
  bun test "$@" --timeout "$TIMEOUT"
  local end=$(date +%s)
  echo "✓ $name done in $((end - start))s"
}

case "$PHASE" in
  api)   run_phase "Phase 1: API" specs/phase1-api/ --max-concurrency "$API_CONCURRENCY" ;;
  smoke) run_phase "Phase 2: Smoke" specs/phase2-smoke/ --max-concurrency 1 ;;
  auth)  run_phase "Phase 3: Auth" specs/phase3-auth-nav/ --max-concurrency 1 ;;
  prod)  run_phase "Phase 4: Products" specs/phase4-product-flows/ --max-concurrency 1 ;;
  flow)  run_phase "Phase 5: Flows" specs/phase5-complex-flows/ --max-concurrency 1 ;;
  pay)   run_phase "Phase 6: Stripe" specs/phase6-stripe/ --max-concurrency 1 ;;
  ai)    run_phase "Phase 7: AI Analysis" ai/specs/ --max-concurrency 1 ;;
  all)
    TOTAL_START=$(date +%s)
    SUITE_STATUS=0

    echo "╔══════════════════════════════════════════╗"
    echo "║  E2E Suite v3 — Parallel Execution       ║"
    echo "║  Browser concurrency: $BROWSER_CONCURRENCY files              ║"
    echo "║  API concurrency: $API_CONCURRENCY files                 ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    # ── Seed ──
    echo "▶ Seeding dev database..."
    SEED_START=$(date +%s)
    bun run lib/seed-dev.ts || echo "⚠ Seed had errors (continuing)"
    SEED_ELAPSED=$(( $(date +%s) - SEED_START ))
    echo "✓ Seed done in ${SEED_ELAPSED}s"
    echo ""

    # ── Sequential: ALL API-only tests (P1 + scattered) ──
    echo "▶ API tests (sequential — 0 Chrome, 27 files, concurrency=$API_CONCURRENCY)"
    API_START=$(date +%s)
    bun test \
      specs/phase1-api/ \
      "${API_ONLY_FILES[@]}" \
      --timeout "$TIMEOUT" \
      --max-concurrency "$API_CONCURRENCY" \
      > /tmp/e2e-api-results.log 2>&1
    API_ELAPSED=$(( $(date +%s) - API_START ))
    echo "✓ API tests done in ${API_ELAPSED}s"
    echo "── API test output ──"
    cat /tmp/e2e-api-results.log
    echo ""

    # ── Main: ALL browser files in parallel (concurrency-limited) ──
    BROWSER_FILES=$(collect_browser_files)
    BROWSER_COUNT=$(echo "$BROWSER_FILES" | wc -l | tr -d ' ')
    echo "══════════════════════════════════════"
    echo "▶ Browser tests ($BROWSER_COUNT files, $BROWSER_CONCURRENCY parallel)"
    echo "══════════════════════════════════════"
    BROWSER_START=$(date +%s)
    # shellcheck disable=SC2086
    bun test $BROWSER_FILES \
      --timeout "$TIMEOUT" \
      --max-concurrency "$BROWSER_CONCURRENCY" \
      || SUITE_STATUS=1
    BROWSER_END=$(date +%s)
    BROWSER_ELAPSED=$((BROWSER_END - BROWSER_START))
    echo "✓ Browser tests done in ${BROWSER_ELAPSED}s"
    echo ""

    TOTAL_ELAPSED=$(( $(date +%s) - TOTAL_START ))

    cat > /tmp/e2e-timing-report.txt <<REPORT
═══════════════════════════════════════════
  E2E TIMING REPORT — $(date '+%Y-%m-%d %H:%M')
═══════════════════════════════════════════
Seed:             ${SEED_ELAPSED}s
API (bg):         ${API_ELAPSED}s  (27 files, concurrency=$API_CONCURRENCY)
Browser (main):   ${BROWSER_ELAPSED}s  ($BROWSER_COUNT files, concurrency=$BROWSER_CONCURRENCY)
───────────────────────────────────────────
TOTAL:            ${TOTAL_ELAPSED}s  ($(( TOTAL_ELAPSED / 60 ))m $(( TOTAL_ELAPSED % 60 ))s)

THRESHOLD: 10 min (600s)
STATUS:    $([ "$TOTAL_ELAPSED" -gt 600 ] && echo "⚠ SLOW — investigate!" || echo "✓ OK")
═══════════════════════════════════════════
REPORT

    cat /tmp/e2e-timing-report.txt

    if [ "$TOTAL_ELAPSED" -gt 600 ]; then
      echo ""
      echo "⚠ SUITE TOOK ${TOTAL_ELAPSED}s (>10min). Check:"
      echo "  1. Rate limiting (429s) — grep '429' /tmp/e2e-api-results.log"
      echo "  2. Timeout hits — grep 'timed out' in output above"
      echo "  3. Slow seed — was seed >60s?"
      echo "  4. Chrome OOM — ps aux | grep -c 'chrome.*defunct'"
      echo "  5. Bump concurrency: E2E_BROWSER_CONCURRENCY=6 ./run-tests.sh all"
    fi
    exit $SUITE_STATUS
    ;;
  *) echo "Usage: ./run-tests.sh [all|api|smoke|auth|prod|flow|pay|ai]"; exit 1 ;;
esac
