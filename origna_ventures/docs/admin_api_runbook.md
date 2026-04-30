# OrignaVentures Admin API Runbook

Last verified: 2026-04-30

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

### 1. Send admin email test

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
    "body": "Postal integration is working."
  }'
```

Success response:

```json
{"success": true}
```

## Related self-hosted APIs in the Ventures plan

Ventures should continue to describe these dependencies as self-hosted Origna infrastructure:

| API | Owner | Used by Ventures | Notes |
|-----|-------|------------------|-------|
| Postal email | Origna VPS | Contact confirmations, support notifications, service/payment emails, `/api/email/test` | Postal response bodies stay server-side; public/admin endpoints return sanitized success/failure only. |
| Meilisearch search | OrignaBase VPS | Product/search proof for OrignaGTA demos and investor deck claims | Search checks run through OrignaBase; do not add hosted Algolia/Elastic Cloud to the plan. |
| GlitchTip error logging | Origna VPS | Error visibility for Flutter and backend incidents, support/debug IDs, `error_events` persistence | Flutter uses the Sentry-compatible SDK with the self-hosted GlitchTip DSN from OrignaBase public config. |

Operational check bundle:

```bash
cd e2e
bun test specs/phase1-api/selfhosted-integrations.spec.ts specs/phase6-stripe/origna-ventures-contact-live.spec.ts
```

## Smoke checks

### Health

```bash
curl -s "$ORIGNA_VENTURES_API_BASE_URL/health"
```

### Verify admin protection

Should return `401`:

```bash
curl -i -s -X POST \
  -H "Content-Type: application/json" \
  "$ORIGNA_VENTURES_API_BASE_URL/email/test" \
  -d '{"to_email":"support@orignaventures.ca","subject":"Unauthorized test","body":"blocked"}'
```

Should return `200`:

```bash
curl -i -s -X POST \
  -H "Content-Type: application/json" \
  "$ORIGNA_VENTURES_API_BASE_URL/email/test" \
  -d '{"to_email":"support@orignaventures.ca","subject":"Authorized test","body":"ok"}'
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

Verified on 2026-04-23:

- `/api/email/test` returns `401` without bearer auth
- `/api/email/test` returns `200` with the configured bearer token
- backend health returns `{"status":"ok"}`

Verified on 2026-04-30:

- Ventures plan/runbook keeps Postal, Meilisearch, and GlitchTip documented as self-hosted APIs.
- Focused E2E ownership remains:
  - Postal: `specs/phase6-stripe/origna-ventures-contact-live.spec.ts`
  - Meilisearch and GlitchTip: `specs/phase1-api/selfhosted-integrations.spec.ts`
