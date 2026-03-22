# Origna GTA — Repo Map

Last updated: 2026-03-22

## Overview

Unified monorepo for Origna GTA, a Canada-first multi-vendor e-commerce platform. Frontend and backend live in the same repo.

| Layer | Directory | Technology |
|-------|-----------|-----------|
| Mobile/Web frontend | `origna_gta/` | Flutter 3.x + Dart, Riverpod, Freezed |
| Backend API | `orignabase/` | OrignaBase (Rust, hosted on VPS 204.168.137.16) |
| Database | SurrealDB v2 (on VPS, via OrignaBase) |
| Search | Meilisearch v1.12 (on VPS, via OrignaBase) |
| Payments | Stripe (Checkout + Connect + webhooks) |
| Bot protection | Cloudflare Turnstile |
| Web reverse proxy | Caddy (on VPS) |
| CI | GitHub Actions |
| E2E | Playwright (TypeScript) + Bun agent-browser |

No Firebase. No Cloud Functions. No Firestore. All backend is OrignaBase on the VPS.

---

## Directory Structure

```
origna_gta/                        # repo root (monorepo: frontend + backend)
├── origna_gta/                    # Flutter app (frontend)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── origna_app.dart
│   │   ├── admin/                 # Admin panel widgets
│   │   ├── config/                # App config (env, URLs)
│   │   ├── core/
│   │   │   ├── constants/         # validation_constants.dart
│   │   │   ├── errors/            # AppError types
│   │   │   ├── providers.dart     # Riverpod providers entry
│   │   │   ├── orignabase_provider.dart
│   │   │   ├── repositories/      # Data access layer
│   │   │   ├── routes.dart        # GoRouter routes
│   │   │   ├── schema/            # schema_constants.dart (field name source of truth)
│   │   │   └── theme_provider.dart
│   │   ├── features/              # Feature-scoped logic (viewmodels, providers)
│   │   │   ├── admin/
│   │   │   ├── auth/
│   │   │   ├── cart/
│   │   │   ├── chat/
│   │   │   ├── checkout/
│   │   │   ├── home/
│   │   │   ├── notifications/
│   │   │   ├── orders/
│   │   │   ├── products/
│   │   │   ├── profile/
│   │   │   ├── qa/
│   │   │   ├── seller/
│   │   │   ├── subscription/
│   │   │   └── terms/
│   │   ├── models/                # Freezed data models
│   │   │   ├── models.dart        # barrel export
│   │   │   ├── qa_model.dart
│   │   │   └── generated/        # Freezed generated files
│   │   ├── screens/               # UI screens (see list below)
│   │   ├── services/              # Platform/integration services
│   │   ├── widgets/               # Shared widgets (see list below)
│   │   └── utils/                 # Shared helpers, responsive layout
│   ├── test/                      # Unit + widget + live tests
│   │   ├── unit/                  # 131 unit test files
│   │   ├── widget/                # 67 widget test files
│   │   ├── screens/               # 23 screen test files
│   │   ├── live/                  # 30 live/integration tests (gated)
│   │   ├── golden/                # Golden tests (6 tests)
│   │   └── helpers/               # Test utilities (EMPTY — planned)
│   ├── integration_test/          # Flutter integration tests (7 files)
│   └── pubspec.yaml
├── e2e/                           # Playwright E2E (TypeScript + agent-browser)
│   ├── specs/
│   │   ├── phase1-api/            # 33 API smoke tests
│   │   ├── phase2-smoke/          # 13 UI quality tests
│   │   ├── phase3-auth-nav/       # 11 auth flow tests
│   │   ├── phase4-product-flows/  # 21 product tests
│   │   ├── phase5-complex-flows/  # 23 cart/order/seller tests
│   │   └── phase6-stripe/         # 13 payment tests
│   ├── lib/
│   │   └── config.ts              # Test accounts, Stripe tokens, URLs
│   └── run-tests.sh               # Parallel runner (4 browsers, 10 API)
├── e2e-agent-browser/             # Bun-based agent browser E2E (mirrors e2e/)
│   ├── specs/                     # Same 114 specs as e2e/
│   ├── lib/config.ts
│   └── run-tests.sh
├── orignabase/                    # Rust backend (OrignaBase BaaS)
│   ├── Cargo.toml                 # Workspace manifest (16 crates)
│   ├── crates/
│   │   ├── orignabase/            # Binary entry point, CLI, server assembly
│   │   ├── ob-core/               # Config, AppState, error types
│   │   ├── ob-database/           # SurrealDB client, CRUD, query translator
│   │   ├── ob-auth/               # JWT, Argon2id, OAuth, MFA/TOTP
│   │   ├── ob-graphql/            # Dynamic GraphQL schema + resolvers
│   │   ├── ob-security/           # Rules DSL parser (pest) + evaluator
│   │   ├── ob-realtime/           # WebSocket subscriptions, presence
│   │   ├── ob-storage/            # Local filesystem, S3/R2, signed URLs
│   │   ├── ob-search/             # Meilisearch client + auto-sync
│   │   ├── ob-functions/          # WASM runtime (wasmi), triggers
│   │   ├── ob-analytics/          # Privacy-first event tracking
│   │   ├── ob-admin/              # Schema mgmt, HTML dashboard
│   │   ├── ob-notifications/      # FCM push proxy, device tokens
│   │   ├── ob-handlers/           # Business logic (Stripe, orders, chat)
│   │   └── ob-mcp/                # MCP server (JSON-RPC 2.0)
│   └── sdks/flutter/orignabase/   # OrignaBase Flutter/Dart SDK
├── scripts/
│   ├── deploy_web.sh              # VPS web deploy (staged releases)
│   ├── run_quality_gate.sh        # 80% coverage threshold
│   ├── deploy_mcp_docs.sh         # MCP docs deploy to VPS
│   └── add-cloudflare-dns.sh      # Cloudflare DNS management
├── docs/
│   ├── REPO_MAP.md                # This file
│   └── plans/                     # Architecture plans
├── docs-site/                     # Next.js 14 + Nextra documentation site
├── .claude/                       # Claude Code configuration
│   ├── settings.json              # Hooks (PreToolUse, PostToolUse, Stop)
│   ├── settings.local.json        # MCP permissions, tool whitelist
│   ├── LEARNED.md                 # Cross-session knowledge archive
│   ├── rules/                     # 6 domain rules (auto-loaded)
│   │   ├── flutter.md
│   │   ├── backend.md
│   │   ├── testing.md
│   │   ├── security.md
│   │   ├── orders.md
│   │   └── payments.md
│   ├── agents/                    # 15 specialized subagents
│   │   ├── orchestrator-agent.md
│   │   ├── security-auditor.md
│   │   ├── logic-auditor.md
│   │   ├── payment-auditor.md
│   │   ├── frontend-auditor.md
│   │   ├── performance-auditor.md
│   │   ├── cross-stack-auditor.md
│   │   ├── dart-reviewer.md
│   │   ├── flutter-tester.md
│   │   ├── rival-agent.md
│   │   ├── heartbeat-agent.md
│   │   ├── legacy-code-auditor.md
│   │   ├── legal-compliance-auditor.md
│   │   ├── uiux-expert.md
│   │   └── repomix-analyzer-agent.md
│   ├── commands/                  # 24 slash commands
│   │   ├── audit-security.md
│   │   ├── deploy.md
│   │   ├── test-all.md
│   │   ├── fix-tests.md
│   │   ├── clear-context.md
│   │   └── ... (20 more)
│   ├── hooks/                     # 9 lifecycle hooks
│   │   ├── protect-production.sh
│   │   ├── block-secrets-files.sh
│   │   ├── flutter-analyze-dart.sh
│   │   └── ... (6 more)
│   ├── plans/                     # Audit reports & remediation plans
│   └── audits/                    # Audit results
├── .github/
│   ├── workflows/                 # CI/CD (quality audit, Flutter web, E2E)
│   ├── instructions/              # Copilot file-pattern instructions
│   ├── copilot-instructions.md
│   └── copilot-skills.md
├── .mcp.json                      # MCP servers: dart-mcp, flutter-pilot, github
├── .copilotignore                 # Noise exclusions for Copilot context
├── AGENTS.md                      # Agent coding guide (build/test/style)
├── CLAUDE.md                      # Claude Code routing rules
├── STATE.md                       # Current project state & blockers
├── TODOS.md                       # Active tasks
├── BUGS.md                        # Known issues
├── LIVE_TESTS_STATUS.md           # Live test execution report
├── Caddyfile                      # VPS reverse proxy config
└── Caddyfile.docs                 # Docs site reverse proxy
```

