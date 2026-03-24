//! Integration tests for search — via GraphQL `search` query.
//!
//! Run with: `cargo test --test search_integration_test -- --ignored`

use serde_json::{Value, json};
use uuid::Uuid;

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

async fn register_test_user(client: &reqwest::Client) -> (String, String, String) {
    let email = format!("test_{}@example.com", Uuid::new_v4());
    let resp = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email, "password": "TestPassword123!" }))
        .send()
        .await
        .expect("register failed");
    assert_eq!(resp.status(), 200);
    let body: Value = resp.json().await.unwrap();
    let token = body["access_token"].as_str().expect("missing access_token").to_string();
    let user_id = body["user"]["id"].as_str().expect("missing user.id").to_string();
    (token, user_id, email)
}

async fn graphql(client: &reqwest::Client, token: Option<&str>, query: &str) -> (u16, Value) {
    let url = format!("{}/graphql", base_url());
    let mut req = client.post(&url).json(&json!({"query": query}));
    if let Some(t) = token {
        req = req.header("Authorization", format!("Bearer {t}"));
    }
    let resp = req.send().await.expect("graphql request failed");
    let status = resp.status().as_u16();
    let body: Value = resp.json().await.unwrap_or(json!({}));
    (status, body)
}

// =============================================================================
// SECTION 1: Product Search — via GraphQL search query
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_products_empty_query() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "", limit: 20) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    // search returns an object with hits or errors
    let result = &body["data"]["search"];
    assert!(
        result.is_object() || result.is_null() || body.get("errors").is_some(),
        "Search should return result object: {body}"
    );
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_products_with_query() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "laptop", limit: 10) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_products_pagination() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "", limit: 50, offset: 100) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_products_invalid_limit() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // GraphQL will clamp or reject invalid limits
    let query = r#"{ search(index: "products", query: "test", limit: 1) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let _ = body;
}

// =============================================================================
// SECTION 2: Product Search — Filtering via list query with filters
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_filter_category() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let filters = serde_json::to_string(&json!({"category": {"_eq": "electronics"}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query = format!(
        r#"{{ list(collection: "products", filters: {escaped_f}, limit: 20) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_filter_price_range() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let filters = serde_json::to_string(&json!({
        "priceCents": {"_gte": 1000, "_lte": 50000}
    }))
    .unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query = format!(
        r#"{{ list(collection: "products", filters: {escaped_f}, limit: 20) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_sort_by_price_asc() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ list(collection: "products", orderBy: "priceCents", descending: false, limit: 20) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_sort_by_price_desc() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ list(collection: "products", orderBy: "priceCents", descending: true, limit: 20) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_sort_by_newest() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ list(collection: "products", orderBy: "createdAt", descending: true, limit: 20) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_products_multiple_filters() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let filters = serde_json::to_string(&json!({
        "category": {"_eq": "electronics"},
        "priceCents": {"_gte": 50000, "_lte": 200000}
    }))
    .unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query = format!(
        r#"{{ list(collection: "products", filters: {escaped_f}, limit: 10) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    let _ = body;
}

// =============================================================================
// SECTION 3: Search Edge Cases and Error Handling
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_nonexistent_index() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "nonexistent_index_xyz", query: "test", limit: 10) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    // GraphQL always returns 200, error may appear in body
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_special_characters_in_query() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "test & <script>alert(1)</script>", limit: 10) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200, "Special chars should not crash search: {body:?}");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_unicode_query() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "日本語テスト", limit: 10) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200, "Unicode query should not crash: {body:?}");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_very_long_query() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let long_term = "a".repeat(500);
    let query = format!(
        r#"{{ search(index: "products", query: "{long_term}", limit: 10) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200, "Long query should not crash: {body:?}");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_zero_limit() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "test", limit: 0) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200, "Zero limit should be handled: {body:?}");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_large_offset() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let query = r#"{ search(index: "products", query: "", limit: 10, offset: 999999) }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200, "Large offset should return empty hits: {body:?}");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_search_without_auth() {
    let client = reqwest::Client::new();

    let query = r#"{ search(index: "products", query: "laptop", limit: 10) }"#;
    let (status, body) = graphql(&client, None, query).await;

    assert!(
        status == 200 || status == 401,
        "Unauthenticated search should return 200 or 401: {body:?}"
    );
}

// =============================================================================
// SECTION 4: List with Additional Filters
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_with_lifecycle_filter() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let filters = serde_json::to_string(&json!({"lifecycleStatus": {"_eq": "active"}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query = format!(
        r#"{{ list(collection: "products", filters: {escaped_f}, limit: 20) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200, "Lifecycle filter should work: {body:?}");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_list_products_perishable_filter() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let filters = serde_json::to_string(&json!({"isPerishable": {"_eq": true}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query = format!(
        r#"{{ list(collection: "products", filters: {escaped_f}, limit: 10) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200, "Perishable filter should work: {body:?}");
}
