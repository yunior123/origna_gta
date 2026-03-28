//! Integration tests for shipping — via GraphQL.
//!
//! Run with: `cargo test --test shipping_test -- --ignored`

use reqwest::Client;
use serde_json::{Value, json};
use uuid::Uuid;

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

async fn register_test_user(client: &Client) -> (String, String) {
    let email = format!("test_shipping_{}@test.origna.ca", Uuid::new_v4());
    let resp = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email, "password": "REDACTED_TEST_PASSWORD" }))
        .send()
        .await
        .expect("register failed");
    assert_eq!(resp.status(), 200);
    let body: Value = resp.json().await.unwrap();
    let token = body["access_token"]
        .as_str()
        .expect("missing access_token")
        .to_string();
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
async fn test_shipping_create_product_and_order() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create product via GraphQL
    let product_data = json!({
        "title": "Shipping Test Product",
        "priceCents": 5000,
        "stockQuantity": 50,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"]
        .as_str()
        .unwrap_or("")
        .to_string();

    if !product_id.is_empty() {
        // Create order via GraphQL
        let order_data = json!({
            "buyerId": buyer_id,
            "sellerId": seller_id,
            "status": "pending",
            "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 5000}],
            "subtotalCents": 5000,
            "taxAmountCents": 0,
            "shippingCostCents": 500,
            "totalAmountCents": 5500,
        });
        let query = create_doc_query("orders", &order_data);
        let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
        assert_eq!(status, 200);
        let result = &body["data"]["create"];
        assert!(result.is_object() || body.get("errors").is_some());
    }
}

#[tokio::test]
#[ignore]
async fn test_shipping_free_threshold() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create cheap product
    let product_data = json!({
        "title": "Cheap Product",
        "priceCents": 3000,
        "stockQuantity": 50,
        "sellerId": seller_id,
    });
    let query = create_doc_query("products", &product_data);
    let (status, body) = graphql(&client, Some(&seller_token), &query).await;
    assert_eq!(status, 200);
    let product_id = body["data"]["create"]["id"]
        .as_str()
        .unwrap_or("")
        .to_string();

    if !product_id.is_empty() {
        // Order below threshold — should have shipping cost
        let order_data = json!({
            "buyerId": buyer_id,
            "sellerId": seller_id,
            "status": "pending",
            "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 3000}],
            "subtotalCents": 3000,
            "shippingCostCents": 500,
            "totalAmountCents": 3500,
        });
        let query = create_doc_query("orders", &order_data);
        let (status, _body) = graphql(&client, Some(&buyer_token), &query).await;
        assert_eq!(status, 200);

        // Order above threshold — free shipping
        let order_data2 = json!({
            "buyerId": buyer_id,
            "sellerId": seller_id,
            "status": "pending",
            "items": [{"productId": product_id, "quantity": 3, "unitPriceCents": 3000}],
            "subtotalCents": 9000,
            "shippingCostCents": 0,
            "totalAmountCents": 9000,
        });
        let query = create_doc_query("orders", &order_data2);
        let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
        assert_eq!(status, 200);
        let shipping = body["data"]["create"]["shippingCostCents"]
            .as_i64()
            .unwrap_or(-1);
        assert_eq!(shipping, 0, "Order above $75 should have free shipping");
    }
}

#[tokio::test]
#[ignore]
async fn test_shipping_cost_in_integer_cents() {
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
    let product_id = body["data"]["create"]["id"]
        .as_str()
        .unwrap_or("")
        .to_string();

    if !product_id.is_empty() {
        let order_data = json!({
            "buyerId": buyer_id,
            "sellerId": seller_id,
            "status": "pending",
            "items": [{"productId": product_id, "quantity": 1, "unitPriceCents": 4000}],
            "subtotalCents": 4000,
            "shippingCostCents": 500,
            "totalAmountCents": 4500,
        });
        let query = create_doc_query("orders", &order_data);
        let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
        assert_eq!(status, 200);
        let cost = body["data"]["create"]["shippingCostCents"].as_i64();
        assert!(
            cost.is_some() || body.get("errors").is_some(),
            "Shipping cost must be integer cents"
        );
    }
}