---

## Screens (`origna_gta/lib/screens/`)

| File | Screen |
|------|--------|
| `home_screen.dart` | Home feed with search, filters, recently viewed |
| `productdetails_screen.dart` | Product detail with reviews, Q&A, add to cart |
| `product_card_screen.dart` | Product card widget |
| `addproduct_screen.dart` | Seller: add new product |
| `editproduct_screen.dart` | Seller: edit existing product |
| `productaddimages_screen.dart` | Seller: upload product images |
| `productaddvideo_screen.dart` | Seller: upload product video |
| `cart_screen.dart` | Cart with free-shipping progress bar |
| `cartitem_screen.dart` | Individual cart item widget |
| `checkout_screen.dart` | Checkout flow |
| `ordersuccess_screen.dart` | Post-purchase confirmation |
| `orders_screen.dart` | Buyer order list (tabs: All/Active/Delivered/Cancelled) |
| `order_detail_screen.dart` | Order detail with timeline |
| `seller_orders_screen.dart` | Seller order management |
| `seller_products_screen.dart` | Seller product list |
| `seller_registration_screen.dart` | Stripe Connect onboarding |
| `seller_setup_screen.dart` | Seller account setup |
| `seller_integration_screen.dart` | Seller integrations |
| `seller/seller_warehouses_screen.dart` | Multi-location warehouse management |
| `shipping_approval_screen.dart` | Seller: approve shipping cost |
| `login_screen.dart` | Auth: login / register |
| `reset_password_screen.dart` | Auth: password reset |
| `authwrapper_screen.dart` | Auth state router |
| `profile_screen.dart` | User profile + theme toggle |
| `addressmanagement_screen.dart` | Saved addresses CRUD |
| `editaddress_screen.dart` | Edit a saved address |
| `favorites_screen.dart` | Saved/favorited products |
| `notifications_screen.dart` | In-app notifications |
| `chat_screen.dart` | Buyer-seller chat |
| `chat_conversations_screen.dart` | Chat conversation list |
| `subscription_screen.dart` | Premium subscription purchase |
| `subscription_cancel_screen.dart` | Premium cancel flow |
| `subscription_success_screen.dart` | Post-subscription confirmation |
| `payment_screens.dart` | Payment result screens |
| `privacy_policy_screen.dart` | Privacy policy |
| `terms_of_service_screen.dart` | Terms of service |
| `terms_screen.dart` | Generic terms screen |
| `main_screen.dart` | Shell: bottom nav + tab routing |
| `common_screens.dart` | Shared screen utilities |

