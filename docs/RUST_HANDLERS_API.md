# OrignaBase Rust Handlers — API Reference

> Auto-generated from source code in `orignabase/crates/`. Last updated: 2026-03-23.

## Overview

OrignaBase replaces all 114 Python Cloud Functions with native Rust handlers organized by domain. The handlers live in `orignabase/crates/ob-handlers/src/` and are composed into a single Axum router in `orignabase/crates/orignabase/src/main.rs`.

### Crate Architecture

| Crate | Purpose |
|-------|---------|
| `orignabase` | Entry point, Axum server setup, route composition, CLI (clap) |
| `ob-core` | Config (TOML+env), error types (`AppError`), `TenantConfig` |
| `ob-database` | PostgreSQL client, CRUD (`crud.rs`), query translator (`query.rs`), transactions |
| `ob-auth` | JWT (RS256), auth routes, MFA/TOTP, email verification, middleware |
| `ob-graphql` | Dynamic schema builder, CRUD resolvers, batch mutations |
| `ob-handlers` | All business logic handlers (orders, payments, products, etc.) |
| `ob-storage` | Local filesystem + S3/R2, signed URLs, resumable uploads |
| `ob-search` | Meilisearch client, `SearchSyncer` |
| `ob-security` | Pest rules DSL parser + evaluator for row-level security |
| `ob-realtime` | WebSocket handler, change dispatcher, registry, presence |
| `ob-functions` | wasmi WASM runtime, function registry, triggers |
| `ob-analytics` | Privacy-first event tracking |
| `ob-admin` | Schema management, user management, HTML dashboard, alerts |
| `ob-notifications` | FCM push proxy, device tokens, topic subscriptions |
| `ob-mcp` | MCP (Model Context Protocol) server for AI agent integration |

---

## Auth — `ob-auth/src/`

### routes.rs

Authentication endpoints with strict rate limiting (10 req/min per IP).

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/auth/register` | `register` | Register a new user |
| POST | `/auth/login` | `login` | Login with email/password |
| POST | `/auth/refresh` | `refresh` | Refresh JWT tokens (body: `{"refresh_token": "..."}`) |
| POST | `/auth/reset-password` | `reset_password` | Reset password using a valid reset token |
| GET | `/auth/providers` | `auth_providers` | Public provider readiness for clients and E2E checks |
| GET | `/auth/google/start` | `google_oauth_start` | Begin backend-owned Google OAuth web flow |
| POST | `/auth/google` | `google_sign_in` | Sign in with Google (ID token exchange) |
| POST | `/auth/apple` | `apple_sign_in` | Sign in with Apple |
| POST | `/auth/oidc` | `oidc_sign_in` | Sign in with a generic OIDC provider |
| POST | `/auth/verify-email` | `verify_email` | Verify email with token |
| POST | `/auth/mfa/setup` | `mfa_setup` | Set up MFA (requires auth; secret stored as "pending") |
| POST | `/auth/mfa/challenge` | `mfa_challenge` | Verify TOTP during login; returns real tokens |
| POST | `/auth/mfa/recovery` | `mfa_recovery` | Use a recovery code to bypass TOTP |
| DELETE | `/auth/mfa` | `mfa_disable` | Disable MFA (requires current TOTP code) |
| POST | `/auth/anonymous` | `anonymous_sign_in` | Create anonymous session (upgradeable to real account) |
| POST | `/auth/magic-link` | `send_magic_link` | Send a magic link email for passwordless login |
| GET | `/admin/users` | `admin_list_users` | List users (admin only) |
| POST | `/admin/users` | `admin_create_user` | Create a user (admin only) |
| GET | `/admin/users/{user_id}` | `admin_get_user` | Get a single user (admin only) |

### jwt.rs

JWT token management using RS256 with key rotation.

- `issue_access_token(claims)` — Short-lived access token
- `issue_access_token_with_claims(claims)` — Access token with custom claims (admin-set)
- `issue_refresh_token(uid)` — Long-lived refresh token
- `issue_verification_token(uid)` — Email verification (24 hours)
- `issue_reset_token(uid)` — Password reset (1 hour)
- `issue_magic_link_token(uid)` — Magic link (15 minutes)
- `issue_challenge_token(uid)` — Indicates password auth passed but TOTP still needed
- `verify_token(token, keys)` — Verify JWT; tries current key, falls back to previous keys
- `generate_rsa_keys()` — Generate RSA key pair (private PEM, public PEM)
- `rotate_keys()` — Rotate keys, returns fingerprint of the new key

### totp.rs

TOTP (Time-based One-Time Password) implementation for MFA.

- `generate_secret()` — Cryptographically random TOTP secret
- `build_otpauth_url(secret, email)` — Standard `otpauth://` URL for authenticator apps
- `generate_qr_base64(url)` — QR code as base64-encoded PNG
- `verify_totp(secret, code)` — Verify TOTP code; rejects replay of same/earlier step
- `generate_recovery_codes()` — 8 hex-character recovery codes (32 bits entropy each)
- `hash_recovery_code(code)` — Argon2id hash for storage
- `verify_recovery_code(code, hash)` — Verify against stored Argon2id hash
- `encrypt_secret(secret, key)` — AES-256-GCM encryption (returns nonce || ciphertext)
- `decrypt_secret(encrypted, key)` — AES-256-GCM decryption

