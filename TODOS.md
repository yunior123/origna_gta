
@~/CLAUDE.md

# OrignaGTA — AI Agent Routing File

Flutter e-commerce app (Canada-first multi-vendor marketplace). Backend: OrignaBase (Rust VPS). 

> This is a routing file. Detailed rules auto-load from `.claude/rules/`. Read `docs/REPO_MAP.md` for full architecture.

---

## Commands

```bash
# CRITICAL: Always cd to the right subdirectory first!
# Repo root has NO Cargo.toml and NO pubspec.yaml.

# Flutter (from origna_gta/origna_gta/ — NOT repo root)
cd origna_gta/origna_gta  # or use absolute path
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
flutter test test/unit/auth_provider_test.dart          # single test
flutter test --name "should calculate subtotal"         # pattern match
flutter pub run build_runner build --delete-conflicting-outputs  # codegen
# Widget previews: REMOVED. start-preview.sh deleted. @Preview annotations stay in code but don't run the preview server — it dumps all widgets into one messy page. Previews should work per-view like SwiftUI, not all-at-once.

# E2E (from e2e/)
bun test specs/phase1-api/
bun x tsc --noEmit

# OrignaBase Rust (from orignabase/)
cargo clippy -D warnings && cargo test
cargo test -p ob-auth # single crate
cargo test -- --ignored # run #[ignore] integration tests

# Live Tests (Flutter)
# Requires: OrignaBase running on localhost:8080 + seeded database
cd origna_gta && flutter test test/live/ \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=emulator

# Run single live test
flutter test test/live/orignabase_live_smoke_test.dart \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=emulator

# Seed local database (from e2e/ folder)
cd e2e && ORIGNABASE_URL=http://127.0.0.1:8080 bun run lib/seed-dev.ts
```

## Key Files

| Purpose | Path |
|---------|------|
| Environment config | `lib/utils/env_config.dart` |
| Auth providers | `lib/core/providers.dart` |
| Design tokens | `lib/utils/design_tokens.dart` |
| Schema constants | `lib/core/schema/schema_constants.dart` |
| Repo map | `docs/REPO_MAP.md` |
| Quality gate | `scripts/run_quality_gate.sh` |

## Architecture

- MVVM: Screens → ViewModels → Services → OrignaBase SDK
- State: Riverpod providers (`lib/providers/`), AsyncNotifier for async state
- Models: `freezed` for all value types. Money = integer cents, never float.
- Backend: OrignaBase SDK only — never raw HTTP to PostgreSQL/Meilisearch

## Common Pitfalls (DO NOT)

- ❌ `Colors.blue` or hex literals — use `DesignTokens.*`
- ❌ `setState()` in screens — use Riverpod
- ❌ `BuildContext` in ViewModels or Services
- ❌ `double`/`float` for money — always integer cents
- ❌ `print()` — use `AppLogger`
- ❌ `FirebaseAuth.instance` — Firebase is gone, use OrignaBase SDK
- ❌ Hardcoded strings, routes, or field names — use `schema_constants.dart`
- ✅ Flutter Widget Previews — SwiftUI-style per-view in VS Code sidebar. Open a .dart file → sidebar auto-shows @Preview widgets for THAT file only. Toggle "Filter previews by selected file" at bottom-left. Each preview has own Hot Restart. Embedded Inspector via gear icon. No terminal commands needed. Old `start-preview.sh` deleted.
- ❌ Relative imports (`../`) — use `package:origna_gta/...`
- ❌ `MediaQuery.of(context).size.width` for layout — use responsive utilities

## Agent Rules

