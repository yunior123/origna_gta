# Origna GTA — Repo Map

Last updated: 2026-04-23

## External Documentation References

### Flutter & Dart
- **Flutter Version**: 3.41.5 (latest stable)
- **Dart Version**: 3.11.0
- **Key Resources**:
  - [Flutter API Docs](https://api.flutter.dev)
  - [Flutter 3.41 Release Notes](https://docs.flutter.dev/release/whats-new)
  - [Effective Dart Guide](https://dart.dev/effective-dart)
  - [Dart Language Tour](https://dart.dev/language)
- **Latest Features in Use**:
  - Dot shorthands syntax (Dart 3.10+)
  - Hot reload on web (stable, no longer experimental)
  - Web development config file support
  - Widget Previewer (experimental)
  - Flutter Widget Property Editor

### Rust
- **Rust Version**: 1.90.0 stable (edition 2024)
- **Key Resources**:
  - [The Rust Programming Language Book](https://doc.rust-lang.org/stable/book/)
  - [Rust By Example](https://doc.rust-lang.org/rust-by-example/)
  - [Rust `Result` API](https://doc.rust-lang.org/std/result/enum.Result.html)
  - [Tokio tracing guide](https://tokio.rs/tokio/topics/tracing)
- **Patterns Used**:
  - Memory safety without garbage collection
  - Zero-cost abstractions
  - Ownership, borrowing, and lifetimes
  - Pattern matching and `Result<T, E>` error handling

### Stripe
- **API Base**: `https://api.stripe.com`
- **Key Resources**:
  - [Stripe API Reference](https://docs.stripe.com/api)
  - [Checkout](https://docs.stripe.com/payments/checkout)
  - [Checkout automatic tax](https://docs.stripe.com/payments/checkout/automatic_taxes)
  - [How Checkout works](https://docs.stripe.com/payments/checkout/how-checkout-works)
  - [Webhooks testing](https://docs.stripe.com/webhooks/test)
  - [Error handling](https://docs.stripe.com/error-low-level)
  - [API keys](https://docs.stripe.com/keys)
- **Current Implementation**:
  - Stripe Checkout Sessions (not Payment Links)
  - `automatic_tax` + `tax_id_collection` for tax handling
  - Webhook verification with raw body signature
  - Idempotency keys per-request
  - Server-authoritative pricing (not client-sent)
  - Checkout tax handling now follows Stripe's current address guidance: shipping address takes priority when collected, otherwise billing/customer address is used
  - Google Pay availability on Stripe Tax + Checkout depends on shipping-address collection or an existing saved shipping address

### Postal
- **API**: Send API v3.1 (`https://api.email.com/v3.1/send`)
- **Key Resources**:
  - [Postal Help Center](https://documentation.email.com/hc/en-us)
  - [Postal templating language](https://documentation.email.com/hc/en-us/articles/16886347025947-Postal-Templating-Language)
  - [Postal email automation examples](https://documentation.email.com/hc/en-us/articles/35021196504219-Email-Automation)
  - [Postal daily send limit controls](https://documentation.email.com/hc/en-us/articles/43977536821147-Daily-Send-Limit-for-Postal-API-keys)
- **Features Used**:
  - Transactional email sending
  - HTML/text multipart emails
  - PDF attachments (receipts)
  - Async dispatch for concurrency
  - `SandboxMode` must be disabled on live hosts or production sends will silently stay non-deliverable
  - For Send API v3.1, template variables belong under `Variables`; template-language toggles remain opt-in

### PostgreSQL
- **Current Major Version**: PostgreSQL 18
- **Key Resources**:
  - [PostgreSQL current documentation](https://www.postgresql.org/docs/current/)
  - [PostgreSQL 18 release notes](https://www.postgresql.org/docs/current/release-18.html)
  - [PostgreSQL JSON/JSONB](https://www.postgresql.org/docs/current/datatype-json.html)
- **Operational Notes**:
  - OrignaBase persists product/user/order documents in PostgreSQL JSONB.
  - Current query-risk areas: numeric casts, `data->>'field'` extraction, and stale Surreal-style syntax in translated SQL.

### Sentry
- **SDK**: `sentry_flutter`
- **Key Resources**:
  - [Sentry Flutter setup](https://docs.sentry.io/platforms/flutter/)
  - [Sentry Flutter user feedback](https://docs.sentry.io/platforms/dart/guides/flutter/user-feedback)
  - [Sentry Flutter debug files](https://docs.sentry.io/platforms/flutter/data-management/debug-files/)
- **Operational Notes**:
  - Keep user-facing `ORIGNA-*` codes separate from internal support event IDs.
  - Pair feedback with the captured Sentry event ID when collecting user crash reports.

## Working Directories (CRITICAL)

```bash
# Flutter commands — run from repo_root/origna_gta/ (NOT repo root)
cd origna_gta && flutter analyze && flutter test

# Rust/Cargo commands — run from repo_root/orignabase/ (NOT repo root)
cd orignabase && cargo clippy -- -D warnings && cargo test

# E2E commands — run from repo_root/e2e/
cd e2e && bun test
```

The repo root (`origna_gta/`) has NO Cargo.toml and NO pubspec.yaml. Running `cargo` or `flutter` from the root will fail with "could not find Cargo.toml" or "pubspec.yaml not found".

## Overview

Unified monorepo for Origna GTA, a Canada-first multi-vendor e-commerce platform. Frontend and backend live in the same repo.

| Layer | Directory | Technology |
|-------|-----------|-----------|
| Mobile/Web frontend | `origna_gta/` | Flutter 3.x + Dart (782 tracked `.dart` files under `origna_gta/`), Riverpod, Freezed |
| Ventures Platform | `origna_ventures/` | Flutter web frontend + Python FastAPI backend |
| Backend API | `orignabase/` | OrignaBase (Rust, 16 workspace crates, hosted on VPS 204.168.137.16). task_queue uses direct SQL for typed table operations; CRUD uses JSONB document storage. |
| Database | PostgreSQL 18 (on VPS, via OrignaBase) |
| Search | Meilisearch v1.12 (on VPS, via OrignaBase) |
| Payments | Stripe (Checkout + Connect + webhooks) |
| Bot protection | Cloudflare Turnstile |
| Web reverse proxy | Caddy (on VPS) |
| CI | GitHub Actions |
| E2E | agent-browser (TypeScript) + Bun agent-browser (118 tracked spec files under `e2e/specs/`) |
| Tests | Current verified local gates on 2026-04-17: Flutter analyze `0 issues`; `flutter test --exclude-tags golden` `4696 pass / 0 fail`; `cargo clippy -p ob-auth -- -D warnings` pass; `cargo clippy -p ob-handlers -- -D warnings` pass; `cargo test -p ob-handlers` pass; `cargo test -p ob-core` pass; `cargo test -p orignabase --no-run` pass; full seeded E2E rerun active in `/tmp/origna_e2e_run_all_after_deep_fix.log`. |

No Firebase. No Cloud Functions. No Firestore. All backend is OrignaBase on the VPS.

## Upstream Notes (2026-04-23)

- **PostgreSQL**: Current stable docs are PostgreSQL 18; the official docs page currently lists `18 / Current`, and the release notes call out AIO, skip scan, `uuidv7()`, virtual generated columns, and OAuth support.
- **Rust**: Current standard docs expose `std::panic` items such as `catch_unwind`, `set_hook`, `take_hook`, and `update_hook`; these are the first references to use when auditing panic handling.
- **Tokio / tracing**: Tokio's tracing guide still recommends registering a subscriber as early as possible in `main` and using structured spans/events instead of plain logs.
- **Sentry Flutter**: Sentry's Flutter guide still centers on `sentry_flutter` plus tracing/profiling options; troubleshooting docs note keeping the SDK current for platform-level fixes.
- **Google OAuth on web**: OrignaGTA now treats a Google web client ID as valid only when it matches the expected `.apps.googleusercontent.com` shape, and the web deploy must replace `__GOOGLE_WEB_CLIENT_ID__` at build time.

## Inventory Source Of Truth

For exhaustive file-by-file coverage, use:
- `docs/REPO_INVENTORY.md` — generated from `git ls-files`
- `docs/REPO_MAP.md` — human-readable architecture/navigation map

Verified inventory snapshot on 2026-04-22:
- total tracked files: `5437`
- tracked files by major top-level area:
  - `orignabase/` → `3865`
  - `origna_gta/` → `996`
  - `e2e/` → `176`
  - `origna_ventures/` → `52`
  - `docs/` → `40`
  - `scripts/` → `21`

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
│   │   │   ├── support/
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
│   │   ├── unit/                  # 149 unit test files
│   │   ├── widget/                # 79 widget test files
│   │   ├── screens/               # 26 screen test files
│   │   ├── live/                  # 37 live/integration tests (gated)
│   │   ├── golden/                # Golden tests (1 file, excluded from CI)
│   │   ├── features/              # 5 feature provider tests
│   │   └── helpers/               # Test utilities (EMPTY — planned)
│   ├── integration_test/          # Flutter integration tests (7 files)
│   └── pubspec.yaml
├── e2e/                           # agent-browser E2E (TypeScript + Bun agent-browser)
│   ├── specs/
│   │   ├── phase1-api/            # 34 API smoke tests
│   │   ├── phase2-smoke/          # 13 UI quality tests
│   │   ├── phase3-auth-nav/       # 11 auth flow tests
│   │   ├── phase4-product-flows/  # 21 product tests
│   │   ├── phase5-complex-flows/  # 23 cart/order/seller tests
│   │   ├── phase6-stripe/         # 13 payment tests
│   │   └── ai-comprehensive/      # 1 AI-powered comprehensive test
│   ├── ai/                        # AI-powered audit tests
│   ├── lib/
│   │   └── config.ts              # Test accounts, Stripe tokens, URLs
│   ├── load/                      # Stress tests (checkout-stress, auth-storm)
│   └── run-tests.sh               # Parallel runner (4 browsers, 10 API)
├── orignabase/                    # Rust backend (OrignaBase BaaS)
│   ├── Cargo.toml                 # Workspace manifest (16 crates)
│   ├── crates/
│   │   ├── orignabase/            # Binary entry point, CLI, server assembly
│   │   ├── ob-core/               # Config, AppState, error types
│   │   ├── ob-database/           # PostgreSQL client, CRUD, query translator
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
│   ├── examples/
│   │   ├── chat-app/              # Example chat app
│   │   └── todo-app/              # Example todo app
│   ├── load-tests/                # Load tests (auth-flow.js, crud-operations.js, stress-test.js, k6/)
│   ├── reliability-tests/chaos/   # Chaos engineering tests
│   └── sdks/flutter/orignabase/   # OrignaBase Flutter/Dart SDK
│       └── example/               # Flutter SDK examples (auth, batch, ecommerce, migration, realtime, todo)
├── origna_ventures/               # OrignaVentures platform
│   ├── backend/                   # Python FastAPI backend (app.py, storage)
│   ├── lib/                       # Flutter frontend code
│   └── web/                       # Flutter web entrypoint
├── scripts/
│   ├── deploy_web.sh              # VPS web deploy (staged releases)
│   ├── run_quality_gate.sh        # 80% coverage threshold
│   ├── deploy_mcp_docs.sh         # MCP docs deploy to VPS
│   └── add-cloudflare-dns.sh      # Cloudflare DNS management
├── docs/
│   ├── REPO_MAP.md                # High-level architecture + navigation map
│   ├── REPO_INVENTORY.md          # Machine-generated tracked-file inventory (`git ls-files`)
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
├── TODOS.md                       # Pointer file; active workboard lives in `CORE.md`
├── CORE.md                        # Active workboard
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
| `seller/seller_analytics_screen.dart` | Seller analytics dashboard |
| `seller/bulk_upload_screen.dart` | Bulk CSV product upload |
| `seller/seller_warehouses_screen.dart` | Warehouse management |

---

## Shared Widgets (`origna_gta/lib/widgets/`)

41 files across 7 subdirectories + root. Key widgets:

| File | Purpose |
|------|---------|
| `modern_button.dart` | `ModernButton` — primary/secondary buttons |
| `modern_textfield.dart` | `ModernTextField` — dark-themed input |
| `modern_card.dart` | `ModernCard` — elevated card with dark theme |
| `modern_appbar.dart` | `ModernAppBar` — dark gradient app bar |
| `modern_loading_indicator.dart` | `ModernLoadingIndicator` — animated spinner |
| `modern_product_card.dart` | Product card for grid/list display |
| `modern_skeleton_loader.dart` | Skeleton loading placeholders |
| `modern_snackbar.dart` | Styled snackbar |
| `animations.dart` | `AnimatedListItem`, `TapScaleAnimation`, `FadeSlideIn` |
| `order_widgets.dart` | Order status chip, package timeline, buy-again |
| `rating_dialog.dart` | Star rating dialog |
| `rating_histogram.dart` | 5-star breakdown bar chart |
| `premium_paywall_widget.dart` | Subscription gate overlay |
| `custom_app_bar.dart` | Legacy app bar (prefer `modern_appbar.dart`) |
| `env_preview_banner.dart` | Dev/staging environment banner |
| `language_selector.dart` | EN/FR/ES language picker |
| `legal_screen_body.dart` | Reusable body for Privacy/Terms screens |
| `gradient_badge.dart` | Gradient badge widget |
| `update_required_dialog.dart` | Force-update dialog |
| `cart/` | `cart_total_display.dart`, `free_shipping_bar.dart` |
| `checkout/` | `delivery_options_section.dart`, `order_review_sheet.dart` |
| `mascot/` | Canadian moose mascot (5 files) |
| `orders/` | Mark shipped/update shipping dialogs, status widgets |
| `profile/` | Header card, menu items, theme toggle |
| `promotions/` | `standalone_promo_widget.dart` |
| `shared/` | `cart_badge.dart`, `filter_chip_widget.dart`, `quantity_button.dart`, `trending_badge.dart` |

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
orignabase (single binary, 15 workspace crates)
├── ob-core       — Config, AppState, error types, validation
├── ob-database   — PostgreSQL client, CRUD, query translator, transactions
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
- **PostgreSQL**: port 5432 (internal), database `orignabase`
- **Meilisearch**: port 7700 (internal)
- **Docker Compose**: `/opt/orignabase/` on VPS
- **Config**: `orignabase.toml` + env var overrides

### Observability

- **Sentry**: Flutter-side crash capture, breadcrumbs, and release diagnostics
- **Internal error events**: `error_events` collection in OrignaBase
- **User-facing codes**: `ORIGNA-{DOMAIN}-{NUMBER}`
- **Internal support IDs**: `SE-YYYYMMDD-XXXXXX`

### Security Features

- RS256 JWT with key rotation support
- Argon2id password hashing
- MFA/TOTP with AES-256-GCM encrypted secrets
- Rate limiting via `tower_governor` (10 req/60s auth, 100 req/60s API)
- SQL identifier validation
- Security rules DSL (25+ collections, default-deny)
- Webhook deduplication (Stripe events)
- CORS origin whitelist (no `Any`)
- Structured internal error persistence from Flutter into `error_events`

### Key Env Overrides

- `OB_DATABASE__ENDPOINT` — PostgreSQL endpoint
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
All Dart code, agent-browser helpers, and OrignaBase Rust handlers must agree on these names.

Key conventions:
- Money: integer cents (`subtotalCents`, `taxAmountCents`, `totalAmountCents`)
- Timestamps: `createdAt` (orders/users/payouts), `dateCreated` (products/cart)
- Status strings: defined in `schema_constants.dart` enums — no magic strings
- Observability fields: `errorCode`, `internalEventId`, `stackTrace`, `environment`, `source`, `routeOrAction`, `metadata`

---

## E2E Tests

### Two Test Runners

| Runner | Language | Directory | Specs |
|--------|----------|-----------|-------|
| agent-browser | TypeScript | `e2e/` | 114 specs across 6 phases |
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
| agent-browser | 14 browser automation tools |
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

### Current Verified Runtime State

- Dev search/category browsing is green.
- Dev `/auth/providers` now reports Google web auth enabled/configured.
- Dev catalog currently has active products in all 21 storefront categories.
- Ventures contact/email live path is returning support + confirmation delivery with `status=sent`.

### Official Provider References

- Stripe Checkout: `https://docs.stripe.com/payments/checkout`
- Postal Send API v3.1: `https://dev.email.com/email/guides/send-api-v31/`
- PostgreSQL JSON/JSONB: `https://www.postgresql.org/docs/current/datatype-json.html`
- Meilisearch Search API: `https://www.meilisearch.com/docs/reference/api/search`
- Sentry Flutter SDK: `https://docs.sentry.io/platforms/dart/guides/flutter/`

---

## Quality Gates

- **Flutter**: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden` (80% coverage via `run_quality_gate.sh`)
- **Rust**: `cargo clippy -D warnings && cargo test && cargo audit` (CI)
- **E2E**: `bun test specs/` with parallel execution
- **Golden tests**: Excluded from normal runs (1 file, `--exclude-tags golden`). Golden tests skipped in CI (Ubuntu renders differently from macOS).

---

## AI Configuration

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code routing rules (42 lines) |
| `AGENTS.md` | Full coding guide: MVVM, build/test/style (136 lines) |
| `docs/AI_COORDINATION.md` | Multi-agent ownership, leases, and handoff rules |
| `WORK_CLAIMS.md` | Live path ownership registry to avoid overlapping edits |
| `.claude/rules/` | 6 domain rules auto-loaded per file type |
| `.claude/agents/` | 15 specialized subagents for delegation |
| `.claude/commands/` | 24 slash commands |
| `.claude/hooks/` | 9 lifecycle hooks (security, quality, validation) |
| `.mcp.json` | 3 MCP servers |
| `.github/copilot-skills.md` | 157 lines of learned patterns |
| `.github/instructions/` | 5 file-pattern Copilot instructions |

---

## OrignaVentures

### Directory Structure

```
origna_ventures/
├── lib/
│   ├── main.dart           # 3688-line single-file Flutter web app (all UI, routing, state)
│   ├── theme_config.dart   # ThemeConfig — unified blue-violet palette (matches OrignaGTA DesignTokens)
│   ├── tiers_config.dart   # TiersConfig — 3 service tier definitions (code, launch, team)
│   └── localization.dart   # loc.tr(en, fr, es) inline trilingual helper
├── backend/
│   ├── app.py              # 1320-line FastAPI backend (Stripe, PDF, webhooks, email)
│   ├── requirements.txt    # Python dependencies
│   ├── venv/               # Python virtual environment
│   ├── contracts.db        # SQLite database for contract/order storage
│   └── generated/          # PDF output directory
├── web/                    # Flutter web entrypoint
├── deploy.sh               # rsync deploy to Hetzner VPS
└── SECURITY.md             # Security policy (admin API key, auth requirements)
```

### Backend Architecture (FastAPI)

- **Framework**: Python FastAPI at `origna_ventures/backend/app.py` (1320 lines)
- **Database**: SQLite (`contracts.db`) — lightweight, file-based
- **Payments**: Stripe Checkout Sessions (one-time + subscription), webhook handling
- **Email**: Postal (order confirmations, contract notifications)
- **PDF Generation**: `reportlab` — generates service contracts on the fly
- **API Base**: `https://api.orignagta.ca/ventures/api`
- **Checkout modes**: `service_code` (direct tier purchase) and `contract_id` (legacy)
- **Security**: Admin API key required for `/api/contracts` and `/api/contracts/{id}/pdf` endpoints; email test endpoint requires admin auth
- **Seller**: OrignaVentures IS the seller (support@orignaventures.ca) — no seller onboarding

### Flutter Architecture

- **Pattern**: Single-page `StatefulWidget` + `setState` — **no Riverpod, no MVVM**
- **All UI** in `lib/main.dart` (3688 lines, single file) — routes managed via in-app navigation
- **Theme**: `ThemeConfig` class (`lib/theme_config.dart`) — unified blue-violet palette with OrignaGTA
- **Tiers**: `TiersConfig` class (`lib/tiers_config.dart`) — defines 3 service tier cards
- **Languages**: EN/FR/ES via inline `loc.tr(enString, frString, esString)` pattern
- **No contract signing** — 3 tappable service cards → Stripe checkout directly

### Key Files

| Purpose | Path |
|---------|------|
| Main app (all UI + routing) | `origna_ventures/lib/main.dart` |
| Theme config (blue-violet palette) | `origna_ventures/lib/theme_config.dart` |
| Service tier definitions | `origna_ventures/lib/tiers_config.dart` |
| FastAPI backend (Stripe, PDF, webhooks) | `origna_ventures/backend/app.py` |
| Deploy script (rsync to VPS) | `origna_ventures/deploy.sh` |
| Security policy | `origna_ventures/SECURITY.md` |

### Service Tiers

| Tier | Price | Type | Description |
|------|-------|------|-------------|
| OrignaCode | $500 CAD | One-time | Code review & optimization service |
| OrignaLaunch | $3,000 CAD | One-time | Full app launch package |
| OrignaTeam | $1,000 CAD/month | Subscription | Ongoing development team support |

### Deploy

- **Method**: `./deploy.sh` — rsync to Hetzner VPS at `204.168.137.16`
- **Target**: `/var/www/orignaventures/production/current` (Caddy serves as static site)
- **Backend**: FastAPI runs on port 8001, Caddy reverse-proxies `/ventures/api/`
- **No Firebase** — all hosting and backend on Hetzner VPS

### Repository Access

- **Manual processing only** — no auto GitHub invite for collaborators
- Access requests handled manually by Yunior

---

## Known Issues

- **537 ob-handler test failures** — SurrealDB→PostgreSQL query migration in progress. The `ob-handlers` crate tests use SurrealDB-specific query syntax (e.g., `RETURN AFTER`, `type::thing()`, `CREATE CONTENT`, `??` coalesce) that must be translated to PostgreSQL equivalents. See `HANDLER_MIGRATION_STRATEGY.md` for the full migration plan and translation patterns.
