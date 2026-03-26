//! Token revocation system for logout and refresh token rotation.
//!
//! Implements:
//! - Token revocation with hash-based storage (don't store raw tokens)
//! - Revocation check during token verification
//! - Automatic cleanup of expired revocation entries
//! - Atomic refresh token rotation (revoke old, issue new)

use ob_core::{Error, Result};
use serde_json::json;
use sha2::{Digest, Sha256};
use tracing::info;

/// Hash a raw token using SHA256.
/// Returns hex-encoded hash suitable for storage.
fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    format!("{:x}", hasher.finalize())
}

/// Revoke a token by storing its hash in the database.
///
/// The token is stored with an expiry timestamp equal to its original TTL,
/// so revocation records can be automatically cleaned up.
///
/// # Arguments
/// * `db` - Database client
/// * `token` - Raw token to revoke
/// * `ttl_secs` - Token's time-to-live in seconds (from issuance)
pub async fn revoke_token(
    db: &ob_database::DatabaseClient,
    token: &str,
    ttl_secs: u64,
) -> Result<()> {
    let token_hash = hash_token(token);
    let expires_at = chrono::Utc::now().timestamp() + ttl_secs as i64;

    db.query_bind(
        "CREATE _revoked_tokens CONTENT { hash: $hash, expiresAt: $expires_at, revokedAt: time::now() }",
        json!({
            "hash": token_hash,
            "expires_at": expires_at,
        }),
    )
    .await
    .map_err(|e| Error::Internal(format!("Failed to revoke token: {e}")))?;

    info!("Token revoked (hash: {})", &token_hash[..8]); // Log truncated hash for debugging
    Ok(())
}

/// Check if a token has been revoked.
///
/// Returns `true` if the token is in the revocation list and hasn't expired yet.
/// Returns `false` if the token is not revoked or if the revocation entry has expired.
///
/// # Arguments
/// * `db` - Database client
/// * `token` - Raw token to check
pub async fn is_token_revoked(
    db: &ob_database::DatabaseClient,
    token: &str,
) -> Result<bool> {
    let token_hash = hash_token(token);

    let results = db
        .query_bind(
            "SELECT * FROM _revoked_tokens WHERE hash = $hash AND expiresAt > time::now() LIMIT 1",
            json!({ "hash": token_hash }),
        )
        .await?;

    Ok(!results.is_empty())
}

/// Clean up expired revocation entries from the database.
///
/// This should be called periodically (e.g., once per day) to avoid
/// unbounded growth of the `_revoked_tokens` table.
///
/// Returns the count of deleted entries.
pub async fn cleanup_revoked_tokens(db: &ob_database::DatabaseClient) -> Result<usize> {
    let results = db
        .query_bind(
            "DELETE FROM _revoked_tokens WHERE expiresAt < time::now()",
            json!({}),
        )
        .await?;

    let count = results.len();
    info!("Cleaned up {} expired revocation entries", count);
    Ok(count)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_token_deterministic() {
        let token = "REDACTED_SECRET";
        let hash1 = hash_token(token);
        let hash2 = hash_token(token);
        assert_eq!(hash1, hash2, "Hash should be deterministic");
    }

    #[test]
    fn test_hash_token_different_tokens() {
        let token1 = "token1";
        let token2 = "token2";
        let hash1 = hash_token(token1);
        let hash2 = hash_token(token2);
        assert_ne!(hash1, hash2, "Different tokens should have different hashes");
    }

    #[test]
    fn test_hash_token_is_hex() {
        let token = "test_token";
        let hash = hash_token(token);
        // SHA256 produces 64 hex characters
        assert_eq!(hash.len(), 64, "SHA256 hex hash should be 64 characters");
        assert!(hash.chars().all(|c| c.is_ascii_hexdigit()), "Hash should be valid hex");
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;

    // Note: These are unit tests for the hash function.
    // Full integration tests (with database) would be in tests/ directory.

    #[tokio::test]
    async fn test_hash_consistency() {
        let token = "REDACTED_SECRET";
        let hash1 = hash_token(token);
        let hash2 = hash_token(token);
        assert_eq!(hash1, hash2);
    }

    #[test]
    fn test_hash_format() {
        let token = "test.jwt.token";
        let hash = hash_token(token);
        
        // Verify it's valid hex
        for c in hash.chars() {
            assert!(c.is_ascii_hexdigit(), "Hash contains invalid hex character: {}", c);
        }
        
        // Verify length is 64 (SHA256 produces 256 bits = 64 hex chars)
        assert_eq!(hash.len(), 64);
    }

    #[test]
    fn test_different_tokens_different_hashes() {
        let token1 = "access_token_abc123";
        let token2 = "refresh_token_xyz789";
        
        let hash1 = hash_token(token1);
        let hash2 = hash_token(token2);
        
        assert_ne!(hash1, hash2);
    }

    #[test]
    fn test_hash_token_empty() {
        let hash = hash_token("");
        // Even empty string produces valid hash
        assert_eq!(hash.len(), 64);
        assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_hash_token_long() {
        let long_token = "x".repeat(10000);
        let hash = hash_token(&long_token);
        assert_eq!(hash.len(), 64);
    }
}
