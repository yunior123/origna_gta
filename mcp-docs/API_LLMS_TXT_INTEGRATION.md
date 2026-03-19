# Adding llms.txt to OrignaBase API

This guide explains how to serve `llms.txt` and `.well-known/mcp.json` directly from the OrignaBase API server, allowing agents to discover the MCP server from the API domain itself.

## Why Add llms.txt to the API?

Agents can discover MCP capabilities from multiple entry points:

1. **Direct documentation site**: `https://mcp.docs.orignagta.ca/llms.txt`
2. **API endpoint** (better): `https://api.orignagta.ca/llms.txt`
3. **Well-known manifest**: `https://api.orignagta.ca/.well-known/mcp.json`

When agents first encounter the API URL, they can immediately check `/.well-known/mcp.json` and `/llms.txt` to discover available MCP capabilities.

## Implementation

### Option 1: Static Routes (Rust Axum)

Add these routes to `orignabase/src/routes.rs`:

```rust
use axum::response::{IntoResponse, Response};
use axum::http::StatusCode;

// Serve llms.txt at /llms.txt
pub async fn get_llms_txt() -> Result<impl IntoResponse, AppError> {
    let content = include_str!("../mcp_docs/llms.txt");
    Ok((
        StatusCode::OK,
        [("Content-Type", "text/plain; charset=utf-8")],
        content,
    ))
}

// Serve .well-known/mcp.json at /.well-known/mcp.json
pub async fn get_mcp_manifest() -> Result<impl IntoResponse, AppError> {
    let content = include_str!("../mcp_docs/mcp.json");
    Ok((
        StatusCode::OK,
        [("Content-Type", "application/json")],
        content,
    ))
}
```

Register routes in your router:

```rust
// In your Axum router setup
let app = Router::new()
    // ... existing routes ...
    .route("/llms.txt", get(get_llms_txt))
    .route("/.well-known/mcp.json", get(get_mcp_manifest))
    // ... rest of routes ...
```

### Option 2: File-Based Routes (More Flexible)

```rust
use axum::response::IntoResponse;
use std::path::Path;

pub async fn get_llms_txt() -> Result<impl IntoResponse, AppError> {
    let path = Path::new("./docs/mcp/llms.txt");
    let content = std::fs::read_to_string(path)
        .map_err(|_| AppError::FileNotFound("llms.txt not found".to_string()))?;
    Ok((
        StatusCode::OK,
        [("Content-Type", "text/plain; charset=utf-8")],
        content,
    ))
}
```

### Option 3: Proxy via Caddy (No Backend Changes)

If modifying the Rust backend is complex, add Caddy reverse proxy rules:

```caddy
api.orignagta.ca {
    # ... existing config ...
    
    # Proxy llms.txt from documentation site
    @llms {
        path /llms.txt
    }
    handle @llms {
        uri /llms.txt
        reverse_proxy https://mcp.docs.orignagta.ca
    }
    
    # Proxy .well-known/mcp.json from documentation site
    @mcp_manifest {
        path /.well-known/mcp.json
    }
    handle @mcp_manifest {
        uri /.well-known/mcp.json
        reverse_proxy https://mcp.docs.orignagta.ca
    }
    
    # All other requests go to backend
    reverse_proxy localhost:8000
}
```

## llms.txt Content

Copy the full `llms.txt` content from the documentation site into your backend:

```bash
# Copy from docs to Rust backend (if using embedded approach)
cp /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/mcp-docs/llms.txt \
   orignabase/src/mcp_docs/llms.txt
```

Or reference it as a module file:

```
orignabase/
├── src/
│   ├── routes.rs
│   ├── mcp_docs/
│   │   ├── llms.txt
│   │   └── mcp.json
```

## Testing

### Verify llms.txt is served

```bash
# Development
curl https://api.dev.orignagta.ca/llms.txt | head -20

# Staging
curl https://api.staging.orignagta.ca/llms.txt | head -20

# Production
curl https://api.orignagta.ca/llms.txt | head -20
```

Expected output: First 20 lines of llms.txt starting with `# OrignaGTA MCP Server`

### Verify .well-known/mcp.json is served

```bash
curl https://api.orignagta.ca/.well-known/mcp.json | jq .name

# Output: "OrignaGTA MCP Server"
```

### Check Content-Type headers

```bash
curl -I https://api.orignagta.ca/llms.txt
# Should show: Content-Type: text/plain

curl -I https://api.orignagta.ca/.well-known/mcp.json
# Should show: Content-Type: application/json
```

## Security Considerations

### 1. Rate Limiting

These endpoints should have generous rate limits (or no limits) since they're informational:

```rust
// Don't rate-limit documentation endpoints
if path != "/llms.txt" && path != "/.well-known/mcp.json" {
    // Apply rate limiting
}
```

### 2. Caching Headers

```rust
// Cache llms.txt for 1 hour
.header("Cache-Control", "public, max-age=3600")

// Cache mcp.json for 1 day
.header("Cache-Control", "public, max-age=86400")
```

### 3. No Authentication Required

These endpoints must be **public and unauthenticated** so agents can discover them without a token:

```rust
pub async fn get_llms_txt() -> Result<impl IntoResponse, AppError> {
    // No auth check — public endpoint
}
```

## Agent Discovery Flow

When an agent encounters the OrignaBase API:

```
1. Agent: GET https://api.orignagta.ca/.well-known/mcp.json
   ↓
2. OriginaBase returns: { name, description, tools, llms_txt_url, ... }
   ↓
3. Agent: GET https://api.orignagta.ca/llms.txt
   ↓
4. OrignaBase returns: Full llms.txt documentation
   ↓
5. Agent: Parses tools, parameters, authentication requirements
   ↓
6. Agent: Makes authenticated MCP calls with JWT token
```

## Deployment Checklist

- [ ] Copy `llms.txt` and `.well-known/mcp.json` to backend
- [ ] Add routes in `routes.rs` (or Caddy proxy rules)
- [ ] Set correct `Content-Type` headers
- [ ] Set cache control headers
- [ ] Test with `curl` to verify
- [ ] Deploy to development environment
- [ ] Deploy to staging environment
- [ ] Deploy to production environment
- [ ] Monitor logs for 404 errors on these routes
- [ ] Update monitoring/alerting if these endpoints become unavailable

## Example: Complete Route Handler

```rust
use axum::{
    response::{IntoResponse, Response},
    http::StatusCode,
    routing::get,
    Router,
};

// Handler for llms.txt
async fn get_llms_txt() -> impl IntoResponse {
    let content = include_str!("../docs/llms.txt");
    (
        StatusCode::OK,
        [
            ("Content-Type", "text/plain; charset=utf-8"),
            ("Cache-Control", "public, max-age=3600"),
        ],
        content,
    )
}

// Handler for .well-known/mcp.json
async fn get_mcp_manifest() -> impl IntoResponse {
    let content = include_str!("../docs/mcp.json");
    (
        StatusCode::OK,
        [
            ("Content-Type", "application/json"),
            ("Cache-Control", "public, max-age=86400"),
        ],
        content,
    )
}

// Register in router
pub fn create_router() -> Router {
    Router::new()
        .route("/llms.txt", get(get_llms_txt))
        .route("/.well-known/mcp.json", get(get_mcp_manifest))
        // ... other routes ...
}
```

## Additional Resources

- **llms.txt Standard**: https://llmstxt.org
- **MCP Specification**: https://modelcontextprotocol.io
- **Agent Discovery**: Agents should check `/.well-known/mcp.json` on any API domain they interact with

---

**Last Updated**: March 2026  
**Status**: Recommended for production