- Use max 5 subagents per session (8GB RAM constraint)
- Kill orphan Chrome processes before E2E tests
- Run smoke tests before full test suite
- If you find a problem, fix it — never silence it
- Create anti-alzheimer memos as you work (document decisions in STATE.md)
- No migration or backward compatibility — wipe dev DB and reseed if needed
- Both OrignaBase backend and Flutter frontend can be modified to fix issues
- Cloudflare MCP exists — search for it, you always forget
- Prefer Rust over TypeScript for server code
- Read `docs/REPO_MAP.md` for context before starting work
- no skipping tests, implement and run instead
- avoid mocks for live integration tests
- no backward compatibility
- solve warnings like a pro
- avoid ignoring live tests
- fix instead of cheating, implement like pro instead of creating temporary workaround
- if u have blockers then stop all and ask user
- use when auditing, before fixing:.claude/skills/quorum-verify/SKILL.md
- avoid launching too many claude code in bash. why?:it consumes too many tokens, subagents are prefered.ex:last time u called 5+ claude and consumed 10% of tokens in 2 minutes.
- no magic strings, it leads to errors in production
- always kill zombie flutter_test consuming ram
- autolearn:if u find an issue while solving other then solve it or added to state.md
- avoid simple unprofessional fixes. if u encounter an issue make sure to solve like pro.
- codex delegation: ONLY gpt-5.4 (full). NEVER gpt-5.4-mini, o4-mini, o3, or any model < 5.3. Lower models destroy the codebase.
- codex flag (v0.117.0+): `codex exec -m gpt-5.4 -s danger-full-access "prompt"` — OLD syntax `--dangerously-bypass-approvals-and-sandbox -c 'model="gpt-5.4"'` is deprecated
- codex batches: launch 3+ parallel codex for non-conflicting tasks (different directories), divide and conquer
- codex temp files: pipe output to `/tmp/codex-batch{N}-output.log` — never lose results
- gemini flag (v0.35.2+): `gemini -m gemini-3-pro-preview -y -p "prompt"` — `-p` for headless, `-y` for yolo. Be patient with 429 retries (2-3 min)
- gemini temp files: MUST use `/tmp/gemini-workspace/` — NEVER create temp files in project root
- mimo/free models: available via OpenRouter inside opencode (`/opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free`) and kilocode. OpenRouter API key already configured. Prefer mimo over subagents for delegation — saves Claude tokens
- after ANY codex run: verify `flutter analyze` + `flutter test` PASS before accepting changes. Revert if broken.
- codex cannot verify screenshots match filenames — always audit screenshots manually after codex captures them.
- codex/gemini monitoring: launch with `> /tmp/codex-output.log 2>&1 &` then monitor via `nohup /tmp/monitor-codex.sh &`. Script checks every 5min: process alive, screenshot count, last output line.
- before commit: always run `/code-review` (4 parallel reviewers: correctness, security, performance, standards). Score ≥9 blocks commit.
- before push: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden && cargo clippy -D warnings && cargo test`
- use sleep as monitor technique
- there might be false positives in audits, be carefull
- use sleep monitor technique to always keep mimo,gemini,codex, etc busy doing audit based on real evidence and no false positive, creating more tests, documenting, fixing issues, searching web for common bugs on github or internet for ecommerce stores and see how we can prevent those in our app, use the harness loop constatntly. in the case of mimo alternate opencode, kilo, openrouter. Search web on how to better always keep working non stop on a project, like infinite work, non stop, always on. check gstack for ideas, skills catalog, etc.
Make them audit full codebase in depth. Use all agents and skills for it.
- fix stale data issues, resseed db if needed
- always monitor disk space in my mac:256gb

## MCP

Project `.mcp.json`: dart-mcp, flutter-pilot, github. Cloudflare MCP available via user-level config.

## AI Skills Catalog

See `docs/AI_SKILLS_CATALOG.md` for the complete inventory of all skills, commands, agents, rules, and workflows available to all AI agents.

# Origna GTA — Repo Map

Last updated: 2026-03-29

## Working Directories (CRITICAL)

```bash
# Flutter commands — run from origna_gta/origna_gta/ (NOT repo root)
cd origna_gta/origna_gta && flutter analyze && flutter test

# Rust/Cargo commands — run from origna_gta/orignabase/ (NOT repo root)
cd origna_gta/orignabase && cargo clippy -- -D warnings && cargo test

