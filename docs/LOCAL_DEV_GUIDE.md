# Local Development Guide

Practical setup for OrignaGTA (Flutter + OrignaBase Rust backend). Written to prevent AI agents and humans from making destructive mistakes.

---

## 1. Prerequisites

| Tool | Install | Notes |
|------|---------|-------|
| macOS (Apple Silicon) | -- | 8GB RAM constraint: never run parallel heavy processes |
| Homebrew | `https://brew.sh` | Package manager |
| Flutter SDK | `/Users/yuniorrodriguezosorio/flutter/bin/flutter` | NOT in PATH for bash; use absolute path or alias |
| Rust toolchain | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` | `rustup`, `cargo`, `clippy`, `rustfmt` |
| Colima + Docker | `brew install colima docker` | Lightweight Docker runtime for macOS |
| Stripe CLI | `/opt/homebrew/bin/stripe` | Config: `~/.config/stripe/config.toml` |
| Bun | `brew install oven-sh/bun/bun` | E2E test runner |
| rust-analyzer | `rustup component add rust-analyzer` | IDE support; symlinked at `~/.cargo/bin/rust-analyzer` |

**RAM rule**: sequential only. Build -> test -> deploy. Never run `flutter build` + `cargo build` simultaneously. Never run emulators.

---

## 2. Environment Overview

| Environment | `baseUrl` (web) | `orignabaseUrl` (API) | Flag |
|-------------|-----------------|----------------------|------|
| emulator | `http://localhost:5001` | `http://localhost:8080` | `--dart-define=ENVIRONMENT=emulator` |
| dev | `https://dev.orignagta.ca` | `https://api.dev.orignagta.ca` | `--dart-define=ENVIRONMENT=dev` |
| staging | `https://staging.orignagta.ca` | `https://api.staging.orignagta.ca` | `--dart-define=ENVIRONMENT=staging` |
| production | `https://orignagta.ca` | `https://api.orignagta.ca` | `--dart-define=ENVIRONMENT=production` |

Config file: `origna_gta/lib/utils/env_config.dart`

You can override the API URL directly: `--dart-define=ORIGNABASE_URL=http://localhost:8080`

---

## 3. Docker Compose (Full Local Stack)

Starts SurrealDB, Meilisearch, OrignaBase, and Caddy in containers.

```bash
colima start
cd orignabase/docker
cp .env.dev .env          # REQUIRED — compose reads .env, not .env.dev
docker compose up -d
```

### Services

| Service | Host Port | Container Port | Memory Limit |
|---------|-----------|---------------|-------------|
| SurrealDB v2 | `127.0.0.1:8000` | 8000 | 512M |
| Meilisearch v1.12 | `127.0.0.1:7700` | 7700 | 256M |
| OrignaBase | `127.0.0.1:8080` | 8080 | 512M |
| Caddy 2.8 | `80`, `443` | 80, 443 | 128M |

### Volumes

| Volume | Purpose |
|--------|---------|
| `surrealdb_data` | SurrealDB RocksDB persistence |
| `meili_data` | Meilisearch index data |
| `caddy_data` | TLS certificates (do NOT delete) |
| `caddy_config` | Caddy runtime config |

### Health Checks

All services have 30s-interval health checks with 3 retries and 40s start period:
- SurrealDB: `curl http://localhost:8000/health`
- Meilisearch: `curl http://localhost:7700/health`
- OrignaBase: `curl http://localhost:8080/health`
- Caddy: `wget --spider http://localhost:80/`

OrignaBase depends on both SurrealDB and Meilisearch being healthy before starting.

### GOTCHA: Docker Internal DNS

Inside Docker, `OB_DATABASE__ENDPOINT` is `ws://surrealdb:8000` and `OB_SEARCH__URL` is `http://meilisearch:7700`. These use Docker DNS service names, NOT `localhost`. The `.env.dev` file has this set correctly. If you create a custom `.env`, use Docker service names for inter-container communication.

### Default Credentials (dev)

| Service | Username | Password |
|---------|----------|----------|
| SurrealDB | `root` | `root` |
| Meilisearch | -- | `dev-meili-key-insecure` |
| OrignaBase JWT | -- | `dev-jwt-secret-not-for-production` |

---

## 4. Embedded OrignaBase (No Docker)

Runs OrignaBase with an embedded SurrealDB (RocksDB on disk). Lighter weight, no containers needed.

```bash
cd orignabase
cargo run -- serve
```

Configuration is read from `orignabase/orignabase.toml`:

```toml
host = "0.0.0.0"
port = 8080

[database]
endpoint = "rocksdb://./local_test_data"
namespace = "orignabase"
name = "main"

[auth]
jwt_secret = "CHANGE_ME_IN_PRODUCTION"
access_token_ttl_secs = 900
refresh_token_ttl_secs = 604800

[search]
url = "http://localhost:7700"
api_key = "test-meili-key"
```

Environment variables with `OB_*` prefix override TOML values.

