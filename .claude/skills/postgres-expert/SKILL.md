---
name: postgres-expert
description: "PostgreSQL + Rust sqlx expert for OrignaBase. Hexagonal architecture (ports & adapters), JSONB document store, parameterized queries (zero SQL injection), query optimization, migration patterns. Use when writing DB code, reviewing queries, optimizing performance, or auditing SQL injection."
---

# PostgreSQL Expert — OrignaBase

Expert-level PostgreSQL guidance for the OrignaBase Rust backend using sqlx, JSONB document storage, and hexagonal (ports & adapters) architecture.

## When to Use

- Writing or reviewing any database query (Rust or SQL)
- Optimizing slow queries or adding indexes
- Creating or modifying PostgreSQL migrations
- Auditing for SQL injection vulnerabilities
- Designing new tables, relations, or JSONB schemas
- Reviewing hexagonal architecture compliance (no SQL leaking into handlers)

## Architecture: Hexagonal (Ports & Adapters) — Non-Negotiable

```
Handlers (ob-handlers, ob-auth, ob-admin, ob-graphql)
    | call: state.db.create_document("orders", data)
    | NEVER: state.db.query_raw("SELECT...")
    v
DatabaseStore trait (ob-core/src/ports/db_store.rs)
    | 13 generic CRUD methods
    v
PgDatabaseStore adapter (ob-database/src/pg_store.rs)
    | sqlx::PgPool underneath
    v
PostgreSQL 18
```

### Rules
1. **Handlers NEVER write raw SQL** — they call trait methods only
2. **All SQL lives in the adapter** (`pg_store.rs`) — nowhere else
3. **Domain models are DB-free** — no sqlx derives on domain types
4. **New DB = new adapter** — zero handler/domain changes needed
5. **Tests mock at trait boundary** — not at SQL level

### Anti-patterns (REJECT these)
```rust
// BAD: SQL in handler
state.db.query_raw(&format!("SELECT * FROM orders WHERE status = '{}'", status))

// GOOD: CRUD method call
state.db.list_documents_where("orders", "status", status).await

// BAD: format! with user input in SQL (SQL INJECTION!)
format!("SELECT * FROM {} WHERE name = '{}'", table, user_input)

// GOOD: Parameterized query via trait method
state.db.query_bind(
    "SELECT * FROM orders WHERE data->>'name' = $1",
    json!({"name": user_input})
)
```

## SQL Injection Prevention — Zero Tolerance

### Rule: NEVER interpolate user input into SQL strings

```rust
// CRITICAL VULNERABILITY — format! with user input
let q = format!("WHERE name = '{}'", user_input); // SQL INJECTION!

// SAFE — parameterized query
sqlx::query("SELECT * FROM users WHERE data->>'name' = $1")
    .bind(&user_input)
    .fetch_all(&pool)
    .await
```

### Checklist (run before every commit touching SQL)
1. `grep -rn 'format!.*SELECT\|format!.*INSERT\|format!.*UPDATE\|format!.*DELETE' crates/` — flag any with user input
2. All `query_bind` calls use `$param` named params, never string interpolation
3. Table names use `sanitize_table_name()` which validates alphanumeric+underscore only
4. Collection names from user input are validated via `ob_core::validate_identifier()`
5. No `query_raw` with format! — use `query_bind` with params instead

### Safe Patterns
```rust
// Table name from constant (safe — not user input)
let table = sanitize_table_name(collections::ORDERS)?; // validated constant
format!("SELECT * FROM {table} WHERE id = $1") // $1 is parameterized

// User field access via JSONB (safe — field name is a constant)
format!("SELECT * FROM {table} WHERE data->>'{}' = $1", fields::STATUS)

// UNSAFE — field name from user input
format!("SELECT * FROM {table} WHERE data->>'{user_field}' = $1") // INJECTION RISK!
```

## JSONB Document Storage Pattern

