//! REST API endpoints for MCP server integration
//! Provides GET-based endpoints that wrap existing business logic handlers

use axum::{
    extract::{Extension, Path, Query, State},
    routing::get,
    Json, Router,
};
use serde::Deserialize;
use serde_json::json;
use ob_auth::middleware::AuthContext;
use crate::HandlersState;
use crate::shared::schema::collections;


pub fn router(state: HandlersState) -> Router {
    Router::new()
        // Products
        .route("/products", get(get_products).post(create_product))
        .route("/products/{id}", get(get_product))
        // Cart
        .route("/cart", get(get_cart))
        // Orders
        .route("/orders", get(list_orders))
        .route("/orders/{id}", get(get_order))
        // User profile
        .route("/user/profile", get(get_user_profile))
        .with_state(state)
}

// ───────────────────────────────────────────────────────────────────────────
// PRODUCTS
// ───────────────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct SearchProductsQuery {
    q: Option<String>,
    category: Option<String>,
    min_price: Option<i64>,
    max_price: Option<i64>,
    sort: Option<String>,
    #[serde(default = "default_limit")]
    limit: i64,
    #[serde(default)]
    offset: i64,
}

fn default_limit() -> i64 { 20 }

async fn get_products(
    State(state): State<HandlersState>,
    Query(qs): Query<SearchProductsQuery>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    // Query products from SurrealDB with filters
    let mut query = format!(
        "SELECT * FROM {} WHERE lifecycleStatus = 'active'",
        collections::PRODUCTS
    );

    if let Some(search) = &qs.q {
        let escaped = escape_surreal_string(search);
        query.push_str(&format!(
            " AND (name ~ '{}' OR description ~ '{}')",
            escaped, escaped
        ));
    }
    if let Some(cat) = &qs.category {
        query.push_str(&format!(" AND category = '{}'", escape_surreal_string(cat)));
    }
    if let Some(min) = qs.min_price {
        query.push_str(&format!(" AND priceCents >= {}", min));
    }
    if let Some(max) = qs.max_price {
        query.push_str(&format!(" AND priceCents <= {}", max));
    }

    match qs.sort.as_deref() {
        Some("price_asc") => query.push_str(" ORDER BY priceCents ASC"),
        Some("price_desc") => query.push_str(" ORDER BY priceCents DESC"),
        Some("newest") => query.push_str(" ORDER BY dateCreated DESC"),
        Some("oldest") => query.push_str(" ORDER BY dateCreated ASC"),
        _ => query.push_str(" ORDER BY dateCreated DESC"),
    }

    query.push_str(&format!(" LIMIT {} OFFSET {}", qs.limit, qs.offset));

    let results = state.db.query_raw(&query).await?;

    Ok(Json(serde_json::Value::Array(results)))
}

async fn get_product(
    State(state): State<HandlersState>,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    let doc = state
        .db
        .get_document(collections::PRODUCTS, &id)
        .await
        .map_err(|_| ob_core::Error::NotFound("Product not found".into()))?;

    Ok(Json(doc))
}

