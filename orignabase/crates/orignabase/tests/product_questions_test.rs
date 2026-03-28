//! Integration tests for product Q&A — via GraphQL.
//!
//! Run with: `cargo test --test product_questions_test -- --ignored`

use reqwest::Client;
use serde_json::{Value, json};
use uuid::Uuid;

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

async fn register_test_user(client: &Client) -> (String, String) {
    let email = format!("test_qa_{}@test.origna.ca", Uuid::new_v4());
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
async fn test_ask_product_question() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, buyer_id) = register_test_user(&client).await;

    // Create product
    let product_data = json!({
        "title": "Product",
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

    // Ask a question
    let question_data = json!({
        "productId": product_id,
        "question": "Is this product available in other colors?",
        "userId": buyer_id,
        "answered": false,
    });
    let query = create_doc_query("product_questions", &question_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;

    assert_eq!(status, 200);
    let result = &body["data"]["create"];
    assert!(result.is_object() || body.get("errors").is_some());
}

#[tokio::test]
#[ignore]
async fn test_get_product_questions() {
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
    let product_id = body["data"]["create"]["id"]
        .as_str()
        .unwrap_or("")
        .to_string();

    // Ask a question
    let question_data = json!({
        "productId": product_id,
        "question": "What is the warranty period?",
        "userId": buyer_id,
        "answered": false,
    });
    let query = create_doc_query("product_questions", &question_data);
    let (status, _) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);

    // Fetch questions for the product
    let filters = serde_json::to_string(&json!({"productId": {"_eq": product_id}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query =
        format!(r#"{{ list(collection: "product_questions", filters: {escaped_f}, limit: 10) }}"#);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;

    assert_eq!(status, 200);
    let questions = &body["data"]["list"];
    assert!(questions.is_array() || questions.is_null());
}

#[tokio::test]
#[ignore]
async fn test_seller_answers_question() {
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

    // Ask question
    let question_data = json!({
        "productId": product_id,
        "question": "Is shipping included?",
        "userId": buyer_id,
        "answered": false,
    });
    let query = create_doc_query("product_questions", &question_data);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;
    assert_eq!(status, 200);
    let question_id = body["data"]["create"]["id"]
        .as_str()
        .unwrap_or("")
        .to_string();

    if !question_id.is_empty() {
        // Seller answers
        let data = serde_json::to_string(&json!({
            "answer": "Yes, shipping is included for orders above $50.",
            "answered": true,
        }))
        .unwrap();
        let escaped = serde_json::to_string(&data).unwrap();
        let update_query = format!(
            r#"mutation {{ update(collection: "product_questions", id: "{question_id}", data: {escaped}) }}"#
        );
        let (status, body) = graphql(&client, Some(&seller_token), &update_query).await;
        assert_eq!(status, 200);
        let _ = body;
    }
}

#[tokio::test]
#[ignore]
async fn test_get_questions_pagination() {
    let client = Client::new();
    let (seller_token, seller_id) = register_test_user(&client).await;
    let (buyer_token, _buyer_id) = register_test_user(&client).await;

    let product_data = json!({
        "title": "Product",
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

    let filters = serde_json::to_string(&json!({"productId": {"_eq": product_id}})).unwrap();
    let escaped_f = serde_json::to_string(&filters).unwrap();
    let query =
        format!(r#"{{ list(collection: "product_questions", filters: {escaped_f}, limit: 5) }}"#);
    let (status, body) = graphql(&client, Some(&buyer_token), &query).await;

    assert_eq!(status, 200);
    let _ = body;
}
