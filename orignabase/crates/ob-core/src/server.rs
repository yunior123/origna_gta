use crate::{AppState, Config, Result};
use axum::Router;
use axum::http::{HeaderValue, Method, header};
use std::time::Duration;
use tower_http::compression::CompressionLayer;
use tower_http::cors::CorsLayer;
use tower_http::timeout::TimeoutLayer;
use tower_http::trace::TraceLayer;

/// Build the Axum router with all middleware.
pub fn build_router(state: AppState) -> Router {
    let is_test_mode = std::env::var("OB_TEST_MODE").unwrap_or_default() == "1";
    let cors_layer = build_cors_layer(&state.config, is_test_mode);
    Router::new()
        .route("/health", axum::routing::get(health_check))
        .layer(CompressionLayer::new())
        .layer(TimeoutLayer::with_status_code(
            axum::http::StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(30),
        ))
        .layer(TraceLayer::new_for_http())
        .layer(cors_layer)
        .with_state(state)
}

/// Build CORS layer with explicit origin whitelist.
/// CRITICAL FIX: Replace .allow_origin(Any) with specific production domains.
fn build_cors_layer(config: &Config, is_test_mode: bool) -> CorsLayer {
    let mut allowed_origins: Vec<HeaderValue> = config
        .cors
        .allowed_origins
        .iter()
        .filter_map(|origin| match origin.parse::<HeaderValue>() {
            Ok(value) => Some(value),
            Err(err) => {
                tracing::warn!(origin, %err, "Skipping invalid CORS origin from config");
                None
            }
        })
        .collect();

    // Allow localhost ONLY in test mode (for local development)
    if is_test_mode {
        allowed_origins.push(
            "http://localhost:3000"
                .parse::<HeaderValue>()
                .expect("static localhost origin should parse"),
        );
        allowed_origins.push(
            "http://localhost:5173"
                .parse::<HeaderValue>()
                .expect("static localhost origin should parse"),
        );
    }

    if allowed_origins.is_empty() && !is_test_mode {
        tracing::warn!(
            "CORS allowed_origins is empty and not in test mode — all cross-origin requests will be denied"
        );
    }

    let cors = if allowed_origins.is_empty() {
        CorsLayer::new()
    } else {
        CorsLayer::new().allow_origin(allowed_origins)
    };

    cors.allow_credentials(true)
        .allow_methods([
        Method::GET,
        Method::POST,
        Method::PUT,
        Method::PATCH,
        Method::DELETE,
        Method::OPTIONS,
    ])
        .allow_headers([
            header::ACCEPT,
            header::AUTHORIZATION,
            header::CONTENT_TYPE,
            header::ORIGIN,
            header::CACHE_CONTROL,
            "x-requested-with".parse().expect("static header should parse"),
            "x-tenant-id".parse().expect("static header should parse"),
        ])
}

async fn health_check() -> &'static str {
    "ok"
}

/// Start the HTTP server.
pub async fn serve(config: Config) -> Result<()> {
    let addr = format!("{}:{}", config.host, config.port);
    let http_client = reqwest::Client::new();
    let state = AppState::new(config, http_client);
    let app = build_router(state);

    tracing::info!("OrignaBase listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .map_err(|e| crate::Error::Internal(format!("Failed to bind {addr}: {e}")))?;

    axum::serve(listener, app)
        .await
        .map_err(|e| crate::Error::Internal(e.to_string()))?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    fn make_state() -> AppState {
        let config: Config = toml::from_str(
            r#"
            [database]
            endpoint = "localhost:8000"
            "#,
        )
        .unwrap();
        AppState::new(config, reqwest::Client::new())
    }

    #[tokio::test]
    async fn test_health_check() {
        let result = health_check().await;
        assert_eq!(result, "ok");
    }

    #[tokio::test]
    async fn test_router_health_endpoint() {
        let app = build_router(make_state());
        let req = Request::builder()
            .uri("/health")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::OK);

        let bytes = resp.into_body().collect().await.unwrap().to_bytes();
        assert_eq!(&bytes[..], b"ok");
    }

    #[tokio::test]
    async fn test_router_unknown_route_404() {
        let app = build_router(make_state());
        let req = Request::builder()
            .uri("/nonexistent")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }

    #[tokio::test]
    async fn test_router_health_post_method_not_allowed() {
        let app = build_router(make_state());
        let req = Request::builder()
            .method("POST")
            .uri("/health")
            .body(Body::empty())
            .unwrap();
        let resp = app.oneshot(req).await.unwrap();
        assert_eq!(resp.status(), StatusCode::METHOD_NOT_ALLOWED);
    }
}
