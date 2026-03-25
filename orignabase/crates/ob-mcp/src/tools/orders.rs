//! Order tools — list, get, return requests, checkout

use crate::errors::{McpError, McpResult};
use crate::safeguards::SpendLimit;
use crate::McpState;
use serde_json::{json, Value};

/// List orders for user
pub async fn list_orders(
    _state: McpState,
    user_id: &str,
    params: &Value,
) -> McpResult<Value> {
    let _status = params.get("status").and_then(|v| v.as_str());
    let limit = params.get("limit").and_then(|v| v.as_u64()).unwrap_or(20);
    let offset = params.get("offset").and_then(|v| v.as_u64()).unwrap_or(0);

    if limit > 100 {
        return Err(McpError::ValidationError("Limit must be <= 100".to_string()));
    }

    // Query orders where buyerId = user_id
    // Filter by status if provided
    // Sort by createdAt DESC (newest first)
    // NOTE: state.db.query("SELECT * FROM orders WHERE buyerId = $userId AND status = $status ORDER BY createdAt DESC LIMIT $limit OFFSET $offset")

    Ok(json!({
        "user_id": user_id,
        "orders": [],
        "total": 0,
        "limit": limit,
        "offset": offset
    }))
}

/// Get order details
pub async fn get_order(
    _state: McpState,
    user_id: &str,
    params: &Value,
) -> McpResult<Value> {
    let order_id = params
        .get("order_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'order_id'".to_string()))?;

    if !order_id.contains(':') {
        return Err(McpError::ValidationError("Invalid order ID format".to_string()));
    }

    // Fetch order
    // NOTE: state.db.get_document("orders", order_id)
    // For now, simulate order fetch - in production this comes from DB
    let order_buyer_id = user_id; // Stub: assume order belongs to requesting user

    // Verify buyerId matches user_id (ownership check)
    if order_buyer_id != user_id {
        return Err(McpError::Forbidden("Access denied".to_string()));
    }

    Ok(json!({
        "id": order_id,
        "buyer_id": user_id,
        "status": "pending",
        "items": [],
        "total_cents": 0,
        "created_at": 0
    }))
}

/// Request a return for an order
pub async fn request_return(
    _state: McpState,
    user_id: &str,
    params: &Value,
) -> McpResult<Value> {
    let order_id = params
        .get("order_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'order_id'".to_string()))?;

    let reason = params
        .get("reason")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'reason'".to_string()))?;

    if !order_id.contains(':') {
        return Err(McpError::ValidationError("Invalid order ID format".to_string()));
    }

    // Fetch order and verify ownership
    // Check if order is in 'delivered' status
    // Check if within 30-day return window
    // Create return request with status 'pending'
    // NOTE: state.db.create_document("return_requests", { orderId, buyerId, reason, status: "pending" })

    Ok(json!({
        "return_id": format!("return_{}", uuid::Uuid::new_v4()),
        "order_id": order_id,
        "buyer_id": user_id,
        "reason": reason,
        "status": "pending"
    }))
}

