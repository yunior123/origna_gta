//! Admin tools — analytics, reviews

use crate::errors::{McpError, McpResult};
use crate::McpState;
use serde_json::{json, Value};

/// Get marketplace analytics (admin only)
pub async fn get_analytics(_state: McpState, params: &Value) -> McpResult<Value> {
    let period = params
        .get("period")
        .and_then(|v| v.as_str())
        .unwrap_or("month");

    match period {
        "day" | "week" | "month" => {}
        _ => {
            return Err(McpError::ValidationError(
                "Period must be 'day', 'week', or 'month'".to_string(),
            ))
        }
    }

    // Query aggregated analytics from orders/products/users
    // NOTE: state.db.query(complex SurrealDB analytics query)
    // - Total orders, total revenue, average order value
    // - Top sellers, top products
    // - Platform fees collected
    // - Return/refund rates

    Ok(json!({
        "period": period,
        "total_orders": 0,
        "total_revenue_cents": 0,
        "average_order_cents": 0,
        "total_platform_fee_cents": 0,
        "top_sellers": [],
        "top_products": []
    }))
}

/// Create product review (any authenticated user)
pub async fn create_review(
    _state: McpState,
    user_id: &str,
    params: &Value,
) -> McpResult<Value> {
    let product_id = params
        .get("product_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'product_id'".to_string()))?;

    let rating = params
        .get("rating")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| McpError::InvalidParams("Missing 'rating'".to_string()))?;

    if rating < 1 || rating > 5 {
        return Err(McpError::ValidationError("Rating must be 1-5".to_string()));
    }

    let review_text = params.get("review").and_then(|v| v.as_str());

    // Verify user has purchased this product
    // NOTE: state.db.query("SELECT * FROM orders WHERE buyerId = $userId AND items[].productId = $productId AND status = 'delivered'")

    // Create review document
    // NOTE: state.db.create_document("reviews", { productId, userId, rating, review: review_text, createdAt })

    Ok(json!({
        "review_id": uuid::Uuid::new_v4().to_string(),
        "product_id": product_id,
        "user_id": user_id,
        "rating": rating,
        "review": review_text,
        "created": true
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

    // ── get_analytics ──

    #[tokio::test]
    async fn test_get_analytics_default_period() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({})).await.unwrap();
        assert_eq!(result["period"], "month");
        assert_eq!(result["total_orders"], 0);
    }

    #[tokio::test]
    async fn test_get_analytics_day_period() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({"period": "day"})).await.unwrap();
        assert_eq!(result["period"], "day");
    }

    #[tokio::test]
    async fn test_get_analytics_week_period() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({"period": "week"})).await.unwrap();
        assert_eq!(result["period"], "week");
    }

    #[tokio::test]
    async fn test_get_analytics_month_period() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({"period": "month"})).await.unwrap();
        assert_eq!(result["period"], "month");
    }

    #[tokio::test]
    async fn test_get_analytics_invalid_period() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({"period": "year"})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_get_analytics_empty_string_period() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({"period": ""})).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_get_analytics_integer_period() {
        let state = make_state().await;
        // Integer period falls through to default "month" since as_str() returns None
        let result = get_analytics(state, &json!({"period": 123})).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap()["period"], "month");
    }

    #[tokio::test]
    async fn test_get_analytics_returns_stub_fields() {
        let state = make_state().await;
        let result = get_analytics(state, &json!({"period": "day"})).await.unwrap();
        assert!(result["top_sellers"].is_array());
        assert!(result["top_products"].is_array());
        assert_eq!(result["total_revenue_cents"], 0);
        assert_eq!(result["average_order_cents"], 0);
    }

    // ── create_review ──

    #[tokio::test]
    async fn test_create_review_success() {
        let state = make_state().await;
        let params = json!({
            "product_id": "products:p1",
            "rating": 5,
            "review": "Great!"
        });
        let result = create_review(state, "users:u1", &params).await.unwrap();
        assert_eq!(result["product_id"], "products:p1");
        assert_eq!(result["user_id"], "users:u1");
        assert_eq!(result["rating"], 5);
        assert_eq!(result["review"], "Great!");
        assert_eq!(result["created"], true);
        assert!(result["review_id"].is_string());
    }

    #[tokio::test]
    async fn test_create_review_missing_product_id() {
        let state = make_state().await;
        let params = json!({"rating": 5});
        let result = create_review(state, "users:u1", &params).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_create_review_missing_rating() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1"});
        let result = create_review(state, "users:u1", &params).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_create_review_rating_too_low() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1", "rating": 0});
        let result = create_review(state, "users:u1", &params).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_create_review_rating_too_high() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1", "rating": 6});
        let result = create_review(state, "users:u1", &params).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_create_review_rating_boundary_1() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1", "rating": 1});
        assert!(create_review(state, "users:u1", &params).await.is_ok());
    }

    #[tokio::test]
    async fn test_create_review_rating_boundary_5() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1", "rating": 5});
        assert!(create_review(state, "users:u1", &params).await.is_ok());
    }

    #[tokio::test]
    async fn test_create_review_without_review_text() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1", "rating": 3});
        let result = create_review(state, "users:u1", &params).await.unwrap();
        assert!(result["review"].is_null());
    }

    #[tokio::test]
    async fn test_create_review_unique_ids() {
        let state = make_state().await;
        let params = json!({"product_id": "products:p1", "rating": 4});
        let r1 = create_review(state.clone(), "users:u1", &params).await.unwrap();
        let r2 = create_review(state, "users:u1", &params).await.unwrap();
        assert_ne!(r1["review_id"], r2["review_id"]);
    }
}
