# MASTER PLAN: Fix 96 Bugs + Migrate SurrealDB → PostgreSQL 18
## Database-Agnostic Hexagonal Architecture

**Scope:** ~133 files, 464 SurrealDB references, 183 DB call sites, 67 tables, 96 unfixed bugs
**Pre-launch:** No data backup needed — fresh start on PostgreSQL
**Duration:** 4 weeks (28 working days)

---

## Architecture: Database-Agnostic via Ports & Adapters

### The Problem
Current code: `state.db.query_raw("SELECT * FROM type::thing(...)")` — SQL leaks into handlers.
Future DB migration = rewrite all 183 call sites again.

### The Solution: `DatabaseStore` Trait

```
Handlers (ob-handlers, ob-auth, ob-admin, ob-graphql)
    │ call: db.get_document("orders", id)
    │ NEVER: db.query_raw("SELECT...")
    ▼
DatabaseStore trait (ob-core/src/ports/db_store.rs)
    │ 13 generic CRUD methods + begin()
    ▼
PgDatabaseStore adapter (ob-database/src/adapters/pg_store.rs)
    │ sqlx::PgPool underneath
    ▼
PostgreSQL 18
```

### Why This Pattern
- 133 existing CRUD call sites stay identical (just change import)
- Raw SQL moves from handlers → adapter implementations
- Future DB change = write new adapter, zero handler changes
- Domain repository traits can be added incrementally

### Migration Cost
| Category | Count | Action |
|----------|-------|--------|
| CRUD calls (already trait-compatible) | 133 | Import change only |
| Raw queries → CRUD conversion | ~20 | Simplify to method calls |
| Raw queries → SQL translation | ~30 | SurrealQL → PostgreSQL |
| Total handler changes | 183 | Most are import-only |

---

## Phase 0: P0 Critical Fixes on SurrealDB (Days 1-4)

Fix 15 showstopper bugs before touching the database layer. One commit per fix.

### 0A — Rust Backend (7 bugs)

| # | Bug | File | Fix |
|---|-----|------|-----|
| 0A-1 | SQL injection in stock decrement | `ob-handlers/payments/checkout.rs:829` | Replace `format!` with `query_bind_value` |
| 0A-2 | Payment failure doesn't restore stock | `ob-handlers/payments/webhooks.rs:751` | Add `restore_stock_for_order` in `handle_payment_intent_failed` |
| 0A-3 | Rollback SQL `??` invalid | `ob-handlers/orders/refunds.rs:466` | Use IF/THEN/ELSE |
| 0A-4 | TOCTOU in `update_item_status` | `ob-handlers/orders/status.rs:959` | Add `WHERE orderStatus = $expected` |
| 0A-5 | TOCTOU in `confirm_item_receipt` | `ob-handlers/orders/status.rs:427` | Same CAS guard |
| 0A-6 | Coupon error swallowed | `ob-handlers/payments/webhooks.rs:604` | Remove `.unwrap_or_default()` |
| 0A-7 | Float arithmetic on money | `ob-handlers/orders/shipping.rs:110` | Use basis points: `(cents * 120 + 50) / 100` |

### 0B — Flutter SDK (5 bugs)

| # | Bug | File | Fix |
|---|-----|------|-----|
| 0B-1 | GraphQL injection in SDK | `collection.dart:49,80,114,127,140` | Escape `collectionName`/`id` |
| 0B-2 | WebSocket auth wrong | `realtime.dart:96` | Use `?token=` query param |
| 0B-3 | Double checkout race | `checkout_payment_section.dart:136` | Set `isProcessing=true` synchronously |
| 0B-4 | Price verification sends dollars | `orignabase_checkout_provider.dart:176` | Send `priceCents` not `price` |
| 0B-5 | Stock validation bugs (3) | `orignabase_cart_repository.dart:79,216` | Fix `updateQuantity`, `addToCart` qty, variant stock |

### 0C — Flutter App (3 bugs)

| # | Bug | File | Fix |
|---|-----|------|-----|
| 0C-1 | Order state machine gaps | `order_state_machine.dart:10` | Add refund transitions to all states |
| 0C-2 | Dual subtotal representation | `checkout_screen.dart:150` | Use `priceCents` throughout |
| 0C-3 | Price truncation `~/ 1` | `models.dart:286` | Use `.round()` consistently |

**Quality gate:** `cargo clippy -D warnings && cargo test` + `flutter analyze && flutter test`

---

## Phase 1: PostgreSQL Setup + Architecture (Days 5-10)

### 1.1 `DatabaseStore` Trait — `ob-core/src/ports/db_store.rs`

