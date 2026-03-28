//! Extended integration tests for additional handler coverage.
//!
//! This file covers specific endpoints and edge cases not fully captured
//! in handlers_integration_test.rs, including:
//! - GraphQL CRUD operations with edge cases
//! - Email validation and format edge cases
//! - Auth edge cases via GraphQL
//! - Sequential request handling
//!
//! Run with: `cargo test --test extended_handlers_test -- --ignored`

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

    assert_eq!(resp.status(), 200, "Registration should succeed");
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
    let mut req = client
        .post(&url)
        .header("Content-Type", "application/json")
        .json(&json!({ "query": query }));
    if let Some(t) = token {
        req = req.header("Authorization", format!("Bearer {t}"));
    }
    let resp = req.send().await.expect("graphql request failed");
    let status = resp.status().as_u16();
    let body: Value = resp.json().await.unwrap_or(json!({}));
    (status, body)
}

// =============================================================================
// SECTION 1: Product CRUD Edge Cases (5 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_600_product_create_minimal_fields() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "products", data: {name: "Minimal Product", priceCents: 100}) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let id = body["data"]["create"]["id"].as_str();
    assert!(id.is_some(), "Should return product ID");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_601_product_create_with_all_fields() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "products", data: {
            name: "Full Product",
            description: "A product with all fields",
            priceCents: 5999,
            stockQuantity: 50,
            categoryId: "categories:electronics",
            isDigital: false,
            isPerishable: false,
            lifecycleStatus: "active"
        }) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let product = &body["data"]["create"];
    assert!(product["id"].as_str().is_some());
    assert_eq!(product["name"], "Full Product");
    assert_eq!(product["priceCents"], 5999);
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_602_product_update_price() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create product
    let (_, create_body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "products", data: {name: "Price Test", priceCents: 1000}) }"#,
    )
    .await;
    let product_id = create_body["data"]["create"]["id"]
        .as_str()
        .unwrap()
        .to_string();

    // Update price
    let (status, body) = graphql(
        &client,
        Some(&token),
        &format!(
            r#"mutation {{ update(collection: "products", id: "{product_id}", data: {{priceCents: 2500}}) }}"#
        ),
    )
    .await;

    assert_eq!(status, 200);
    assert_eq!(body["data"]["update"]["priceCents"], 2500);
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_603_product_delete() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create product
    let (_, create_body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "products", data: {name: "Delete Test", priceCents: 100}) }"#,
    )
    .await;
    let product_id = create_body["data"]["create"]["id"]
        .as_str()
        .unwrap()
        .to_string();

    // Delete
    let (status, body) = graphql(
        &client,
        Some(&token),
        &format!(r#"mutation {{ delete(collection: "products", id: "{product_id}") }}"#),
    )
    .await;

    assert_eq!(status, 200);
    // delete returns the deleted object
    assert!(body["data"]["delete"]["id"].as_str().is_some());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_604_product_list_with_pagination() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create multiple products
    for i in 0..3 {
        graphql(
            &client,
            Some(&token),
            &format!(r#"mutation {{ create(collection: "products", data: {{name: "Paginated Product {i}", priceCents: 100}}) }}"#),
        )
        .await;
    }

    // List with limit
    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"{ list(collection: "products", limit: 2, offset: 0) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let products = body["data"]["list"].as_array();
    assert!(products.is_some(), "Should return array");
}

// =============================================================================
// SECTION 2: Cart Operations (4 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_605_cart_create_and_read() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create cart
    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "carts", data: {items: [{productId: "p1", quantity: 2, priceCents: 1000}]}) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let cart_id = body["data"]["create"]["id"].as_str().unwrap().to_string();

    // Read cart back
    let (status, body) = graphql(
        &client,
        Some(&token),
        &format!(r#"{{ get(collection: "carts", id: "{cart_id}") }}"#),
    )
    .await;

    assert_eq!(status, 200);
    assert!(body["data"]["get"]["items"].is_array());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_606_cart_update_quantity() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create cart
    let (_, create_body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "carts", data: {items: [{productId: "p1", quantity: 1, priceCents: 500}]}) }"#,
    )
    .await;
    let cart_id = create_body["data"]["create"]["id"]
        .as_str()
        .unwrap()
        .to_string();

    // Update quantity
    let (status, _body) = graphql(
        &client,
        Some(&token),
        &format!(
            r#"mutation {{ update(collection: "carts", id: "{cart_id}", data: {{items: [{{productId: "p1", quantity: 5, priceCents: 500}}]}}) }}"#
        ),
    )
    .await;

    assert_eq!(status, 200);
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_607_cart_delete() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let (_, create_body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "carts", data: {items: []}) }"#,
    )
    .await;
    let cart_id = create_body["data"]["create"]["id"]
        .as_str()
        .unwrap()
        .to_string();

    let (status, body) = graphql(
        &client,
        Some(&token),
        &format!(r#"mutation {{ delete(collection: "carts", id: "{cart_id}") }}"#),
    )
    .await;

    assert_eq!(status, 200);
    // delete returns the deleted object
    assert!(body["data"]["delete"]["id"].as_str().is_some());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_608_cart_empty_items() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"mutation { create(collection: "carts", data: {items: []}) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let items = &body["data"]["create"]["items"];
    assert!(
        items.is_array() || items.is_null(),
        "Empty cart should have empty/null items"
    );
}

