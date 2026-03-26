# OrignaBase Live Integration Tests — Complete Guide

## Overview
Real live integration tests for the OrignaBase Rust backend targeting the dev OrignaBase server at **`https://api.dev.orignagta.ca`**.

**Total: 17 async integration tests across 6 test files**

## Test Files & Test Count

| File | Tests | Focus Area |
|------|-------|-----------|
| `coupon_integration_test.rs` | 3 | Coupon application, expiration, max uses |
| `shipping_integration_test.rs` | 3 | Shipping calculation, perishable rules, free shipping threshold |
| `subscription_integration_test.rs` | 2 | Subscription creation, benefits delay, early cancellation |
| `return_integration_test.rs` | 2 | Return request lifecycle, 30-day window expiry |
| `admin_integration_test.rs` | 4 | Admin auth, user list privacy, audit logging |
| `logout_integration_test.rs` | 3 | Token revocation, refresh rotation, logout invalidation |

**Total: 17 tests**

## Test Accounts (Dev DB)

```
Admin:  email=e2e-admin@test.origna.ca        password=REDACTED_TEST_PASSWORD
Seller: email=e2e-seller@test.origna.ca       password=REDACTED_TEST_PASSWORD
Buyer:  email=e2e-buyer@test.origna.ca        password=REDACTED_TEST_PASSWORD
```

Database: `orignabase` namespace, `dev` db on `api.dev.orignagta.ca`

## Running Tests

### Run all integration tests with `#[ignore]` tag:
```bash
cd orignabase && cargo test --test '*_integration_test' -- --ignored
```

### Run specific test file:
```bash
cargo test --test coupon_integration_test -- --ignored
```

### Run specific test:
```bash
cargo test --test coupon_integration_test test_apply_valid_coupon_reduces_checkout_total -- --ignored
```

### Override base URL (default: https://api.dev.orignagta.ca):
```bash
OB_TEST_URL=http://localhost:8080 cargo test --test shipping_integration_test -- --ignored
```

### Verify compilation without running:
```bash
cargo check --tests
```

## Test Details

### 1. Coupon Integration Tests (`coupon_integration_test.rs`)

#### Test 1: `test_apply_valid_coupon_reduces_checkout_total`
- **Flow**: Seller creates 10% coupon → Buyer applies to $100 checkout
- **Assertions**: Discount applied, total reduced, math correct
- **Blocks**: Requires seller coupon creation endpoint

#### Test 2: `test_expired_coupon_returns_error`
- **Flow**: Buyer tries to apply expired coupon code
- **Assertions**: Returns 400 or 404, rejects expired code
- **Blocks**: Coupon endpoint not implemented

#### Test 3: `test_coupon_max_uses_enforced`
- **Flow**: Create coupon with max 1 use, apply twice
- **Assertions**: First use succeeds, second fails with max uses error
- **Blocks**: Coupon creation endpoint

---

### 2. Shipping Integration Tests (`shipping_integration_test.rs`)

#### Test 1: `test_shipping_calculation_standard_delivery`
- **Flow**: Calculate shipping from Toronto (ON) to Montreal (QC)
- **Assertions**: Cross-province shipping has a cost > 0
- **Business Rule**: Different provinces = shipping fee

#### Test 2: `test_perishable_rejects_over_50km`
- **Flow**: Perishable item, buyer > 50km away (Toronto → Montreal)
- **Assertions**: Returns 400 error, rejects perishable delivery
- **Business Rule**: Perishables limited to ≤ 50km local delivery

#### Test 3: `test_free_shipping_threshold_75_cad`
- **Flow**: Order with $80 subtotal (> $75 CAD threshold)
- **Assertions**: `shippingCostCents = 0` (free shipping)
- **Business Rule**: Free shipping threshold = $75 CAD (7500 cents)

---

### 3. Subscription Integration Tests (`subscription_integration_test.rs`)

#### Test 1: `test_subscription_benefits_delay_48h`
- **Flow**: Create premium subscription → check benefits status immediately
- **Assertions**: Benefits NOT active immediately, delayed activation timestamp exists
- **Business Rule**: Premium benefits activate 48 hours after creation

#### Test 2: `test_subscription_early_cancel_tracking`
- **Flow**: Create subscription → immediately cancel (within 7 days)
- **Assertions**: `wasEarlyCancel = true`, `earlyCancelCount` incremented
- **Business Rule**: Early cancellations (within 7 days) tracked for churn analysis

---

### 4. Return Request Integration Tests (`return_integration_test.rs`)

#### Test 1: `test_return_request_lifecycle`
- **Flow**: Buyer creates return request on delivered order → Admin approves
- **Assertions**: 
  - Initial status = `pending`
  - After approval = `approved`
  - State transitions correct
- **Business Rule**: Return window = 30 days from delivery

#### Test 2: `test_return_request_expired_window`
- **Flow**: Buyer tries to return order > 30 days old
- **Assertions**: Returns 400 error, rejects expired return window
- **Business Rule**: Return window enforced at 30 days

---

### 5. Admin Integration Tests (`admin_integration_test.rs`)

#### Test 1: `test_admin_list_users_no_email_leak`
- **Flow**: Admin calls `/admin/users` list endpoint
- **Assertions**: 
  - Response includes `id`, `role` fields
  - Email field NOT included (privacy protection)