---

## Orders — `ob-handlers/src/orders/`

### status.rs — Order Status Management

State machine for order-level and item-level status transitions.

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/orders/confirm-receipt` | `confirm_item_receipt` | Buyer confirms delivery of a specific item |
| POST | `/api/orders/update-status` | `update_order_status` | Seller/admin updates order-level status |
| POST | `/api/orders/update-item-status` | `update_item_status` | Seller/admin updates per-item status |

**Order-Level State Machine:**

```
PendingPayment -> PaymentAuthorized -> Processing -> Shipped -> Delivered
                                    -> AwaitingShippingApproval -> Processing
PendingPayment -> Cancelled | Failed
PaymentAuthorized -> Cancelled
AwaitingShippingApproval -> Cancelled
Processing -> Cancelled
Shipped -> ReturnRequested
Delivered -> ReturnRequested | Refunded
ReturnRequested -> ReturnApproved | ReturnRejected
ReturnApproved -> Returned -> Refunded
```

**Item-Level (DeliveryStatus):** `Pending -> Shipped -> Delivered -> Refunded`

### refunds.rs — Refunds and Cancellations

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/orders/refund-item` | `refund_order_item` | Refund a specific item (Stripe refund + stock restore) |
| POST | `/api/orders/cancel` | `cancel_order` | Cancel an entire order |

**Side effects:** Stripe refund API call, stock quantity restoration (atomic PostgreSQL transaction), buyer/seller email notifications.

### returns.rs — Return Requests

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/returns/create` | `create_return_request` | Buyer creates a return request (30-day window) |
| POST | `/api/returns/approve` | `approve_return_request` | Seller/admin approves a return |
| POST | `/api/returns/reject` | `reject_return_request` | Seller/admin rejects a return |
| POST | `/api/returns/escalate` | `escalate_return_request` | Escalate a stale return request |

### shipping.rs — Shipping Approval Workflow

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/orders/approve-shipping` | `approve_shipping_cost` | Buyer approves calculated shipping cost |
| POST | `/api/orders/update-shipping` | `update_shipping_cost` | Seller updates shipping cost for an order |

---

## Payments — `ob-handlers/src/payments/`

### checkout.rs — Stripe Checkout

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/checkout/session` | `create_checkout_session` | Create a Stripe Checkout Session |
| POST | `/api/checkout/verify-prices` | `verify_cart_prices` | Verify cart prices haven't changed |

**Validation:** Canadian postal code format (`A1A1A1`), price > 0, price <= $100,000 CAD.

### webhooks.rs — Stripe Webhooks

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/webhooks/stripe` | `handle_stripe_webhook` | Validate HMAC signature, route events to handlers |

**Security:** HMAC signature verification (constant-time comparison), replay protection (reject > 300s old), idempotent processing via `webhook_events` collection dedup.

### capture.rs — Payment Capture

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/payments/capture` | `capture_payment` | Capture an authorized payment |

### connect.rs — Stripe Connect (Seller Onboarding)

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/connect/create-account` | `create_account` | Create a Stripe Connect account for a seller |
| POST | `/api/connect/account-link` | `create_account_link` | Generate an onboarding link |
| GET | `/api/connect/status` | `get_account_status` | Check seller Connect account status |