### Search Features Require Meilisearch

Embedded mode does NOT include Meilisearch. If you need search, run it separately:

```bash
docker run -d --name meilisearch -p 7700:7700 \
  -e MEILI_MASTER_KEY=test-meili-key \
  getmeili/meilisearch:v1.12
```

### GOTCHA: SurrealDB ws:// Prefix

When using the SurrealDB WebSocket client (not embedded RocksDB), use `host:port` format ONLY. Adding the `ws://` prefix causes a silent hang. The embedded `rocksdb://` prefix is correct and different.

---

## 5. Stripe Webhook Forwarding

Forward Stripe test webhooks to your local OrignaBase:

```bash
/opt/homebrew/bin/stripe listen --forward-to localhost:8080/api/webhooks/stripe
```

The CLI will print a signing secret like `whsec_...`. Copy it to your `.env`:

```
OB_SECRETS__STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_REDACTED
```

Or set it as an environment variable when running embedded:

```bash
OB_SECRETS__STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_REDACTED cargo run -- serve
```

Config file: `~/.config/stripe/config.toml`

Test cards (dev only):
- Success: `4242 4242 4242 4242`
- Requires auth: `4000 0025 0000 3155`
- Decline: `4000 0000 0000 9995`

---

## 6. Running Flutter

```bash
cd origna_gta

# Against local OrignaBase (embedded or Docker)
flutter run --dart-define=ENVIRONMENT=emulator

# Against remote dev server
flutter run --dart-define=ENVIRONMENT=dev

# With explicit API URL override
flutter run --dart-define=ENVIRONMENT=emulator --dart-define=ORIGNABASE_URL=http://localhost:8080

# Web build for deployment
flutter build web --debug \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
  --dart-define=FORCE_SEMANTICS=true
```

Widget previews (ALWAYS use the script, never `flutter widget-preview start`):

```bash
cd origna_gta
./start-preview.sh
```

---

## 7. Test Commands

### Flutter Unit/Widget (no backend needed)

```bash
cd origna_gta
flutter analyze --no-fatal-infos
flutter test --exclude-tags golden
```

Always run analyze first — it catches compile errors faster than test runner.

### Flutter Live Tests (needs running backend)

```bash
cd origna_gta
flutter test \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=dev \
  --exclude-tags golden
```

Without `RUN_ORIGNABASE_LIVE_TESTS=true`, live integration tests silently skip.

### Rust Unit Tests

```bash
cd orignabase
cargo test
cargo clippy -- -D warnings    # lint — must pass before commit
```

Single crate:

```bash
cargo test -p ob-auth
cargo test -p ob-graphql
```

### Rust Integration Tests (needs running server)

Integration tests are marked `#[ignore]` and require a running OrignaBase instance:

```bash
cd orignabase

# Against local server
OB_TEST_URL=http://localhost:8080 cargo test -- --ignored

# Against remote dev server
OB_TEST_URL=https://api.dev.orignagta.ca cargo test -- --ignored
```

### OrignaBase Flutter SDK Tests

```bash
cd orignabase/sdks/flutter/orignabase

# Unit tests (mocked)
flutter test

# Live integration tests (needs running server)
OB_TEST_URL=https://api.dev.orignagta.ca dart test test/live_integration_test.dart
```

### E2E Tests (Bun + agent-browser)

```bash
cd e2e
bun test specs/phase1-api/

# Type check
bun x tsc --noEmit
```

Kill orphan Chrome processes before running E2E:

```bash
pkill -f "Google Chrome.*--headless" 2>/dev/null || true
```

---

## 8. Test Accounts (dev DB)

| Role | Email | Password | SurrealDB ID |
|------|-------|----------|-------------|
| Admin | `e2e-admin@test.origna.ca` | `REDACTED_TEST_PASSWORD` | `users:jtcns172qplow96s2bjq` |
| Seller | `e2e-seller@test.origna.ca` | `REDACTED_TEST_PASSWORD` | `users:7z9ggqkw83txgx5p9k8t` |
| Buyer | `e2e-buyer@test.origna.ca` | `REDACTED_TEST_PASSWORD` | `users:ele88v13dnos5axa3zdr` |

Additional seed accounts: `buyer1@example.com`, `buyer2@example.com`, `seller1@example.com`, `seller2@example.com`, `admin@example.com` (passwords: `REDACTED_TEST_PASSWORD` / `AdminPass123!`).

Legacy dev accounts (may still work): Admin `yr62813@gmail.com`, Seller `yuniorrodriguezo4601@yahoo.com`, Buyer `yuniorrodriguezo460@gmail.com`.

---

## 9. ChromaDB (Knowledge Base)

