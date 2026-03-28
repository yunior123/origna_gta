//! Catalog tools — search, get product, check inventory

use crate::McpState;
use crate::errors::{McpError, McpResult};
use serde_json::{Value, json};

/// Search products by query, category, price range
pub async fn search_products(state: McpState, params: &Value) -> McpResult<Value> {
    let _query = params
        .get("query")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'query' parameter".to_string()))?;

    let category = params.get("category").and_then(|v| v.as_str());
    let min_price = params.get("min_price").and_then(|v| v.as_u64());
    let max_price = params.get("max_price").and_then(|v| v.as_u64());
    let raw_limit = params.get("limit").and_then(|v| v.as_u64()).unwrap_or(20);
    let limit = raw_limit.clamp(1, 100);
    let offset = params.get("offset").and_then(|v| v.as_u64()).unwrap_or(0);

    // If Meilisearch is available, use it; otherwise fall back to SurrealDB
    if let Some(_search) = &state.search {
        // Build Meilisearch filter query
        let mut filters = Vec::new();
        if let Some(cat) = category {
            let safe_cat = cat.replace('\'', "\\'");
            filters.push(format!("categoryId = '{}'", safe_cat));
        }
        if let Some(min) = min_price {
            filters.push(format!("priceCents >= {}", min));
        }
        if let Some(max) = max_price {
            filters.push(format!("priceCents <= {}", max));
        }
        filters.push("lifecycleStatus = 'active'".to_string());

        // Call Meilisearch
        let _filter_str = if filters.is_empty() {
            None
        } else {
            Some(filters.join(" AND "))
        };

        // NOTE: This calls search.search() method which would be implemented in ob-search
        // For now, stub the response
        return Ok(json!({
            "results": [],
            "total": 0,
            "limit": limit,
            "offset": offset
        }));
    }

    // Fallback: SurrealDB query
    // NOTE: In production, construct SurrealDB query via state.db
    Ok(json!({
        "results": [],
        "total": 0,
        "limit": limit,
        "offset": offset
    }))
}

/// Get product by ID
pub async fn get_product(_state: McpState, params: &Value) -> McpResult<Value> {
    let product_id = params
        .get("product_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'product_id'".to_string()))?;

    // Validate SurrealDB ID format
    if !product_id.contains(':') {
        return Err(McpError::ValidationError(
            "Invalid product ID format".to_string(),
        ));
    }

    // Fetch from SurrealDB
    // NOTE: state.db.get_document("products", product_id)
    // For now, stub
    Ok(json!({
        "id": product_id,
        "name": "Example Product",
        "description": "Product description",
        "priceCents": 10000,
        "stockQuantity": 5,
        "lifecycleStatus": "active"
    }))
}

/// Check inventory for a product
pub async fn check_inventory(_state: McpState, params: &Value) -> McpResult<Value> {
    let product_id = params
        .get("product_id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| McpError::InvalidParams("Missing 'product_id'".to_string()))?;

    if !product_id.contains(':') {
        return Err(McpError::ValidationError(
            "Invalid product ID format".to_string(),
        ));
    }

    // Fetch stock from SurrealDB
    // NOTE: state.db.get_document("products", product_id)
    // and extract stockQuantity field
    Ok(json!({
        "product_id": product_id,
        "stock_quantity": 5,
        "available": true
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

    // ── search_products ──

    #[tokio::test]
    async fn test_search_products_missing_query() {
        let state = make_state().await;
        let result = search_products(state, &json!({})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_search_products_valid_query() {
        let state = make_state().await;
        let result = search_products(state, &json!({"query": "shirt"}))
            .await
            .unwrap();
        assert_eq!(result["total"], 0);
        assert_eq!(result["limit"], 20);
        assert_eq!(result["offset"], 0);
    }

    #[tokio::test]
    async fn test_search_products_with_all_params() {
        let state = make_state().await;
        let params = json!({
            "query": "shirt",
            "category": "clothing",
            "min_price": 1000,
            "max_price": 5000,
            "limit": 10,
            "offset": 5
        });
        let result = search_products(state, &params).await.unwrap();
        assert_eq!(result["limit"], 10);
        assert_eq!(result["offset"], 5);
    }

    #[tokio::test]
    async fn test_search_products_limit_clamped_to_100() {
        let state = make_state().await;
        // limit > 100 is clamped to 100
        let result = search_products(state, &json!({"query": "x", "limit": 101})).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap()["limit"], 100);
    }

    #[tokio::test]
    async fn test_search_products_limit_boundary_100() {
        let state = make_state().await;
        let result = search_products(state, &json!({"query": "x", "limit": 100})).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap()["limit"], 100);
    }

    #[tokio::test]
    async fn test_search_products_default_limit_offset() {
        let state = make_state().await;
        let result = search_products(state, &json!({"query": "x"}))
            .await
            .unwrap();
        assert_eq!(result["limit"], 20);
        assert_eq!(result["offset"], 0);
    }

    #[tokio::test]
    async fn test_search_products_zero_limit_clamped_to_1() {
        let state = make_state().await;
        // limit=0 is clamped to 1
        let result = search_products(state, &json!({"query": "x", "limit": 0})).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap()["limit"], 1);
    }

    #[tokio::test]
    async fn test_search_products_non_string_query() {
        let state = make_state().await;
        let result = search_products(state, &json!({"query": 42})).await;
        assert!(result.is_err());
    }

    // ── get_product ──

    #[tokio::test]
    async fn test_get_product_missing_id() {
        let state = make_state().await;
        let result = get_product(state, &json!({})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_get_product_valid_id() {
        let state = make_state().await;
        let result = get_product(state, &json!({"product_id": "products:p1"}))
            .await
            .unwrap();
        assert_eq!(result["id"], "products:p1");
        assert!(result["priceCents"].is_number());
    }

    #[tokio::test]
    async fn test_get_product_invalid_format_no_colon() {
        let state = make_state().await;
        let result = get_product(state, &json!({"product_id": "p1"})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_get_product_empty_id() {
        let state = make_state().await;
        let result = get_product(state, &json!({"product_id": ""})).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_get_product_returns_expected_fields() {
        let state = make_state().await;
        let result = get_product(state, &json!({"product_id": "products:p1"}))
            .await
            .unwrap();
        assert!(result["name"].is_string());
        assert!(result["description"].is_string());
        assert!(result["stockQuantity"].is_number());
        assert_eq!(result["lifecycleStatus"], "active");
    }

    // ── check_inventory ──

    #[tokio::test]
    async fn test_check_inventory_missing_id() {
        let state = make_state().await;
        let result = check_inventory(state, &json!({})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::InvalidParams(_)));
    }

    #[tokio::test]
    async fn test_check_inventory_valid() {
        let state = make_state().await;
        let result = check_inventory(state, &json!({"product_id": "products:p1"}))
            .await
            .unwrap();
        assert_eq!(result["product_id"], "products:p1");
        assert!(result["stock_quantity"].is_number());
        assert_eq!(result["available"], true);
    }

    #[tokio::test]
    async fn test_check_inventory_invalid_format() {
        let state = make_state().await;
        let result = check_inventory(state, &json!({"product_id": "badformat"})).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_check_inventory_integer_id() {
        let state = make_state().await;
        let result = check_inventory(state, &json!({"product_id": 123})).await;
        assert!(result.is_err());
    }
}