### subscriptions.rs — Premium Subscriptions ($7.86/mo CAD)

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/subscriptions/create` | `create_subscription` | Create a premium subscription |
| POST | `/api/subscriptions/cancel` | `cancel_subscription` | Cancel a subscription |
| GET | `/api/subscriptions/status` | `subscription_status` | Check subscription status |

- `route_subscription_webhook(event)` — Route Stripe subscription webhook events.

### providers.rs — Payment Provider Admin

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/api/payments/providers/list` | `get_payment_providers` | List configured payment providers |
| GET | `/api/payments/providers/status` | `get_provider_status` | Get provider health status |

---

## Products — `ob-handlers/src/products/`

### crud.rs — Product CRUD

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/products/upload-images` | `upload_images` | Upload product images (Cloudflare R2) |
| POST | `/api/products/upload-video` | `upload_product_video` | Upload product video |
| POST | `/api/products/delete-images` | `delete_product_images` | Delete product images from R2 |
| POST | `/api/products/create-atomic` | `create_product_atomic` | Create product with all data in one call |
| POST | `/api/products/delete` | `delete_product` | Soft-delete product (lifecycle: `deleted`) |
| GET | `/api/products/list` | `list_products` | List products with pagination |
| GET | `/api/products/seller-list` | `seller_list` | List seller's own products |
| POST | `/api/products/bulk-update` | `bulk_update_products` | Bulk update multiple products |
| POST | `/api/products/bulk` | `bulk_upload_products` | Bulk upload products |
| POST | `/api/products/update` | `update_product` | Update a single product |
| POST | `/api/products/toggle-favorite` | `toggle_favorite` | Toggle product favorite for user |

**Lifecycle:** `draft -> active -> inactive -> deleted`

### questions.rs — Product Q&A

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/products/questions/ask` | `ask_question` | Buyer asks a product question |
| POST | `/api/products/questions/answer` | `answer_question` | Seller answers a question |
| GET | `/api/products/questions/list` | `list_questions` | List questions for a product |

### ratings.rs — Ratings and Reviews

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/products/submit-rating` | `submit_rating` | Submit a product rating/review |
| GET | `/api/products/ratings` | `get_ratings` | Get paginated ratings for a product |
| POST | `/api/products/review-vote` | `review_vote` | Vote on a review (helpful/not) |
| POST | `/api/products/answer-review` | `answer_review` | Seller responds to a review |

### stock.rs — Stock Notifications

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/products/stock-notify/subscribe` | `subscribe` | Subscribe to back-in-stock notification |
| POST | `/api/products/stock-notify/unsubscribe` | `unsubscribe` | Unsubscribe from stock notification |

### triggers.rs — DB Triggers (Not HTTP Routes)

Called from `ob-functions` trigger system when product documents change:

- `on_product_created(doc)` — Sync new product to Meilisearch; set draft products with deactivation reason
- `on_product_updated(doc)` — Re-sync to Meilisearch; remove if deactivated/archived
- `on_product_deleted(doc)` — Remove from Meilisearch

---

## Shipping — `ob-handlers/src/shipping_calc/`

### mod.rs — Shipping Cost Calculator

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/shipping/calculate` | `calculate_shipping` | Calculate shipping cost |

Province-based pricing tiers, distance calculation via Geoapify, weight/volumetric surcharges, express/same-day multipliers. Perishable items: max 50km local delivery, no cross-province.

**Business rule:** Free shipping threshold at `$75.00 CAD` (7500 cents).

---

## Users — `ob-handlers/src/users/`

### mod.rs — User Profile Management

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/users/profile/update` | `update_profile` | Update user profile |
| GET | `/api/users/profile/get` | `get_profile` | Get user profile |
| POST | `/api/users/email-consent` | `email_consent` | CASL email consent management |
| POST | `/api/users/create-profile` | `create_profile` | Create initial profile |
| POST | `/api/users/cleanup-fcm-token` | `cleanup_fcm_token` | Remove stale FCM tokens |
| POST | `/api/users/address/add` | `add_buyer_address` | Add a buyer address |
| POST | `/api/users/address/update` | `update_buyer_address` | Update a buyer address |
| POST | `/api/users/address/delete` | `delete_buyer_address` | Delete a buyer address |

---

## Addresses — `ob-handlers/src/addresses/`

