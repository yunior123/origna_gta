# ob-handlers SurrealDB → PostgreSQL Migration Strategy

> **Goal:** Fix 537 failing tests in `orignabase/crates/ob-handlers/` by translating SurrealDB queries to PostgreSQL.
> **Status:** In progress — ~3,268 tests passing, 537 failing (all in ob-handlers).
> **Last updated:** 2026-03-29

---

## 1. SurrealDB → PostgreSQL Translation Patterns

Every failing test uses one or more of these SurrealDB-specific patterns. Master these translations and the migration is mechanical.

### 1.1 `RETURN AFTER` → `RETURNING`

SurrealDB returns the modified record after write operations. PostgreSQL uses `RETURNING *`.

```sql
-- SurrealDB
CREATE users CONTENT { name: "Alice", email: "alice@example.com" } RETURN AFTER;

-- PostgreSQL
INSERT INTO users (id, data) VALUES ($1, $2::jsonb) RETURNING *;
```

**Rust translation:**
```rust
// Before (SurrealDB)
query_bind("CREATE users CONTENT $data RETURN AFTER", data)

// After (PostgreSQL) — use query_bind which auto-translates, or:
query_bind("INSERT INTO users (id, data) VALUES ($1, $2::jsonb) RETURNING *", (id, data))
```

### 1.2 `type::thing($table, $id)` → Direct ID

SurrealDB's `type::thing()` constructs a record ID reference. PostgreSQL just uses the ID directly.

```sql
-- SurrealDB
SELECT * FROM type::thing("users", $user_id);

-- PostgreSQL
SELECT * FROM users WHERE id = $1;
```

**Rust translation:**
```rust
// Before
query_bind("SELECT * FROM type::thing($table, $id)", ("users", user_id))

// After
query_bind("SELECT * FROM users WHERE id = $1", user_id)
```

### 1.3 `CREATE collection CONTENT $data` → `INSERT INTO`

```sql
-- SurrealDB
CREATE orders CONTENT { userId: $uid, status: "pending", items: [...] } RETURN AFTER;

-- PostgreSQL
INSERT INTO orders (id, data) VALUES ($1, $2::jsonb) RETURNING *;
```

**Rust translation:**
```rust
// Before
let mut data = json!({ "userId": uid, "status": "pending", "items": items });
query_bind("CREATE orders CONTENT $data RETURN AFTER", data)

// After
let id = generate_ulid();
let mut data = json!({ "id": id, "userId": uid, "status": "pending", "items": items });
query_bind(
    "INSERT INTO orders (id, data) VALUES ($1, $2::jsonb) RETURNING *",
    (id, serde_json::to_value(&data)?)
)
```

### 1.4 `UPDATE type::thing($table, $id) MERGE $data` → `UPDATE ... SET data = data ||`

SurrealDB's `MERGE` does a JSON merge (shallow). PostgreSQL equivalent: `data = data || $2::jsonb`.

```sql
-- SurrealDB
UPDATE type::thing("orders", $order_id) MERGE { status: "shipped" } RETURN AFTER;

-- PostgreSQL
UPDATE orders SET data = data || '{"status": "shipped"}'::jsonb WHERE id = $1 RETURNING *;
```

**Rust translation:**
```rust
// Before
query_bind(
    "UPDATE type::thing($table, $id) MERGE $data RETURN AFTER",
    ("orders", order_id, json!({ "status": "shipped" }))
)

// After
query_bind(
    "UPDATE orders SET data = data || $2::jsonb WHERE id = $1 RETURNING *",
    (order_id, json!({ "status": "shipped" }))
)
```

### 1.5 `DELETE type::thing($table, $id)` → `DELETE FROM ... WHERE id =`

```sql
-- SurrealDB
DELETE type::thing("cart_items", $item_id);

-- PostgreSQL
DELETE FROM cart_items WHERE id = $1;
```

### 1.6 `SELECT * FROM collection WHERE field = $param` → JSONB field access

SurrealDB fields are top-level. PostgreSQL stores them in a JSONB `data` column.

```sql
-- SurrealDB
SELECT * FROM orders WHERE userId = $uid;

-- PostgreSQL
SELECT * FROM orders WHERE data->>'userId' = $1;
```

**Rust translation:**
```rust
// Before
query_bind("SELECT * FROM orders WHERE userId = $uid", uid)

// After
query_bind("SELECT * FROM orders WHERE data->>'userId' = $1", uid)
```

For nested fields:
```sql
-- SurrealDB
SELECT * FROM products WHERE seller.stripeAccountId = $account_id;

-- PostgreSQL
SELECT * FROM products WHERE data->'seller'->>'stripeAccountId' = $1;
```

