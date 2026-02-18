#!/bin/bash
# Build Flutter for STAGING environment (profile mode + forced semantics)
# Usage: ./scripts/build/build_staging.sh web|apk|ios|appbundle
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:-web}"
DEFINES="--dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true"

cd "$REPO_ROOT/origna_gta"
echo "🧪  Building Flutter [$TARGET] — STAGING (profile)"
flutter build "$TARGET" --profile $DEFINES
echo "✅ STAGING build complete"
