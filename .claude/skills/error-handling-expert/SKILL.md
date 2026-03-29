---
name: error-handling-expert
description: "State-of-the-art error handling for OrignaGTA Rust + Dart. Typed errors, structured error codes, proper propagation, no string matching. Use when asked to 'improve error handling', 'error codes', 'typed errors', or 'error audit'."
---

# Error Handling Expert — OrignaGTA

State-of-the-art error handling for the Rust backend and Flutter frontend. Ensures typed errors, structured error codes, proper propagation, and zero string matching.

## When to Use

- Writing new Rust handlers or Dart repositories
- After finding swallowed errors or silent failures
- When asked to "improve error handling", "error codes", "typed errors"
- During code review for error handling quality

## Error Code Taxonomy

All errors use a structured code system:

```
AUTH_REQUIRED        — No valid JWT token
AUTH_EXPIRED         — JWT token expired
AUTH_INVALID         — JWT token malformed
AUTH_MFA_REQUIRED    — MFA challenge needed
AUTH_RATE_LIMITED    — Too many auth attempts

ORDER_NOT_FOUND      — Order doesn't exist
ORDER_INVALID_TRANS  — Invalid state transition
ORDER_ALREADY_PAID   — Order already confirmed
ORDER_CANCELLED      — Order was cancelled

STOCK_INSUFFICIENT   — Not enough stock
STOCK_LOCKED         — Stock reserved by another checkout

PAY_FAILED           — Payment processing failed
PAY_AMOUNT_MISMATCH  — Client amount != server amount
PAY_IDEMPOTENT       — Duplicate payment attempt

VALID_REQUIRED       — Required field missing
VALID_INVALID_FORMAT — Field format invalid
VALID_OUT_OF_RANGE   — Value outside acceptable range

RATE_LIMITED         — Generic rate limiting
INTERNAL_ERROR       — Unexpected server error
INTERNAL_DB_ERROR    — Database operation failed
```

## Rust Error Handling

### Pattern 1: Typed Error Enum

```rust
// CORRECT — typed error with structured code
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("stock insufficient: requested {requested}, available {available}")]
    StockInsufficient { requested: i64, available: i64 },

    #[error("order invalid transition: {from} -> {to}")]
    OrderInvalidTransition { from: String, to: String },

    #[error("auth required")]
    AuthRequired,

    #[error("internal error: {0}")]
    Internal(String),
}

impl AppError {
    pub fn code(&self) -> &'static str {
        match self {
            Self::StockInsufficient { .. } => "STOCK_INSUFFICIENT",
            Self::OrderInvalidTransition { .. } => "ORDER_INVALID_TRANS",
            Self::AuthRequired => "AUTH_REQUIRED",
            Self::Internal(_) => "INTERNAL_ERROR",
        }
    }

    pub fn status_code(&self) -> u16 {
        match self {
            Self::StockInsufficient { .. } => 409,
            Self::OrderInvalidTransition { .. } => 409,
            Self::AuthRequired => 401,
            Self::Internal(_) => 500,
        }
    }
}
```

### Pattern 2: Proper Propagation

```rust
// CORRECT — propagate with context
let order = state.db
    .get_document("orders", order_id)
    .await
    .map_err(|e| AppError::Internal(format!("failed to fetch order: {e}")))?;

// CORRECT — map specific errors
let stock = get_stock(&state, product_id).await
    .map_err(|e| match e {
        DbError::NotFound => AppError::Validation("product not found".into()),
        DbError::ConnectionFailed => AppError::Internal("database unavailable".into()),
        other => AppError::Internal(format!("unexpected: {other}")),
    })?;

// FORBIDDEN — unwrap in production
let order = state.db.get_document("orders", order_id).await.unwrap();

// FORBIDDEN — swallowing errors
let _ = state.db.update_document(...).await;

// FORBIDDEN — string matching on errors
if err.to_string().contains("not found") { ... }
```