# E2E commands — run from origna_gta/e2e/
cd origna_gta/e2e && bun test
```

The repo root (`origna_gta/`) has NO Cargo.toml and NO pubspec.yaml. Running `cargo` or `flutter` from the root will fail with "could not find Cargo.toml" or "pubspec.yaml not found".

## Overview

Unified monorepo for Origna GTA, a Canada-first multi-vendor e-commerce platform. Frontend and backend live in the same repo.

| Layer | Directory | Technology |
|-------|-----------|-----------|
| Mobile/Web frontend | `origna_gta/` | Flutter 3.x + Dart (347 .dart files), Riverpod, Freezed |
| Backend API | `orignabase/` | OrignaBase (Rust, 16 workspace crates, hosted on VPS 204.168.137.16). task_queue uses direct SQL for typed table operations; CRUD uses JSONB document storage. |
| Database | PostgreSQL 18 (on VPS, via OrignaBase) |
| Search | Meilisearch v1.12 (on VPS, via OrignaBase) |
| Payments | Stripe (Checkout + Connect + webhooks) |
| Bot protection | Cloudflare Turnstile |
| Web reverse proxy | Caddy (on VPS) |
| CI | GitHub Actions |
| E2E | agent-browser (TypeScript) + Bun agent-browser (116 specs across 7 phases) |
| Tests | Flutter: 3,173+ passing. Rust: ~3,268 passing + 537 failing (ob-handlers SurrealDB→PG migration in progress). SDK: 531 passing. |

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

### Security Features

- RS256 JWT with key rotation support
- Argon2id password hashing
- MFA/TOTP with AES-256-GCM encrypted secrets
- Rate limiting via `tower_governor` (10 req/60s auth, 100 req/60s API)
- SQL identifier validation
- Security rules DSL (25+ collections, default-deny)
- Webhook deduplication (Stripe events)
- CORS origin whitelist (no `Any`)

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

OrignaBase includes an MCP server crate (`ob-mcp`) with JSON-RPC 2.0 over HTTP/SSE/stdio. Includes safeguards: idempotency keys, spend limits, confirmation tokens.Make it production ready

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
- **Golden tests**: Excluded from normal runs (1 file, `--exclude-tags golden`). Golden tests skipped in CI (Ubuntu renders differently from macOS).

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

---



# TODOS.md — Reusable Execution Runbook

This file is the reusable execution checklist.

`STATE.md` is the evidence ledger.
Record every completed, blocked, or verified checkpoint in `STATE.md` immediately after evidence exists.

## Core Rules

- [ ] Never mark work done without test, live, or capture evidence.
- [ ] Save long-running command output to `/tmp/...`.
- [ ] Keep backend live validation ahead of Flutter live validation.
- [ ] Keep Flutter live validation ahead of browser/E2E capture.
- [ ] Keep browser/E2E capture ahead of screenshot rename/delete cleanup.
- [ ] Start load, stress, reliability, and benchmark work only after live and E2E are stable.
- [ ] Reseed dev/local as often as needed; do not preserve bad seed state.
- [ ] Fix root causes instead of silencing failures.
- [ ] Monitor VPS RAM, disk, rebuild progress, and container health during backend work.
- [ ] Kill stale local heavy processes before starting new heavy work.
- [ ] Dont be lazy, work, go the extra mile if needed
- [ ] When auditing the codebase do it as an outsider
- [ ] Document as you fix
- [ ] Deploy all then use agent-browser to test the changes
- [ ] Live tests are mandatory, do not skip them
- [ ] No sql injection
- [ ] No exageration, no ai slop, quorum verify findings, search web as needed
- [ ] do not skip tests
- [ ] make sure dev, staging and prod are updated in vps with latest builds
- [ ] audit app lificycle per view. ex: how does it work for video player in product detail view?


## Definition Of Done

A task is done only when all are true:

- [ ] Code or config is updated if needed.
- [ ] Relevant tests, live checks, or captures pass.
- [ ] New warnings introduced by the change are fixed.
- [ ] `STATE.md` records the result, evidence, and next blocking impact.

## Execution Order

1. [ ] Execute backend live wave.
2. [ ] Execute Flutter live only after backend live is stable.
3. [ ] Execute E2E and browser/design capture only after deploy and seed state are stable.
4. [ ] Execute screenshot/name audit only after manifest-driven capture is in place.
5. [ ] Execute reliability, load, stress, benchmarks, and example apps only after live and E2E are green.

Use `STATE.md` to determine the current active gate inside this order.

## Phase 0 — Control Plane

- [ ] Keep `STATE.md` current and compressed.
- [ ] Keep this file ordered; update existing items instead of appending duplicates.
- [ ] Keep `.claude/harness/` aligned with the active wave when using harness-loop.
- [ ] Monitor VPS health:
  - [ ] `docker compose ps`
  - [ ] memory / swap
  - [ ] disk / docker image growth
  - [ ] rebuild progress
- [ ] Monitor local RAM and clear zombie `flutter_test`, Chrome, agent-browser, Cargo, and stale dev servers before heavy runs.

## Phase 1 — Backend Live First

### 1A. VPS / Runtime Stability

- [x] Confirm the newest intended dev/staging/prod images are actually running.
- [x] Verify the current target health endpoints:
  - [x] API dev health
  - [x] API staging health
  - [x] production app/backend health route behavior
- [x] Confirm all required containers are healthy after restart or rebuild.
- [ ] Clean only safe old Docker artifacts when rebuilds are idle.

Current verified progress on 2026-04-17:
- `orignabase/` local source was synced to `/opt/orignabase/source/` on the VPS before rebuild.
- Web releases deployed successfully:
  - `dev`: `20260417191711`
  - `staging`: `20260417191829`
  - `production`: `20260417191953`
- Backend containers were rebuilt and recreated from the synced source:
  - `orignabase-dev`, `orignabase-staging`, and `orignabase-prod` all restarted and reported `healthy`
  - fresh images for `orignabase-orignabase-{dev,staging,prod}` were created on 2026-04-17
- External health checks are green:
  - `https://api.dev.orignagta.ca/health` -> `ok`
  - `https://api.staging.orignagta.ca/health` -> `ok`
  - `https://api.orignagta.ca/health` -> `ok`
  - `https://dev.orignagta.ca`, `https://staging.orignagta.ca`, and `https://orignagta.ca` all responded successfully