---

## Shared Widgets (`origna_gta/lib/widgets/`)

| File | Purpose |
|------|---------|
| `modern_button.dart` | `ModernButton` — primary/secondary buttons (use instead of ElevatedButton/TextButton) |
| `modern_textfield.dart` | `ModernTextField` — dark-themed input (use instead of raw TextField) |
| `modern_card.dart` | `ModernCard` — elevated card with dark theme |
| `modern_appbar.dart` | `ModernAppBar` — dark gradient app bar |
| `modern_loading_indicator.dart` | `ModernLoadingIndicator` — animated spinner |
| `modern_product_card.dart` | Product card for grid/list display |
| `animations.dart` | `AnimatedListItem`, `TapScaleAnimation`, `FadeSlideIn` |
| `order_widgets.dart` | Order status chip, package timeline, buy-again button |
| `rating_dialog.dart` | Star rating dialog |
| `rating_histogram.dart` | 5-star breakdown bar chart |
| `premium_paywall_widget.dart` | Subscription gate overlay |
| `custom_app_bar.dart` | Legacy app bar (prefer `modern_appbar.dart`) |
| `env_preview_banner.dart` | Dev/staging environment banner |
| `language_selector.dart` | EN/FR/ES language picker |
| `legal_screen_body.dart` | Reusable body for Privacy/Terms screens |

---

## Schema Constants (`origna_gta/lib/core/schema/schema_constants.dart`)

All field names, API endpoint paths, and key constants live here. **Never use magic strings** — use these constants instead.

Key classes:
| Class | Contains |
|-------|---------|
| `ApiEndpoints` | 60 backend API path constants (e.g. `ApiEndpoints.products`, `ApiEndpoints.orders`) |
| `DeepLinkParams` | 7 query parameter keys for deep links |
| `SortOption` | Enum: relevance / priceLowToHigh / priceHighToLow / newest |
| `LocalStorageKeys` | recently_viewed, recent_searches |
| `AlgoliaReplicaSuffixes` | _price_asc, _price_desc |
| `NotificationTypes` | All notification type string constants |
| `UserRoles` | admin, seller, buyer |
| `BusinessRules` | freeShippingThresholdCents (7500), localDeliveryRadiusKm (50.0) |

---

## Services (`origna_gta/lib/services/`)