For numeric comparisons (cast from JSONB text):
```sql
-- SurrealDB
SELECT * FROM products WHERE priceCents > 1000;

-- PostgreSQL
SELECT * FROM products WHERE (data->>'priceCents')::int > 1000;
```

### 1.7 `IF ... THEN ... ELSE ... END` → `CASE WHEN`

```sql
-- SurrealDB
IF $status = "pending" THEN
  UPDATE type::thing("orders", $id) MERGE { status: "confirmed" }
ELSE
  SELECT * FROM type::thing("orders", $id)
END

-- PostgreSQL
UPDATE orders
SET data = data || jsonb_build_object('status', 'confirmed')::jsonb
WHERE id = $1 AND data->>'status' = 'pending'
RETURNING *;
```

### 1.8 `??` (SurrealDB coalesce) → `COALESCE()`

```sql
-- SurrealDB
SELECT name ?? "Unknown" AS name FROM products WHERE id = $id;

-- PostgreSQL
SELECT COALESCE(data->>'name', 'Unknown') AS name FROM products WHERE id = $1;
```

### 1.9 `string::startsWith()` / `string::contains()` → `LIKE` / `LEFT()`

```sql
-- SurrealDB
SELECT * FROM products WHERE string::startsWith(slug, $prefix);

-- PostgreSQL
SELECT * FROM products WHERE data->>'slug' LIKE $1 || '%';
```

### 1.10 `array::contains()` → `@>` (JSONB contains)

```sql
-- SurrealDB
SELECT * FROM products WHERE array::contains(tags, "organic");

-- PostgreSQL
SELECT * FROM products WHERE data->'tags' @> '"organic"'::jsonb;
```

### 1.11 `math::sum()` / `math::count()` → Aggregate functions

```sql
-- SurrealDB
SELECT math::sum(totalCents) AS total FROM orders WHERE userId = $uid;

-- PostgreSQL
SELECT SUM((data->>'totalCents')::int) AS total FROM orders WHERE data->>'userId' = $1;
```

### 1.12 `GROUP BY` with JSONB fields

```sql
-- SurrealDB
SELECT status, count() AS cnt FROM orders GROUP BY status;

-- PostgreSQL
SELECT data->>'status' AS status, COUNT(*) AS cnt FROM orders GROUP BY data->>'status';
```

### 1.13 `ORDER BY` with JSONB fields

```sql
-- SurrealDB
SELECT * FROM products ORDER BY dateCreated DESC LIMIT 20;

-- PostgreSQL
SELECT * FROM products ORDER BY (data->>'dateCreated')::timestamptz DESC LIMIT 20;
```

---

## 2. Impact-Based Priority

### P0: Payments & Checkout (Revenue-Critical)
| Handler | File | Est. Tests | Risk |
|---------|------|-----------|------|
| Checkout | `checkout.rs` | ~30 | Stripe session creation, amount validation |
| Webhooks | `webhooks.rs` | ~40 | Stripe event processing, idempotency |
| Subscriptions | `subscriptions.rs` | ~25 | Premium lifecycle, proration |

**Why P0:** Payment failures = lost revenue. Every test here validates money flow correctness.

### P1: Orders & Status (Order Lifecycle)
| Handler | File | Est. Tests | Risk |
|---------|------|-----------|------|
| Status | `status.rs` | ~20 | Status transitions, stock updates |
| Returns | `returns.rs` | ~15 | Return requests, refund triggers |
| Refunds | `refunds.rs` | ~15 | Stripe refund API, stock restoration |
| Notifications | `notifications.rs` | ~10 | Order status change notifications |

**Why P1:** Broken order flow = broken business. Status transitions affect inventory + notifications.

### P2: Products (Catalog Management)
| Handler | File | Est. Tests | Risk |
|---------|------|-----------|------|
| CRUD | `crud.rs` | ~25 | Product create/update/delete |
| Stock | `stock.rs` | ~15 | Inventory tracking, oversell prevention |
| Triggers | `triggers.rs` | ~10 | Price change triggers, search sync |
| Reviews | `reviews.rs` | ~10 | Rating aggregation |

**Why P2:** Products are the catalog backbone. Broken CRUD = no catalog.

### P3: Users, Addresses & Chat (Social Features)
| Handler | File | Est. Tests | Risk |
|---------|------|-----------|------|
| Users | `users.rs` | ~15 | Profile, settings |
| Addresses | `addresses.rs` | ~10 | Shipping address CRUD |
| Chat | `chat.rs` | ~20 | Real-time messaging |
| Favorites | `favorites.rs` | ~10 | Wishlist |

**Why P3:** Important for UX but not revenue-blocking.

