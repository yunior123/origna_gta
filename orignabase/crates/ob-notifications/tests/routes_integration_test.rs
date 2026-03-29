use axum::body::{Body, to_bytes};
use axum::http::{Request, StatusCode};
use ob_database::DatabaseClient;
use ob_notifications::{NotificationsState, notifications_router};
use serde_json::{Value, json};
use tower::util::ServiceExt;

async fn test_state() -> NotificationsState {
    NotificationsState::new(
        DatabaseClient::new_mem().await,
        Some("integration-project".into()),
        None,
        reqwest::Client::new(),
    )
}

async fn parse_json(response: axum::response::Response) -> Value {
    let body = to_bytes(response.into_body(), 1024 * 1024).await.unwrap();
    serde_json::from_slice(&body).unwrap()
}

#[tokio::test]
async fn register_then_send_to_user_persists_pending_notification() {
    let state = test_state().await;
    let db = state.db.clone();
    let app = notifications_router(state);

    let register_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/register")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "user_id": "users:buyer-1",
                        "token": "device-token-1",
                        "platform": "android"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(register_response.status(), StatusCode::OK);

    let send_response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/send")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "to": "users:buyer-1",
                        "target_type": "user",
                        "title": "Order update",
                        "body": "Your order has shipped",
                        "data": { "order_id": "orders:1" }
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(send_response.status(), StatusCode::OK);

    let payload = parse_json(send_response).await;
    assert_eq!(payload["sent"], 1);
    assert_eq!(payload["failed"], 0);
    assert_eq!(payload["total_devices"], 1);

    let pending = db
        .list_documents("_pending_notifications", None, None)
        .await
        .unwrap();
    assert_eq!(pending.len(), 1);
    assert_eq!(pending[0]["token"], "device-token-1");
    assert_eq!(pending[0]["title"], "Order update");
    assert_eq!(pending[0]["data"]["order_id"], "orders:1");
}

#[tokio::test]
async fn subscribe_send_and_unsubscribe_topic_uses_real_router_flow() {
    let state = test_state().await;
    let db = state.db.clone();
    let app = notifications_router(state);

    let subscribe_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/subscribe")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "token": "device-topic-1",
                        "topic": "flash-sales"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(subscribe_response.status(), StatusCode::OK);

    let first_send_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/send")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "to": "flash-sales",
                        "target_type": "topic",
                        "title": "Big sale",
                        "body": "Starts now"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(first_send_response.status(), StatusCode::OK);
    let first_send_payload = parse_json(first_send_response).await;
    assert_eq!(first_send_payload["sent"], 1);
    assert_eq!(first_send_payload["total_devices"], 1);

    let unsubscribe_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("DELETE")
                .uri("/push/subscribe")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "token": "device-topic-1",
                        "topic": "flash-sales"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(unsubscribe_response.status(), StatusCode::OK);

    let second_send_response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/send")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "to": "flash-sales",
                        "target_type": "topic",
                        "title": "Big sale",
                        "body": "Starts now"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(second_send_response.status(), StatusCode::OK);
    let second_send_payload = parse_json(second_send_response).await;
    assert_eq!(second_send_payload["sent"], 0);
    assert_eq!(second_send_payload["message"], "No devices found");

    let pending = db
        .list_documents("_pending_notifications", None, None)
        .await
        .unwrap();
    assert_eq!(pending.len(), 1);
    assert_eq!(pending[0]["token"], "device-topic-1");
}

#[tokio::test]
async fn unregistering_a_token_removes_it_from_user_fanout() {
    let state = test_state().await;
    let router = notifications_router(state);

    let register_response = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/register")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "user_id": "users:buyer-2",
                        "token": "device-token-2",
                        "platform": "ios"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(register_response.status(), StatusCode::OK);

    let unregister_response = router
        .clone()
        .oneshot(
            Request::builder()
                .method("DELETE")
                .uri("/push/register")
                .header("content-type", "application/json")
                .body(Body::from(json!({ "token": "device-token-2" }).to_string()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(unregister_response.status(), StatusCode::OK);

    let send_response = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/push/send")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({
                        "to": "users:buyer-2",
                        "target_type": "user",
                        "title": "Order update",
                        "body": "No device should receive this"
                    })
                    .to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(send_response.status(), StatusCode::OK);
    let payload = parse_json(send_response).await;
    assert_eq!(payload["sent"], 0);
    assert_eq!(payload["message"], "No devices found");
}