| File | Purpose |
|------|---------|
| `orignabase_conf_service.dart` | OrignaBase config / env resolution |
| `orignabase_analytics_service.dart` | Analytics via OrignaBase |
| `orignabase_digital_service.dart` | Digital product delivery |
| `orignabase_notification_service.dart` | Push notifications via OrignaBase |
| `conf_services.dart` | App configuration service |
| `analytics_service.dart` | Analytics abstraction |
| `push_transport.dart` | Push notification transport |
| `session_timeout_service.dart` | Auto session expiry |
| `turnstile_service.dart` | Cloudflare Turnstile bot protection |
| `turnstile_service_web.dart` | Web platform impl |
| `turnstile_service_stub.dart` | Non-web stub |
| `web_auth_redirect_web.dart` | Web OAuth redirect handler |
| `web_auth_redirect_stub.dart` | Non-web stub |

---

## Backend (OrignaBase Rust)

### Architecture — 16 Workspace Crates

```
orignabase (single binary, 16 workspace crates)
├── ob-core       — Config, AppState, error types, validation
├── ob-database   — SurrealDB client, CRUD, query translator, transactions
├── ob-auth       — JWT (RS256/HS256), Argon2id, OAuth, MFA/TOTP, email
├── ob-graphql    — Dynamic GraphQL schema + resolvers (async-graphql)
├── ob-security   — Rules DSL parser (pest) + evaluator
├── ob-realtime   — WebSocket subscriptions, change dispatcher, presence
├── ob-storage    — Local filesystem, HMAC-signed URLs, S3/R2 support
├── ob-search     — Meilisearch client + auto-sync
├── ob-functions  — WASM runtime (wasmi), function registry, triggers
├── ob-analytics  — Privacy-first event tracking (hashed IPs)
├── ob-admin      — Schema mgmt, user mgmt, HTML dashboard
├── ob-notifications — FCM push proxy, device tokens
├── ob-handlers   — Business logic (Stripe, orders, products, chat, etc.)
├── ob-mcp        — MCP server (JSON-RPC 2.0 over HTTP/SSE/stdio)
└── orignabase    — Binary entry point, CLI, server assembly
```

### VPS Configuration

- **Host**: `204.168.137.16`
- **API**: `https://api.dev.orignagta.ca` (dev), `https://api.orignagta.ca` (prod)
- **Web**: `https://dev.orignagta.ca` (dev), `https://orignagta.ca` (prod)
- **SurrealDB**: port 8000 (internal), namespace `orignabase`, db `production`
- **Meilisearch**: port 7700 (internal)
- **Docker Compose**: `/opt/orignabase/` on VPS
- **Config**: `orignabase.toml` + env var overrides

### Security Features

- RS256 JWT with key rotation support
- Argon2id password hashing
- MFA/TOTP with AES-256-GCM encrypted secrets
- Rate limiting via `tower_governor` (10 req/60s auth, 100 req/60s API)
- SurrealQL identifier validation
- Security rules DSL (25+ collections, default-deny)
- Webhook deduplication (Stripe events)
- CORS origin whitelist (no `Any`)

### Key Env Overrides

- `OB_DATABASE__ENDPOINT` — SurrealDB endpoint
- `OB_SEARCH__ENDPOINT` — Meilisearch endpoint
- `OB_AUTH__JWT_SECRET` — JWT signing secret
- `OB_AUTH__TOTP_ENCRYPTION_KEY` — TOTP secret encryption (REQUIRED in prod)
- `OB_TEST_MODE` — Enable test mode features

---

## OrignaBase Flutter SDK (`orignabase/sdks/flutter/orignabase/`)

Pure Dart SDK (no Flutter dependency). Communicates with OrignaBase via GraphQL + REST.

| Module | Purpose |
|--------|---------|
| `client.dart` | Main entry point, HTTP client with retry |
| `auth.dart` | 20+ auth methods (email, Google, Apple, OIDC, MFA, magic link) |
| `collection.dart` | CollectionRef, DocumentRef (CRUD) |
| `query.dart` | Query builder (where, orderBy, limit, offset) |
| `batch.dart` | WriteBatch (non-atomic, grouped by type) |
| `field_value.dart` | ServerTimestamp, Increment, ArrayUnion, ArrayRemove, Delete |
| `realtime.dart` | WebSocket subscriptions with auto-reconnect |
| `storage.dart` | File upload/download/resumable |
| `offline.dart` | Offline cache with pending write queue |
| `aggregate.dart` | COUNT/SUM/AVG queries |
| `config.dart` | Remote config (typed getters) |
| `errors.dart` | 7 typed exceptions mapped from HTTP status |

---

## Schema Source of Truth

