# Admin Dashboard Setup Guide

The OrignaBase Admin Dashboard is a web-based management interface for monitoring and administering the OrignaBase backend services.

## Overview

The admin dashboard is served by each OrignaBase deployment and displays:
- System health and uptime metrics
- Database collections and statistics
- User management
- Product and order administration
- Configuration and schema management

An environment badge is displayed in the top-right corner indicating which environment is active:
- **Green (DEV)**: Development environment
- **Yellow (STAGING)**: Staging environment
- **Red (PRODUCTION)**: Production environment

## URLs

| Environment | Dashboard URL | API Base URL |
|-------------|---------------|-------------|
| Development | `http://dev.admin.orignagta.ca` | `https://api.dev.orignagta.ca` |
| Staging | `https://staging.admin.orignagta.ca` | `https://api.staging.orignagta.ca` |
| Production | `https://admin.orignagta.ca` | `https://api.orignagta.ca` |

The dashboard is served at the following routes on any OrignaBase instance:
- `GET /_admin/`
- `GET /_admin`
- `GET /admin/`
- `GET /admin`

## Accessing the Dashboard

### Development (Localhost)

If running OrignaBase locally on `localhost:8080`:

```bash
curl http://localhost:8080/_admin/
```

Or open in your browser: `http://localhost:8080/_admin/`

### Remote Environments

#### Production

Access at `https://admin.orignagta.ca`

**Authentication:** Requires a valid JWT token with `admin` role.

**Security:**
- TLS required
- IP-based rate limiting enabled
- Admin role verification on all endpoints
- Webhook signature validation on sensitive operations

#### Staging

Access at `https://staging.admin.orignagta.ca`

**Authentication:** Requires a valid JWT token with `admin` role.

**Security:**
- TLS required
- Admin role verification on all endpoints

#### Development

Access at `https://dev.admin.orignagta.ca` or `http://localhost:8081`

**Authentication:** Localhost requests (`127.0.0.1`, `::1`) bypass JWT requirement.
Remote requests require `admin` role JWT (when `OB_TEST_MODE=1` is not set, rate limiting is relaxed).

## VPS Configuration (204.168.137.16)

The admin dashboards are reverse-proxied via Caddy on the VPS.

### Caddy Configuration

Add the following to `/etc/caddy/Caddyfile`:

```caddyfile
# Development Admin Dashboard
dev.admin.orignagta.ca {
    reverse_proxy localhost:8081 {
        header_up X-Forwarded-For {http.request.remote}
        header_up X-Forwarded-Proto {http.request.scheme}
    }
}

# Staging Admin Dashboard
staging.admin.orignagta.ca {
    reverse_proxy localhost:8082 {
        header_up X-Forwarded-For {http.request.remote}
        header_up X-Forwarded-Proto {http.request.scheme}
    }
}

# Production Admin Dashboard
admin.orignagta.ca {
    reverse_proxy localhost:8080 {
        header_up X-Forwarded-For {http.request.remote}
        header_up X-Forwarded-Proto {http.request.scheme}
    }
    # Optional: Add basic auth or IP restriction
    # @restricted not remote_ip 1.2.3.4/32
    # respond @restricted 403
}
```

After updating Caddyfile, reload Caddy:

```bash
sudo systemctl reload caddy
# or
sudo caddy reload --config /etc/caddy/Caddyfile
```

### Verify Configuration

```bash
# Test each admin dashboard endpoint
curl -I https://admin.orignagta.ca/_admin/
curl -I https://staging.admin.orignagta.ca/_admin/
curl -I https://dev.admin.orignagta.ca/_admin/
```

## Cloudflare DNS Configuration

Add the following A records in Cloudflare DNS pointing to the VPS IP `204.168.137.16`:

| Record | Type | Content | Proxied |
|--------|------|---------|---------|
| `admin` | A | `204.168.137.16` | :orange_cloud: Yes |
| `staging.admin` | A | `204.168.137.16` | :orange_cloud: Yes |
| `dev.admin` | A | `204.168.137.16` | :orange_cloud: Yes |

**Notes:**
- Orange cloud icon = Proxied through Cloudflare CDN
- Cloudflare will auto-provision TLS certificates via Let's Encrypt
- Ensure Cloudflare SSL/TLS mode is set to "Full (strict)" or "Full"

## Dashboard Features

### System Health (`GET /_admin/health`)

Returns JSON with system status, version, and timestamp:

