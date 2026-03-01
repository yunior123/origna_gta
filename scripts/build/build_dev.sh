#!/bin/bash
# Build Flutter for DEV environment (debug mode)
# Usage: ./scripts/build/build_dev.sh web|apk|ios|appbundle
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:-web}"
DEFINES="--dart-define=ENVIRONMENT=dev --dart-define=FORCE_SEMANTICS=true"

cd "$REPO_ROOT/origna_gta"
echo "🛠️  Building Flutter [$TARGET] — DEV (debug, semantics forced)"
flutter build "$TARGET" --debug $DEFINES
echo "✅ DEV build complete"
