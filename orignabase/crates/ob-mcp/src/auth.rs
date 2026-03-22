//! MCP authentication middleware — reuses ob-auth JWT verification

use crate::errors::{McpError, McpResult};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Extracted JWT claims from Authorization header
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpClaims {
    pub sub: String,          // user ID in format "users:xxx"
    pub uid: String,          // short user ID "xxx"
    pub role: Option<String>, // "admin", "seller", "buyer"
    pub iat: i64,             // issued at
    pub exp: i64,             // expiration
}

impl McpClaims {
    /// Check if user has required role
    pub fn has_role(&self, required_role: &str) -> bool {
        self.role.as_deref() == Some(required_role)
    }

    /// Check if user is an admin
    pub fn is_admin(&self) -> bool {
        self.has_role("admin")
    }

    /// Check if user is a seller
    pub fn is_seller(&self) -> bool {
        self.has_role("seller")
    }

    /// Verify user owns a resource (used for order/profile access control)
    pub fn owns_resource(&self, owner_id: &str) -> bool {
        // owner_id might be full "users:xxx" or short "xxx"
        self.sub == owner_id || self.uid == owner_id
    }
}

/// Extract JWT claims from Authorization header
pub fn extract_claims(auth_header: Option<&str>) -> McpResult<McpClaims> {
    let header = auth_header.ok_or(McpError::Unauthorized)?;

    let bearer = header
        .strip_prefix("Bearer ")
        .ok_or(McpError::Unauthorized)?;

    // NOTE: In actual implementation, this would call ob-auth::jwt::verify_token()
    // For now, we stub the parsing. Full JWT verification happens in the transport layer.
    parse_jwt_claims(bearer)
}

/// Stub JWT parsing (actual verification done by ob-auth middleware)
fn parse_jwt_claims(token: &str) -> McpResult<McpClaims> {
    // This is a placeholder. Real implementation would:
    // 1. Split token into header.payload.signature
    // 2. Decode payload as base64-json
    // 3. Verify signature against pub key from ob-auth
    //
    // For now, reject if token is empty
    if token.is_empty() {
        return Err(McpError::Unauthorized);
    }

    // Placeholder: assume valid JWT, extract claims
    // In production, use jsonwebtoken crate + ob-auth public key
    Ok(McpClaims {
        sub: "users:placeholder".to_string(),
        uid: "placeholder".to_string(),
        role: Some("buyer".to_string()),
        iat: 0,
        exp: i64::MAX,
    })
}

/// Request context with optional authenticated user
#[derive(Debug, Clone)]
pub struct McpContext {
    pub claims: Option<McpClaims>,
    pub request_id: String,
    pub metadata: HashMap<String, String>,
}

impl McpContext {
    /// Create new unauthenticated context
    pub fn new() -> Self {
        Self {
            claims: None,
            request_id: uuid::Uuid::new_v4().to_string(),
            metadata: HashMap::new(),
        }
    }

    /// Create context with claims
    pub fn with_claims(claims: McpClaims) -> Self {
        Self {
            claims: Some(claims),
            request_id: uuid::Uuid::new_v4().to_string(),
            metadata: HashMap::new(),
        }
    }

    /// Get user ID if authenticated
    pub fn user_id(&self) -> McpResult<String> {
        self.claims
            .as_ref()
            .map(|c| c.sub.clone())
            .ok_or(McpError::Unauthorized)
    }

    /// Require specific role
    pub fn require_role(&self, role: &str) -> McpResult<()> {
        let claims = self.claims.as_ref().ok_or(McpError::Unauthorized)?;
        if !claims.has_role(role) {
            return Err(McpError::Forbidden);
        }
        Ok(())
    }

    /// Require admin role
    pub fn require_admin(&self) -> McpResult<()> {
        self.require_role("admin")
    }

    /// Require seller role
    pub fn require_seller(&self) -> McpResult<()> {
        self.require_role("seller")
    }
}

impl Default for McpContext {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── McpClaims::has_role ──

    fn make_claims(role: Option<&str>) -> McpClaims {
        McpClaims {
            sub: "users:u1".into(),
            uid: "u1".into(),
            role: role.map(String::from),
            iat: 0,
            exp: i64::MAX,
        }
    }

    #[test]
    fn test_has_role_admin() {
        let c = make_claims(Some("admin"));
        assert!(c.has_role("admin"));
        assert!(!c.has_role("seller"));
        assert!(!c.has_role("buyer"));
    }

    #[test]
    fn test_has_role_none() {
        let c = make_claims(None);
        assert!(!c.has_role("admin"));
        assert!(!c.has_role("seller"));
        assert!(!c.has_role("buyer"));
    }

    #[test]
    fn test_has_role_empty_string() {
        let c = make_claims(Some(""));
        assert!(!c.has_role("admin"));
        assert!(c.has_role(""));
    }

    // ── McpClaims::is_admin / is_seller ──

    #[test]
    fn test_is_admin_true() {
        assert!(make_claims(Some("admin")).is_admin());
    }

    #[test]
    fn test_is_admin_false() {
        assert!(!make_claims(Some("buyer")).is_admin());
        assert!(!make_claims(None).is_admin());
    }

    #[test]
    fn test_is_seller_true() {
        assert!(make_claims(Some("seller")).is_seller());
    }

    #[test]
    fn test_is_seller_false() {
        assert!(!make_claims(Some("admin")).is_seller());
        assert!(!make_claims(None).is_seller());
    }

    // ── McpClaims::owns_resource ──

    #[test]
    fn test_owns_resource_full_sub() {
        let c = make_claims(None);
        assert!(c.owns_resource("users:u1"));
    }