- Active remaining work in Phase 1:
  - move from deploy verification into the remaining backend live/quality gates (`1B` and `1C`)
  - keep `STATE.md` aligned as each live/backend proof point is added

### 1B. Rust Live Test Wave

Run backend live files in priority order and fix as needed:

- [x] smoke
- [x] security/payment/storage/search/shipping/order/returns/reliability/stress core wave
- [x] admin and other live-only ignored suites
* - [ ] remaining `crates/orignabase/tests/*.rs` files that exercise live/dev behavior
* - [ ] re-run any suite whose previous pass tolerated an error or depended on a stale assumption

### 1C. Backend Quality Gates

- [x] `cargo clippy -D warnings`
- [x] `cargo test`
- [x] Fix real warnings instead of suppressing them.
- [ ] Run Stripe webhook CLI verification against current backend behavior using a metadata path that matches production expectations.
- [ ] Keep Flutter live blocked until backend webhook verification is green.

## Phase 2 — Flutter Live After Backend

- [x] Ensure the active OrignaBase target is healthy and correctly seeded.
* - [ ] Run Flutter live tests with `RUN_ORIGNABASE_LIVE_TESTS=true`.
* - [ ] Fix live failures before broader UI audit.
- [x] Run `flutter analyze --no-fatal-infos`.
* - [ ] Run impacted unit/widget suites after live fixes.
- [x] Fix analyzer warnings and test regressions introduced during the wave.

## Phase 3 — E2E And Design Capture

### 3A. Deterministic Seed

- [x] Seed representative sample data, including image and video coverage where needed.
- [x] Ensure major buyer, seller, and admin views have intended non-empty states.
- [x] Ensure required test accounts exist, are usable, and match the current test manifest.
- [ ] Re-seed whenever drift invalidates a live or capture result.

### 3B. Browser / E2E

- [ ] Run E2E smoke first.
- [ ] Run remaining E2E phases in order.
- [ ] Fix failures instead of documenting them as expected.
- [ ] Exercise required email-triggering flows for the test accounts in scope.
- [ ] Save outputs to `/tmp/...` and summarize verified results in `STATE.md`.

Current verified progress on 2026-04-17:
- smoke/browser harness stabilization is complete and recorded in `STATE.md`.
- targeted phase5 rerun is green:
  `bun test e2e/specs/phase5-complex-flows/order-lifecycle.spec.ts e2e/specs/phase5-complex-flows/buyer-flow.spec.ts e2e/specs/phase5-complex-flows/chat-inbox.spec.ts --timeout 120000`
  result: `27 pass / 0 fail`.
