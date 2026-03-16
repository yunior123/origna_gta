# Origna GTA — Repo Map

Last updated: 2026-03-15 (updated: schema constants, API endpoints, widgets, E2E specs)

## Overview

Monorepo for Origna GTA, a Canada-first multi-vendor e-commerce platform.

| Layer | Technology |
|-------|-----------|
| Mobile/Web frontend | Flutter 3.x + Dart, Riverpod, Freezed |
| Backend API | OrignaBase (Rust, hosted on VPS 204.168.137.16) |
| Database | SurrealDB v2 (on VPS, via OrignaBase) |
| Search | Meilisearch v1.12 (on VPS, via OrignaBase) |
| Payments | Stripe (Checkout + Connect + webhooks) |
| Bot protection | Cloudflare Turnstile |
| Web reverse proxy | Caddy (on VPS) |
| CI | GitHub Actions |
| E2E | Playwright (TypeScript) |

No Firebase. No Cloud Functions. No Firestore. All backend is OrignaBase on the VPS.

---

## Directory Structure

```
origna_gta/                        # repo root
├── origna_gta/                    # Flutter app
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
│   ├── test/                      # Unit + widget tests
│   ├── integration_test/          # Flutter integration tests
│   └── pubspec.yaml
├── e2e/                           # Playwright E2E test suite
│   ├── playwright_ui/             # .spec.ts test files
│   ├── playwright.config.dev.ts
│   ├── playwright.config.staging.ts
│   ├── playwright.config.ci.ts
│   └── README.md                  # How to run E2E tests
├── scripts/
│   ├── deploy_web.sh              # VPS web deploy (staged releases)
│   └── pre_push_validation.sh     # Pre-push quality checks
├── .claude/
│   ├── hooks/                     # Claude Code hooks
│   ├── agents/                    # Sub-agent definitions
│   └── rules/                     # Coding rules
├── Caddyfile                      # VPS reverse proxy config
├── README.md                      # Root README
├── TODOS.md                       # Active task list
├── BUGS.md                        # Known bugs
└── STATE.md                       # Current app state / audit
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

## Backend (OrignaBase VPS)

- **Host**: `204.168.137.16`
- **API**: `https://api.dev.orignagta.ca` (dev), `https://api.orignagta.ca` (prod)
- **Web**: `https://dev.orignagta.ca` (dev), `https://orignagta.ca` (prod)
- **SurrealDB**: port 8000 (internal), namespace `orignabase`, db `production`
- **Meilisearch**: port 7700 (internal), key `REDACTED_SECRET`
- **Docker Compose**: `/opt/orignabase/` on VPS
- **Config**: `orignabase.toml` + env var overrides

Key env overrides:
- `OB_DATABASE__ENDPOINT` — SurrealDB endpoint
- `OB_SEARCH__ENDPOINT` — Meilisearch endpoint
- JWT keys auto-generated at `./data/keys` on first startup

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

Config files:
- `e2e/playwright.config.dev.ts` — target: `https://dev.orignagta.ca`
- `e2e/playwright.config.staging.ts` — staging
- `e2e/playwright.config.ci.ts` — CI (GitHub Actions)

Run instructions: `e2e/README.md`

Test spec files: `e2e/playwright_ui/*.spec.ts` — **62 specs** covering:
- **Auth**: auth-gates, google-auth-config, password-reset
- **Buyer flows**: buyer-flow, cart-manipulation, checkout-validation, favorites, order-lifecycle, order-cancellation-refund, return-request, reorder-language
- **Seller flows**: seller-flow, seller-registration, seller-product-management, seller-screens-ui, add-product-e2e, edit-product, shipping-approval, shipping-calculation
- **Admin**: admin-panel, admin-actions, admin-reviews, admin-security
- **Search**: search-products, search-filters-sort, subcategory-filtering, trending-products
- **Payments**: stripe-payment, payment-edge-cases, premium-subscription, non-premium-paywall
- **Chat/Notifications**: chat-screen, notifications, order-notifications, new-notification-features, stock-notif
- **Profile/Address**: profile-management, address-management
- **Legal**: legal-screens
- **Warehouse**: warehouse-multi-location, multi-seller-orders
- **Security**: edge-cases-security, adversarial-injection, rate-limiting, security-access-control-deep, orignabase-security
- **Misc**: accessibility, design-audit, visual-audit, visual-regression, coverage-gate, api-coverage, deep-ui-scenarios, product-video-e2e, digital-product-e2e, qa-product

---

## Deploy

Web (Flutter) to VPS:
```bash
VPS_HOST=root@204.168.137.16 ./scripts/deploy_web.sh dev
```
Uses staged releases at `/var/www/orignagta/{env}/releases/<timestamp>` with atomic `current` symlink via Caddy.

Build commands per env:
- Dev: `flutter build web --debug --dart-define=ENVIRONMENT=dev --dart-define=FORCE_SEMANTICS=true`
- Staging: `flutter build web --profile --dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true`
- Production: `flutter build web --release --dart-define=ENVIRONMENT=production`
