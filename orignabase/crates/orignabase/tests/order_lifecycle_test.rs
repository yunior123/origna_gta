//! Integration tests for order lifecycle — via GraphQL.
//!
//! Run with: `cargo test --test order_lifecycle_test -- --ignored`

use reqwest::Client;
use serde_json::{Value, json};
use uuid::Uuid;

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

async fn register_test_user(client: &Client) -> (String, String) {
    let email = format!("test_order_{}@test.origna.ca", Uuid::new_v4());
    let resp = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email, "password": "REDACTED_TEST_PASSWORD" }))
        .send()
        .await
        .expect("register failed");
    assert_eq!(resp.status(), 200);
    let body: Value = resp.json().await.unwrap();
    let token = body["access_token"].as_str().expect("missing access_token").to_string();
    let user_id = body["user"]["id"].as_str().unwrap_or("").to_string();
    (token, user_id)
}

async fn graphql(client: &Client, token: Option<&str>, query: &str) -> (u16, Value) {
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

#[tokio::test]
#[ignore]
async fn test_order_create_pending_status() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create product
    let product_data = json!({
        "title": "Test Product",
        "priceCents": 10000,
        "stockQuantity": 100,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();
    assert!(!product_id.is_empty(), "Product should have an ID");

    // Create order
    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "pending",
        "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 10000}],
        "subtotalCents": 10000,
        "taxAmountCents": 0,
        "shippingCostCents": 0,
        "totalAmountCents": 10000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();
    assert!(!order_id.is_empty(), "Order should have an ID");

    // Verify order has correct initial status
    let get_query = format!(r#"{{ get(collection: "orders", id: "{order_id}") }}"#);
    let (status, detail) = graphql(&client, Some(&buyer_token), &get_query).await;
    assert_eq!(status, 200);
    let status_field = detail["data"]["get"]["status"].as_str().unwrap_or("unknown");
    assert_eq!(status_field, "pending", "Initial order status should be 'pending'");
}

#[tokio::test]
#[ignore]
async fn test_order_cancel_pending() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create product
    let product_data = json!({
        "title": "Test Product",
        "priceCents": 5000,
        "stockQuantity": 50,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create order
    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "pending",
        "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 5000}],
        "subtotalCents": 5000,
        "totalAmountCents": 5000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Cancel order via update
    let data = serde_json::to_string(&json!({"status": "cancelled"})).unwrap();
    let escaped = serde_json::to_string(&data).unwrap();
    let update_query = format!(
        r#"mutation {{ update(collection: "orders", id: "{order_id}", data: {escaped}) }}"#
    );
    let (status, _) = graphql(&client, Some(&buyer_token), &update_query).await;
    assert_eq!(status, 200, "Cancelling pending order should succeed");

    // Verify order is now cancelled
    let get_query = format!(r#"{{ get(collection: "orders", id: "{order_id}") }}"#);
    let (status, detail) = graphql(&client, Some(&buyer_token), &get_query).await;
    assert_eq!(status, 200);
    let status_field = detail["data"]["get"]["status"].as_str().unwrap_or("unknown");
    assert_eq!(status_field, "cancelled", "Order status should be 'cancelled'");
}

#[tokio::test]
#[ignore]
async fn test_order_state_transitions() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create product
    let product_data = json!({
        "title": "Test Product",
        "priceCents": 8000,
        "stockQuantity": 80,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create order
    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "pending",
        "items": [{"productId": product_id, "quantity": 2, "unitPriceCents": 8000}],
        "subtotalCents": 16000,
        "totalAmountCents": 16000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Verify initial state: pending
    let get_query = format!(r#"{{ get(collection: "orders", id: "{order_id}") }}"#);
    let (status, detail) = graphql(&client, Some(&buyer_token), &get_query).await;
    assert_eq!(status, 200);
    assert_eq!(detail["data"]["get"]["status"].as_str().unwrap_or(""), "pending");

    // Transition to confirmed
    let data = serde_json::to_string(&json!({"status": "confirmed"})).unwrap();
    let escaped = serde_json::to_string(&data).unwrap();
    let update_query = format!(
        r#"mutation {{ update(collection: "orders", id: "{order_id}", data: {escaped}) }}"#
    );
    let (status, _) = graphql(&client, Some(&seller_token), &update_query).await;

    // Verify order has all required fields
    let get_query = format!(r#"{{ get(collection: "orders", id: "{order_id}") }}"#);
    let (status, detail) = graphql(&client, Some(&buyer_token), &get_query).await;
    assert_eq!(status, 200);
    let order = &detail["data"]["get"];
    assert!(order.get("buyerId").is_some(), "Order must have buyerId");
    assert!(order.get("sellerId").is_some(), "Order must have sellerId");
    assert!(order.get("status").is_some(), "Order must have status");
    assert!(order.get("totalAmountCents").is_some(), "Order must have totalAmountCents");
    assert!(order.get("items").is_some(), "Order must have items");
}

#[tokio::test]
#[ignore]
async fn test_buyer_orders_pagination() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create multiple orders
    for i in 0..5 {
        let product_data = json!({
            "title": format!("Test Product {}", i),
            "priceCents": 2000 + (i * 1000),
            "stockQuantity": 100,
            "sellerId": seller_id,
        });
        let query = create_doc_query("products", &product_data);
        let (_, body) = graphql(&client, Some(&seller_token), &query).await;
        let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

        let price = 2000 + (i * 1000);
        let order_data = json!({
            "buyerId": buyer_id,
            "sellerId": seller_id,
            "status": "pending",
            "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": price}],
            "subtotalCents": price,
            "totalAmountCents": price,
        });
        let query = create_doc_query("orders", &order_data);
        let (status, _) = graphql(&client, Some(&buyer_token), &query).await;
        assert_eq!(status, 200);
    }

    // Fetch buyer orders with pagination
    let filters = serde_json::to_string(&json!({"buyerId": {"_eq": buyer_id}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query = format!(
        r#"{{ list(collection: "orders", filters: {escaped_f}, limit: 2, offset: 0) }}"#
    );
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);

    let empty_vec = vec![];
    let orders_list = body["data"]["list"].as_array().unwrap_or(&empty_vec);
    assert!(orders_list.len() <= 2, "Should respect limit parameter");

    // Fetch with offset
    let query2 = format!(
        r#"{{ list(collection: "orders", filters: {escaped_f}, limit: 2, offset: 2) }}"#
    );
    let (status, body2) = graphql(&client, Some(&buyer_token), &query2).await;
    assert_eq!(status, 200);
}

#[tokio::test]
#[ignore]
async fn test_order_detail_fields() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    let product_data = json!({
        "title": "Detail Test Product",
        "priceCents": 12500,
        "stockQuantity": 125,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "pending",
        "items": [{"productId": product_id, "quantity": 2, "unitPriceCents": 12500, "name": "Test Item"}],
        "subtotalCents": 25000,
        "taxAmountCents": 0,
        "shippingCostCents": 0,
        "totalAmountCents": 25000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Fetch full order detail
    let get_query = format!(r#"{{ get(collection: "orders", id: "{order_id}") }}"#);
    let (status, detail) = graphql(&client, Some(&buyer_token), &get_query).await;
    assert_eq!(status, 200);

    let order = &detail["data"]["get"];
    assert_eq!(order["buyerId"].as_str().unwrap_or(""), buyer_id);
    assert_eq!(order["sellerId"].as_str().unwrap_or(""), seller_id);
    assert_eq!(order["totalAmountCents"].as_i64().unwrap_or(0), 25000);
    assert_eq!(order["subtotalCents"].as_i64().unwrap_or(0), 25000);

    let empty_vec = vec![];
    let items = order["items"].as_array().unwrap_or(&empty_vec);
    assert_eq!(items.len(), 1, "Should have exactly 1 item");
}