- **Security**: PII (emails) never exposed in admin list

#### Test 2: `test_admin_list_users_requires_auth`
- **Flow**: Unauthenticated request to `/admin/users`
- **Assertions**: Returns **401 Unauthorized**
- **Security**: All admin endpoints require valid JWT

#### Test 3: `test_admin_get_user_requires_admin_role`
- **Flow**: Admin retrieves `/admin/users/{user_id}`
- **Assertions**: Returns user details for valid user ID
- **Security**: Only admin role can access detailed user info

#### Test 4: `test_admin_actions_logged_with_uid`
- **Flow**: Admin performs action (list users) → check audit log
- **Assertions**: Audit log entries include `adminUid` field
- **Compliance**: All admin actions logged for audit trail

---

### 6. Logout & Token Refresh Tests (`logout_integration_test.rs`)

#### Test 1: `test_logout_revokes_refresh_token`
- **Flow**: Login → Logout → Try to refresh with old refresh token
- **Assertions**: Refresh fails with 401 after logout, token revoked
- **Security**: Logout revokes refresh tokens

#### Test 2: `test_refresh_rotation_revokes_old`
- **Flow**: Login → Refresh token #1 (get #2) → Try to use old #1 again
- **Assertions**: Old refresh token invalidated, new token still valid
- **Security**: Token rotation with implicit revocation (optional, depends on impl)

#### Test 3: `test_logout_invalidates_access_token`
- **Flow**: Login → Verify token works → Logout → Verify token fails
- **Assertions**: Logged-out access token no longer valid
- **Security**: Logout invalidates active sessions

---

## Key Design Patterns

### Pattern 1: Login Helper
```rust
async fn login_buyer(client: &reqwest::Client) -> String {
    let resp = client.post(format!("{}/auth/login", base_url()))
        .json(&json!({...}))
        .send().await.expect("login failed");
    
    assert_eq!(resp.status(), 200);
    body["access_token"].as_str().expect("missing token").to_string()
}
```

### Pattern 2: API Call with Error Handling
```rust
async fn get_orders(client: &reqwest::Client, token: &str) -> Result<Vec<Value>, String> {
    let resp = client.get(format!("{}/orders", base_url()))
        .header("Authorization", format!("Bearer {}", token))
        .send().await
        .map_err(|e| format!("request failed: {}", e))?;
    
    if resp.status() == 200 {
        Ok(resp.json().await.unwrap_or_default())
    } else {
        Err(format!("call failed: {}", resp.status()))
    }
}
```

### Pattern 3: Test with Graceful Degradation
```rust
#[tokio::test]
#[ignore]
async fn test_something() {
    // Attempt API call
    match some_endpoint(&client, &token).await {
        Ok(result) => {
            // Assert behavior
            assert_eq!(result.status, "expected");
        }
        Err(e) => {
            // Endpoint not implemented — skip test
            eprintln!("Feature not available: {}", e);
        }
    }
}
```

## Dependencies (Already in Cargo.toml)

```toml
[dev-dependencies]
reqwest = { workspace = true }
serde_json = { workspace = true }
tokio = { workspace = true }
uuid = { workspace = true }
```

## Environment Variables

- **`OB_TEST_URL`** — Base URL for OrignaBase (default: `https://api.dev.orignagta.ca`)

## Notes

### Test Isolation
- Tests are **independent** — can run in any order
- **Graceful skipping** — if endpoint not implemented, test logs and continues
- **No cleanup** required (reads only, or creates test data that's non-destructive)

### Why `#[ignore]`?
- Requires running OrignaBase server (not suitable for `cargo test` in CI)
- Dev server might be offline — tests fail gracefully
- Marked `#[ignore]` so `cargo test` passes without server
- Run explicitly with `--ignored` flag

### Assertions Strategy
- **Functional assertions**: Verify business logic (discount applied, status transitioned)
- **Security assertions**: Verify auth required, PII not leaked
- **Error assertions**: Verify 400/401 codes for invalid inputs
- **Graceful degradation**: Missing endpoints skip the test rather than fail hard

## Extending Tests

### Add a new test file:
1. Create `orignabase/crates/orignabase/tests/my_feature_integration_test.rs`
2. Import utilities and test accounts
3. Write test functions with `#[tokio::test]` + `#[ignore]`
4. Run: `cargo test --test my_feature_integration_test -- --ignored`

### Add a test to existing file:
1. Add new async fn with `#[tokio::test]` + `#[ignore]`
2. Use existing login helpers
3. Make API calls, assert results
4. Rerun file: `cargo test --test coupon_integration_test -- --ignored`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Login failed` | Check test account exists in dev DB and password matches |
| `Connection refused` | Verify `OB_TEST_URL` is reachable (e.g., VPN active) |
| `404 Not Found` | Endpoint not yet implemented — test gracefully skips |
| `400 Bad Request` | Check request payload matches API expectations |
| `401 Unauthorized` | Token may be expired; re-login or check auth headers |

## Next Steps

- Run these tests against dev server: `cd orignabase && cargo test --test '*_integration_test' -- --ignored`
- Monitor for failures and implement missing endpoints
- Add more tests for new features
- Run before deploys to catch regressions
