#!/usr/bin/env bash

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "  Pre-Push Validation Suite"
echo "============================================"

# 0a. Flutter unit/widget tests — run FIRST while RAM is fresh (before heavy builds)
echo ""
echo "--- [0a] Flutter Tests (pre-build, RAM-fresh) ---"
cd origna_gta
if ! flutter test --reporter compact --concurrency=4; then
    echo "❌ ERROR: Flutter tests failed."
    exit 1
fi
cd "$REPO_ROOT"
echo "✅ Flutter tests passed."

# 0b. Python backend tests — run before builds too
echo ""
echo "--- [0b] Python Backend Tests (pre-build) ---"
cd functions
pip install -q pytest pytest-mock mockito sentry_sdk > /dev/null 2>&1
if ! python3 -m pytest tests/ -q --tb=short; then
    echo "❌ ERROR: Backend Python tests failed."
    exit 1
fi
cd "$REPO_ROOT"
echo "✅ Backend tests passed."

# 0. Per-environment: build → validate → deploy (3 builds total, one per env)
echo ""
echo "--- [0/10] Multi-Env Build + Deploy ---"
BUILD_DIR="$REPO_ROOT/origna_gta/build/web"

get_env_config() {
  case "$1" in
    orignagta-dev)
      ENV_NAME="dev"
      BUILD_MODE="--debug"
      DART_DEFINES="--dart-define=ENVIRONMENT=dev --dart-define=FORCE_SEMANTICS=true"
      # Cloudflare Turnstile: always-pass test key for dev
      TURNSTILE_SITE_KEY="1x00000000000000000000AA"
      ;;
    orignagta-staging)
      ENV_NAME="staging"
      BUILD_MODE="--profile"
      # reCAPTCHA Enterprise key for staging (orignagta-staging project)
      DART_DEFINES="--dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true --dart-define=RECAPTCHA_SITE_KEY=REDACTED_SECRET"
      # Cloudflare Turnstile: staging widget (orignagta-staging.web.app)
      TURNSTILE_SITE_KEY="0x4AAAAAACmRNCDQqc20J_1T"
      ;;
    orignagta)
      ENV_NAME="prod"
      BUILD_MODE="--release"
      # reCAPTCHA Enterprise key for prod (orignagta project, domain: www.orignagta.ca)
      DART_DEFINES="--dart-define=ENVIRONMENT=production --dart-define=RECAPTCHA_SITE_KEY=6LeRUH8sAAAAAAy_kF_aBSzAP3cdneh-P_a14Og-"
      # Cloudflare Turnstile: prod widget (www.orignagta.ca)
      TURNSTILE_SITE_KEY="0x4AAAAAACmRNXgZQ1M928iq"
      ;;
  esac
}

for PROJECT in orignagta-dev orignagta-staging orignagta; do
  get_env_config "$PROJECT"
  echo ""
  echo -e "${YELLOW}→ [$ENV_NAME] $PROJECT${NC}"

  echo -e "  ${YELLOW}Building Flutter web for $ENV_NAME...${NC}"
  cd "$REPO_ROOT/origna_gta"
  if ! flutter build web $BUILD_MODE $DART_DEFINES; then
      echo "❌ ERROR: Flutter $ENV_NAME build failed."
      exit 1
  fi

  if grep -q "ENVIRONMENT" "$BUILD_DIR/main.dart.js" 2>/dev/null; then
      echo -e "  ${GREEN}Build verified for $ENV_NAME${NC}"
  fi

  # Inject Turnstile site key into built index.html (placeholder → real key)
  if [ -f "$BUILD_DIR/index.html" ]; then
      sed -i '' "s/__TURNSTILE_SITE_KEY__/${TURNSTILE_SITE_KEY}/g" "$BUILD_DIR/index.html"
      echo -e "  ${GREEN}Turnstile site key injected for $ENV_NAME${NC}"
  fi

  # Guardrail: prod build must NOT contain FORCE_SEMANTICS
  if [ "$ENV_NAME" = "prod" ]; then
      if grep -q "FORCE_SEMANTICS" "$BUILD_DIR/main.dart.js" 2>/dev/null; then
          echo "❌ ERROR: FORCE_SEMANTICS found in PROD build — dev/staging artifacts leaked into release!"
          exit 1
      fi
      echo -e "  ${GREEN}PROD build guardrail OK (no dev/staging artifacts)${NC}"
  fi

  cd "$REPO_ROOT"

  # Deploy Firestore rules, indexes, and hosting
  firebase deploy --only firestore:rules,firestore:indexes,hosting --project "$PROJECT"

  # Deploy storage rules — gracefully skip if Firebase Storage not provisioned
  storage_exit=0
  storage_out=$(firebase deploy --only storage --project "$PROJECT" 2>&1) || storage_exit=$?
  if echo "$storage_out" | grep -q "Firebase Storage has not been set up"; then
      echo -e "  ${YELLOW}[$ENV_NAME] Firebase Storage not provisioned — skipping${NC}"
  elif [ "${storage_exit}" -ne 0 ]; then
      echo "$storage_out"
      exit "${storage_exit}"
  fi

  echo -e "  ${GREEN}[$ENV_NAME] Done${NC}"
