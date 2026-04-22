# OrignaVentures Admin API Runbook

Last verified: 2026-04-21

## Purpose

This runbook documents the protected OrignaVentures admin endpoints and the safe way to call them.

Base URL:

```bash
export ORIGNA_VENTURES_API_BASE_URL="https://api.orignaventures.ca/api"
```

## Authentication

Admin endpoints require a bearer token from `ORIGNA_ADMIN_API_KEY`.

```bash
export ORIGNA_VENTURES_ADMIN_API_KEY="<admin-api-key>"
```

Auth header format:

```bash
```

Expected behavior:

- no bearer token → `401 Unauthorized`
- invalid bearer token → `401 Unauthorized`
- missing server-side admin key config → `503 Admin API not configured`

## Endpoints

### 1. List contracts

Route:

```text
GET /api/contracts
```

Example:

```bash
curl -s \
  "$ORIGNA_VENTURES_API_BASE_URL/contracts"
```

Example response shape:

```json
{
  "contracts": [
    {
      "id": "ovc_...",
      "service_code": "origna_launch",
      "client_company": "Origna Ventures Services",
      "client_email": "support@orignaventures.ca",
      "payer_email": "support@orignaventures.ca",
      "github_username": "",
      "status": "paid",
      "repo_unlock_status": "manual",
      "repo_unlock_error": "",
      "github_invitation_id": "",
      "created_at": "2026-04-21T...Z"
    }
  ]
}
```

### 2. Send admin email test

Route:

```text
POST /api/email/test
```

Notes:

- requires admin bearer token
- rate limited per IP
- body is HTML-escaped on the server side

Example:

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  "$ORIGNA_VENTURES_API_BASE_URL/email/test" \
  -d '{
    "to_email": "support@orignaventures.ca",
    "subject": "Admin API smoke test",
    "body": "Mailjet integration is working."
  }'
```

Success response:

```json
{"success": true}
```

## Smoke checks

### Health

```bash
curl -s "$ORIGNA_VENTURES_API_BASE_URL/health"
```

### Verify admin protection

Should return `401`:

```bash
curl -i -s "$ORIGNA_VENTURES_API_BASE_URL/contracts"
```

Should return `200`:

```bash
curl -i -s \
  "$ORIGNA_VENTURES_API_BASE_URL/contracts"
```

## Secrets handling

Do not commit the admin key.

Recommended storage:

- VPS runtime env: `/opt/origna_ventures/backend/.env`
- machine memory: `~/.claude/TOOLS.md`
- shell session only: exported environment variable

Avoid:

- hardcoding bearer tokens in scripts committed to git
- pasting tokens into screenshots or issue trackers
- logging full curl commands that contain the token

## Runtime config that must exist on the VPS

```env
ORIGNA_ADMIN_API_KEY=...
TRUSTED_PROXY_COUNT=1
```

Backend code also supports:

```env
ORIGNA_TRUSTED_PROXY_COUNT=1
```

## Verified live status

Verified on 2026-04-21:

- `/api/contracts` returns `401` without bearer auth
- `/api/contracts` returns `200` with the configured bearer token
- backend health returns `{"status":"ok"}`