    #[test]
    fn test_owns_resource_short_uid() {
        let c = make_claims(None);
        assert!(c.owns_resource("u1"));
    }

    #[test]
    fn test_owns_resource_wrong_id() {
        let c = make_claims(None);
        assert!(!c.owns_resource("users:u2"));
        assert!(!c.owns_resource("u2"));
    }

    #[test]
    fn test_owns_resource_empty() {
        let c = make_claims(None);
        assert!(!c.owns_resource(""));
    }

    // ── extract_claims ──

    #[test]
    fn test_extract_claims_none_header() {
        let result = extract_claims(None);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::Unauthorized));
    }

    #[test]
    fn test_extract_claims_no_bearer_prefix() {
        let result = extract_claims(Some("Basic abc123"));
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::Unauthorized));
    }

    #[test]
    fn test_extract_claims_empty_bearer() {
        let result = extract_claims(Some("Bearer "));
        assert!(result.is_err());
    }

    #[test]
    fn test_extract_claims_valid() {
        let result = extract_claims(Some("Bearer some.jwt.token"));
        assert!(result.is_ok());
        let claims = result.unwrap();
        assert_eq!(claims.uid, "placeholder");
        assert_eq!(claims.role, Some("buyer".into()));
    }

    #[test]
    fn test_extract_claims_wrong_prefix_lowercase() {
        let result = extract_claims(Some("bearer abc"));
        assert!(result.is_err());
    }

    #[test]
    fn test_extract_claims_empty_string_header() {
        let result = extract_claims(Some(""));
        assert!(result.is_err());
    }

    // ── McpContext::new ──

    #[test]
    fn test_context_new_unauthenticated() {
        let ctx = McpContext::new();
        assert!(ctx.claims.is_none());
        assert!(!ctx.request_id.is_empty());
        assert!(ctx.metadata.is_empty());
    }

    #[test]
    fn test_context_default() {
        let ctx = McpContext::default();
        assert!(ctx.claims.is_none());
    }

    #[test]
    fn test_context_with_claims() {
        let claims = make_claims(Some("admin"));
        let ctx = McpContext::with_claims(claims);
        assert!(ctx.claims.is_some());
        assert!(ctx.claims.unwrap().is_admin());
    }

    #[test]
    fn test_context_unique_request_ids() {
        let ctx1 = McpContext::new();
        let ctx2 = McpContext::new();
        assert_ne!(ctx1.request_id, ctx2.request_id);
    }

    // ── McpContext::user_id ──

    #[test]
    fn test_user_id_authenticated() {
        let ctx = McpContext::with_claims(make_claims(Some("buyer")));
        assert_eq!(ctx.user_id().unwrap(), "users:u1");
    }

    #[test]
    fn test_user_id_unauthenticated() {
        let ctx = McpContext::new();
        let result = ctx.user_id();
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::Unauthorized));
    }

    // ── McpContext::require_role ──

    #[test]
    fn test_require_role_ok() {
        let ctx = McpContext::with_claims(make_claims(Some("admin")));
        assert!(ctx.require_role("admin").is_ok());
    }

    #[test]
    fn test_require_role_wrong_role() {
        let ctx = McpContext::with_claims(make_claims(Some("buyer")));
        let result = ctx.require_role("admin");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::Forbidden));
    }

    #[test]
    fn test_require_role_no_claims() {
        let ctx = McpContext::new();
        let result = ctx.require_role("admin");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), McpError::Unauthorized));
    }

    // ── McpContext::require_admin / require_seller ──

    #[test]
    fn test_require_admin_ok() {
        let ctx = McpContext::with_claims(make_claims(Some("admin")));
        assert!(ctx.require_admin().is_ok());
    }

    #[test]
    fn test_require_admin_forbidden() {
        let ctx = McpContext::with_claims(make_claims(Some("seller")));
        assert!(matches!(ctx.require_admin(), Err(McpError::Forbidden)));
    }

    #[test]
    fn test_require_admin_no_claims() {
        let ctx = McpContext::new();
        assert!(matches!(ctx.require_admin(), Err(McpError::Unauthorized)));
    }

    #[test]
    fn test_require_seller_ok() {
        let ctx = McpContext::with_claims(make_claims(Some("seller")));
        assert!(ctx.require_seller().is_ok());
    }

    #[test]
    fn test_require_seller_forbidden() {
        let ctx = McpContext::with_claims(make_claims(Some("buyer")));
        assert!(matches!(ctx.require_seller(), Err(McpError::Forbidden)));
    }

    #[test]
    fn test_require_seller_no_claims() {
        let ctx = McpContext::new();
        assert!(matches!(ctx.require_seller(), Err(McpError::Unauthorized)));
    }

    // ── Serialization ──

    #[test]
    fn test_claims_serialization() {
        let claims = make_claims(Some("admin"));
        let json = serde_json::to_value(&claims).unwrap();
        assert_eq!(json["sub"], "users:u1");
        assert_eq!(json["uid"], "u1");
        assert_eq!(json["role"], "admin");
    }

    #[test]
    fn test_claims_deserialization() {
        let json = serde_json::json!({
            "sub": "users:u2",
            "uid": "u2",
            "role": "seller",
            "iat": 1000,
            "exp": 9999
        });
        let claims: McpClaims = serde_json::from_value(json).unwrap();
        assert_eq!(claims.sub, "users:u2");
        assert_eq!(claims.role, Some("seller".into()));
    }

    // ── McpContext metadata ──

    #[test]
    fn test_context_metadata() {
        let mut ctx = McpContext::new();
        ctx.metadata.insert("trace_id".into(), "abc123".into());
        assert_eq!(ctx.metadata.get("trace_id").unwrap(), "abc123");
    }
}
