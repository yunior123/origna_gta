#!/bin/bash
# Hook: Stop — Verify code quality before Claude finishes a session
# Runs: (a) dart analyze on modified .dart files
#        (b) associated unit tests for changed Dart files
# Backend is Rust on VPS (OrignaBase) — no local Python/Firebase functions.
# Returns JSON with decision:block if critical errors found

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FLUTTER_DIR="$PROJECT_DIR/origna_gta"

# Collect stdin (Claude hook protocol)
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

# Don't loop — if we're already in a stop hook, let it finish
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# ─── Detect modified files (staged + unstaged vs HEAD) ───
DART_FILES=()

while IFS= read -r file; do
  case "$file" in
    origna_gta/lib/*.dart) DART_FILES+=("$file") ;;
  esac
done < <(cd "$PROJECT_DIR" && { git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached HEAD 2>/dev/null; } | sort -u)

# If no files changed, nothing to verify
if [ ${#DART_FILES[@]} -eq 0 ]; then
  exit 0
fi

ERRORS=()
WARNINGS=()

# ═══════════════════════════════════════════════════════════
# (a) Dart Analysis — dart analyze --fatal-infos
# ═══════════════════════════════════════════════════════════
if [ ${#DART_FILES[@]} -gt 0 ]; then
  if command -v dart &>/dev/null; then
    DART_OUTPUT=$(cd "$FLUTTER_DIR" && dart analyze --fatal-infos 2>&1) || true

    # Count errors and warnings
    DART_ERRORS=$(echo "$DART_OUTPUT" | grep -c " error " || true)
    DART_WARNS=$(echo "$DART_OUTPUT" | grep -c " warning " || true)

    if [ "$DART_ERRORS" -gt 0 ]; then
      ERROR_DETAILS=$(echo "$DART_OUTPUT" | grep " error " | head -5)
      ERRORS+=("🎯 Dart: $DART_ERRORS error(s) found. First errors: $ERROR_DETAILS")
    fi

    if [ "$DART_WARNS" -gt 0 ]; then
      WARNINGS+=("⚠️ Dart: $DART_WARNS warning(s) found")
    fi
  else
    WARNINGS+=("⚠️ dart CLI not found — skipping Dart analysis")
  fi
fi

# ═══════════════════════════════════════════════════════════
# (b) Run associated unit tests for changed Dart files
# ═══════════════════════════════════════════════════════════

if [ ${#DART_FILES[@]} -gt 0 ] && command -v flutter &>/dev/null; then
  for dart_file in "${DART_FILES[@]}"; do
    test_file=$(echo "$dart_file" | sed 's|origna_gta/lib/|origna_gta/test/|' | sed 's|\.dart$|_test.dart|')
    if [ -f "$PROJECT_DIR/$test_file" ]; then
      TEST_OUT=$(cd "$FLUTTER_DIR" && flutter test "$PROJECT_DIR/$test_file" --no-pub 2>&1) || true
      if echo "$TEST_OUT" | grep -q "Some tests failed"; then
        FAIL_DETAILS=$(echo "$TEST_OUT" | grep -A2 "FAILED" | head -3)
        ERRORS+=("Dart test failed: $test_file — $FAIL_DETAILS")
      fi
    fi
  done
fi

# ═══════════════════════════════════════════════════════════
# Decision: Block or Allow
# ═══════════════════════════════════════════════════════════

TOTAL_ERRORS=${#ERRORS[@]}
TOTAL_WARNINGS=${#WARNINGS[@]}

if [ "$TOTAL_ERRORS" -gt 0 ]; then
  ERROR_MSG=""
  for err in ${ERRORS[@]+"${ERRORS[@]}"}; do
    ERROR_MSG+="$err\n"
  done
  for warn in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
    ERROR_MSG+="$warn\n"
  done

  MODIFIED_SUMMARY="Dart: ${#DART_FILES[@]} files"

  echo "STOP HOOK — Quality Gate FAILED ❌"
  echo ""
  echo "Modified: $MODIFIED_SUMMARY"
  echo ""
  printf "$ERROR_MSG"
  echo ""
  echo "Fix these issues before completing the task."

  cat <<EOF
{"decision": "block", "reason": "Quality gate failed: $TOTAL_ERRORS error(s). $MODIFIED_SUMMARY modified. Fix Dart analysis errors and failing tests before stopping."}
EOF
  exit 1
fi

# All clear
if [ "$TOTAL_WARNINGS" -gt 0 ]; then
  echo "STOP HOOK — Quality Gate PASSED ✅ (with ${TOTAL_WARNINGS} warning(s))"
  for warn in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
    echo "  $warn"
  done
else
  echo "STOP HOOK — Quality Gate PASSED ✅"
  echo "  Dart files checked: ${#DART_FILES[@]}"
fi

exit 0