```rust
#[async_trait]
pub trait DatabaseStore: Send + Sync + Clone + 'static {
    async fn create_document(&self, collection: &str, data: Value) -> AppResult<Value>;
    async fn get_document(&self, collection: &str, id: &str) -> AppResult<Value>;
    async fn update_document(&self, collection: &str, id: &str, data: Value) -> AppResult<Value>;
    async fn upsert_document(&self, collection: &str, id: &str, data: Value) -> AppResult<Value>;
    async fn delete_document(&self, collection: &str, id: &str) -> AppResult<Value>;
    async fn list_documents(&self, collection: &str, limit: Option<usize>, offset: Option<usize>) -> AppResult<Vec<Value>>;
    async fn query_raw(&self, query: &str) -> AppResult<Vec<Value>>;
    async fn query_raw_value(&self, query: &str) -> AppResult<Value>;
    async fn query_bind(&self, query: &str, binds: Value) -> AppResult<Vec<Value>>;
    async fn query_bind_value(&self, query: &str, binds: Value) -> AppResult<Value>;
    async fn batch_create(&self, collection: &str, docs: Vec<Value>) -> AppResult<Vec<Value>>;
    async fn begin(&self) -> AppResult<Box<dyn DatabaseTransaction>>;
}

#[async_trait]
pub trait DatabaseTransaction: Send {
    async fn execute(&mut self, query: &str, binds: Value) -> AppResult<u64>;
    async fn query(&mut self, query: &str, binds: Value) -> AppResult<Vec<Value>>;
    async fn commit(self: Box<Self>) -> AppResult<()>;
    async fn rollback(self: Box<Self>) -> AppResult<()>;
}
```

### 1.2 State Type Changes (8 consumers)

| State Type | Before | After |
|-----------|--------|-------|
| `HandlersState` | `db: DatabaseClient` | `db: Arc<dyn DatabaseStore>` |
| `AuthState` | `db: ob_database::DatabaseClient` | `db: Arc<dyn DatabaseStore>` |
| `AdminState` | `db: DatabaseClient` | `db: Arc<dyn DatabaseStore>` |
| `AnalyticsState` | `db: DatabaseClient` | `db: Arc<dyn DatabaseStore>` |
| `NotificationsState` | `db: DatabaseClient` | `db: Arc<dyn DatabaseStore>` |
| `FunctionsState` | `db: Option<DatabaseClient>` | `db: Option<Arc<dyn DatabaseStore>>` |
| `McpState` | `db: Arc<DatabaseClient>` | `db: Arc<dyn DatabaseStore>` |
| GraphQL | `ctx.data::<DatabaseClient>()` | `ctx.data::<Arc<dyn DatabaseStore>>()` |

### 1.3 PostgreSQL Schema (67 Tables)

All tables get: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()` + auto-update trigger.

**User Domain:** users, user_security, pending_profiles, addresses, buyer_addresses, fcm_tokens
**Product Domain:** products, favorites, reviews, product_ratings, product_questions, product_recommendations, user_recommendations, review_votes, seller_ratings, stock_notifications
**Order Domain:** orders, order_events, return_requests, refunds, disputes, coupons, coupon_uses, pending_redemptions
**Cart Domain:** cart (UNIQUE user,product,variant)
**Seller Domain:** seller_profiles, seller_metrics, seller_skus, warehouses, inventory_levels, payouts
**Chat Domain:** chats, messages, message_reports
**Notification Domain:** notifications, _mail_logs, licenses, book_access_tokens, software_access_tokens, download_sessions
**Auth/Payment Domain:** webhook_events, webhook_logs, security_alerts, rate_limits, subscriptions, payment_providers
**Internal:** _task_queue, _cron_locks, _cron_failures, _locks, config, _admin_audit_log, _analytics_events, _metrics, _dynamic_links

### 1.4 Indexes

```sql
CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(lifecycle_status);
CREATE INDEX idx_products_price ON products(price_cents);
CREATE INDEX idx_products_created ON products(date_created DESC);
CREATE INDEX idx_products_tags ON products USING GIN(tags);
CREATE INDEX idx_products_images ON products USING GIN(images);
CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_stripe_session ON orders(stripe_session_id);
CREATE INDEX idx_orders_stripe_pi ON orders(stripe_payment_intent_id);
CREATE INDEX idx_cart_user ON cart(user_id);
CREATE INDEX idx_cart_product ON cart(product_id);
CREATE INDEX idx_cart_user_product ON cart(user_id, product_id);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_messages_thread ON messages(chat_id, created_at);
CREATE INDEX idx_task_queue_claim ON _task_queue(status, scheduled_at) WHERE status = 'pending';
CREATE INDEX idx_rate_limits_window ON rate_limits(user_id, action, created_at);
CREATE INDEX idx_webhook_events_id ON webhook_events(id);
CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_product ON favorites(product_id);
```

### 1.5 Migration Files (~15)

```
orignabase/migrations/
  001_create_users.sql
  002_create_products.sql
  003_create_orders.sql
  004_create_order_extras.sql
  005_create_cart.sql
  006_create_coupons.sql
  007_create_sellers.sql
  008_create_chat.sql
  009_create_notifications.sql
  010_create_digital.sql
  011_create_subscriptions.sql
  012_create_webhooks.sql
  013_create_internal.sql
  014_create_admin.sql
  015_create_recommends.sql
