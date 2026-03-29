# Rust Test Patterns — origna_gta (OrignaBase)

## Unit Test: Basic Function

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_record_id_for_meilisearch() {
        // Arrange
        let record_id = "products_abc123";

        // Act
        let meili_id = sanitize_id(record_id);

        // Assert
        assert_eq!(meili_id, "products_abc123");
    }

    #[test]
    fn test_platform_fee_calculation() {
        // Arrange
        let subtotal_cents: i64 = 10000; // $100.00
        let fee_rate = 0.10; // 10%

        // Act
        let fee_cents = (subtotal_cents as f64 * fee_rate).round() as i64;

        // Assert
        assert_eq!(fee_cents, 1000); // $10.00
    }
}
```

## Async Test: API Handler

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::StatusCode;
    use axum_test::TestServer;

    #[tokio::test]
    async fn test_login_returns_jwt() {
        // Arrange
        let app = create_test_app().await;
        let server = TestServer::new(app).unwrap();
        let body = serde_json::json!({
            "email": "test@example.com",
            "password": "REDACTED_TEST_PASSWORD"
        });

        // Act
        let response = server
            .post("/auth/login")
            .json(&body)
            .await;

        // Assert
        assert_eq!(response.status_code(), StatusCode::OK);
        let json: serde_json::Value = response.json();
        assert!(json["token"].is_string());
    }

    #[tokio::test]
    async fn test_login_invalid_password_returns_401() {
        // Arrange
        let app = create_test_app().await;
        let server = TestServer::new(app).unwrap();
        let body = serde_json::json!({
            "email": "test@example.com",
            "password": "wrong"
        });

        // Act
        let response = server
            .post("/auth/login")
            .json(&body)
            .await;

        // Assert
        assert_eq!(response.status_code(), StatusCode::UNAUTHORIZED);
    }
}
```

## Webhook HMAC Verification Test

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use hmac::{Hmac, Mac};
    use sha2::Sha256;

    #[test]
    fn test_webhook_signature_valid() {
        // Arrange
        let secret = "STRIPE_WEBHOOK_SECRET_REDACTED";
        let payload = b"test payload";
        let timestamp = "1234567890";

        let signed_payload = format!("{}.{}", timestamp, String::from_utf8_lossy(payload));
        type HmacSha256 = Hmac<Sha256>;
        let mut mac = HmacSha256::new_from_slice(secret.as_bytes()).unwrap();
        mac.update(signed_payload.as_bytes());
        let signature = hex::encode(mac.finalize().into_bytes());

        // Act
        let result = verify_webhook_signature(payload, timestamp, &signature, secret);

        // Assert
        assert!(result.is_ok());
    }

    #[test]
    fn test_webhook_signature_invalid() {
        // Arrange
        let payload = b"test payload";
        let timestamp = "1234567890";
        let bad_signature = "deadbeef";
        let secret = "STRIPE_WEBHOOK_SECRET_REDACTED";

        // Act
        let result = verify_webhook_signature(payload, timestamp, bad_signature, secret);

        // Assert
        assert!(result.is_err());
    }
}
```

## Testing with PostgreSQL (Integration)

```rust
#[cfg(test)]
mod tests {
    use sqlx::PgPool;

    async fn setup_test_db() -> PgPool {
        let pool = PgPool::connect("postgresql://localhost:5432/test_db")
            .await
            .unwrap();
        // Run schema migrations
        sqlx::migrate!("../migrations").run(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_create_order() {
        // Arrange
        let pool = setup_test_db().await;
        let order = Order {
            buyer_id: "buyer1".into(),
            seller_id: "seller1".into(),
            status: OrderStatus::Pending,
            total_amount_cents: 5000,
            items: vec![],
        };

        // Act
        let created: Option<Order> = db
            .create("orders")
            .content(&order)
            .await
            .unwrap();

        // Assert
        assert!(created.is_some());
        let created = created.unwrap();
        assert_eq!(created.status, OrderStatus::Pending);
        assert_eq!(created.total_amount_cents, 5000);
    }
}
```

## Order State Transition Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_transition_pending_to_confirmed() {
        assert!(OrderStatus::Pending.can_transition_to(&OrderStatus::Confirmed));
    }

    #[test]
    fn test_invalid_transition_pending_to_delivered() {
        assert!(!OrderStatus::Pending.can_transition_to(&OrderStatus::Delivered));
    }

    #[test]
    fn test_terminal_states_cannot_transition() {
        assert!(!OrderStatus::Delivered.can_transition_to(&OrderStatus::Cancelled));
        assert!(!OrderStatus::Cancelled.can_transition_to(&OrderStatus::Pending));
    }

    #[test]
    fn test_all_valid_transitions() {
        let valid = vec![
            (OrderStatus::Pending, OrderStatus::Confirmed),
            (OrderStatus::Pending, OrderStatus::Cancelled),
            (OrderStatus::Confirmed, OrderStatus::Shipped),
            (OrderStatus::Confirmed, OrderStatus::Cancelled),
            (OrderStatus::Shipped, OrderStatus::Delivered),
        ];
        for (from, to) in valid {
            assert!(from.can_transition_to(&to), "{:?} -> {:?} should be valid", from, to);
        }
    }
}
```

## Running Tests

```bash
# All tests
cargo test

# Single crate
cargo test -p ob-auth

# Single test by name
cargo test test_login_returns_jwt

# With output
cargo test -- --nocapture

# Only doc tests
cargo test --doc
```