### mod.rs — Address Suggestions and Management

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/suggestions` | `get_suggestions` | Geoapify address autocomplete proxy |
| POST | `/buyer` | `add_buyer_address` | Add buyer address |
| PUT | `/buyer` | `update_buyer_address` | Update buyer address |
| DELETE | `/buyer` | `delete_buyer_address` | Delete buyer address |
| POST | `/buyer/default` | `set_default_buyer_address` | Set default buyer address |

---

## Chat — `ob-handlers/src/chat/`

### mod.rs — Product-Scoped Messaging

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/chat/get-or-create` | `get_or_create_chat` | Get or create a chat for a product |
| POST | `/api/chat/send` | `send_message` | Send a chat message |
| POST | `/api/chat/mark-read` | `mark_messages_read` | Mark messages as read |
| POST | `/api/chat/delete-message` | `delete_message` | Delete a chat message |
| POST | `/api/chat/report` | `report_message` | Report a chat message |
| POST | `/api/support/chat` | `support_chat` | AI-generated support chat responses |

---

## Coupons — `ob-handlers/src/coupons/`

### mod.rs — Coupon/Promo Code Management

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/coupons/apply` | `apply_coupon` | Validate and apply a coupon to cart |
| POST | `/api/admin/coupons/create` | `create_coupon` | Create a coupon (admin only) |
| POST | `/api/coupons/redeem` | `redeem_coupon` | Redeem a coupon |

---

## Digital Products — `ob-handlers/src/digital/`

### mod.rs — License Activation and Downloads

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/digital/activate-license` | `activate_license` | Activate a digital license |
| POST | `/api/digital/deactivate-license` | `deactivate_license` | Deactivate a digital license |
| POST | `/api/digital/download/book` | `download_book` | Generate a book download token |
| POST | `/api/digital/download/software` | `download_software` | Generate a software download token |
| POST | `/api/digital/verify-license` | `verify_license` | Verify license validity |
| GET | `/dl` | `get_book_redirect` | Redirect to book download URL |
| GET | `/sdl` | `get_software_redirect` | Redirect to software download URL |

---

## Warehouses — `ob-handlers/src/warehouses/`

### mod.rs — Seller Warehouse Management

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/api/warehouses/create` | `create_warehouse` | Create a warehouse |
| POST | `/api/warehouses/update` | `update_warehouse` | Update warehouse details |
| POST | `/api/warehouses/delete` | `delete_warehouse` | Delete a warehouse |
| GET | `/api/warehouses/list` | `list_warehouses` | List seller's warehouses |

---

## Geocoding — `ob-handlers/src/geocoding/`

### mod.rs — Geoapify Proxy

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/api/geocode/autocomplete` | `autocomplete` | Forward autocomplete requests with server-side API key |

---

## Email — `ob-handlers/src/email/`

### mod.rs — Postal Integration

Bilingual (EN/FR) email templates, CASL-compliant.

- `send_email(to, subject, html)` — POST to Postal REST API v3.1 (Basic auth)
- `order_confirmation_html(order)` — Order confirmation template
- `seller_notification_html(order)` — Seller new-order notification
- `low_stock_alert_html(product)` — Low stock alert
- `abandoned_cart_html(user, items)` — Abandoned cart reminder

### templates.rs

- `shipping_notification_html(order, tracking)` — Buyer shipping notification with tracking

### helpers.rs

- `send_order_confirmation_emails(order, state)` — Send confirmation to buyer + seller
- `send_shipping_notification(order, tracking)` — Send shipping update to buyer
- `resolve_buyer_contact(order)` — Get buyer name, email, language
- `resolve_seller_contact(order)` — Get seller name, email

---

## PDF — `ob-handlers/src/pdf/`

### mod.rs — Invoice Generation

Uses `genpdf` crate to produce bilingual PDF invoices.

- `generate_invoice(order)` — PDF bytes (Helvetica font, no external files)
- `generate_invoice_with_lang(order, lang)` — Bilingual PDF (EN or FR)

---

## Push Notifications — `ob-handlers/src/push/`

### mod.rs — FCM HTTP v1 API

- `send_push(state, user_id, title, body, data)` — Send push via FCM; rate limited to 20/day per user
- `check_daily_limit(state, user_id)` — Returns `true` if user can receive more pushes today

