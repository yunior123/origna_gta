# Caddy Configuration for MCP Documentation Sites

Add these blocks to `/etc/caddy/Caddyfile` on VPS (204.168.137.16) to serve MCP documentation across all environments.

## Development Environment

```caddy
mcp.docs.dev.orignagta.ca {
    root * /var/www/orignagta/mcp-docs/dev/current
    file_server
    
    # Enable gzip compression
    encode gzip
    
    # Set proper content types
    header /.well-known/mcp.json Content-Type "application/json"
    header /llms.txt Content-Type "text/plain"
    
    # Cache control
    header /api-reference/* Cache-Control "public, max-age=3600"
    header /*.html Cache-Control "public, max-age=1800"
    
    # Security headers
    header X-Content-Type-Options "nosniff"
    header X-Frame-Options "DENY"
    header Referrer-Policy "strict-origin-when-cross-origin"
    
    # Serve index.html for directory requests
    @notFile {
        not file
        not {
            path /.well-known/*
            path /llms.txt
        }
    }
    rewrite @notFile /index.html
    
    # Error handling
    handle_errors {
        root * /var/www/orignagta/mcp-docs/dev/current
        file_server
    }
}
```

## Staging Environment

```caddy
mcp.docs.staging.orignagta.ca {
    root * /var/www/orignagta/mcp-docs/staging/current
    file_server
    
    encode gzip
    header /.well-known/mcp.json Content-Type "application/json"
    header /llms.txt Content-Type "text/plain"
    header /api-reference/* Cache-Control "public, max-age=3600"
    header /*.html Cache-Control "public, max-age=1800"
    header X-Content-Type-Options "nosniff"
    header X-Frame-Options "DENY"
    
    @notFile {
        not file
        not {
            path /.well-known/*
            path /llms.txt
        }
    }
    rewrite @notFile /index.html
    
    handle_errors {
        root * /var/www/orignagta/mcp-docs/staging/current
        file_server
    }
}
```

## Production Environment

```caddy
mcp.docs.orignagta.ca {
    root * /var/www/orignagta/mcp-docs/prod/current
    file_server
    
    encode gzip
    header /.well-known/mcp.json Content-Type "application/json"
    header /llms.txt Content-Type "text/plain"
    header /api-reference/* Cache-Control "public, max-age=86400"
    header /*.html Cache-Control "public, max-age=3600"
    header X-Content-Type-Options "nosniff"
    header X-Frame-Options "DENY"
    header Referrer-Policy "strict-origin-when-cross-origin"
    header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    
    @notFile {
        not file
        not {
            path /.well-known/*
            path /llms.txt
        }
    }
    rewrite @notFile /index.html
    
    handle_errors {
        root * /var/www/orignagta/mcp-docs/prod/current
        file_server
    }
}
```

## Installation Steps

### 1. SSH into VPS

```bash
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16
```

### 2. Edit Caddyfile

```bash
nano /etc/caddy/Caddyfile
```

### 3. Add the blocks above for your environment(s)

### 4. Test Caddy configuration

```bash
caddy validate --config /etc/caddy/Caddyfile
```

### 5. Reload Caddy

```bash
caddy reload --config /etc/caddy/Caddyfile
```

### 6. Verify deployment

```bash
# Check Caddy is running
systemctl status caddy

# Test SSL certificate
curl -I https://mcp.docs.orignagta.ca

# Verify content
curl https://mcp.docs.orignagta.ca/llms.txt | head -20
curl https://mcp.docs.orignagta.ca/.well-known/mcp.json | jq .
```

## Key Configuration Details

### Content-Type Headers
- **mcp.json**: `application/json` — AI agents can parse as JSON
- **llms.txt**: `text/plain` — Standard llms.txt format for AI discovery

### Cache Control
- **API reference pages** (3600s / 1h) — Updated occasionally, safe to cache
- **HTML files** (1800s / 30min for dev, 3600s / 1h for staging, 1h for prod) — Updated more frequently
- **Static assets** — Longer cache times for images, CSS, JS if added

### Security Headers
- **X-Content-Type-Options: nosniff** — Prevent MIME type sniffing
- **X-Frame-Options: DENY** — Prevent clickjacking
- **Referrer-Policy** — Protect privacy
- **HSTS** (production only) — Enforce HTTPS

### URL Rewriting
- Requests to directories without files → `index.html`
- Preserves direct access to `.well-known/mcp.json` and `/llms.txt`

## DNS Configuration

Ensure DNS records point to VPS:

```bash
# Add A records to your DNS provider:
mcp.docs.dev.orignagta.ca      A   204.168.137.16
mcp.docs.staging.orignagta.ca  A   204.168.137.16
mcp.docs.orignagta.ca          A   204.168.137.16
```

## SSL Certificates

Caddy automatically handles SSL via Let's Encrypt for all configured domains.

**Verify certificate:**
```bash
curl -vI https://mcp.docs.orignagta.ca
# Should show certificate details from Let's Encrypt
```

## Monitoring

### Check logs
```bash
journalctl -u caddy -f
```

### Monitor uptime
```bash
watch -n 5 'curl -s -o /dev/null -w "%{http_code}" https://mcp.docs.orignagta.ca && echo " OK"'
```

### Test discovery
```bash
curl -s https://mcp.docs.orignagta.ca/.well-known/mcp.json | jq .version
# Should output: "1.0.0"
```

## Troubleshooting

### Caddy won't reload
```bash
# Validate syntax first
caddy validate --config /etc/caddy/Caddyfile

# Check for permission errors
ls -la /var/www/orignagta/mcp-docs/
```

### DNS not resolving
```bash
nslookup mcp.docs.orignagta.ca
# Should resolve to 204.168.137.16
```

### Certificate issues
```bash
# Force certificate renewal
caddy stop
caddy run --config /etc/caddy/Caddyfile
```

## Deployment Workflow

1. **Make changes locally**
   ```bash
   # Edit HTML, markdown, or JSON files in mcp-docs/
   ```

2. **Deploy to VPS**
   ```bash
   ./scripts/deploy_mcp_docs.sh dev  # or staging/prod
   ```

3. **Reload Caddy**
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@204.168.137.16 "caddy reload --config /etc/caddy/Caddyfile"
   ```

4. **Verify**
   ```bash
   curl https://mcp.docs.orignagta.ca/
   ```

## File Structure on VPS

```
/var/www/orignagta/mcp-docs/
├── dev/current/
│   ├── index.html
│   ├── llms.txt
│   ├── .well-known/
│   │   └── mcp.json
│   ├── api-reference/
│   │   ├── index.html
│   │   └── architecture.html
│   ├── getting-started.html
│   └── assets/
├── staging/current/
│   └── [same structure]
└── prod/current/
    └── [same structure]
```

---

**Last Updated**: March 2026  
**Caddy Version**: v2.7+ required