Field names are defined in `origna_gta/lib/core/schema/schema_constants.dart`.
All Dart code, Playwright helpers, and OrignaBase Rust handlers must agree on these names.

Key conventions:
- Money: integer cents (`subtotalCents`, `taxAmountCents`, `totalAmountCents`)
- Timestamps: `createdAt` (orders/users/payouts), `dateCreated` (products/cart)
- Status strings: defined in `schema_constants.dart` enums — no magic strings

---

## E2E Tests

### Two Test Runners

| Runner | Language | Directory | Specs |
|--------|----------|-----------|-------|
| Playwright | TypeScript | `e2e/` | 114 specs across 6 phases |
| Agent Browser | TypeScript + Bun | `e2e-agent-browser/` | 114 specs (mirrors e2e/) |

### Phase Breakdown

| Phase | Files | Coverage |
|-------|-------|----------|
| phase1-api | 33 | API, security, data integrity, rate limiting |
| phase2-smoke | 13 | UI quality, loading/error states, accessibility |
| phase3-auth-nav | 11 | Auth flows, MFA, registration, JWT rotation |
| phase4-product-flows | 21 | Product CRUD, search, reviews, favorites, digital |
| phase5-complex-flows | 23 | Cart, orders, seller flows, analytics, reordering |
| phase6-stripe | 13 | Payment, webhooks, subscriptions, connect, refunds |

### Config

- `e2e/lib/config.ts` — Test accounts, Stripe test card `4242424242424242`, timeouts, URLs
- `e2e/run-tests.sh` — Parallel: 4 concurrent browsers, 10 concurrent API tests, <10min target

### Run Commands

```bash
cd e2e-agent-browser
bun test specs/phase1-api/          # API smoke tests
bun test specs/phase2-auth/         # Auth flow tests
bun test specs/phase3-products/     # Product tests
bun x tsc --noEmit                  # TypeScript check
```

---

## MCP Configuration

### Project-Level (`.mcp.json`)

| Server | Type | Purpose |
|--------|------|---------|
| dart-mcp | NPX | Dart SDK: analyze, compile, test, format (10 tools) |
| flutter-pilot | NPX | Flutter: live app debugging and UI inspection |
| github | HTTP | GitHub: repos, issues, PRs, actions (18 tools) |

### User-Level (in `.claude/settings.local.json`)

| Plugin | Tools |
|--------|-------|
| Playwright | 14 browser automation tools |
| Firebase | 3 Firestore/Firebase tools |
| Figma | 1 design generation tool |
| Stitch | 6 screen generation tools |
| Gmail | 4 email tools |
| Cloudflare | 2 DNS/worker tools |

### Planned: ob-mcp (Rust)

OrignaBase includes an MCP server crate (`ob-mcp`) with JSON-RPC 2.0 over HTTP/SSE/stdio. Includes safeguards: idempotency keys, spend limits, confirmation tokens. Not yet production-ready.

---

## Deploy

### Flutter Web to VPS

```bash
VPS_HOST=root@204.168.137.16 ./scripts/deploy_web.sh dev
```

Uses staged releases at `/var/www/orignagta/{env}/releases/<timestamp>` with atomic `current` symlink via Caddy.

Build commands per env:
- Dev: `flutter build web --debug --dart-define=ENVIRONMENT=dev --dart-define=FORCE_SEMANTICS=true`
- Staging: `flutter build web --profile --dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true`
- Production: `flutter build web --release --dart-define=ENVIRONMENT=production`

### OrignaBase Backend

Docker Compose at `/opt/orignabase/` on VPS. Binary built with `cargo build --release`. Non-root user (orignabase:1000). Health check configured.

---

## Quality Gates

- **Flutter**: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden` (80% coverage via `run_quality_gate.sh`)
- **Rust**: `cargo clippy -D warnings && cargo test && cargo audit` (CI)
- **E2E**: `bun test specs/` with parallel execution
- **Golden tests**: Excluded from normal runs, run separately via `flutter test test/golden/`

---

## AI Configuration

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code routing rules (42 lines) |
| `AGENTS.md` | Full coding guide: MVVM, build/test/style (136 lines) |
| `.claude/rules/` | 6 domain rules auto-loaded per file type |
| `.claude/agents/` | 15 specialized subagents for delegation |
| `.claude/commands/` | 24 slash commands |
| `.claude/hooks/` | 9 lifecycle hooks (security, quality, validation) |
| `.mcp.json` | 3 MCP servers |
| `.github/copilot-skills.md` | 157 lines of learned patterns |
| `.github/instructions/` | 5 file-pattern Copilot instructions |
