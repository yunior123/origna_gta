# /test-all — Run all tests

**Usage**: `/test-all [flutter|e2e|all]`

## Rules (8GB RAM — sequential only)
- NEVER run flutter test + Playwright simultaneously
- No emulators — test against dev OrignaBase (`api.dev.orignagta.ca`)
- Deploy latest Flutter build before running E2E tests

## Flutter Tests (default)
```bash
cd origna_gta

# 1. Static analysis first (fast fail)
flutter analyze --no-fatal-infos

# 2. Unit + widget tests
flutter test --reporter=expanded

# 3. Summary
echo "✓ Flutter tests complete"
```

## E2E Tests (Playwright)
```bash
# 1. Deploy latest dev build first
flutter build web --debug \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=FORCE_SEMANTICS=true
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/dev/current/

# 2. Run Playwright tests (max 2 workers on 8GB Mac)
cd e2e
npx playwright test --config=playwright.config.dev.ts --workers=2

# 3. View report
npx playwright show-report
```

## All Tests
```bash
# Sequential: Flutter → E2E
cd origna_gta && flutter analyze --no-fatal-infos && flutter test
cd ../e2e && npx playwright test --config=playwright.config.dev.ts --workers=2
```

## Test Accounts (dev)
| Role | Email | Password |
|------|-------|----------|
| Buyer | `yuniorrodriguezo460@gmail.com` | `REDACTED_TEST_PASSWORD` |
| Seller | `yuniorrodriguezo4601@yahoo.com` | `REDACTED_TEST_PASSWORD` |
| Admin | `yr62813@gmail.com` | `REDACTED_TEST_PASSWORD` |

## Coverage Targets
- `flutter analyze`: 0 errors, 0 warnings
- `flutter test`: all pass, ≥ 80% coverage on ViewModels/Services
- Playwright E2E: ≥ 90% coverage across user flows

## On Failure
1. Read the full error message
2. Check if it's a missing `Semantics` label (Playwright) → add to Flutter widget
3. Check if it's a provider/mock issue (Flutter) → verify `ProviderScope` overrides
4. Never retry blindly — diagnose first
