# VPS Deployment & Operations Guide

## 1. VPS Architecture

| Property | Value |
|----------|-------|
| Provider | Hetzner CAX21 (ARM64) |
| IP | 204.168.137.16 |
| SSH | `ssh -i ~/.ssh/id_ed25519 root@204.168.137.16` |
| Docker root | `/opt/orignabase/` |
| Web root | `/var/www/orignagta/` |
| OS | Ubuntu (Docker Compose) |

All services run as Docker containers managed by `docker compose` in `/opt/orignabase/`.

---

## 2. Multi-Environment Setup

| Service | Port | Env File | Database | Memory Limit |
|---------|------|----------|----------|-------------|
| orignabase-prod | 8080 | .env.prod | main | 512M |
| orignabase-dev | 8081 | .env.dev | dev | 256M |
| orignabase-staging | 8082 | .env.staging | staging | 256M |
| postgresql | 8000 | — | all (namespaced) | — |
| meilisearch | 7700 | — | — | — |
| glitchtip | 8010 loopback | `/opt/glitchtip/.env` | glitchtip | — |
| caddy | 80/443 | Caddyfile | — | — |

- Dev has `OB_TEST_MODE=1` (disables rate limits for testing).
- Prod does NOT have test mode enabled.

---

## 3. Domain Routing (Caddy)