---

## Native Triggers — `ob-handlers/src/native_triggers.rs`

Database change triggers called by the `ob-functions` system on document mutations. Triggers Meilisearch sync, stock updates, and notification dispatch.

---

## Cron Jobs — `ob-handlers/src/cron/`

### mod.rs — 16+ Scheduled Jobs

All jobs use distributed cron locks to prevent concurrent execution. Batch operations commit every 500 docs.

| Job | Schedule | Description |
|-----|----------|-------------|
| `auto_capture_confirmed_receipts` | Periodic | Auto-deliver orders past `AUTO_CONFIRM_DAYS` without dispute |
| `check_expired_authorizations` | Periodic | Cancel orders with expired payment auth (7+ days) |
| `auto_archive_old_orders` | Periodic | Archive delivered/cancelled orders 30+ days old |
| `monitor_meilisearch_sync` | Periodic | Alert if DB-to-Meilisearch mismatch > 5% |
| `cleanup_stale_rate_limits` | Periodic | Delete rate_limits docs older than 2 hours |
| `cleanup_orphaned_r2_images` | Periodic | Find unreferenced R2 images (24h safety window) |
| `cleanup_stale_webhook_events` | Periodic | Delete webhook_events older than 7 days |
| `cleanup_stale_security_alerts` | Periodic | Archive resolved security_alerts older than 90 days |
| `retry_failed_meilisearch_syncs` | Periodic | Retry DLQ items with exponential backoff (max 3 retries) |
| `check_low_stock_alerts` | Periodic | Email sellers when stock <= threshold (23h cooldown) |
| `send_abandoned_cart_emails` | Periodic | Email users with cart items > 24h (72h cooldown) |
| `compute_seller_metrics` | Weekly | Dispute rate, refund rate, cancellation rate |
| `compute_trending_products` | Hourly | Weighted: 1x view + 3x purchase + 2x favorite (24h window) |
| `sync_expired_subscriptions` | Periodic | Fix subscription-user cache mismatches |
| `escalate_stale_return_requests` | Periodic | Escalate returns stuck > 7 days in "requested" |
| `send_premium_renewal_reminders` | Periodic | Email 7d + 1d before renewal |
| `drain_pending_notifications` | Periodic | Retry pending notifications; mark "failed" after 3+ attempts |

---

## Shared Utilities — `ob-handlers/src/shared/`

### rate_limiter.rs — Per-Endpoint Rate Limiting

- `check(key, limit)` — Check rate limit using governor
- `extract_client_ip(headers)` — Extract IP from `X-Forwarded-For` / `X-Real-IP` / peer address
- `check_user_rate_limit(state, user_id, action, limit)` — DB-backed per-user rate limiting

### validation.rs — Input Validation

- `validate_string(value, field, max_len)` — Non-empty, within max length
- `validate_amount_cents(amount)` — Positive, within bounds
- `validate_email(email)` — RFC 5322 simplified regex
- `validate_uid(uid)` — UUID format
- `sanitize_html(input)` — Strip all HTML tags (XSS prevention)
- `redact_contact_info(text)` — Redact phone/email from chat messages
- `validate_phone_e164(phone)` — E.164 format (e.g., `+14165551234`)
- `validate_postal_code_ca(code)` — Canadian format `A1A 1A1`

### auth.rs — Auth Helpers

- `require_authenticated(auth)` — Extract user ID or 401
- `require_admin(auth)` — Require admin role or 403
- `resolve_self_user_id(auth, body)` — Resolve user ID from auth context
- `resolve_admin_user_id(auth, body)` — Resolve admin user ID

### schema.rs — Schema Constants

Single source of truth for all collection names, field names, and enum values. Key collections: `users`, `products`, `orders`, `reviews`, `payouts`, `refunds`, `webhook_events`, `return_requests`, `subscriptions`, `chats`, `coupons`, `seller_profiles`, `warehouses`, `cart`, `addresses`.

### indexes.rs — Database Indexes

- `create_required_indexes(db)` — Idempotent index creation on frequently-queried tables

---

## Storage — `ob-storage/src/routes.rs`