### Pattern 3: HTTP Response Mapping

```rust
// CORRECT — structured error response
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status = StatusCode::from_u16(self.status_code()).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR);
        let body = serde_json::json!({
            "error": {
                "code": self.code(),
                "message": self.to_string(),
            }
        });
        (status, Json(body)).into_response()
    }
}
```

## Dart Error Handling

### Pattern 1: AppError Hierarchy

```dart
// CORRECT — typed error hierarchy
abstract class AppError implements Exception {
  String get code;
  String get message;
}

class StockInsufficientError extends AppError {
  @override final String code = 'STOCK_INSUFFICIENT';
  @override final String message;
  final int requested;
  final int available;
  StockInsufficientError({required this.requested, required this.available})
      : message = 'Only $available available';
}

class OrderInvalidTransitionError extends AppError {
  @override final String code = 'ORDER_INVALID_TRANS';
  @override final String message;
  final String from;
  final String to;
  OrderInvalidTransitionError({required this.from, required this.to})
      : message = 'Cannot go from $from to $to';
}

// FORBIDDEN — generic Exception
throw Exception('something went wrong');

// FORBIDDEN — string-based error
throw 'stock insufficient';
```

### Pattern 2: Repository Layer Error Mapping

```dart
// CORRECT — map SDK exceptions to domain errors
Future<void> addToCart(String productId, int quantity) async {
  try {
    await _client.collection('cart_items').add({...});
  } on OrignaBaseException catch (e) {
    if (e.code == 'stock_insufficient') {
      throw StockInsufficientError(
        requested: quantity,
        available: e.details?['available'] ?? 0,
      );
    }
    rethrow;
  }
}

// FORBIDDEN — catch-all with string matching
catch (e) {
  if (e.toString().contains('stock')) { ... }
}
```

### Pattern 3: ViewModel Error States

```dart
// CORRECT — AsyncValue.guard() with typed errors
class CheckoutNotifier extends AsyncNotifier<CheckoutState> {
  Future<void> startCheckout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repository.createSession();
      return CheckoutState.ready(session: result);
    });
  }
}

// CORRECT — UI error handling
consumer.when(
  data: (state) => CheckoutWidget(state: state),
  loading: () => LoadingWidget(),
  error: (error, stack) {
    if (error is StockInsufficientError) {
      return StockErrorWidget(available: error.available);
    }
    return GenericErrorWidget(error: error);
  },
);

// FORBIDDEN — ignoring errors
consumer.when(
  data: (state) => CheckoutWidget(state: state),
  loading: () => LoadingWidget(),
  error: (_, __) => SizedBox(), // Silent failure!
);
```

## Audit Checklist

When auditing error handling:

- [ ] No `unwrap()` in Rust production code (tests OK)
- [ ] No `catch (e) {}` empty blocks in Dart
- [ ] No `print()` or `debugPrint()` — use `AppLogger`
- [ ] No string matching on error messages (use typed codes)
- [ ] All `Result` types properly propagated in Rust
- [ ] All `Future`/`Stream` errors handled in Dart
- [ ] No `fire-and-forget` async without error callback
- [ ] HTTP status codes match error type (400 vs 401 vs 409 vs 500)
- [ ] Error responses are structured: `{ "error": { "code": "...", "message": "..." } }`
- [ ] No PII in error messages (emails, addresses, tokens)
- [ ] No stack traces in production error responses

## Quick Commands

```bash
# Find unwrap() in Rust production code (exclude tests)
rg '\.unwrap\(\)' orignabase/crates/ --glob '!**/tests/**' --glob '!**/*_test*' | wc -l

# Find empty catch blocks in Dart
rg 'catch.*\{[\s]*\}' origna_gta/lib/ | wc -l

# Find print() statements in Dart
rg '\bprint\(' origna_gta/lib/ | wc -l

# Find string-based error matching in Dart
rg "e\.toString\(\)\.contains\(" origna_gta/lib/ | wc -l
```