/// Create checkout session
pub async fn create_checkout(
    _state: McpState,
    user_id: &str,
    params: &Value,
    spend_limit: Option<&SpendLimit>,
) -> McpResult<Value> {
    let items = params
        .get("items")
        .and_then(|v| v.as_array())
        .ok_or_else(|| McpError::InvalidParams("Missing 'items' array".to_string()))?;

    if items.is_empty() {
        return Err(McpError::ValidationError("Items array cannot be empty".to_string()));
    }

    let _shipping_address = params
        .get("shipping_address")
        .ok_or_else(|| McpError::InvalidParams("Missing 'shipping_address'".to_string()))?;

    let _idempotency_key = params.get("idempotency_key").and_then(|v| v.as_str());

    // Validate each item and calculate total for spend limit check
    let mut total_cents: u64 = 0;
    for item in items {
        let _product_id = item
            .get("product_id")
            .and_then(|v| v.as_str())
            .ok_or_else(|| McpError::InvalidParams("Item missing 'product_id'".to_string()))?;

        let quantity = item
            .get("quantity")
            .and_then(|v| v.as_u64())
            .ok_or_else(|| McpError::InvalidParams("Item missing 'quantity'".to_string()))?;

        // In production, fetch product price from DB; here use price_cents from item if provided
        let price_cents = item
            .get("price_cents")
            .and_then(|v| v.as_u64())
            .unwrap_or(0);
        total_cents = total_cents.saturating_add(price_cents.saturating_mul(quantity));
    }

    // Check spend limit before proceeding with checkout
    if let Some(safeguards) = spend_limit {
        safeguards.check(user_id, total_cents).await?;
    }

    // Check idempotency if key provided
    // NOTE: idempotency_tracker.check(idempotency_key) for duplicate checkout

    // Calculate totals (subtotal, tax, shipping, platform fee)
    // Create order documents (one per seller)
    // Call Stripe to create checkout session
    // NOTE: ob-handlers::payments::create_checkout_session()
    // Return session_url

    // Record the spend after successful checkout initiation
    if let Some(safeguards) = spend_limit {
        safeguards.record(user_id.to_string(), total_cents).await;
    }

    Ok(json!({
        "checkout_id": uuid::Uuid::new_v4().to_string(),
        "user_id": user_id,
        "session_url": "https://checkout.stripe.com/...",
        "expires_at": chrono::Utc::now().timestamp() + 1800
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::McpState;
    use std::sync::Arc;

    async fn make_state() -> McpState {
        McpState {
            db: Arc::new(ob_database::DatabaseClient::new_mem().await),
            search: None,
            config: Arc::new(ob_core::Config::load(None).unwrap()),
            jwt_keys: Arc::new(ob_auth::JwtKeys::from_secret("test-secret")),
        }
    }

    // ── list_orders ──

    #[tokio::test]
    async fn test_list_orders_default() {
        let state = make_state().await;
        let result = list_orders(state, "users:u1", &json!({})).await.unwrap();
        assert_eq!(result["user_id"], "users:u1");
        assert_eq!(result["total"], 0);
        assert_eq!(result["limit"], 20);
        assert_eq!(result["offset"], 0);
    }

    #[tokio::test]
    async fn test_list_orders_with_status() {
        let state = make_state().await;
        let result = list_orders(state, "users:u1", &json!({"status": "delivered"})).await.unwrap();
        assert_eq!(result["user_id"], "users:u1");
    }

    #[tokio::test]
    async fn test_list_orders_with_pagination() {
        let state = make_state().await;
        let result = list_orders(state, "users:u1", &json!({"limit": 5, "offset": 10})).await.unwrap();
        assert_eq!(result["limit"], 5);
        assert_eq!(result["offset"], 10);
    }

    #[tokio::test]
    async fn test_list_orders_limit_exceeds_max() {
        let state = make_state().await;
        let result = list_orders(state, "users:u1", &json!({"limit": 101})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_list_orders_limit_boundary_100() {
        let state = make_state().await;
        let result = list_orders(state, "users:u1", &json!({"limit": 100})).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap()["limit"], 100);
    }

    // ── get_order ──

    #[tokio::test]
    async fn test_get_order_missing_id() {
        let state = make_state().await;
        let result = get_order(state, "users:u1", &json!({})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_get_order_valid() {
        let state = make_state().await;
        let result = get_order(state, "users:u1", &json!({"order_id": "orders:o1"})).await.unwrap();
        assert_eq!(result["id"], "orders:o1");
        assert_eq!(result["buyer_id"], "users:u1");
    }

    #[tokio::test]
    async fn test_get_order_invalid_format() {
        let state = make_state().await;
        let result = get_order(state, "users:u1", &json!({"order_id": "badformat"})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_get_order_empty_id() {
        let state = make_state().await;
        let result = get_order(state, "users:u1", &json!({"order_id": ""})).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_get_order_integer_id() {
        let state = make_state().await;
        let result = get_order(state, "users:u1", &json!({"order_id": 123})).await;
        assert!(result.is_err());
    }

    // ── request_return ──

    #[tokio::test]
    async fn test_request_return_missing_order_id() {
        let state = make_state().await;
        let result = request_return(state, "users:u1", &json!({"reason": "defective"})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_request_return_missing_reason() {
        let state = make_state().await;
        let result = request_return(state, "users:u1", &json!({"order_id": "orders:o1"})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_request_return_valid() {
        let state = make_state().await;
        let params = json!({"order_id": "orders:o1", "reason": "defective"});
        let result = request_return(state, "users:u1", &params).await.unwrap();
        assert_eq!(result["order_id"], "orders:o1");
        assert_eq!(result["buyer_id"], "users:u1");
        assert_eq!(result["reason"], "defective");
        assert_eq!(result["status"], "pending");
        assert!(result["return_id"].as_str().unwrap().starts_with("return_"));
    }

    #[tokio::test]
    async fn test_request_return_invalid_order_id_format() {
        let state = make_state().await;
        let params = json!({"order_id": "invalid", "reason": "defective"});
        let result = request_return(state, "users:u1", &params).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_request_return_unique_return_ids() {
        let state = make_state().await;
        let params = json!({"order_id": "orders:o1", "reason": "defective"});
        let r1 = request_return(state.clone(), "users:u1", &params).await.unwrap();
        let r2 = request_return(state, "users:u1", &params).await.unwrap();
        assert_ne!(r1["return_id"], r2["return_id"]);
    }

    // ── create_checkout ──

    #[tokio::test]
    async fn test_create_checkout_missing_items() {
        let state = make_state().await;
        let result = create_checkout(
            state,
            "users:u1",
            &json!({"shipping_address": {"line1": "123 Main"}}),
            None,
        ).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_create_checkout_missing_shipping_address() {
        let state = make_state().await;
        let result = create_checkout(
            state,
            "users:u1",
            &json!({"items": [{"product_id": "p1", "quantity": 1}]}),
            None,
        ).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_create_checkout_empty_items() {
        let state = make_state().await;
        let result = create_checkout(
            state,
            "users:u1",
            &json!({"items": [], "shipping_address": {}}),
            None,
        ).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_create_checkout_item_missing_product_id() {
        let state = make_state().await;
        let params = json!({
            "items": [{"quantity": 1}],
            "shipping_address": {"line1": "123 Main"}
        });
        let result = create_checkout(state, "users:u1", &params, None).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_create_checkout_item_missing_quantity() {
        let state = make_state().await;
        let params = json!({
            "items": [{"product_id": "products:p1"}],
            "shipping_address": {"line1": "123 Main"}
        });
        let result = create_checkout(state, "users:u1", &params, None).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_create_checkout_valid() {
        let state = make_state().await;
        let params = json!({
            "items": [{"product_id": "products:p1", "quantity": 2}],
            "shipping_address": {"line1": "123 Main St"}
        });
        let result = create_checkout(state, "users:u1", &params, None).await.unwrap();
        assert!(result["checkout_id"].is_string());
        assert_eq!(result["user_id"], "users:u1");
        assert!(result["session_url"].as_str().unwrap().starts_with("https://"));
        assert!(result["expires_at"].is_number());
    }

    #[tokio::test]
    async fn test_create_checkout_with_idempotency_key() {
        let state = make_state().await;
        let params = json!({
            "items": [{"product_id": "products:p1", "quantity": 1}],
            "shipping_address": {"line1": "123 Main"},
            "idempotency_key": "abc-123"
        });
        let result = create_checkout(state, "users:u1", &params, None).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_create_checkout_multiple_items() {
        let state = make_state().await;
        let params = json!({
            "items": [
                {"product_id": "products:p1", "quantity": 1},
                {"product_id": "products:p2", "quantity": 3}
            ],
            "shipping_address": {"line1": "123 Main"}
        });
        let result = create_checkout(state, "users:u1", &params, None).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_create_checkout_unique_checkout_ids() {
        let state = make_state().await;
        let params = json!({
            "items": [{"product_id": "products:p1", "quantity": 1}],
            "shipping_address": {"line1": "123 Main"}
        });
        let r1 = create_checkout(state.clone(), "users:u1", &params, None).await.unwrap();
        let r2 = create_checkout(state, "users:u1", &params, None).await.unwrap();
        assert_ne!(r1["checkout_id"], r2["checkout_id"]);
    }

    #[tokio::test]
    async fn test_create_checkout_expires_in_future() {
        let state = make_state().await;
        let params = json!({
            "items": [{"product_id": "products:p1", "quantity": 1}],
            "shipping_address": {"line1": "123 Main"}
        });
        let result = create_checkout(state, "users:u1", &params, None).await.unwrap();
        let expires = result["expires_at"].as_i64().unwrap();
        assert!(expires > chrono::Utc::now().timestamp());
    }

    #[tokio::test]
    async fn test_create_checkout_spend_limit_exceeded() {
        let state = make_state().await;
        let spend_limit = SpendLimit::new(5000, 100_000); // $50 max per request
        let params = json!({
            "items": [{"product_id": "products:p1", "quantity": 1, "price_cents": 10000}],
            "shipping_address": {"line1": "123 Main"}
        });
        let result = create_checkout(state, "users:u1", &params, Some(&spend_limit)).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_create_checkout_spend_limit_ok() {
        let state = make_state().await;
        let spend_limit = SpendLimit::new(100_000, 1_000_000); // $1000 max
        let params = json!({
            "items": [{"product_id": "products:p1", "quantity": 1, "price_cents": 5000}],
            "shipping_address": {"line1": "123 Main"}
        });
        let result = create_checkout(state, "users:u1", &params, Some(&spend_limit)).await;
        assert!(result.is_ok());
    }
}