File storage with S3/R2 backend, signed URLs, and resumable uploads.

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| PUT | `/storage/upload/{*path}` | `upload_file` | Upload via signed URL |
| GET | `/storage/download/{*path}` | `download_file` | Download with on-the-fly transforms (`w`, `h`, `fit`, `q`, `format`) |
| DELETE | `/storage/delete/{*path}` | `delete_file` | Delete via signed URL |
| POST | `/storage/upload/resumable` | `init_resumable` | Initiate resumable upload session |
| PUT | `/storage/upload/resumable/{id}` | `append_resumable` | Append chunk (`Upload-Offset` header) |
| GET | `/storage/upload/resumable/{id}` | `get_resumable_status` | Query upload progress |
| DELETE | `/storage/upload/resumable/{id}` | `cancel_resumable` | Cancel resumable upload |
| POST | `/storage/presign/upload` | `batch_presign_upload` | Batch presigned upload URLs |
| POST | `/storage/presign/download` | `batch_presign_download` | Batch presigned download URLs |
| POST | `/storage/batch-delete` | `batch_delete` | Delete multiple files (requires auth) |

---

## GraphQL — `ob-graphql/src/`

### schema.rs

- `build_schema(config, db, security)` — Build GraphQL schema with security limits from env vars
- `build_schema_with_limits(config, db, security, limits)` — Build with custom limits

### resolvers.rs

Dynamic CRUD resolvers for all collections. Accessed via `POST /graphql`. Supports filtering with object syntax: `{field: {_op: value}}`.

---

## Admin — `ob-admin/src/routes.rs`

HTML dashboard and administrative endpoints.

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/_admin` | `dashboard` | Admin HTML dashboard |
| GET | `/_admin/analytics` | `analytics_summary` | Analytics summary |
| GET | `/_admin/users` | `list_users` | List users |
| DELETE | `/_admin/users/{id}` | `delete_user` | Delete a user |
| GET | `/_admin/config` | `admin_config_get_all` | Get all config |
| GET | `/_admin/links` | `list_links` | List short links |
| GET | `/_admin/metrics` | `query_metrics` | Query metrics |
| DELETE | `/_admin/indexes/{name}` | `drop_index` | Drop a database index |
| GET | `/_admin/usage` | `usage_dashboard` | Usage dashboard |
| GET | `/_admin/alerts` | `system_alerts` | System alerts |
| POST | `/_admin/jwt/rotate` | `rotate_jwt_keys` | Rotate JWT signing keys |
| GET | `/_admin/jwt/status` | `jwt_key_status` | JWT key rotation status |
| POST | `/links` | `create_link` | Create a short link |
| GET | `/l/{slug}` | `redirect_link` | Redirect short link |
| GET | `/config` | `config_get_all` | Get all config (public) |
| GET | `/config/{key}` | `config_get` | Get single config value |
| GET | `/_admin/health` | `health` | Health check |

---

## Notifications — `ob-notifications/src/routes.rs`

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| POST | `/push/send` | `send_notification` | Send a push notification |

---

## REST API (MCP Integration) — `ob-handlers/src/rest_api.rs`

GET-based endpoints wrapping business logic for MCP server integration.

| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/products` | `get_products` | Search/list products (query params: `q`, `category`, `min_price`, `max_price`, `sort`, `limit`, `offset`) |
| GET | `/products/{id}` | `get_product` | Get single product |
| POST | `/products` | `create_product` | Create product (validated: priceCents > 0, <= $100k, valid lifecycle) |
| GET | `/cart` | `get_cart` | Get authenticated user's cart |
| GET | `/orders` | `list_orders` | List user's orders |
| GET | `/orders/{id}` | `get_order` | Get single order |
| GET | `/user/profile` | `get_user_profile` | Get authenticated user's profile |

---

## Router Composition — `orignabase/src/main.rs`

The main router assembles all sub-routers:

1. `/health` — Health check (outside rate limiting layer)
2. `/graphql` — GraphQL endpoint (GET: GraphiQL UI, POST: queries)
3. `/auth/*`, `/admin/*` — Auth routes with strict rate limiting (10 req/min per IP)
4. `/api/*` — All handler routes with standard rate limiting
5. `/storage/*` — Storage routes
6. `/push/*` — Notification routes
7. `/_admin/*` — Admin dashboard
8. `/fn/*` — WASM function triggers (catch-all)

**Middleware stack:** CORS, request tracing, JWT auth extraction, rate limiting (tower_governor), tenant resolution.