Caddy handles TLS termination (auto Let's Encrypt) and reverse proxying.

### API Routes

| Domain | Target |
|--------|--------|
| `api.orignagta.ca` | `orignabase-prod:8080` |
| `api.dev.orignagta.ca` | `orignabase-dev:8081` |
| `api.staging.orignagta.ca` | `orignabase-staging:8082` |

### Static Web Routes

| Domain | Document Root |
|--------|--------------|
| `orignagta.ca` | `/var/www/orignagta/production/current` |
| `dev.orignagta.ca` | `/var/www/orignagta/dev/current` |
| `staging.orignagta.ca` | `/var/www/orignagta/staging/current` |

### Observability Routes

| Domain | Target |
|--------|--------|
| `glitchtip.orignagta.ca` | `glitchtip:8000` via `orignabase_default` Docker network |

---

## 4. Flutter Web Deployment

### Build

```bash
# Dev
flutter build web --debug \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
  --dart-define=FORCE_SEMANTICS=true

# Staging
flutter build web --profile \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=ORIGNABASE_URL=https://api.staging.orignagta.ca \
  --dart-define=FORCE_SEMANTICS=true

# Production
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=ORIGNABASE_URL=https://api.orignagta.ca
```

### Deploy via rsync

```bash
# Dev
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/dev/current/

# Staging
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/staging/current/

# Production
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/production/current/
```

The `current/` directory is the live symlink target. Caddy serves directly from it.

---

## 5. Stripe Webhooks

| Environment | Endpoint ID | URL | Signing Secret |
|-------------|-------------|-----|----------------|
| Dev | `we_1TBt7uPPD6r8xGIz9VzZXiXP` | `https://api.dev.orignagta.ca/stripe/webhook` | Stored in `.env.dev` on VPS |
| Staging | `we_1TBt8BPPD6r8xGIzSpeuwv4P` | `https://api.staging.orignagta.ca/stripe/webhook` | Stored in `.env.staging` on VPS |
| Production | Live mode endpoint | `https://api.orignagta.ca/stripe/webhook` | Stored in `.env.prod` on VPS |

- All webhook secrets are stored in VPS `.env` files (never in git).
- Webhook signature (HMAC) is verified on every incoming request.
- Replay protection rejects events older than 300 seconds.
- Events are deduplicated via the `webhook_events` collection.

---

## 6. Database Access

### PostgreSQL Credentials

| Property | Value |
|----------|-------|
| Username | `root` |
| Password | `orignabase_root_2026` |
| Namespace | `orignabase` |
| DB (prod) | `main` |
| DB (dev) | `dev` |
| DB (staging) | `staging` |

### Access via Docker

```bash
# Interactive PostgreSQL shell
docker exec -it postgresql psql -U orignabase -d orignabase

# Quick query
docker exec postgresql psql -U orignabase -d orignabase -c "SELECT count(*) FROM users;"
```

### Meilisearch

```bash
# Check health
curl http://localhost:7700/health

# Query (from VPS)
  http://localhost:7700/indexes/products/search \
  -d '{"q": "test"}'
```

---

## 7. Operations Commands

### Rebuild & Restart a Service

```bash
cd /opt/orignabase

# Single service
docker compose build orignabase-dev && docker compose up -d orignabase-dev

# All services
docker compose up -d --build

# Restart without rebuild
docker compose restart orignabase-prod
```

### Health Checks

```bash
curl https://api.orignagta.ca/health
curl https://api.dev.orignagta.ca/health
curl https://api.staging.orignagta.ca/health
```

### Tail Logs

```bash
# Follow specific service
docker logs -f orignabase-dev --tail 100

# All services
docker compose logs -f --tail 50
```

### Clear Rate Limits (Dev)

Dev has `OB_TEST_MODE=1` so rate limits are already disabled. For staging/prod, restart the service to clear in-memory rate limit state:

```bash
docker compose restart orignabase-staging
```

### Wipe Dev Database

```bash
# Wipe dev database
docker exec postgresql psql -U orignabase -d orignabase -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Then restart dev to re-initialize schema
docker compose restart orignabase-dev
```

---

## 8. Backup & Recovery

### Backup

```bash
# Backup script location
/opt/orignabase/scripts/backup.sh

# Manual PostgreSQL export
docker exec postgresql pg_dump -U orignabase orignabase > /opt/orignabase/backups/main-$(date +%Y%m%d).sql
```

### Cron Schedule

```
0 3 * * * /opt/orignabase/scripts/backup.sh >> /var/log/orignabase-backup.log 2>&1
```

### Restore

```bash
docker exec -i postgresql psql -U orignabase orignabase < /opt/orignabase/backups/main-20260323.sql
```

---

## 9. CI/CD Workflows

### ci-flutter-web.yml

- **Triggers**: Push to `main`, PRs
- **Jobs**: `flutter analyze --no-fatal-infos` + `flutter test --exclude-tags golden`
- **Secrets**: `STRIPE_TEST_KEY`, `MAIL_USERNAME`, `MAIL_PASSWORD`

### cd-e2e.yml

- **Triggers**: Merge to `main`
- **Jobs**: Flutter web build (dev) -> rsync to VPS -> Bun E2E tests
- **Secrets**: SSH key, `STRIPE_TEST_KEY`

### ci-rust.yml

- **Triggers**: Changes to `orignabase/` directory
- **Jobs**: `cargo clippy -D warnings` + `cargo test`

---

## 10. Secrets Management

### VPS .env Files

Located at `/opt/orignabase/.env.{prod,dev,staging}` with `chmod 600` (root-only read).

Contents include:
- `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET`
- `POSTGRESQL_URL` / `POSTGRESQL_USER` / `POSTGRESQL_PASS`
- `MEILISEARCH_URL` / `MEILISEARCH_KEY`
- `POSTAL_API_KEY` / `POSTAL_SECRET_KEY`
- `JWT_PRIVATE_KEY_PATH` / `JWT_PUBLIC_KEY_PATH`
- `OB_TEST_MODE` (dev only)

### GitHub Actions Secrets

| Secret | Purpose |
|--------|---------|
| `STRIPE_TEST_KEY` | Stripe test mode key for CI |
| `MAIL_USERNAME` | CI failure notification email |
| `MAIL_PASSWORD` | CI failure notification email |

### macOS Keychain (Local Dev)

```bash
get-secret KEY_NAME    # Read from vault
set-secret KEY_NAME VALUE  # Write to vault
list-secrets           # List available keys
```

Keychain file: `~/.secrets/vault.keychain-db` (never access directly).

### Rules

- Secrets are NEVER committed to git.
- No API keys in `dart-define` (use for non-secret config only).
- No credentials in Flutter source code.

---

## 11. Security

### Firewall (UFW)

```
22/tcp    LIMIT    # SSH with brute-force protection
80/tcp    ALLOW    # HTTP (Caddy redirects to HTTPS)
443/tcp   ALLOW    # HTTPS
```

All other ports are blocked. PostgreSQL (8000) and Meilisearch (7700) are internal only.

### TLS

- Managed automatically by Caddy via Let's Encrypt.
- Certificates auto-renew before expiration.
- All HTTP traffic redirected to HTTPS.

### Rate Limiting

| Endpoint | Limit |
|----------|-------|
| Auth (login/register) | 5 req/min |
| Checkout | 10 req/min |
| Search | 30 req/min |
| General API | 60 req/min |

Enforced by `tower_governor` in OrignaBase. Dev environment has rate limits disabled (`OB_TEST_MODE=1`).

### SSH Hardening

- Key-only authentication (password auth disabled).
- Root login via key only.
- Fail2ban active for SSH brute-force protection.

---

## 12. Monitoring

### Health Endpoints

| Service | Endpoint |
|---------|----------|
| OrignaBase Prod | `https://api.orignagta.ca/health` |
| OrignaBase Dev | `https://api.dev.orignagta.ca/health` |
| OrignaBase Staging | `https://api.staging.orignagta.ca/health` |
| PostgreSQL | `http://localhost:5432/health` (internal) |
| Meilisearch | `http://localhost:7700/health` (internal) |

### Docker Healthchecks

Each service in `docker-compose.yml` has a `healthcheck` directive:
- OrignaBase: `curl -f http://localhost:{port}/health`
- PostgreSQL: `curl -f http://localhost:5432/health`
- Meilisearch: `curl -f http://localhost:7700/health`

Unhealthy containers are automatically restarted by Docker.

### Error Tracking

- **GlitchTip**: self-hosted error tracking on the VPS, pinned to Docker image `glitchtip/glitchtip:6.1.6`.
- Flutter sends events through the Sentry-compatible SDK to the configured GlitchTip DSN.
- Errors are tagged with environment (dev/staging/production).
- Critical errors trigger alerts.
- The app reads `glitchtip_dsn` from OrignaBase remote config, with a temporary fallback to legacy `sentry_dns`.

### GlitchTip Deployment

Repo-managed files:

- `infra/glitchtip/compose.yml`
- `infra/glitchtip/.env.example`

Deploy/update on the VPS:

```bash
mkdir -p /opt/glitchtip
rsync -av infra/glitchtip/ root@204.168.137.16:/opt/glitchtip/
ssh root@204.168.137.16
cd /opt/glitchtip
cp .env.example .env
openssl rand -hex 32  # paste into SECRET_KEY
docker compose pull
docker compose up -d
```

Caddy route:

```caddy
glitchtip.orignagta.ca {
  reverse_proxy glitchtip:8000
}
```

After the first admin account is created, keep `ENABLE_USER_REGISTRATION=false`.

### Contact

- `support@orignagta.ca` via Cloudflare Email Routing forwards to `yuniorrodriguezo460@gmail.com`.