- the deep phase6 blocker that surfaced in the seeded all-up run has been fixed in `e2e/lib/auth.ts`:
  stale bootstrap-admin token reuse during `repairOrignaBaseUiAccount(...)` caused auth failures while provisioning fresh UI accounts for `deep-ui-scenarios.spec.ts`.
- focused verification after the fix is green:
  `bun test e2e/specs/phase6-stripe/deep-ui-scenarios.spec.ts --timeout 120000`
  result: `14 pass / 0 fail`.
- the full `e2e/run-tests.sh all` rerun completed green from a clean browser process set:
  `E2E_BROWSER_CONCURRENCY=1 E2E_API_CONCURRENCY=1 ./run-tests.sh all > /tmp/origna_e2e_run_all_after_deep_fix.log 2>&1`
  result:
  - browser wave: `697 pass / 0 fail` across `75` files
  - seed: `341s`
  - API: `472s`
  - browser: `4086s`
  - total: `4899s` (`81m 39s`)
  - status: green but too slow for the runner target; investigate performance before treating this wave as operationally healthy.
- focused runtime follow-up after the green all-up result is also verified in `STATE.md`:
  - `seller-integration.spec.ts`: `3 pass / 0 fail` in `44.11s`
  - `bulk-upload.spec.ts`: `10 pass / 0 fail` in `51.33s`
  - `premium-subscription.spec.ts`: `29 pass / 0 fail` in `141.28s`
  - `deep-ui-scenarios.spec.ts`: `14 pass / 0 fail` in `112.58s`
  - `seller-setup.spec.ts`: `5 pass / 0 fail` in `21.80s`
- active remaining work for this area:
  - correctness is green; a fresh all-up rerun after the runtime patches also stayed green at `4269s` (`71m 9s`), improving by `630s` (`10m 30s`) vs the prior `4899s` run.
  - keep reducing runtime; the suite is materially faster but still far above the runner target.

### 3C. Screenshot / Naming Audit

- [ ] Use a manifest-driven capture source of truth.
- [ ] Enforce `filename -> persona -> route -> seeded state -> required anchors`.
- [ ] Save screenshots to the agreed output location.
- [ ] Audit filename/content alignment.
- [ ] Rename mismatches only after verification.
- [ ] Delete true duplicates only after verification.
- [ ] Re-run captures after each navigation or seed fix until the set is trustworthy.

### 3D. Full Design Audit

- [ ] Audit every major view, widget family, variant, and state.
- [ ] Cover desktop and mobile layouts.
- [ ] Audit full-page screenshots, not only top-of-screen captures.
- [ ] Check beginning, middle, and end states for long scrolling views.
- [ ] Record verified findings and fixes in `STATE.md`.

## Phase 4 — Codebase Audits And Fixes

### 4A. Magic Strings

- [ ] Audit Rust runtime magic strings file by file.
- [ ] Audit Dart runtime magic strings file by file.
- [ ] Replace contract strings, route fragments, persisted status values, and payload keys with shared constants or enums.
- [ ] Fix warnings and todos in vscode panel

### 4B. Auth / Payments / Webhooks / Infra / Chat / Products lifecycle / Notifications / Orders lifecycle

- [ ] Audit auth end to end in backend and frontend using the current project skills/runbooks where relevant.
- [ ] Audit Stripe checkout, Connect, payouts, refunds, and webhook handling using real seller-account state.
- [ ] Improve localhost test configuration for PostgreSQL, Meilisearch, Stripe CLI, Flutter, and OrignaBase.
- [ ] Reinforce Rust and Dart error code / error handling quality.
- [ ] Review environment handling for localhost, dev, staging, and prod against current repo reality.
- [ ] Apply infra/security findings conservatively and only after verification.
- [ ] Audit all flows, fix as needed, verify with quorum

### 4C. Unwired / Incomplete Features

- [ ] Audit for unwired features, stale TODOs, dead paths, and incomplete integrations.
- [ ] Add only validated findings to `STATE.md`.

## Phase 5 — Reliability, Load, Stress, Benchmarks, Example Apps