```

### 1.6 Docker + Config Changes

**Cargo.toml:** surrealdb → sqlx + async-trait
**docker-compose.yml:** surrealdb service → postgres:18-alpine
**docker-compose.test.yml:** same change
**.env files:** SurrealDB vars → PG vars
**config/*.toml:** SurrealDB config → PG config

---

## Phase 2: Rewrite ob-database Crate (Days 11-16)

### 2.1 client.rs — Surreal<Any> → PgPool
### 2.2 crud.rs — 13 DatabaseStore methods → PostgreSQL SQL
### 2.3 query.rs — GraphQL filters → PostgreSQL WHERE
### 2.4 transaction.rs — Fake SurrealDB tx → Real ACID
### 2.5 task_queue.rs — TOCTOU → FOR UPDATE SKIP LOCKED

### SurrealQL → SQL Conversion Table

| SurrealDB | PostgreSQL |
|-----------|-----------|
| `type::thing($t,$id)` | `$1::uuid` |
| `CREATE $t CONTENT $d RETURN AFTER` | `INSERT INTO {t} (...) VALUES (...) RETURNING *` |
| `UPSERT type::thing($t,$id) CONTENT $d` | `INSERT ... ON CONFLICT (id) DO UPDATE SET ... RETURNING *` |
| `UPDATE type::thing($t,$id) MERGE $d` | `UPDATE {t} SET ... WHERE id = $1 RETURNING *` |
| `DELETE FROM type::thing($t,$id)` | `DELETE FROM {t} WHERE id = $1` |
| `time::now()` | `now()` |
| `string::startsWith($f,$p)` | `$f LIKE $p \|\| '%'` |
| `array::union($a,$b)` | `$a \|\| $b` |
| `$field ?? $default` | `COALESCE($field, $default)` |
| `INFO FOR DB` | `SELECT table_name FROM information_schema.tables WHERE table_schema='public'` |
| `START $offset` | `OFFSET $offset` |
| `math::mean()` | `AVG()` |
| `DEFINE INDEX` | `CREATE INDEX IF NOT EXISTS` |
| `RETURN 1` | `SELECT 1` |

---

## Phase 3: Handler Rewrites (Days 17-22, 183 call sites)

133 CRUD calls: import change only (trait instead of concrete type)
~20 raw→CRUD: simplify to `get_document`/`query_bind` calls
~30 raw→SQL: translate SurrealQL to PostgreSQL

Key handlers:
- `ob-handlers/cron/mod.rs` — 28 calls
- `ob-handlers/orders/returns.rs` — 14 calls
- `ob-handlers/payments/subscriptions.rs` — 6 calls
- `ob-handlers/users/mod.rs` — 9 calls
- `ob-auth/routes.rs` — 38 calls
- `ob-admin/routes.rs` — 12 calls
- `ob-graphql/resolvers.rs` — 13 calls

Components original plan missed:
- rules.ob → app-layer middleware
- shared/indexes.rs → CREATE INDEX
- shared/rate_limiter.rs → COUNT query
- scripts/backup.sh → pg_dump
- scripts/data-retention.sh → psql
- main.rs health/backup/schema init

---

## Phase 4: Dart SDK + Flutter (Days 23-25)

- collection.dart: HTTP REST (already mostly HTTP)
- realtime.dart: fix WebSocket auth (P0-7)
- Remove ID normalization helpers (products:abc123 → abc123)
- Remove timestamp.dart nanosecond normalization
- Update E2E TEST_UIDS format

---

## Phase 5: Remaining P1/P2/P3 Fixes (Days 26-28)

Auto-fixed by architecture: P0-4/5, P1-10, P2-26
Remaining: 18 P1 + 40 P2 + 24 P3 = 82 manual fixes

---

## Quality Gates (After Every Phase)

```bash
cargo clippy -D warnings && cargo test --all
cd origna_gta && flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
cd origna_gta/sdks/flutter/orignabase && flutter test
cd origna_gta/e2e && bun test specs/phase1-api/
```

---

## Timeline

| Phase | Days | Milestone |
|-------|------|-----------|
| 0: P0 Fixes | 1-4 | All 15 critical bugs fixed |
| 1: Architecture + PG Setup | 5-10 | DatabaseStore trait, 67-table schema, Docker |
| 2: ob-database Rewrite | 11-16 | PostgreSQL adapter passes tests |
| 3: Handler Rewrites | 17-22 | All 183 call sites migrated |
| 4: Dart SDK + Flutter | 23-25 | App runs end-to-end on PG |
| 5: P1/P2/P3 Fixes | 26-28 | All 96 bugs fixed |
| **TOTAL** | **28 days** | **Ship it** |

---

## DB-Agnostic Guarantees

| Principle | Implementation |
|-----------|---------------|
| Trait boundary | `DatabaseStore` trait in `ob-core` |
| No SQL in handlers | All SQL in `PgDatabaseStore` adapter |
| Domain models are DB-free | No DB-specific derives on domain types |
| Transaction abstraction | `DatabaseTransaction` trait |
| Error mapping | `map_db_error()` converts DB errors → domain errors |
| Factory pattern | Config-driven adapter selection |

**Future migration to MySQL/MongoDB/etc.:**
1. Write new adapter in `ob-database/src/adapters/mysql/`
2. Implement `DatabaseStore` trait methods
3. Update config to select new adapter
4. **Zero handler changes. Zero domain changes.**
