---
name: test-coverage-boost
description: "Increases test coverage for OrignaGTA to 95%+. Priority: live tests (Rust first, then Flutter), unit tests secondary. Covers test generation, coverage analysis, and gap identification. Use when asked to 'increase coverage', 'add tests', 'test coverage', or 'missing tests'."
---

# Test Coverage Boost — OrignaGTA

Increase test coverage to 95%+ across Rust backend and Flutter frontend. Priority: live integration tests against real OrignaBase + PostgreSQL + Meilisearch.

## When to Use

- After implementing new features
- Before releases (coverage gate)
- When asked to "increase coverage", "add tests", "missing tests"
- During quality audits

## Priority Order

1. **Rust live tests** (against localhost OrignaBase + PostgreSQL) — HIGHEST
2. **Flutter live tests** (against localhost OrignaBase) — HIGH
3. **Rust unit tests** — MEDIUM
4. **Flutter unit/widget tests** — MEDIUM

## Prerequisites

```bash
# OrignaBase must be running on localhost:8080
# PostgreSQL must be seeded
cd e2e && ORIGNABASE_URL=http://127.0.0.1:8080 bun run lib/seed-dev.ts

# Meilisearch should be running for search tests
```

## Coverage Analysis

### Rust

```bash
# Generate coverage report
cd orignabase
cargo tarpaulin --out html --output-dir /tmp/coverage-rust

# Per-crate coverage
cargo tarpaulin -p ob-handlers --out html --output-dir /tmp/coverage-handlers

# Find uncovered lines
cargo tarpaulin --out json --output-dir /tmp/coverage-rust
```

### Flutter

```bash
cd origna_gta
flutter test --coverage --reporter=compact --exclude-tags golden

# Generate HTML report
genhtml coverage/lcov.info -o /tmp/coverage-flutter

# Find uncovered files
lcov --summary coverage/lcov.info 2>&1 | grep "lines"
```

## Test Generation Strategy

### Phase 1: Critical Path Coverage (Target: 95%)

These paths MUST have live tests:

| Path | Rust Handler | Flutter Repository | Priority |
|------|-------------|-------------------|----------|
| Checkout flow | `payments/checkout.rs` | `orignabase_order_repository.dart` | P0 |
| Webhook processing | `payments/webhooks.rs` | N/A | P0 |
| Stock management | `products/crud.rs` | `orignabase_cart_repository.dart` | P0 |
| Auth (login/register) | `ob-auth/src/routes.rs` | `orignabase_auth_repository.dart` | P0 |
| Order state transitions | `orders/status.rs` | `orignabase_order_repository.dart` | P0 |
| Refunds | `orders/refunds.rs` | `orignabase_order_repository.dart` | P1 |
| Returns | `orders/returns.rs` | N/A | P1 |
| Shipping calc | `shipping_calc/mod.rs` | N/A | P1 |
| Coupons | `coupons/mod.rs` | N/A | P1 |
| Subscriptions | `payments/subscriptions.rs` | N/A | P1 |
| Seller registration | N/A | `orignabase_seller_registration_vm.dart` | P1 |
| Notifications | `native_triggers.rs` | `orignabase_notification_service.dart` | P2 |

### Phase 2: Edge Case Coverage

For each critical path, test:

- Happy path (normal flow)
- Boundary values (0, max int, empty string)
- Error paths (invalid input, auth failure, not found)
- Concurrency (race conditions, TOCTOU)
- Idempotency (duplicate requests)

### Phase 3: Negative Test Coverage

- [ ] Invalid JWT token → 401
- [ ] Expired JWT token → 401
- [ ] Missing required fields → 400
- [ ] Insufficient stock → 409
- [ ] Invalid order transition → 409
- [ ] Duplicate webhook event → 200 (no-op)
- [ ] Non-existent resource → 404
- [ ] Rate limiting → 429
- [ ] Cross-user access → 403

## Rust Live Test Template

```rust
#[tokio::test]
#[ignore] // Run with: cargo test -- --ignored
async fn test_checkout_creates_order_with_correct_amount() {
    let state = test_state().await;

    // Seed test data
    let product = seed_product(&state, 2500, 10).await; // $25.00, 10 in stock
    let buyer = seed_buyer(&state).await;
    let address = seed_address(&state, &buyer).await;

    // Execute checkout
    let result = create_checkout_session(
        state.clone(),
        Extension(buyer.clone()),
        Json(json!({
            "items": [{"productId": product.id, "quantity": 2}],
            "shippingAddress": address,
        })),
    ).await;

    // Verify
    assert!(result.is_ok());
    let session = result.unwrap();
    assert_eq!(session.total_amount_cents, 5000); // $50.00 (2 × $25.00)
}
```

## Flutter Live Test Template

```dart
void main() {
  late OrignaBaseClient client;

  setUpAll(() async {
    // Connect to localhost OrignaBase
    client = OrignaBaseClient(
      baseUrl: 'http://127.0.0.1:8080',
    );
    await client.auth.signInWithEmail(
      email: 'test@example.com',
      password: 'Test1234!',
    );
  });

  testWidgets('cart add validates stock', (tester) async {
    // Seed a product with 1 stock
    final product = await seedProduct(client, stockQuantity: 1);

    // Add 1 to cart — should succeed
    final repo = OrignaCartRepository(client: client);
    await repo.addToCart(product.id, 1);

    // Add another — should throw StockInsufficientError
    expect(
      () => repo.addToCart(product.id, 1),
      throwsA(isA<StockInsufficientError>()),
    );
  });
}
```

## Coverage Gates

| Metric | Minimum | Target |
|--------|---------|--------|
| Rust line coverage | 85% | 95% |
| Rust branch coverage | 75% | 90% |
| Flutter line coverage | 80% | 95% |
| Critical path coverage | 100% | 100% |
| E2E flow coverage | 90% | 100% |

## Quick Commands

```bash
# Run all Rust tests with coverage
cd orignabase && cargo tarpaulin --skip-clean

# Run Rust handler tests only
cargo test -p ob-handlers --lib

# Run ignored (live) tests
cargo test -p ob-handlers -- --ignored

# Run all Flutter tests
cd origna_gta && flutter test --exclude-tags golden

# Run Flutter live tests
flutter test test/live/ --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=emulator

# Run Flutter coverage
flutter test --coverage --exclude-tags golden

# Kill zombie test processes
pkill -f flutter_test || true
```
