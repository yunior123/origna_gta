#!/usr/bin/env bash

set -e

echo "Running Pre-Push Validation for State Regression Fixes..."

# 1. Check for old admin password leaks
echo "Checking for old admin password leaks..."
if grep -r "960227Y#y" e2e/ origna_gta/lib/ origna_gta/test/ origna_gta/patrol_test/; then
    echo "❌ ERROR: Old admin password found in source code. Please remove it."
    exit 1
fi
echo "✅ No old admin password leaks found."

# 2. Validate composite indexes across all environments
echo "Validating Firestore composite indexes against dev, staging, and prod..."
python3 scripts/validate_indexes.py

# 3. Validate Firestore rules across all environments
echo "Validating Firestore rules against dev, staging, and prod..."
python3 scripts/validate_rules.py

# 3.1. Validate Firebase Storage rules across all environments
echo "Validating Firebase Storage rules against dev, staging, and prod..."
python3 scripts/validate_storage_rules.py

# 3.5. Validate Cloud Functions sync across all environments
echo "Validating Cloud Functions sync against dev, staging, and prod..."
python3 scripts/verify_functions_sync.py

# 3.6. Validate deploy version parity (rules, indexes, functions, hosting, schema)
echo "Validating deploy version parity across dev, staging, and prod..."
python3 scripts/check_deploy_versions.py

# 4. Run ALL Flutter Unit & Widget Tests
echo "Running ALL Flutter Tests..."
cd origna_gta
if ! flutter test; then
    echo "❌ ERROR: Flutter tests failed."
    exit 1
fi
cd ..
echo "✅ Flutter tests passed."

# 5. Run Python Backend Tests
echo "Running Python Backend Tests..."
cd functions
# Ensure dependencies are installed (quietly)
pip install -q pytest pytest-mock mockito > /dev/null 2>&1
if ! pytest tests/test_handlers_payment_stripe.py tests/test_handlers_products_orders.py tests/test_handlers_admin_cron.py tests/test_edge_cases_advanced.py -q; then
    echo "❌ ERROR: Backend Python tests failed."
    exit 1
fi
cd ..
echo "✅ Backend tests passed."

# 6. Run Playwright E2E Tests against Dev
echo "Running Playwright E2E Tests against dev environment..."
cd e2e
if ! npx playwright test --config=playwright.config.dev.ts --retries=1 --workers=4; then
    echo "❌ ERROR: Playwright E2E tests failed on dev."
    exit 1
fi
cd ..
echo "✅ Playwright E2E tests passed."

echo "🎉 All pre-push validation tests passed!"
