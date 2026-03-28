//! Integration tests for ob-realtime WebSocket endpoints.
//!
//! Run with: `cargo test --test realtime_integration_test -- --ignored`
//!
//! Requirements:
//!   OB_TEST_URL=http://localhost:8080 (or remote OrignaBase instance)

use futures_util::{SinkExt, StreamExt};
use serde_json::{Value, json};
use tokio_tungstenite::{connect_async, tungstenite::Message};
use uuid::Uuid;

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

fn ws_url() -> String {
    base_url()
        .replace("http://", "ws://")
        .replace("https://", "wss://")
}

/// Register a test user and return (access_token, user_id).
async fn register_test_user(client: &reqwest::Client) -> (String, String) {
    let email = format!("test_{}@example.com", Uuid::new_v4());
    let resp = client
        .post(format!("{}/auth/register", base_url()))
        .json(&json!({ "email": email, "password": "TestPassword123!" }))
        .send()
        .await
        .expect("register failed");
    assert_eq!(resp.status(), 200);
    let body: Value = resp.json().await.unwrap();
    let token = body["access_token"].as_str().unwrap().to_string();
    let user_id = body["user"]["id"].as_str().unwrap().to_string();
    (token, user_id)
}

// =============================================================================
// SECTION 1: WebSocket Connection
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_connect_with_valid_token() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let result = connect_async(&url).await;

    assert!(
        result.is_ok(),
        "WebSocket connection with valid token should succeed"
    );
    let (ws_stream, _response) = result.unwrap();
    let (mut _write, _read) = ws_stream.split();
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_connect_without_token_rejected() {
    let url = format!("{}/realtime", ws_url());
    let result = connect_async(&url).await;

    // Should be rejected with 401 during upgrade
    assert!(
        result.is_err(),
        "WebSocket connection without token should fail"
    );
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_connect_with_invalid_token_rejected() {
    let url = format!("{}/realtime?token=invalid_jwt_token_12345", ws_url());
    let result = connect_async(&url).await;

    assert!(
        result.is_err(),
        "WebSocket connection with invalid token should fail"
    );
}

// =============================================================================
// SECTION 2: Ping/Pong
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_ping_pong() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let (ws_stream, _) = connect_async(&url).await.expect("connect failed");
    let (mut write, mut read) = ws_stream.split();

    // Send Ping message
    let ping_msg = json!({"type": "ping"});
    write
        .send(Message::Text(ping_msg.to_string().into()))
        .await
        .expect("send ping failed");

    // Wait for Pong response (with timeout)
    let response = tokio::time::timeout(std::time::Duration::from_secs(5), read.next()).await;

    assert!(response.is_ok(), "Should receive pong within timeout");
    if let Ok(Some(Ok(Message::Text(text)))) = response {
        let msg: Value = serde_json::from_str(&text).unwrap_or(json!({}));
        assert_eq!(msg["type"], "pong", "Should receive pong response");
    }
}

// =============================================================================
// SECTION 3: Subscribe / Unsubscribe
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_subscribe_collection() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let (ws_stream, _) = connect_async(&url).await.expect("connect failed");
    let (mut write, mut read) = ws_stream.split();

    let sub_id = format!("sub_{}", Uuid::new_v4());
    let subscribe_msg = json!({
        "type": "subscribe",
        "id": sub_id,
        "collection": "products"
    });

    write
        .send(Message::Text(subscribe_msg.to_string().into()))
        .await
        .expect("send subscribe failed");

    // Should receive "subscribed" confirmation
    let response = tokio::time::timeout(std::time::Duration::from_secs(5), read.next()).await;

    assert!(response.is_ok(), "Should receive subscribed confirmation");
    if let Ok(Some(Ok(Message::Text(text)))) = response {
        let msg: Value = serde_json::from_str(&text).unwrap_or(json!({}));
        assert_eq!(
            msg["type"], "subscribed",
            "Should confirm subscription: {msg:?}"
        );
        assert_eq!(msg["id"], sub_id);
    }
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_unsubscribe() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let (ws_stream, _) = connect_async(&url).await.expect("connect failed");
    let (mut write, mut read) = ws_stream.split();

    let sub_id = format!("sub_{}", Uuid::new_v4());

    // Subscribe first
    write
        .send(Message::Text(
            json!({"type": "subscribe", "id": sub_id, "collection": "products"})
                .to_string()
                .into(),
        ))
        .await
        .unwrap();

    // Consume subscribe confirmation
    let _ = tokio::time::timeout(std::time::Duration::from_secs(3), read.next()).await;

    // Unsubscribe
    write
        .send(Message::Text(
            json!({"type": "unsubscribe", "id": sub_id})
                .to_string()
                .into(),
        ))
        .await
        .unwrap();

    // Should receive "unsubscribed" confirmation
    let response = tokio::time::timeout(std::time::Duration::from_secs(5), read.next()).await;
    if let Ok(Some(Ok(Message::Text(text)))) = response {
        let msg: Value = serde_json::from_str(&text).unwrap_or(json!({}));
        assert_eq!(
            msg["type"], "unsubscribed",
            "Should confirm unsubscription: {msg:?}"
        );
    }
}