```json
{
  "status": "ok",
  "version": "0.1.0",
  "timestamp": "2026-03-25T10:30:00Z"
}
```

### Collections Management

- **List collections**: Fetch all PostgreSQL tables with metadata
- **Create collection**: Define new collections with schema
- **Drop collection**: Remove collections (admin only)

### User Management

- List all users with pagination (limit, offset)
- View user roles and metadata
- Modify user permissions and settings

### Metrics & Analytics

- Real-time system uptime and performance metrics
- Request throughput and error rates
- Database query performance tracking
- Storage usage by collection

## Environment Variable Configuration

The environment badge is controlled by the `ENVIRONMENT` environment variable set on each OrignaBase instance:

```bash
# Development
ENVIRONMENT=development  # Badge: GREEN "DEV"

# Staging
ENVIRONMENT=staging      # Badge: YELLOW "STAGING"

# Production
ENVIRONMENT=production   # Badge: RED "PRODUCTION"
```

If `ENVIRONMENT` is not set, defaults to `"development"`.

## API Endpoints

All endpoints are prefixed with `/_admin/` or `/admin/`:

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| `GET` | `/` | Serve dashboard HTML | Any |
| `GET` | `/health` | System health check | None |
| `GET` | `/collections` | List all collections | JWT (admin) |
| `POST` | `/collections` | Create new collection | JWT (admin) |
| `DELETE` | `/collections/:name` | Drop collection | JWT (admin) |
| `GET` | `/users` | List users (paginated) | JWT (admin) |
| `POST` | `/users/:id/roles` | Update user roles | JWT (admin) |
| `GET` | `/usage` | System usage metrics | JWT (admin) |
| `POST` | `/index` | Create database index | JWT (admin) |
| `DELETE` | `/index/:name` | Drop index | JWT (admin) |

## Security Considerations

### Authentication

- **Development**: Localhost (`127.0.0.1`, `::1`) allowed without JWT

### Authorization

- User must have `admin` role in `users` PostgreSQL table
- All mutations (create, update, delete) require admin JWT
- Read operations require JWT on production/staging; localhost bypass on dev

### Rate Limiting

- Auth endpoints: stricter limits (prevent brute force)
- General endpoints: standard rate limits via `tower_governor`
- Dev mode (`OB_TEST_MODE=1`): rate limits disabled

### Data Privacy

- Admin dashboard logs all mutations with admin user ID
- Sensitive data (passwords, payment info) never exposed in dashboard
- PII (emails, addresses) requires admin access
- All requests logged for audit trail

## Troubleshooting

### Dashboard Not Loading

1. **Check OrignaBase status**:
   ```bash
   curl http://204.168.137.16:8080/_admin/health
   ```

2. **Check Caddy reverse proxy**:
   ```bash
   sudo systemctl status caddy
   sudo journalctl -u caddy -f  # Follow logs
   ```

3. **Verify DNS resolution**:
   ```bash
   nslookup admin.orignagta.ca
   dig admin.orignagta.ca
   ```

### Authentication Fails

- Ensure JWT token has `admin` role
- Check token expiration: `jq -R 'split(".") | .[1] | @base64d | fromjson' <<< "$TOKEN"`

### Badge Shows Wrong Environment

- Check `ENVIRONMENT` env var on the OrignaBase instance:
  ```bash
  ssh root@204.168.137.16 "ps aux | grep orignabase | grep ENVIRONMENT"
  ```
- Restart OrignaBase container with correct environment variable

## Implementation Details

The environment badge is rendered using inline CSS and JavaScript:

```html
<div style="position:fixed;top:8px;right:8px;background:#ef4444;color:white;
    padding:6px 14px;border-radius:4px;font-size:12px;font-weight:bold;
    z-index:9999;font-family:monospace;letter-spacing:0.5px;
    box-shadow:0 2px 8px rgba(0,0,0,0.3)">PRODUCTION</div>
```

The badge is injected at request time in the `dashboard()` handler in `orignabase/crates/ob-admin/src/routes.rs`, replacing the `</body>` tag with the badge HTML + closing body tag.

Colors:
- **Production**: `#ef4444` (red)
- **Staging**: `#f59e0b` (amber)
- **Development**: `#22c55e` (green)

## Related Documentation

- OrignaBase API: See `orignabase/README.md`
- PostgreSQL schema: See `orignabase/crates/ob-database/README.md`
- Authentication: See `orignabase/crates/ob-auth/README.md`