### Schema
```sql
CREATE TABLE IF NOT EXISTS table_name (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Field Access
```sql
-- Text field
data->>'fieldName'                    -- returns TEXT
-- Nested field
data->'seller'->>'stripeAccountId'    -- returns TEXT
-- Numeric comparison (cast required)
(data->>'priceCents')::int > 1000
-- Boolean
(data->>'isPerishable')::boolean = true
-- Array contains
data->'tags' @> '"organic"'::jsonb
-- Full object
data->'address'                       -- returns JSONB object
```

### JSONB Update Patterns
```sql
-- Merge (shallow)
UPDATE orders SET data = data || '{"status": "shipped"}'::jsonb WHERE id = $1

-- Set specific field
UPDATE orders SET data = jsonb_set(data, '{status}', '"shipped"') WHERE id = $1

-- Increment integer field
UPDATE products SET data = jsonb_set(
    data,
    '{stockQuantity}',
    ((COALESCE((data->>'stockQuantity')::int, 0) - 1)::text)::jsonb
) WHERE id = $1 AND (data->>'stockQuantity')::int > 0

-- Remove field
UPDATE users SET data = data - 'temporaryToken' WHERE id = $1

-- Array append
UPDATE products SET data = jsonb_set(
    data,
    '{tags}',
    COALESCE(data->'tags', '[]'::jsonb) || '"newTag"'::jsonb
) WHERE id = $1
```

## Indexing Strategy

### Expression Indexes for JSONB
```sql
-- Always index fields used in WHERE clauses
CREATE INDEX idx_orders_status ON orders ((data->>'orderStatus'));
CREATE INDEX idx_orders_buyer ON orders ((data->>'buyerId'));
CREATE INDEX idx_products_price ON products (((data->>'priceCents')::int));
CREATE INDEX idx_products_seller ON products ((data->>'sellerId'));

-- GIN index for array/contains queries
CREATE INDEX idx_products_tags ON products USING GIN ((data->'tags'));

-- Partial index for active records only
CREATE INDEX idx_products_active ON products ((data->>'lifecycleStatus'))
    WHERE data->>'lifecycleStatus' = 'active';

-- Composite index
CREATE INDEX idx_orders_buyer_status ON orders (
    (data->>'buyerId'), (data->>'orderStatus')
);
```

### When to Add Indexes
- Any field used in WHERE with > 10K rows
- Any field used in ORDER BY
- Any field used in JOIN conditions
- Foreign key-like fields (buyerId, sellerId, productId)

### When NOT to Index
- Fields only used in SELECT (not filtered/sorted)
- Low-cardinality fields with < 1K rows
- Fields that change frequently (high write cost)

## Query Optimization

### EXPLAIN ANALYZE Everything
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE data->>'buyerId' = 'user123'
ORDER BY data->>'createdAt' DESC LIMIT 20;
```

### Common Performance Pitfalls
1. **Missing cast in comparison**: `data->>'priceCents' > 1000` compares TEXT, not INT
   - Fix: `(data->>'priceCents')::int > 1000`
2. **Full table scan on unindexed JSONB field**: Always create expression indexes
3. **N+1 queries**: Use batch fetches or JOINs instead of loops
4. **Unbounded SELECT**: Always use LIMIT + OFFSET, default page size = 20
5. **Large JSONB documents**: Keep docs < 8KB for optimal B-tree performance

### Pagination
```sql
-- Offset-based (simple, works for most cases)
SELECT * FROM products
WHERE data->>'lifecycleStatus' = 'active'
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- Keyset/cursor-based (better for deep pages)
SELECT * FROM products
WHERE created_at < $1
AND data->>'lifecycleStatus' = 'active'
ORDER BY created_at DESC
LIMIT $2;
```

## Migration Best Practices

### File Naming
```
orignabase/migrations/
  001_full_schema.sql          -- Initial schema (67 tables)
  002_add_product_variants.sql -- Feature additions
  003_add_shipping_zones.sql
```

### Rules
1. Migrations are **append-only** — never modify existing migration files
2. Every migration must be **idempotent** (`IF NOT EXISTS`, `CREATE OR REPLACE`)
3. Add `DOWN` migration comments for rollback documentation
4. Test migrations on a fresh database before deploying
5. Large data migrations: use `CONCURRENTLY` for index creation

