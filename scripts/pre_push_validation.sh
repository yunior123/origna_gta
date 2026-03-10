#!/usr/bin/env bash

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "============================================"
echo "  Pre-Push Validation Suite"
echo "============================================"

ALLOW_LOCAL_HEAVY_PRE_PUSH="${ALLOW_LOCAL_HEAVY_PRE_PUSH:-0}"

if [ "$ALLOW_LOCAL_HEAVY_PRE_PUSH" = "1" ]; then
    echo ""
    echo "Heavy local pre-push validation enabled (ALLOW_LOCAL_HEAVY_PRE_PUSH=1)."
else
    echo ""
    echo "Heavy local pre-push validation skipped by default."
    echo "Remote strict validation runs in GitHub Actions/Codemagic."
    echo "Set ALLOW_LOCAL_HEAVY_PRE_PUSH=1 to force local Flutter builds/tests and Firebase checks."
fi

# 0a. Flutter unit/widget tests — run FIRST while RAM is fresh (before heavy builds)
if [ "$ALLOW_LOCAL_HEAVY_PRE_PUSH" = "1" ]; then
    echo ""
    echo "--- [0a] Flutter Tests (pre-build, RAM-fresh) ---"
    cd origna_gta
    if ! flutter test --reporter compact --concurrency=2; then
        echo "❌ ERROR: Flutter tests failed."
        exit 1
    fi
    cd "$REPO_ROOT"
    echo "✅ Flutter tests passed."
else
    echo ""
    echo "--- [0a] Flutter Tests (pre-build, RAM-fresh) ---"
    echo "⏭️  Skipped locally. Remote strict gate enforces Flutter coverage/tests."
fi

# 0. Validate Flutter builds for all 3 environments
echo ""
echo "--- [0/10] Multi-Env Build Validation ---"
if [ "$ALLOW_LOCAL_HEAVY_PRE_PUSH" = "1" ]; then
    BUILD_DIR="$REPO_ROOT/origna_gta/build/web"
    cd "$REPO_ROOT/origna_gta"

    echo "  Building DEV..."
    flutter build web --debug --dart-define=ENVIRONMENT=dev --dart-define=FORCE_SEMANTICS=true > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Flutter DEV build failed."
        exit 1
    fi
    echo "  ✅ DEV build OK"

    echo "  Building STAGING..."
    flutter build web --profile --dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Flutter STAGING build failed."
        exit 1
    fi
    echo "  ✅ STAGING build OK"

    echo "  Building PROD..."
    flutter build web --release --dart-define=ENVIRONMENT=production > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Flutter PROD build failed."
        exit 1
    fi
    # Guardrail: prod build must NOT contain FORCE_SEMANTICS
    if grep -q "FORCE_SEMANTICS" "$BUILD_DIR/main.dart.js" 2>/dev/null; then
        echo "❌ ERROR: FORCE_SEMANTICS found in PROD build — dev/staging artifacts leaked into release!"
        exit 1
    fi
    echo "  ✅ PROD build OK (no dev/staging artifacts)"

    cd "$REPO_ROOT"
    echo "✅ All 3 environment builds validated."
else
    echo "⏭️  Skipped locally. Remote CI/Codemagic own multi-env Flutter validation."
fi

# 1. Check for credential leaks
echo ""
echo "--- [1/5] Credential Leak Check ---"
if grep -r "960227Y#y" e2e/ origna_gta/lib/ origna_gta/test/ origna_gta/patrol_test/ 2>/dev/null; then
    echo "❌ ERROR: Old admin password found in source code."
    exit 1
fi
echo "✅ No credential leaks found."

# 2. Validate Firestore indexes, rules, storage across environments
echo ""
echo "--- [2/5] Firestore Rules & Indexes ---"
if [ "$ALLOW_LOCAL_HEAVY_PRE_PUSH" = "1" ]; then
    python3 scripts/validate_indexes.py
    python3 scripts/validate_rules.py
    python3 scripts/validate_storage_rules.py
else
    echo "⏭️  Skipped locally. Remote CI/Codemagic enforce Firebase validation."
fi

# 3. Git diff summary
echo ""
echo "--- [3/5] Changed Files Summary ---"
git diff --check
echo "✅ No whitespace or conflict marker issues."

# 4. Playwright E2E tests against dev
echo ""
echo "--- [4/5] Playwright E2E Tests (dev) ---"
if [ "$ALLOW_LOCAL_HEAVY_PRE_PUSH" = "1" ]; then
    cd e2e
    if ! npx playwright test --config=playwright.config.dev.ts --retries=1 --workers=2; then
        echo "❌ ERROR: Playwright E2E tests failed on dev."
        exit 1
    fi
    cd "$REPO_ROOT"
    echo "✅ Playwright E2E tests passed."
else
    echo "⏭️  Skipped locally. Remote strict gate enforces Playwright flows and coverage."
fi

# 5. Ready to push
echo ""
echo "--- [5/5] Ready For Push ---"
echo "✅ Local lightweight pre-push checks completed."

echo ""
echo "============================================"
echo "  All pre-push validations passed!"
echo "============================================"