### P4: Native Triggers & Cron (Background Jobs)
| Handler | File | Est. Tests | Risk |
|---------|------|-----------|------|
| Cron | `cron.rs` | ~10 | Scheduled tasks |
| Native triggers | `native_triggers.rs` | ~15 | Event-driven side effects |
| Analytics | `analytics.rs` | ~10 | Privacy-first tracking |

**Why P4:** Background jobs are less time-critical.

---

## 3. Migration Approach

### 3.1 Strategy: One Handler File = One PR

Each handler file (`checkout.rs`, `webhooks.rs`, etc.) is migrated as a single, atomic PR:

1. **Translate** all SurrealDB queries to PostgreSQL equivalents
2. **Update** test setup/teardown (seed data via `INSERT INTO` instead of `CREATE CONTENT`)
3. **Run** `cargo test -p ob-handlers <handler_name>` — all tests must pass
4. **Run** `cargo clippy -D warnings` — no warnings
5. **Commit** and move to next file

### 3.2 Query Translation Layers

The codebase has two paths for running queries:

#### Path A: `query_bind()` (auto-translated)
The `query_bind` method in `ob-database` already has a SurrealQL → PostgreSQL translator. For simple queries, just pass the SurrealDB-style query and it will translate automatically.

```rust
// This may already work if the translator handles it:
query_bind("SELECT * FROM orders WHERE userId = $uid", uid)
```

**Use Path A when:** The translator handles the pattern (simple SELECT, INSERT, UPDATE, DELETE).

#### Path B: Direct SQL with `pool()`
For complex queries that the translator can't handle (subqueries, CTEs, complex JSONB operations), write raw PostgreSQL:

```rust
use crate::database::pool;

let rows = pool()
    .query(
        "SELECT * FROM orders WHERE data->>'userId' = $1 ORDER BY (data->>'createdAt')::timestamptz DESC LIMIT $2",
        &[&uid, &limit]
    )
    .await?;
```

**Use Path B when:** The query is complex, involves multiple JSONB operations, or the translator produces incorrect SQL.

### 3.3 Test Data Seeding

Test setup currently uses SurrealDB `CREATE CONTENT` patterns. Replace with direct SQL:

```rust
// Before (SurrealDB)
query_bind("CREATE users CONTENT $data", test_user_data()).await?;

// After (PostgreSQL)
pool().execute(
    "INSERT INTO users (id, data) VALUES ($1, $2::jsonb)",
    &[&user_id, &serde_json::to_value(&test_user_data())?]
).await?;
```

### 3.4 Transaction Handling

SurrealDB transactions:
```rust
let mut txn = db.begin_transaction().await?;
// ... operations ...
txn.commit().await?;
```

PostgreSQL transactions (via `pool()`):
```rust
let mut txn = pool().begin().await?;
// ... operations using txn.execute() instead of pool().query() ...
txn.commit().await?;
```

---

## 4. Verification Checklist (Per Handler)

After migrating each handler file:

```bash
# 1. Run the specific handler tests
cargo test -p ob-handlers <handler_name>

# 2. Run clippy (must pass with zero warnings)
cargo clippy -D warnings

# 3. Run the full ob-handlers suite to check for regressions
cargo test -p ob-handlers

# 4. Run the full workspace tests
cargo test
```

---

## 5. Effort Estimate

| Priority | Files | Tests | Est. Hours/File | Total Hours |
|----------|-------|-------|----------------|-------------|
| P0 | ~5 | ~95 | 3h (complex Stripe logic) | ~15h |
| P1 | ~8 | ~60 | 2.5h | ~20h |
| P2 | ~10 | ~60 | 2h | ~20h |
| P3 | ~12 | ~55 | 1.5h | ~18h |
| P4 | ~15 | ~267 | 1.5h | ~22h |
| **Total** | **~50** | **537** | **avg 2h** | **~95h** |

**Realistic timeline:** 2–3 focused days (8h/day) for a single developer, or 1 day with parallel agents on independent handlers.

---

## 6. Anti-Patterns to Avoid

1. **Don't wrap SurrealDB queries in string manipulation** — use the `query_bind` translator or write clean PostgreSQL directly.
2. **Don't use `SELECT *` and deserialize with SurrealDB structs** — PostgreSQL returns `(id, data)` tuples; update deserialization accordingly.
3. **Don't forget `RETURNING *`** — SurrealDB's `RETURN AFTER` is implicit in some cases; PostgreSQL always needs explicit `RETURNING`.
4. **Don't use `double` for money** — PostgreSQL JSONB stores numbers as numeric; cast `(data->>'priceCents')::int` when comparing.
5. **Don't skip test teardown** — PostgreSQL requires explicit `DELETE FROM` cleanup; SurrealDB's namespace isolation won't save you.
