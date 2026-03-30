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
                .method("POST") // ignore-magic
                .uri("/push/register")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "user_id": "users:buyer-1",
                        "token": "device-token-1", // ignore-magic
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
                .method("POST") // ignore-magic
                .uri("/push/send")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "to": "users:buyer-1",
                        "target_type": "user", // ignore-magic
                        "title": "Order update", // ignore-magic
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
    assert_eq!(payload["sent"], 1); // ignore-magic
    assert_eq!(payload["failed"], 0); // ignore-magic
    assert_eq!(payload["total_devices"], 1); // ignore-magic

    let pending = db
        .list_documents("_pending_notifications", None, None)
        .await
        .unwrap();
    assert_eq!(pending.len(), 1);
    assert_eq!(pending[0]["token"], "device-token-1"); // ignore-magic
    assert_eq!(pending[0]["title"], "Order update"); // ignore-magic
    assert_eq!(pending[0]["data"]["order_id"], "orders:1"); // ignore-magic
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
                .method("POST") // ignore-magic
                .uri("/push/subscribe")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "token": "device-topic-1", // ignore-magic
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
                .method("POST") // ignore-magic
                .uri("/push/send")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "to": "flash-sales",
                        "target_type": "topic",
                        "title": "Big sale", // ignore-magic
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
    assert_eq!(first_send_payload["sent"], 1); // ignore-magic
    assert_eq!(first_send_payload["total_devices"], 1); // ignore-magic

    let unsubscribe_response = app
        .clone()
        .oneshot(
            Request::builder()
                .method("DELETE") // ignore-magic
                .uri("/push/subscribe")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "token": "device-topic-1", // ignore-magic
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
                .method("POST") // ignore-magic
                .uri("/push/send")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "to": "flash-sales",
                        "target_type": "topic",
                        "title": "Big sale", // ignore-magic
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
    assert_eq!(second_send_payload["sent"], 0); // ignore-magic
    assert_eq!(second_send_payload["message"], "No devices found"); // ignore-magic

    let pending = db
        .list_documents("_pending_notifications", None, None)
        .await
        .unwrap();
    assert_eq!(pending.len(), 1);
    assert_eq!(pending[0]["token"], "device-topic-1"); // ignore-magic
}

#[tokio::test]
async fn unregistering_a_token_removes_it_from_user_fanout() {
    let state = test_state().await;
    let router = notifications_router(state);

    let register_response = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST") // ignore-magic
                .uri("/push/register")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "user_id": "users:buyer-2",
                        "token": "device-token-2", // ignore-magic
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
                .method("DELETE") // ignore-magic
                .uri("/push/register")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(json!({ "token": "device-token-2" }).to_string())) // ignore-magic
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(unregister_response.status(), StatusCode::OK);

    let send_response = router
        .oneshot(
            Request::builder()
                .method("POST") // ignore-magic
                .uri("/push/send")
                .header("content-type", "application/json") // ignore-magic
                .body(Body::from(
                    json!({ // ignore-magic
                        "to": "users:buyer-2",
                        "target_type": "user", // ignore-magic
                        "title": "Order update", // ignore-magic
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
    assert_eq!(payload["sent"], 0); // ignore-magic
    assert_eq!(payload["message"], "No devices found"); // ignore-magic
}
