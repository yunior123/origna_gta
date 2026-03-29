# Rust Standards — origna_gta (OrignaBase)

## Error Handling

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Unauthorized")]
    Unauthorized,

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Internal error: {0}")]
    Internal(String),

    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".into()),
            AppError::Validation(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            AppError::Internal(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Internal server error".into(), // Never expose internal details
            ),
            AppError::Database(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Database error".into(),
            ),
        };
        (status, Json(json!({"error": message}))).into_response()
    }
}
```

## Handler Pattern

```rust
use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct CreateProductRequest {
    pub name: String,
    pub description: String,
    pub price_cents: i64,       // Always integer cents
    pub category_id: String,
    pub stock_quantity: i32,
}

#[derive(Serialize)]
pub struct ProductResponse {
    pub id: String,
    pub name: String,
    pub price_cents: i64,
}

pub async fn create_product(
    State(state): State<AppState>,
    claims: Claims,              // Extracted from JWT middleware
    Json(req): Json<CreateProductRequest>,
) -> Result<Json<ProductResponse>, AppError> {
    // Validate input
    if req.price_cents <= 0 || req.price_cents > 10_000_000 {
        return Err(AppError::Validation("Price must be 1-10000000 cents".into()));
    }

    // Use parameterized query — NEVER string concatenation
    let product: Option<ProductResponse> = state.db
        .query("CREATE products SET name = $name, price_cents = $price_cents, seller_id = $seller_id")
        .bind(("name", &req.name))
        .bind(("price_cents", req.price_cents))
        .bind(("seller_id", &claims.sub))  // From JWT, never from request body
        .await?
        .take(0)?;

    product
        .map(Json)
        .ok_or_else(|| AppError::Internal("Failed to create product".into()))
}
```

## Money in Rust

```rust
// CORRECT — integer cents
let price_cents: i64 = 7500;           // $75.00
let platform_fee_cents: i64 = 750;     // $7.50
let subtotal_cents: i64 = items.iter().map(|i| i.unit_price_cents * i.quantity as i64).sum();

// FORBIDDEN
let price: f64 = 75.00;               // Float money
let total: f32 = 86.25;               // Float money
```

## Logging (tracing, not println)

```rust
use tracing::{info, warn, error, debug};

// CORRECT
info!(order_id = %order.id, "Order confirmed");
warn!(user_id = %user.id, "Rate limit approaching");
error!(error = %e, "Webhook processing failed");

// FORBIDDEN
println!("Order confirmed: {}", order.id);   // Never println
eprintln!("Error: {}", e);                    // Never eprintln
```

## PostgreSQL Queries (Parameterized Only)

```rust
// CORRECT — parameterized
let orders: Vec<Order> = sqlx::query_as(
    "SELECT * FROM orders WHERE buyer_id = $1 ORDER BY createdAt DESC LIMIT $2"
)
.bind(&user_id)
.bind(limit)
.fetch_all(&pool)
.await?;

// FORBIDDEN — string concatenation (SQL injection risk)
let query = format!("SELECT * FROM orders WHERE buyer_id = '{}'", user_id);
```

## JWT Claims

```rust
#[derive(Debug, Deserialize, Serialize)]
pub struct Claims {
    pub sub: String,        // User UUID
    pub uid: String,        // Short ID: "abc123"
    pub role: String,       // "buyer", "seller", "admin"
    pub exp: usize,
    pub iat: usize,
}

// Always derive user identity from JWT, never from request body
pub async fn get_my_orders(
    State(state): State<AppState>,
    claims: Claims,
) -> Result<Json<Vec<Order>>, AppError> {
    // Use claims.sub — never trust user-supplied IDs
    let orders = fetch_orders_for_user(&state.db, &claims.sub).await?;
    Ok(Json(orders))
}
```

## Stripe Integration

```rust
// Always use idempotency keys
let idempotency_key = format!("{}-checkout", order_id);

// Webhook signature verification — constant-time comparison
use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;
let mut mac = HmacSha256::new_from_slice(webhook_secret.as_bytes())
    .map_err(|_| AppError::Internal("HMAC init failed".into()))?;
mac.update(signed_payload.as_bytes());
mac.verify_slice(&expected_sig)  // Constant-time comparison
    .map_err(|_| AppError::Unauthorized)?;
```

## Module Organization

```
orignabase/
  crates/
    ob-auth/        # Authentication (JWT, OAuth, MFA)
    ob-core/        # Shared types, AppError, config
    ob-payments/    # Stripe integration
    ob-products/    # Product CRUD, search sync
    ob-orders/      # Order lifecycle, state machine
    ob-storage/     # Cloudflare R2 integration
```

## Clippy Compliance

Run with `-D warnings` (all warnings are errors):

```bash
cargo clippy -D warnings
```

Common fixes:
- `&String` → `&str` in function params
- `clone()` when borrow is sufficient
- `unwrap()` → proper error handling with `?`
- Unused variables → prefix with `_`
