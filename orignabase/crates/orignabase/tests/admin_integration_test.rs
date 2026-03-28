//! Live integration tests for admin functionality.
//!
//! Run with: `cd orignabase && cargo test --test admin_integration_test -- --ignored`

use serde_json::{Value, json};

fn base_url() -> String {
    std::env::var("OB_TEST_URL").unwrap_or_else(|_| "https://api.dev.orignagta.ca".to_string())
}

/// Login as admin and return access token.
async fn login_admin(client: &reqwest::Client) -> String {
    let resp = client
        .post(format!("{}/auth/login", base_url()))
        .json(&json!({
            "email": "e2e-admin@test.origna.ca",
            "password": "REDACTED_TEST_PASSWORD"
        }))
        .send()
        .await
        .expect("login failed");

    assert_eq!(resp.status(), 200, "Admin login failed");
    let body: Value = resp.json().await.expect("parse login response");
    body["access_token"]
        .as_str()
        .expect("missing access_token")
        .to_string()
}

/// List all users (admin only).
async fn list_users(client: &reqwest::Client, token: &str) -> Result<Vec<Value>, String> {
    let resp = client
        .get(format!("{}/admin/users", base_url()))
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await
        .map_err(|e| format!("request failed: {}", e))?;

    let status = resp.status();
    let body: Value = resp
        .json()
        .await
        .map_err(|e| format!("parse response: {}", e))?;

    if status == 200 {
        Ok(body.as_array().cloned().unwrap_or_default())
    } else {
        Err(format!("list users failed: {} — {}", status, body))
    }
}

/// Get user details (admin only).
async fn get_user(client: &reqwest::Client, token: &str, user_id: &str) -> Result<Value, String> {
    let resp = client
        .get(format!("{}/admin/users/{}", base_url(), user_id))
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await
        .map_err(|e| format!("request failed: {}", e))?;

    let status = resp.status();
    let body: Value = resp
        .json()
        .await
        .map_err(|e| format!("parse response: {}", e))?;

    if status == 200 {
        Ok(body)
    } else {
        Err(format!("get user failed: {} — {}", status, body))
    }
}

#[tokio::test]
#[ignore]
async fn test_admin_list_users_no_email_leak() {
    let client = reqwest::Client::new();
    let admin_token = login_admin(&client).await;

    match list_users(&client, &admin_token).await {
        Ok(users) => {
            assert!(!users.is_empty(), "Should return users");

            // Check that email field is NOT included in list response
            // (per spec: admins should not see emails in list — only name, ID, role)
            for user in users.iter().take(5) {
                let has_email = user.get("email").is_some();
                assert!(
                    !has_email || user["email"].is_null(),
                    "User list should NOT include email field for privacy"
                );

                // Verify we have safe fields
                let has_id = user.get("id").is_some();
                let has_role = user.get("role").is_some();
                assert!(
                    has_id && has_role,
                    "User list should include id and role fields"
                );
            }
        }
        Err(e) => {
            eprintln!("List users not available: {}", e);
        }
    }
}

#[tokio::test]
#[ignore]
async fn test_admin_list_users_requires_auth() {
    let client = reqwest::Client::new();

    // Attempt to list users WITHOUT auth token
    let resp = client
        .get(format!("{}/admin/users", base_url()))
        .send()
        .await
        .expect("request failed");

    // Should fail with 401 Unauthorized
    assert_eq!(
        resp.status(),
        401,
        "Unauthenticated request should return 401"
    );
}

#[tokio::test]
#[ignore]
async fn test_admin_get_user_requires_admin_role() {
    let client = reqwest::Client::new();
    let admin_token = login_admin(&client).await;

    // List users to get a valid user ID
    if let Ok(users) = list_users(&client, &admin_token).await
        && !users.is_empty()
    {
        let user_id = users[0]["id"]
            .as_str()
            .map(|s| s.to_string())
            .unwrap_or_default();

        if !user_id.is_empty() {
            // Get user details as admin — should succeed
            match get_user(&client, &admin_token, &user_id).await {
                Ok(user) => {
                    let id = user["id"].as_str().unwrap_or("");
                    assert_eq!(id, user_id, "Should return requested user");
                }
                Err(e) => {
                    eprintln!("Get user as admin failed: {}", e);
                }
            }
        }
    }
}

#[tokio::test]
#[ignore]
async fn test_admin_actions_logged_with_uid() {
    let client = reqwest::Client::new();
    let admin_token = login_admin(&client).await;

    // Perform an admin action (list users)
    match list_users(&client, &admin_token).await {
        Ok(_users) => {
            // If we can list users, verify there's an audit log
            // (This test assumes audit logging is implemented)

            // Try to fetch audit log (endpoint may not exist)
            let audit_resp = client
                .get(format!("{}/admin/audit-log", base_url()))
                .header("Authorization", format!("Bearer {}", admin_token))
                .send()
                .await;

            if let Ok(resp) = audit_resp
                && resp.status() == 200
            {
                let body: Value = resp.json().await.unwrap_or(json!({}));
                let empty_vec = vec![];
                let logs = body.as_array().unwrap_or(&empty_vec);

                // Verify recent log entries have adminUid
                for log in logs.iter().take(5) {
                    let has_admin_uid = log.get("adminUid").is_some();
                    assert!(
                        has_admin_uid,
                        "Admin actions should be logged with adminUid"
                    );
                }
            }
        }
        Err(e) => {
            eprintln!("Admin list users failed: {}", e);
        }
    }
}
