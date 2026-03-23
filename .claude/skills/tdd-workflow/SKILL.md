---
name: tdd-workflow
description: "Enforces test-driven development for Flutter/Dart and Rust. Tests before code, with coverage targets and anti-pattern enforcement. Use when implementing features, fixing bugs, or refactoring."
---

# TDD Workflow

Test-driven development adapted for origna_gta's Flutter/Dart + Rust stack.

## When to Use

- Implementing new features
- Fixing bugs (write failing test first, then fix)
- Refactoring existing code
- When asked to "add tests" or "write tests"

## Core Principle

**Tests BEFORE code.** Always.

1. Write a failing test
2. Run it, confirm it fails for the right reason
3. Write minimal code to make it pass
4. Run it, confirm it passes
5. Refactor if needed
6. Run all tests to confirm no regressions

## Test Structure: Arrange-Act-Assert

Every test follows this pattern:

```
// Arrange — set up preconditions and inputs
// Act — call the method under test
// Assert — verify the expected outcome
```

## Coverage Targets

| Layer | Target | Enforced? |
|-------|--------|-----------|
| ViewModels | >= 80% line coverage | Yes |
| Services | >= 70% line coverage | Yes |
| Payment paths (checkout, webhooks, refunds) | 100% branch coverage | Yes |
| Screens | Smoke tests required | Yes (build + no exceptions) |
| UI pixel layout | Not required | No |

## File Naming Convention

Test files mirror source files:

| Source | Test |
|--------|------|
| `lib/viewmodels/cart_viewmodel.dart` | `test/viewmodels/cart_viewmodel_test.dart` |
| `lib/services/order_service.dart` | `test/services/order_service_test.dart` |
| `lib/screens/checkout_screen.dart` | `test/screens/checkout_screen_test.dart` |
| `orignabase/crates/ob-auth/src/routes.rs` | Tests in `#[cfg(test)] mod tests` inside the file or `tests/` dir |

## Flutter/Dart Testing

### Mocking

Use `mocktail` for all mocks:

```dart
class MockOrderService extends Mock implements OrderService {}
```

### Widget Tests

Always wrap with ProviderScope:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [orderServiceProvider.overrideWithValue(mockService)],
    child: const MaterialApp(home: CheckoutScreen()),
  ),
);
```

### Running Tests

```bash
# All tests (excluding golden)
flutter test --exclude-tags golden

# Single file
flutter test test/viewmodels/cart_viewmodel_test.dart

# Pattern match
flutter test --name "should calculate subtotal"
```

## Rust Testing

```bash
# All tests
cd orignabase && cargo test

# Single crate
cargo test -p ob-auth

# Single test
cargo test test_name
```

Use `#[tokio::test]` for async tests, `#[cfg(test)]` for test modules.

## Anti-Patterns (NEVER do these)

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| `print()` or `debugPrint()` in tests | Noise, not assertions | Use `expect()` |
| `test.skip` or `skip:` | Tests must pass or be fixed | Fix the test or infrastructure |
| `sleep()` / `Future.delayed()` | Flaky, slow | Use `pumpAndSettle()` or async patterns |
| Deleting failing tests | Hides regressions | Fix the code or the test |
| Real Stripe live-mode calls | Costs money, side effects | Use test keys or mocks |
| Hardcoded UIDs/tokens | Breaks on reseed | Use test account constants |
| `flutter test --coverage` on single file | Overwrites lcov.info | Run on full suite only |
| Mocks for live integration tests | Defeats the purpose | Use real dev OrignaBase |

## Money Testing

Always test with integer cents:

```dart
// Good
expect(cart.subtotalCents, equals(7500)); // $75.00

// Bad — NEVER
expect(cart.subtotal, equals(75.00)); // float money
```

## Test Categories

| Tag | Purpose | Command |
|-----|---------|---------|
| `golden` | Screenshot comparison | Excluded in CI |
| `live` | Hits real dev OrignaBase | `--tags live` |
| (default) | Unit/widget, mocked | `flutter test` |

## References

See `references/flutter-test-patterns.md` for Dart examples.
See `references/rust-test-patterns.md` for Rust examples.
