# /tdd — Test-Driven Development Workflow

**Usage**: `/tdd $ARGUMENTS`

Start a TDD workflow for the given feature or bugfix.

## Process

### Step 1: Define the User Journey
Write: "As a [buyer/seller/admin], I want to [action], so that [benefit]"

### Step 2: Generate Test Cases
Create test file mirroring source path:
- `lib/viewmodels/X.dart` → `test/viewmodels/X_test.dart`
- `lib/services/X.dart` → `test/services/X_test.dart`

Use `mocktail` for mocking. Wrap widget tests with `ProviderScope(overrides: [...])`.

### Step 3: Run Tests (Expect Failure)
```bash
flutter test test/path_to_test.dart
```

### Step 4: Implement Minimal Code
Write just enough to make tests pass. No over-engineering.

### Step 5: Run Tests Again (Expect Green)
```bash
flutter test test/path_to_test.dart
```

### Step 6: Refactor
Improve code quality while keeping tests green.

### Step 7: Verify
```bash
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
```

## Coverage Targets
- ViewModels: ≥80% line coverage
- Services: ≥70% line coverage
- Payment-critical paths: 100% branch coverage

## Anti-Patterns (NEVER)
- `print()` or `debugPrint()` in test files
- `test.skip` — fix infrastructure, never skip
- `sleep()` / `Future.delayed()` — use `pumpAndSettle()`
- Real Stripe live-mode API calls
- Hardcoded UIDs or tokens
- Deleting tests that fail — fix them
- `flutter test --coverage` on single file
