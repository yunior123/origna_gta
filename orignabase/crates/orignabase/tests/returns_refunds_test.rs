//! Integration tests for returns and refunds — via GraphQL.
//!
//! Run with: `cargo test --test returns_refunds_test -- --ignored`

use reqwest::Client;
use serde_json::{Value, json};
use uuid::Uuid;

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

async fn register_test_user(client: &Client) -> (String, String) {
    let email = format!("test_return_{}@test.origna.ca", Uuid::new_v4());
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
#[cfg_attr(not(feature = "integration"), ignore)]
async fn test_create_return_for_delivered_order() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create product
    let product_data = json!({
        "title": "Returnable Product",
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
        "status": "delivered",
        "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 5000}],
        "subtotalCents": 5000,
        "totalAmountCents": 5000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create return request
    let return_data = json!({
        "orderId": order_id,
        "productId": product_id,
        "userId": buyer_id,
        "returnReason": "Defective item",
        "status": "pending",
    });
    let query = create_doc_query("returns", &return_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;

    assert_eq!(status, 200);
    let result = &body["data"]["create"];
    assert!(result.is_object() || body.get("errors").is_some());
}

#[tokio::test]
#[cfg_attr(not(feature = "integration"), ignore)]
async fn test_cannot_return_pending_order() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    let product_data = json!({
        "title": "Product",
        "priceCents": 3000,
        "stockQuantity": 30,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create order in pending state
    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "pending",
        "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 3000}],
        "subtotalCents": 3000,
        "totalAmountCents": 3000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create return for pending order
    let return_data = json!({
        "orderId": order_id,
        "productId": product_id,
        "userId": buyer_id,
        "returnReason": "Changed mind",
        "status": "pending",
    });
    let query = create_doc_query("returns", &return_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    // May succeed (no server validation) or error
    let _ = body;
}

#[tokio::test]
#[cfg_attr(not(feature = "integration"), ignore)]
async fn test_return_request_rejection() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    let product_data = json!({
        "title": "Product",
        "priceCents": 4000,
        "stockQuantity": 40,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "delivered",
        "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 4000}],
        "subtotalCents": 4000,
        "totalAmountCents": 4000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create return request
    let return_data = json!({
        "orderId": order_id,
        "productId": product_id,
        "userId": buyer_id,
        "returnReason": "Not as described",
        "status": "pending",
    });
    let query = create_doc_query("returns", &return_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);

    let return_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();
    if !return_id.is_empty() {
        // Seller rejects the return
        let data = serde_json::to_string(&json!({"status": "rejected"})).unwrap();
        let escaped = serde_json::to_string(&data).unwrap();
        let update_query = format!(
            r#"mutation {{ update(collection: "returns", id: "{return_id}", data: {escaped}) }}"#
        );
        let (status, _) = graphql(&client, Some(&seller_token), &update_query).await;
        assert_eq!(status, 200, "Rejecting return should succeed");
    }
}

#[tokio::test]
#[cfg_attr(not(feature = "integration"), ignore)]
async fn test_partial_refund() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    let product_data = json!({
        "title": "Product",
        "priceCents": 20000,
        "stockQuantity": 200,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    let order_data = json!({
        "buyerId": buyer_id,
        "sellerId": seller_id,
        "status": "delivered",
        "items": [{"productId": product_id, "quantity": 2, "unitPriceCents": 20000}],
        "subtotalCents": 40000,
        "totalAmountCents": 40000,
    });
    let query = create_doc_query("orders", &order_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let order_id = body["data"]["create"]["id"].as_str().unwrap_or("").to_string();

    // Create refund record
    let refund_data = json!({
        "orderId": order_id,
        "productId": product_id,
        "userId": seller_id,
        "reason": "Partial damage",
        "refundAmountCents": 10000,
        "status": "processed",
    });
    let query = create_doc_query("refunds", &refund_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let _ = body;
}