### Schema Changes
```sql
-- Adding a column (JSONB = just add to data, no ALTER TABLE needed!)
-- But for indexed fields, add the expression index:
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_variant
    ON products ((data->>'variantId'));

-- For actual schema columns (rare):
ALTER TABLE orders ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0;
```

## Transactions

### When to Use
- Stock decrement + order creation (atomic)
- Refund + stock restore (atomic)
- Any read-modify-write cycle (TOCTOU prevention)
- Multi-table operations that must succeed or fail together

### Pattern
```rust
let mut tx = pool.begin().await?;

sqlx::query("UPDATE products SET data = jsonb_set(...) WHERE id = $1 AND (data->>'stockQuantity')::int >= $2")
    .bind(&product_id)
    .bind(quantity)
    .execute(&mut *tx)
    .await?;

sqlx::query("INSERT INTO orders (id, data) VALUES ($1, $2::jsonb)")
    .bind(&order_id)
    .bind(&order_data)
    .execute(&mut *tx)
    .await?;

tx.commit().await?;
```

### Optimistic Locking (CAS)
```sql
-- Compare-and-swap: only update if field matches expected value
UPDATE orders SET data = data || $1::jsonb
WHERE id = $2 AND data->>'updatedAt' = $3
RETURNING id, data::TEXT, created_at, updated_at;
-- Returns 0 rows if precondition failed (concurrent modification)
```

## Connection Pool Tuning

```rust
PgPoolOptions::new()
    .max_connections(20)        // Match expected concurrent handlers
    .min_connections(2)         // Keep warm connections ready
    .acquire_timeout(Duration::from_secs(10))
    .idle_timeout(Duration::from_secs(300))
    .max_lifetime(Duration::from_secs(1800))
```

### 8GB RAM Constraint
- Max 20 connections (each ~10MB)
- Never run parallel builds + database operations
- Monitor with: `SELECT count(*) FROM pg_stat_activity WHERE datname = 'orignabase';`

## Rust sqlx Patterns

### Compile-Time Checked (preferred for static queries)
```rust
let row = sqlx::query_as!(
    OrderRow,
    r#"SELECT id, data::TEXT as "data!", created_at, updated_at
       FROM orders WHERE id = $1"#,
    order_id
)
.fetch_optional(&pool)
.await?;
```

### Dynamic Queries (for translated/constructed queries)
```rust
let mut q = sqlx::query(&pg_query);
for val in &bind_values {
    q = bind_json_value(q, val);
}
let rows = q.fetch_all(&pool).await?;
```

### Error Handling
```rust
.map_err(|e| match e {
    sqlx::Error::RowNotFound => ob_core::Error::NotFound("Order not found".into()),
    sqlx::Error::Database(db_err) if db_err.is_unique_violation() =>
        ob_core::Error::Conflict("Duplicate record".into()),
    other => ob_core::Error::Database(format!("DB error: {other}")),
})
```

## Audit Checklist

Run this before any PR touching database code:

```bash
# 1. SQL injection scan
grep -rn 'format!.*SELECT\|format!.*INSERT\|format!.*UPDATE\|format!.*DELETE' \
    crates/ob-handlers/src/ | grep -v '//.*format'

# 2. Raw SQL in handlers (should be zero outside tests)
grep -rn 'query_raw\|query_bind' crates/ob-handlers/src/ | grep -v 'test' | grep -v '//'

# 3. Missing parameterization
grep -rn "format!.*WHERE.*=.*'{}" crates/ | grep -v test

# 4. Unbounded fetches (missing LIMIT)
grep -rn 'SELECT \* FROM' crates/ | grep -v 'LIMIT\|WHERE id' | grep -v test

# 5. Float money (should be zero)
grep -rn 'f64\|f32' crates/ob-handlers/src/ | grep -i 'price\|amount\|cost\|fee'
```