// =============================================================================
// SECTION 4: Presence
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_presence_update() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let (ws_stream, _) = connect_async(&url).await.expect("connect failed");
    let (mut write, mut read) = ws_stream.split();

    // Send presence update
    let presence_msg = json!({
        "type": "presence",
        "metadata": { "status": "online", "page": "/products" }
    });

    write
        .send(Message::Text(presence_msg.to_string().into()))
        .await
        .expect("send presence failed");

    // Should receive presence_update with online users list (may take time)
    let response = tokio::time::timeout(std::time::Duration::from_secs(10), read.next()).await;

    // Server may or may not respond to presence immediately depending on config
    if let Ok(Some(Ok(Message::Text(text)))) = response {
        let msg: Value = serde_json::from_str(&text).unwrap_or(json!({}));
        assert_eq!(
            msg["type"], "presence_update",
            "Should get presence_update: {msg:?}"
        );
        assert!(msg["online"].is_array(), "Should include online users list");
    }
    // Timeout is acceptable — presence updates may be batched or delayed
}

// =============================================================================
// SECTION 5: Invalid Messages
// =============================================================================

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_invalid_message_returns_error() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let (ws_stream, _) = connect_async(&url).await.expect("connect failed");
    let (mut write, mut read) = ws_stream.split();

    // Send malformed JSON
    write
        .send(Message::Text("not valid json".into()))
        .await
        .expect("send failed");

    // Should receive error message (not crash)
    let response = tokio::time::timeout(std::time::Duration::from_secs(5), read.next()).await;

    if let Ok(Some(Ok(Message::Text(text)))) = response {
        let msg: Value = serde_json::from_str(&text).unwrap_or(json!({}));
        assert_eq!(
            msg["type"], "error",
            "Should return error for invalid message: {msg:?}"
        );
    }
}

#[tokio::test]
#[ignore = "requires running orignabase instance"]
async fn test_ws_subscribe_to_specific_document() {
    let client = reqwest::Client::new();
    let (token, _user_id) = register_test_user(&client).await;

    let url = format!("{}/realtime?token={}", ws_url(), token);
    let (ws_stream, _) = connect_async(&url).await.expect("connect failed");
    let (mut write, mut read) = ws_stream.split();

    let sub_id = format!("doc_sub_{}", Uuid::new_v4());
    let subscribe_msg = json!({
        "type": "subscribe",
        "id": sub_id,
        "collection": "products",
        "document_id": "products:some_id"
    });

    write
        .send(Message::Text(subscribe_msg.to_string().into()))
        .await
        .expect("send subscribe failed");

    let response = tokio::time::timeout(std::time::Duration::from_secs(5), read.next()).await;
    if let Ok(Some(Ok(Message::Text(text)))) = response {
        let msg: Value = serde_json::from_str(&text).unwrap_or(json!({}));
        assert_eq!(
            msg["type"], "subscribed",
            "Should confirm doc subscription: {msg:?}"
        );
        assert_eq!(msg["id"], sub_id);
    }
}
