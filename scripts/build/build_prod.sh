#!/bin/bash
# Build Flutter for PRODUCTION environment (release mode)
# Usage: ./scripts/build/build_prod.sh web|apk|ios|appbundle
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:-web}"
DEFINES="--dart-define=ENVIRONMENT=production"

cd "$REPO_ROOT/origna_gta"
echo "🏭  Building Flutter [$TARGET] — PROD (release)"
flutter build "$TARGET" --release $DEFINES
echo "✅ PROD build complete"
