---
name: orignabase-rust-reliability
description: "Audit and debug OrignaBase Rust failures with a production-first checklist for panic handling, tracing, SQL/JSONB filters, and PostgreSQL-backed test isolation."
---

# OrignaBase Rust Reliability

Use this when auditing or fixing Rust server failures in `orignabase/`.

## Sources

- Rust std panic docs: `https://doc.rust-lang.org/std/panic/`
- Tokio tracing guide: `https://tokio.rs/tokio/topics/tracing`
- PostgreSQL JSON/JSONB docs: `https://www.postgresql.org/docs/current/datatype-json.html`
- Repo map references: `docs/REPO_MAP.md`
- Workspace architecture: `orignabase/docs/ARCHITECTURE.md`

## What To Check First

### 1) Panic boundaries
- Search for `unwrap()`, `expect()`, `panic!`, `unreachable!`
- Keep panics out of request paths unless they indicate corrupted process state
- For startup-only fatal checks, prefer explicit startup validation with actionable logs
- If panics are unavoidable, verify they include enough context to debug quickly

### 2) Tracing quality
- Ensure tracing is initialized as early as possible in `main`
- Prefer structured fields over string-only logs
- Include request IDs, user IDs, collection names, product IDs, order IDs where relevant
- Log error class + sanitized message + support/debug ID linkage

### 3) PostgreSQL JSONB correctness
- Verify whether a field lives in `data->>'field'` vs top-level SQL columns
- Check text-vs-numeric casts carefully (`NULLIF(..., '')::numeric` for numeric JSONB text)
- Validate case normalization for status fields (`active` vs `ACTIVE`)
- Confirm `categoryId`/`createdAt`/`priceCents` field names exactly match app constants

### 4) Test isolation
- `DatabaseClient::new_mem()` currently uses the shared local PostgreSQL test DB, so tests can race if they depend on global table state
- Prefer unique per-test IDs, seller IDs, categories, search terms, and cursors
- If a test expects exact row counts, isolate with unique filters instead of broad global queries
- Beware parallel truncation + insert races when the same PostgreSQL database is reused across tests

### 5) Query determinism
- For cursor pagination tests, scope rows with a unique seller/category/filter
- For search/filter tests, use UUID-scoped search tokens and categories
- When assertions fail only in full-suite runs but pass in isolation, suspect shared-state interference first

## Fast Audit Commands

```bash
cd orignabase
cargo clippy -- -D warnings
cargo test
cargo test -p ob-handlers test_get_products_filters_active_category_and_search -- --nocapture
cargo test -p ob-handlers test_get_products_accepts_category_id_alias -- --nocapture
cargo test -p ob-handlers test_list_products_honors_start_after_cursor -- --nocapture
rg -n "unwrap\(|expect\(|panic!|unreachable!" crates/
rg -n "data->>|::numeric|categoryId|lifecycleStatus|createdAt|priceCents" crates/
```

## Failure Patterns Seen In This Repo

### Shared DB test contamination
Symptoms:
- test passes alone, fails in full suite
- extra rows appear in list/search assertions
- cursor pagination returns more rows than expected

Fix approach:
- unique UUID-scoped fixtures
- narrow filters in tests
- avoid exact global-count assumptions

### JSONB filter drift
Symptoms:
- category/search/price filters return unexpected rows
- docs exist but handler filtering looks wrong

Fix approach:
- verify JSON path and type casts
- verify normalized status values
- compare against `origna_gta/lib/core/schema/schema_constants.dart`

### Startup security hard-fails
Symptoms:
- local server refuses to boot
- JWT/test-mode/secret checks stop startup

Fix approach:
- keep production-grade startup validation
- use explicit local dev env vars for test runs
- never weaken production checks to satisfy local shortcuts

## Done Criteria

- failing test reproduced
- root cause identified as code bug vs test isolation bug
- fix keeps production behavior strict
- targeted test passes
- `cargo clippy -- -D warnings` passes
- `cargo test` rerun documents any remaining blockers clearly