/// POST /products — Create a product with validation.
async fn create_product(
    State(state): State<HandlersState>,
    Extension(auth): Extension<AuthContext>,
    Json(body): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    // Require authentication
    let user_id = require_authenticated(&auth)?;

    let obj = body
        .as_object()
        .ok_or_else(|| ob_core::Error::Validation("Request body must be a JSON object".into()))?;

    // Validate priceCents: must be > 0 and <= 10,000,000
    if let Some(price) = obj.get("priceCents").and_then(|v| v.as_i64()) {
        if price <= 0 {
            return Err(ob_core::Error::Validation(
                "Product price must be greater than 0 cents".into(),
            ));
        }
        if price > 10_000_000 {
            return Err(ob_core::Error::Validation(
                "Product price cannot exceed $100,000 CAD".into(),
            ));
        }
    }

    // Validate stockQuantity: must be >= 0
    if let Some(stock) = obj.get("stockQuantity").and_then(|v| v.as_i64())
        && stock < 0
    {
        return Err(ob_core::Error::Validation(
            "Stock quantity cannot be negative".into(),
        ));
    }

    // Validate lifecycleStatus if present
    if let Some(status) = obj.get("lifecycleStatus").and_then(|v| v.as_str()) {
        let valid_states = ["draft", "active", "inactive", "archived"];
        if !valid_states.contains(&status) {
            return Err(ob_core::Error::Validation(format!(
                "Invalid lifecycle status: {status}"
            )));
        }
    }

    // Build product document
    let mut product = body.clone();
    let product_obj = product
        .as_object_mut()
        .expect("already validated as object");
    product_obj.insert("sellerId".into(), json!(user_id));
    product_obj.insert("createdAt".into(), json!(chrono::Utc::now().to_rfc3339()));
    product_obj.insert("updatedAt".into(), json!(chrono::Utc::now().to_rfc3339()));

    let created = state
        .db
        .create_document(collections::PRODUCTS, product)
        .await
        .map_err(|e| ob_core::Error::Database(format!("Failed to create product: {e}")))?;

    Ok(Json(json!({
        "success": true,
        "product": created
    })))
}

/// GET /user/profile — Get authenticated user's profile.
async fn get_user_profile(
    State(state): State<HandlersState>,
    Extension(auth): Extension<AuthContext>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    let user_id = require_authenticated(&auth)?;

    let doc = state
        .db
        .get_document(collections::USERS, &user_id)
        .await
        .map_err(|_| ob_core::Error::NotFound("User not found".into()))?;

    Ok(Json(doc))
}

// ───────────────────────────────────────────────────────────────────────────
// CART
// ───────────────────────────────────────────────────────────────────────────

async fn get_cart(
    State(state): State<HandlersState>,
    Extension(auth): Extension<AuthContext>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    let user_id = require_authenticated(&auth)?;

    // Get cart from user document
    let user = state
        .db
        .get_document(collections::USERS, &user_id)
        .await
        .map_err(|_| ob_core::Error::NotFound("User not found".into()))?;

    let cart = user
        .get("cart")
        .cloned()
        .unwrap_or_else(|| json!([]));

    Ok(Json(cart))
}
// ───────────────────────────────────────────────────────────────────────────
// ORDERS
// ───────────────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct ListOrdersQuery {
    status: Option<String>,
    #[serde(default = "default_limit")]
    limit: i64,
    #[serde(default)]
    offset: i64,
}

async fn list_orders(
    State(state): State<HandlersState>,
    Extension(auth): Extension<AuthContext>,
    Query(qs): Query<ListOrdersQuery>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    let user_id = require_authenticated(&auth)?;

    let mut query = format!(
        "SELECT * FROM {} WHERE buyerId = '{}'",
        collections::ORDERS,
        escape_surreal_string(&user_id)
    );

    if let Some(status) = &qs.status {
        query.push_str(&format!(" AND status = '{}'", escape_surreal_string(status)));
    }

    query.push_str(&format!(" ORDER BY createdAt DESC LIMIT {} OFFSET {}", qs.limit, qs.offset));

    let results = state.db.query_raw(&query).await?;

    Ok(Json(serde_json::Value::Array(results)))
}

async fn get_order(
    State(state): State<HandlersState>,
    Extension(auth): Extension<AuthContext>,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    let user_id = require_authenticated(&auth)?;

    let order = state
        .db
        .get_document(collections::ORDERS, &id)
        .await
        .map_err(|_| ob_core::Error::NotFound("Order not found".into()))?;

    // Verify user owns this order
    let buyer_id = order
        .get("buyerId")
        .and_then(|b| b.as_str())
        .unwrap_or("");

    if buyer_id != user_id {
        return Err(ob_core::Error::Forbidden("You do not own this order".into()));
    }

    Ok(Json(order))
}

// ───────────────────────────────────────────────────────────────────────────
// HELPERS
// ───────────────────────────────────────────────────────────────────────────

