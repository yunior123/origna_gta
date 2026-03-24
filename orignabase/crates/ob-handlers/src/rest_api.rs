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
    // Build parameterized query to prevent SQL injection
    let mut query = format!(
        "SELECT * FROM {} WHERE lifecycleStatus = 'active'",
        collections::PRODUCTS
    );
    let mut bind_params = serde_json::Map::new();

    if qs.q.is_some() {
        query.push_str(" AND (name ~ $search OR description ~ $search)");
        bind_params.insert("search".into(), json!(qs.q));
    }
    if qs.category.is_some() {
        query.push_str(" AND categoryId = $category");
        bind_params.insert("category".into(), json!(qs.category));
    }
    if let Some(min) = qs.min_price {
        query.push_str(" AND priceCents >= $min_price");
        bind_params.insert("min_price".into(), json!(min));
    }
    if let Some(max) = qs.max_price {
        query.push_str(" AND priceCents <= $max_price");
        bind_params.insert("max_price".into(), json!(max));
    }

    match qs.sort.as_deref() {
        Some("price_asc") => query.push_str(" ORDER BY priceCents ASC"),
        Some("price_desc") => query.push_str(" ORDER BY priceCents DESC"),
        Some("newest") => query.push_str(" ORDER BY dateCreated DESC"),
        Some("oldest") => query.push_str(" ORDER BY dateCreated ASC"),
        _ => query.push_str(" ORDER BY dateCreated DESC"),
    }

    // Clamp limit to prevent abuse
    let limit = qs.limit.clamp(1, 100);
    let offset = qs.offset.max(0);
    query.push_str(" LIMIT $limit OFFSET $offset");
    bind_params.insert("limit".into(), json!(limit));
    bind_params.insert("offset".into(), json!(offset));

    let results = state.db.query_bind_value(
        &query,
        serde_json::Value::Object(bind_params),
    ).await?;

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
/// Requires authentication and seller role.
async fn create_product(
    State(state): State<HandlersState>,
    Extension(auth): Extension<AuthContext>,
    Json(body): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, ob_core::Error> {
    // Require authentication
    let user_id = require_authenticated(&auth)?;

    // Require seller role
    if !auth.roles.iter().any(|r| r == "seller" || r == "admin") {
        return Err(ob_core::Error::Forbidden(
            "Only sellers can create products".into(),
        ));
    }

    let obj = body
        .as_object()
        .ok_or_else(|| ob_core::Error::Validation("Request body must be a JSON object".into()))?;

    // Require name
    match obj.get("name").and_then(|v| v.as_str()) {
        Some(name) if name.trim().is_empty() => {
            return Err(ob_core::Error::Validation("Product name cannot be empty".into()));
        }
        None => {
            return Err(ob_core::Error::Validation("Product name is required".into()));
        }
        _ => {}
    }

    // Require priceCents: must be > 0 and <= 10,000,000
    match obj.get("priceCents").and_then(|v| v.as_i64()) {
        Some(price) if price <= 0 => {
            return Err(ob_core::Error::Validation(
                "Product price must be greater than 0 cents".into(),
            ));
        }
        Some(price) if price > 10_000_000 => {
            return Err(ob_core::Error::Validation(
                "Product price cannot exceed $100,000 CAD".into(),
            ));
        }
        None => {
            return Err(ob_core::Error::Validation(
                "Product priceCents is required".into(),
            ));
        }
        _ => {}
    }

    // Validate stockQuantity: must be >= 0
    if let Some(stock) = obj.get("stockQuantity").and_then(|v| v.as_i64())
        && stock < 0
    {
        return Err(ob_core::Error::Validation(
            "Stock quantity cannot be negative".into(),
        ));
    }

    // Validate lifecycleStatus if present (draft -> active -> inactive -> deleted)
    if let Some(status) = obj.get("lifecycleStatus").and_then(|v| v.as_str()) {
        let valid_states = ["draft", "active", "inactive", "deleted"];
        if !valid_states.contains(&status) {
            return Err(ob_core::Error::Validation(format!(
                "Invalid lifecycle status: {status}. Valid values: draft, active, inactive, deleted"
            )));
        }
    }

    // Build product document
    let mut product = body.clone();
    let product_obj = product
        .as_object_mut()
        .expect("already validated as object");
    product_obj.insert("sellerId".into(), json!(user_id));
    // Products use dateCreated (not createdAt) per schema
    product_obj.insert("dateCreated".into(), json!(chrono::Utc::now().to_rfc3339()));
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
/// Strips sensitive fields before returning.
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

    // Strip sensitive fields
    let mut profile = doc;
    if let Some(obj) = profile.as_object_mut() {
        obj.remove("passwordHash");
        obj.remove("password_hash");
        obj.remove("mfaSecret");
        obj.remove("mfa_secret");
        obj.remove("backupCodes");
        obj.remove("backup_codes");
        obj.remove("refreshTokens");
        obj.remove("refresh_tokens");
        obj.remove("totpSecret");
        obj.remove("totp_secret");
    }

    Ok(Json(profile))
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

    // Use parameterized query to prevent injection
    let mut query = format!(
        "SELECT * FROM {} WHERE buyerId = $user_id",
        collections::ORDERS,
    );
    let mut bind_params = serde_json::Map::new();
    bind_params.insert("user_id".into(), json!(user_id));

    if qs.status.is_some() {
        query.push_str(" AND status = $status");
        bind_params.insert("status".into(), json!(qs.status));
    }

    let limit = qs.limit.clamp(1, 100);
    let offset = qs.offset.max(0);
    query.push_str(" ORDER BY createdAt DESC LIMIT $limit OFFSET $offset");
    bind_params.insert("limit".into(), json!(limit));
    bind_params.insert("offset".into(), json!(offset));

    let results = state.db.query_bind_value(
        &query,
        serde_json::Value::Object(bind_params),
    ).await?;

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

    // Verify user owns this order (buyer or seller)
    let buyer_id = order
        .get("buyerId")
        .and_then(|b| b.as_str())
        .unwrap_or("");
    let seller_id = order
        .get("sellerId")
        .and_then(|s| s.as_str())
        .unwrap_or("");

    if buyer_id != user_id && seller_id != user_id {
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

#[cfg(test)]
mod tests {
    use super::*;
    use ob_core::Config;
    use ob_database::DatabaseClient;
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
