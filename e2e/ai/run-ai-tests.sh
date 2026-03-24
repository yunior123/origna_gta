#!/bin/bash
# e2e/ai/run-ai-tests.sh
# AI-powered E2E analysis runner.
# Usage: ./run-ai-tests.sh [screens|flows|all]
#
# This script is a lightweight entry point. The real analysis happens
# when an AI agent (Claude/Kilo) runs the SKILL.md workflow.
# For CI, use this script which delegates to the TypeScript NVIDIA NIM tests.
set -e

cd "$(dirname "$0")/.."

TARGET="${1:-all}"
TIMEOUT="${AI_TEST_TIMEOUT:-120000}"

case "$TARGET" in
  screens)
    echo "▶ AI Screen Analysis (accessibility + UI/UX)"
    bun test ai/specs/accessibility-audit.spec.ts ai/specs/ui-ux-review.spec.ts --timeout "$TIMEOUT"
    ;;
  flows)
    echo "▶ AI User Flow Analysis"
    bun test ai/specs/user-flow-feedback.spec.ts --timeout "$TIMEOUT"
    ;;
  all)
    echo "▶ Full AI E2E Suite"
    bun test ai/specs/ --timeout "$TIMEOUT"
    ;;
  *)
    echo "Usage: $0 [screens|flows|all]"
    exit 1
    ;;
esac