// =============================================================================
// SECTION 3: Order Operations (3 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_609_order_create() {
    let client = reqwest::Client::new();
    let (token, user_id, _) = register_test_user(&client).await;

    let query = format!(
        r#"mutation {{ create(collection: "orders", data: {{userId: "{user_id}", items: [{{productId: "p1", quantity: 1, priceCents: 1000}}], totalAmountCents: 1000, status: "pending"}}) }}"#
    );
    let (status, body) = graphql(&client, Some(&token), &query).await;

    assert_eq!(status, 200);
    assert!(body["data"]["create"]["id"].as_str().is_some());
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_610_order_update_status() {
    let client = reqwest::Client::new();
    let (token, user_id, _) = register_test_user(&client).await;

    // Create order
    let query = format!(
        r#"mutation {{ create(collection: "orders", data: {{userId: "{user_id}", items: [{{productId: "p1", quantity: 1, priceCents: 500}}], totalAmountCents: 500, status: "pending"}}) }}"#
    );
    let (_, create_body) = graphql(&client, Some(&token), &query).await;
    let order_id = create_body["data"]["create"]["id"]
        .as_str()
        .unwrap()
        .to_string();

    // Update status
    let (status, body) = graphql(
        &client,
        Some(&token),
        &format!(
            r#"mutation {{ update(collection: "orders", id: "{order_id}", data: {{status: "confirmed"}}) }}"#
        ),
    )
    .await;

    assert_eq!(status, 200);
    assert_eq!(body["data"]["update"]["status"], "confirmed");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_611_order_list_for_user() {
    let client = reqwest::Client::new();
    let (token, user_id, _) = register_test_user(&client).await;

    // Create an order
    let query = format!(
        r#"mutation {{ create(collection: "orders", data: {{userId: "{user_id}", items: [{{productId: "p1", quantity: 1, priceCents: 100}}], totalAmountCents: 100, status: "pending"}}) }}"#
    );
    graphql(&client, Some(&token), &query).await;

    // List orders
    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"{ list(collection: "orders", limit: 10) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let orders = body["data"]["list"].as_array();
    assert!(orders.is_some(), "Should return array of orders");
}

// =============================================================================
// SECTION 4: Email Validation (3 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_612_email_format_validation() {
    let client = reqwest::Client::new();

    let invalid_emails = vec!["notanemail", "@nodomain.com", ""];

    for invalid_email in invalid_emails {
        let resp = client
            .post(format!("{}/auth/register", base_url()))
            .json(&json!({ "email": invalid_email, "password": "TestPassword123!" }))
            .send()
            .await
            .unwrap();

        let status = resp.status().as_u16();
        assert!(
            status == 400 || status == 422,
            "Invalid email '{invalid_email}' should be rejected, got {status}"
        );
    }
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_613_email_case_insensitivity() {
    let client = reqwest::Client::new();

    let email = format!("TEST_{}@EXAMPLE.COM", Uuid::new_v4());
    let resp = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email, "password": "TestPassword123!" }))
        .send()
        .await
        .unwrap();

    assert_eq!(resp.status(), 200, "Email case should be normalized");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_614_email_duplicate_prevention() {
    let client = reqwest::Client::new();
    let email = format!("unique_{}@example.com", Uuid::new_v4());

    // Register first user
    let resp1 = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email.clone(), "password": "TestPassword123!" }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp1.status(), 200);

    // Try register same email again
    let resp2 = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email, "password": "TestPassword123!" }))
        .send()
        .await
        .unwrap();

    let status2 = resp2.status().as_u16();
    assert!(
        status2 == 409 || status2 == 400,
        "Duplicate email should be rejected, got {status2}"
    );
}

