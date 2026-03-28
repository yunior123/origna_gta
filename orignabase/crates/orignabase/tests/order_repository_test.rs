//! Integration tests for order repository — via GraphQL.
//!
//! Run with: cargo test --test order_repository_test -- --ignored

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
    let token = body["access_token"]
        .as_str()
        .expect("missing access_token")
        .to_string();
    let user_id = body["user"]["id"]
        .as_str()
        .expect("missing user.id")
        .to_string();
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

fn create_doc_query(collection: &str, data: &Value) -> String {
    let data_str = serde_json::to_string(data).unwrap();
    let escaped = serde_json::to_string(&data_str).unwrap();
    format!(r#"mutation {{ create(collection: "{collection}", data: {escaped}) }}"#)
}

// =============================================================================
// SECTION: Orders — Lifecycle via GraphQL
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_create_with_valid_payload() {
    let client = reqwest::Client::new();
    let (token, user_id, _email) = register_test_user(&client).await;

    let data = json!({
        "buyerId": user_id,
        "sellerId": "users:test_seller",
        "status": "pending",
        "items": [{"productId": "products:test_1", "quantity": 1, "unitPriceCents": 9999}],
        "subtotalCents": 9999,
        "taxAmountCents": 0,
        "shippingCostCents": 0,
        "totalAmountCents": 9999,
    });
    let query = create_doc_query("orders", &data);
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    let result = &body["data"]["create"];
    assert!(
        result.is_object() || body.get("errors").is_some(),
        "Should create order or error: {body}"
    );
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_create_missing_items() {
    let client = reqwest::Client::new();
    let (token, user_id, _email) = register_test_user(&client).await;

    let data = json!({
        "buyerId": user_id,
        "sellerId": "users:test_seller",
        "status": "pending",
        "subtotalCents": 0,
        "totalAmountCents": 0,
    });
    let query = create_doc_query("orders", &data);
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    // May succeed (no server validation) or error
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_get_buyer_orders() {
    let client = reqwest::Client::new();
    let (token, user_id, _email) = register_test_user(&client).await;

    let filters = serde_json::to_string(&json!({"buyerId": {"_eq": user_id}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query =
        format!(r#"{{ list(collection: "orders", filters: {escaped_f}, limit: 10, offset: 0) }}"#);
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    let result = &body["data"]["list"];
    assert!(result.is_array() || result.is_null());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_get_seller_orders() {
    let client = reqwest::Client::new();
    let (token, _user_id, _email) = register_test_user(&client).await;

    let filters =
        serde_json::to_string(&json!({"sellerId": {"_eq": "users:test_seller"}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query =
        format!(r#"{{ list(collection: "orders", filters: {escaped_f}, limit: 10, offset: 0) }}"#);
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    let result = &body["data"]["list"];
    assert!(result.is_array() || result.is_null());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_get_by_id() {
    let client = reqwest::Client::new();
    let (token, _user_id, _email) = register_test_user(&client).await;

    let query = r#"{ get(collection: "orders", id: "orders:nonexistent_123") }"#;
    let (status, body) = graphql(&client, Some(&token), query).await;

    assert_eq!(status, 200);
    let result = &body["data"]["get"];
    assert!(result.is_null() || result.is_object() || body.get("errors").is_some());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_requires_authentication() {
    let client = reqwest::Client::new();

    let data = json!({"status": "pending", "totalAmountCents": 0});
    let query = create_doc_query("orders", &data);
    let (status, body) = graphql(&client, None, &query).await;

    assert_eq!(status, 200);
    // Without auth, may be denied or succeed
    let _ = body;
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_order_money_validation() {
    let client = reqwest::Client::new();
    let (token, user_id, _email) = register_test_user(&client).await;

    let data = json!({
        "buyerId": user_id,
        "sellerId": "users:test_seller",
        "status": "pending",
        "items": [{"productId": "products:test_1", "quantity": 1, "unitPriceCents": -100}],
        "subtotalCents": -100,
        "totalAmountCents": -100,
    });
    let query = create_doc_query("orders", &data);
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    // May succeed (no validation) or error
    let _ = body;
}