done

echo ""
echo "Recording deployed versions..."
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=dev     --component=all
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=staging --component=all
python3 "$REPO_ROOT/scripts/record_deploy_version.py" --env=prod    --component=all

echo "✅ All 3 environments built and deployed."

# 1. Check for credential leaks
echo ""
echo "--- [1/10] Credential Leak Check ---"
if grep -r "960227Y#y" e2e/ origna_gta/lib/ origna_gta/test/ origna_gta/patrol_test/ 2>/dev/null; then
    echo "❌ ERROR: Old admin password found in source code."
    exit 1
fi
echo "✅ No credential leaks found."

# 2. Schema sync: Python ↔ Dart constants
echo ""
echo "--- [2/10] Schema Constants Sync (Python ↔ Dart) ---"
if ! python3 scripts/validate_schema_sync.py; then
    echo "❌ ERROR: Schema constants are out of sync."
    exit 1
fi
echo "✅ Schema constants in sync."

# 3. Algolia config validation
echo ""
echo "--- [3/10] Algolia Configuration Sync ---"
if ! python3 scripts/validate_algolia_sync.py; then
    echo "❌ ERROR: Algolia configuration mismatch."
    exit 1
fi
echo "✅ Algolia config validated."

# 4. Magic string detection on changed files
echo ""
echo "--- [4/10] Magic String Detection ---"
if ! python3 scripts/validate_no_magic_strings.py --ci; then
    echo "⚠️  WARNING: Magic strings detected (see above). Consider fixing before push."
    # Non-blocking for now — switch to exit 1 after cleanup
fi

# 5. API endpoint cross-reference (static analysis only — no HTTP)
echo ""
echo "--- [5/10] API Endpoint Sync (Frontend ↔ Backend) ---"
if ! python3 scripts/validate_api_endpoints.py --skip-http; then
    echo "❌ ERROR: API endpoint mismatch between frontend and backend."
    exit 1
fi
echo "✅ API endpoints in sync."

# 6. Validate Firestore indexes, rules, storage across environments
echo ""
echo "--- [6/10] Firestore Rules & Indexes ---"
python3 scripts/validate_indexes.py
python3 scripts/validate_rules.py
python3 scripts/validate_storage_rules.py

# 7. Cloud Functions sync + deploy version parity
echo ""
echo "--- [7/10] Cloud Functions & Deploy Parity ---"
python3 scripts/verify_functions_sync.py
python3 scripts/check_deploy_versions.py

# 8. (Flutter tests already ran in step 0a)
# 9. (Python tests already ran in step 0b)

# 10. Playwright E2E tests against dev
echo ""
echo "--- [10/10] Playwright E2E Tests (dev) ---"
cd e2e
if ! npx playwright test --config=playwright.config.dev.ts --retries=1 --workers=4; then
    echo "❌ ERROR: Playwright E2E tests failed on dev."
    exit 1
fi
cd "$REPO_ROOT"
echo "✅ Playwright E2E tests passed."

echo ""
echo "============================================"
echo "  All pre-push validations passed!"
echo "============================================"