Optional. Used by the `chromadb-search` skill for AI-assisted research (O'Reilly books, papers).

```bash
docker run -d --name chromadb -p 8100:8000 chromadb/chroma:latest
```

Accessible at `http://localhost:8100`. Not required for app development.

---

## 10. Gotchas

| # | Gotcha | Impact | Fix |
|---|--------|--------|-----|
| 1 | `flutter widget-preview start` | Broken preview server | Always use `./start-preview.sh` |
| 2 | SurrealDB `ws://` prefix in embedded mode | Silent hang, no error | Use `host:port` only (e.g., `surrealdb:8000`), never `ws://surrealdb:8000` |
| 3 | `#[ignore]` on Rust integration tests | Tests silently skipped with `cargo test` | Use `cargo test -- --ignored` with `OB_TEST_URL` set |
| 4 | Missing `RUN_ORIGNABASE_LIVE_TESTS=true` | Flutter live tests silently skip | Add `--dart-define=RUN_ORIGNABASE_LIVE_TESTS=true` |
| 5 | Docker compose needs `.env` copy | Compose fails with empty vars | `cp .env.dev .env` before `docker compose up` |
| 6 | Docker internal DNS vs localhost | OrignaBase can't reach SurrealDB | Inside Docker: `ws://surrealdb:8000`. Outside Docker: `ws://localhost:8000` |
| 7 | `cargo build --release` on 8GB RAM | OOM kill (full LTO + codegen-units=1) | Add 4GB swap first: `sudo dd if=/dev/zero of=/swapfile bs=1m count=4096 && sudo mkswap /swapfile && sudo swapon /swapfile` |
| 8 | Sequential image compression | Slow uploads if done in a for loop | Use `Future.wait()` for parallel compression, not sequential `for` loops |
| 9 | Deleting `caddy_data` volume | Loses TLS certificates, rate-limited by Let's Encrypt | Never `docker volume rm caddy_data` unless you understand the re-issuance delay |
| 10 | Test account emails don't match seeded DB | Auth failures in tests | Use exact emails from the test accounts table above; reseed if DB was wiped |
| 11 | `flutter test --coverage` on single file | Overwrites `lcov.info` for entire project | Never run coverage on a single file; always full suite |
| 12 | Parallel `flutter build` + `cargo build` | OOM on 8GB RAM | Sequential only: build one, then the other |
| 13 | `print()` in Dart code | Fails quality gate, blocks commit | Use `AppLogger.i()` / `AppLogger.e()` |
| 14 | `Colors.blue` or hex literals | Fails code review | Use `DesignTokens.*` constants |
| 15 | `setState()` in screens | Architecture violation | Use Riverpod providers |
| 16 | Money as `double` | Rounding errors in pricing | Always integer cents (`priceCents`, `subtotalCents`, etc.) |
| 17 | `ref.watch()` without `.select()` | Unnecessary widget rebuilds, jank | Use `ref.watch(provider.select((s) => s.field))` for targeted rebuilds |

---

## 11. Quick Start Checklist

### Local Development (Embedded OrignaBase)

1. Install prerequisites (Flutter, Rust, Stripe CLI)
2. Clone repo: `git clone` into `~/Documents/GitHub/origna_gta`
3. Install Flutter deps: `cd origna_gta && flutter pub get`
4. (Optional) Start Meilisearch for search: `docker run -d --name meilisearch -p 7700:7700 -e MEILI_MASTER_KEY=test-meili-key getmeili/meilisearch:v1.12`
5. Start OrignaBase: `cd orignabase && cargo run -- serve`
6. (Optional) Forward Stripe webhooks: `/opt/homebrew/bin/stripe listen --forward-to localhost:8080/api/webhooks/stripe`
7. Run Flutter: `cd origna_gta && flutter run --dart-define=ENVIRONMENT=emulator`
8. Run tests: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden`

### Remote Dev (No Local Backend)

1. Install Flutter
2. Clone repo
3. Install Flutter deps: `cd origna_gta && flutter pub get`
4. Run Flutter against dev: `cd origna_gta && flutter run --dart-define=ENVIRONMENT=dev`
5. Run tests: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden`
6. (Optional) Run live tests: `flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev --exclude-tags golden`

### Docker Compose (Full Stack)

1. Install prerequisites (Flutter, Rust, Colima, Docker)
2. Start Colima: `colima start`
3. Copy env: `cd orignabase/docker && cp .env.dev .env`
4. Start stack: `docker compose up -d`
5. Wait for health checks: `docker compose ps` (all should show "healthy")
6. (Optional) Forward Stripe webhooks: `/opt/homebrew/bin/stripe listen --forward-to localhost:8080/api/webhooks/stripe`
7. Run Flutter: `cd origna_gta && flutter run --dart-define=ENVIRONMENT=emulator`
8. Run Rust tests against local: `cd orignabase && OB_TEST_URL=http://localhost:8080 cargo test -- --ignored`

### Before Every Commit

```bash
cd origna_gta
flutter analyze --no-fatal-infos
flutter test --exclude-tags golden

# If Rust changed:
cd orignabase
cargo clippy -- -D warnings
cargo test
```

All must pass with zero errors, zero warnings, zero skips. No exceptions.
