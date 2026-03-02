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

# Guardrail: verify no debug/dev artifacts in release build
if [ "$TARGET" = "web" ]; then
  BUILD_DIR="$REPO_ROOT/origna_gta/build/web"
  if [ -f "$BUILD_DIR/main.dart.js" ]; then
    if grep -q "FORCE_SEMANTICS" "$BUILD_DIR/main.dart.js" 2>/dev/null; then
      echo "❌ ERROR: FORCE_SEMANTICS found in production build — this is a dev/staging build!"
      exit 1
    fi
    echo "✅ Build verified: no dev/staging artifacts in production output"
  fi
fi