fn require_authenticated(auth: &AuthContext) -> Result<String, ob_core::Error> {
    if auth.authenticated { Ok(auth.user_id.clone()) } else { Err(ob_core::Error::Auth("Authentication required".into())) }
}

fn escape_surreal_string(s: &str) -> String {
    s.replace('\'', "''")
}

#[cfg(test)]
mod tests {
    use super::*;
    use ob_core::Config;
    use ob_database::DatabaseClient;
    use ob_auth::middleware::AuthContext;
    use std::sync::Arc;

    #[tokio::test]
    async fn test_rest_api_router_builds() {
        let state = HandlersState {
            config: Arc::new(Config::load(None).unwrap()),
            db: DatabaseClient::new_mem().await,
            http_client: reqwest::Client::new(),
            stripe_client: None,
            stripe_base_url: "https://api.stripe.com/v1".into(),
            turnstile_secret_key: None,
        };
        let _router = router(state);
    }

    #[test]
    fn test_search_products_query_deserialize_all_fields() {
        let qs: SearchProductsQuery = serde_json::from_value(serde_json::json!({
            "q": "widget",
            "category": "electronics",
            "min_price": 100,
            "max_price": 5000,
            "sort": "price_asc",
            "limit": 10,
            "offset": 20,
        }))
        .unwrap();
        assert_eq!(qs.q.as_deref(), Some("widget"));
        assert_eq!(qs.category.as_deref(), Some("electronics"));
        assert_eq!(qs.min_price, Some(100));
        assert_eq!(qs.max_price, Some(5000));
        assert_eq!(qs.sort.as_deref(), Some("price_asc"));
        assert_eq!(qs.limit, 10);
        assert_eq!(qs.offset, 20);
    }

    #[test]
    fn test_search_products_query_defaults() {
        let qs: SearchProductsQuery = serde_json::from_value(serde_json::json!({})).unwrap();
        assert!(qs.q.is_none());
        assert!(qs.category.is_none());
        assert!(qs.min_price.is_none());
        assert!(qs.max_price.is_none());
        assert!(qs.sort.is_none());
        assert_eq!(qs.limit, 20);
        assert_eq!(qs.offset, 0);
    }

    #[test]
    fn test_list_orders_query_deserialize() {
        let qs: ListOrdersQuery = serde_json::from_value(serde_json::json!({
            "status": "shipped",
            "limit": 5,
            "offset": 10,
        }))
        .unwrap();
        assert_eq!(qs.status.as_deref(), Some("shipped"));
        assert_eq!(qs.limit, 5);
        assert_eq!(qs.offset, 10);
    }

    #[test]
    fn test_list_orders_query_defaults() {
        let qs: ListOrdersQuery = serde_json::from_value(serde_json::json!({})).unwrap();
        assert!(qs.status.is_none());
        assert_eq!(qs.limit, 20);
        assert_eq!(qs.offset, 0);
    }

    #[test]
    fn test_default_limit() {
        assert_eq!(super::default_limit(), 20);
    }

    #[test]
    fn test_escape_surreal_string_no_special_chars() {
        assert_eq!(escape_surreal_string("hello"), "hello");
    }

    #[test]
    fn test_escape_surreal_string_single_quote() {
        assert_eq!(escape_surreal_string("it's"), "it''s");
    }

    #[test]
    fn test_escape_surreal_string_multiple_quotes() {
        assert_eq!(escape_surreal_string("a'b'c"), "a''b''c");
    }

    #[test]
    fn test_escape_surreal_string_empty() {
        assert_eq!(escape_surreal_string(""), "");
    }

    #[test]
    fn test_require_authenticated_valid() {
        let auth = AuthContext {
            user_id: "user_123".into(),
            roles: vec!["user".into()],
            authenticated: true,
            email_verified: false,
            custom_claims: serde_json::Value::Null,
        };
        let result = require_authenticated(&auth);
        assert_eq!(result.unwrap(), "user_123");
    }

    #[test]
    fn test_require_authenticated_not_auth() {
        let auth = AuthContext::anonymous();
        let result = require_authenticated(&auth);
        assert!(result.is_err());
    }
}