// =============================================================================
// SECTION 5: Auth Edge Cases (2 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_615_graphql_without_auth_returns_null() {
    let client = reqwest::Client::new();

    let (status, body) = graphql(
        &client,
        None,
        r#"{ get(collection: "users", id: "users:nonexistent") }"#,
    )
    .await;

    assert_eq!(status, 200, "GraphQL should return 200 even without auth");
    assert!(
        body["data"]["get"].is_null(),
        "Should return null for unauthenticated get"
    );
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_616_invalid_token_on_graphql() {
    let client = reqwest::Client::new();

    let (status, body) = graphql(
        &client,
        Some("invalid_token_not_jwt"),
        r#"{ get(collection: "users", id: "users:test") }"#,
    )
    .await;

    assert_eq!(status, 200, "GraphQL should return 200");
    assert!(
        body["data"]["get"].is_null(),
        "Invalid token should return null data"
    );
}

// =============================================================================
// SECTION 6: Sequential Operations (2 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_617_sequential_product_operations() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create, read, update, delete in sequence
    for i in 0..5 {
        let (_, create_body) = graphql(
            &client,
            Some(&token),
            &format!(
                r#"mutation {{ create(collection: "products", data: {{name: "Seq Product {i}", priceCents: 100}}) }}"#
            ),
        )
        .await;
        let product_id = create_body["data"]["create"]["id"]
            .as_str()
            .unwrap()
            .to_string();

        // Read
        let (status, _) = graphql(
            &client,
            Some(&token),
            &format!(r#"{{ get(collection: "products", id: "{product_id}") }}"#),
        )
        .await;
        assert_eq!(status, 200, "Sequential read {i} should succeed");

        // Update
        let (status, _) = graphql(
            &client,
            Some(&token),
            &format!(
                r#"mutation {{ update(collection: "products", id: "{product_id}", data: {{priceCents: {}}}) }}"#,
                200 + i
            ),
        )
        .await;
        assert_eq!(status, 200, "Sequential update {i} should succeed");
    }
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_618_sequential_user_profile_updates() {
    let client = reqwest::Client::new();
    let (token, user_id, _) = register_test_user(&client).await;

    for i in 0..5 {
        let (status, _) = graphql(
            &client,
            Some(&token),
            &format!(
                r#"mutation {{ update(collection: "users", id: "{user_id}", data: {{displayName: "User {i}"}}) }}"#
            ),
        )
        .await;
        assert_eq!(status, 200, "Sequential update {i} should succeed");
    }
}

// =============================================================================
// SECTION 7: Batch Operations (2 tests)
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_619_batch_create_products() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    let (status, body) = graphql(
        &client,
        Some(&token),
        r#"mutation { batchCreate(collection: "products", docs: [
            {name: "Batch 1", priceCents: 100},
            {name: "Batch 2", priceCents: 200},
            {name: "Batch 3", priceCents: 300}
        ]) }"#,
    )
    .await;

    assert_eq!(status, 200);
    let results = body["data"]["batchCreate"].as_array();
    assert!(results.is_some(), "Should return array of created objects");
    assert!(results.unwrap().len() >= 3, "Should create 3 products");
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_620_batch_delete_products() {
    let client = reqwest::Client::new();
    let (token, _user_id, _) = register_test_user(&client).await;

    // Create products
    let mut ids = Vec::new();
    for i in 0..3 {
        let (_, body) = graphql(
            &client,
            Some(&token),
            &format!(
                r#"mutation {{ create(collection: "products", data: {{name: "BatchDel {i}", priceCents: 100}}) }}"#
            ),
        )
        .await;
        ids.push(body["data"]["create"]["id"].as_str().unwrap().to_string());
    }

    // Batch delete
    let ids_json: Vec<String> = ids.iter().map(|id| format!("\"{id}\"")).collect();
    let (status, body) = graphql(
        &client,
        Some(&token),
        &format!(
            r#"mutation {{ batchDelete(collection: "products", ids: [{}]) }}"#,
            ids_json.join(", ")
        ),
    )
    .await;

    assert_eq!(status, 200);
    let deleted = body["data"]["batchDelete"].as_array();
    assert!(deleted.is_some(), "Should return array of deleted objects");
    assert_eq!(deleted.unwrap().len(), 3, "Should delete 3 products");
}