Start only after Phases 1 through 3 are stable.

- [ ] Run all example app tests.
- [ ] Clean generated artifacts and stale processes after example app runs.
- [ ] Run reliability tests.
- [ ] Run load tests.
- [ ] Run stress tests.
- [ ] Run benchmarks.
- [ ] Record commands, pass/fail counts, and bottlenecks in `STATE.md`.

## Phase 6 — Coverage And Documentation

- [ ] Push Rust and Flutter coverage higher 
- [ ] Prioritize tests that exercise localhost/dev integrations over shallow unit-only gains.
- [ ] Document functions, classes, systems, and tricky flows that caused repeated drift or confusion.
- [ ] Search current best practices before final docs for complex systems.
- [ ] Improve weak runbooks/skills that caused avoidable churn during the wave.

## Delegation Rules

- [ ] Delegate bounded audits and disjoint implementation work when appropriate.
- [ ] Verify delegated findings locally before escalating them into `STATE.md`.
- [ ] Prefer existing local skills/runbooks over noisy ad hoc workflows.
- [ ] Do not let delegated work bypass local verification.

## Parking Lot

- [ ] Study repo/process improvements that materially reduce repeat failures.
- [ ] Explore additional AI/model feedback loops for UI/UX review only if they improve verified output quality.
- [ ] Revisit app-update prompting and other future enhancements after the active delivery gates are green.
* - [ ] improve if not already flutter app lifecycle events handling, search web, github for examples for e-commerce app
* - [ ] fix todos, warnings in vscode panel
- [ ] improve e2e api tests, add more live tests, run them all
- [ ] use them all for full audit:/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/.claude/skills
- [ ] audit and improve skills, claude.md, agents.md, etc
- [ ] track all notes in app and make sure all is wired
- [ ] increase number of live tests, cover more gaps, do it for rust and flutter, search web in depth to do it like a pro
- [ ] increase number of e2e visual tests, cover all gaps, execute them, debug, fix ui ux errors or issues
- [ ] after a fix then add 5+ tests to prevent the same issue from happening, also add inline docs for it
- [ ] use strong pro try catch that log the errors to sentry or logs collection. use modern tecniques, search web for rust and flutter best practices
- [ ] make sure db is replaceable using hexagonal architecture
- [ ] orignabase rules should be as strong as firebase rules
- [ ] orignabase queries should be similar to firebase
* - [ ] fix gaps with previews, right now it shows only empty state in some views. improve previews, cover all gaps
- [ ] no backward compatibility is needed, make sure no legacy code
- [ ] coverage for live tests and e2e should be 95+, its an order. Identify gaps and add tests accordingly
- [ ] there should be more than 200+ screenshots in desktop covering all states, variants, views. everytime we clear before generating again, to avoid duplication. cover any missing gaps
- [ ] search rust docs for best practices, create new skills as needed or improve. look for best practices for websockkets server, graphql, etc. audit full codebase.
- [ ] all screenshots in desktop should match the view they are supposed to represent. make sure login works. make sure to cover all gaps so that investors can see all views and states and variants with enough seeded data. if login fails crash and nuke test suite and investigate
- [ ] make sure there are semantic labels all over, find gaps and fix, add more e2e tests if needed.
- [ ] make sure to run all phases /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/specs . fix as needed
- [ ] run them all [text](e2e/ai), 


- audit screenshots in desktop vs views, widgets gaps
- audit for not connected elements in app
- dont stop till all screenshots in desktop, we are gonna show screenshots to investors, so make sure that the screenshots match the view
- fix gaps with previews, there is missing mockup data for previews
- /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/screens' add missing mockups for previews,  fix overflows or issues displaying if any
- /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/widgets' add missing mockups for previews, fix overflows or issues displaying if any
-everytime u do a pass u put a star before the element:.claude/skills/harness-loop/SKILL.md . dont stop
-always keep vps updated with latest deployement
-add x or star to mark work done on every pass
-improve all based on gaps, bugs, audit reports
-dont stop till 300+ screenshots on desktop, no excuses
-delete users if not already in mail api to restart free tier of less than 3000 users while we test
-fix testing failures as pro
-commit and push all to github




      