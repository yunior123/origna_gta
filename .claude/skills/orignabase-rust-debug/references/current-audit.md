# OrignaBase Rust Audit — 2026-04-23

Use this note alongside `SKILL.md` when investigating current search/category/internal-error regressions.

## Sources Checked

- Rust `std::panic` docs:
  - `set_hook`: https://doc.rust-lang.org/std/panic/fn.set_hook.html
  - `catch_unwind`: https://doc.rust-lang.org/std/panic/fn.catch_unwind.html
- Tokio tracing guide: https://tokio.rs/tokio/topics/tracing
- `tracing` repo usage docs: https://github.com/tokio-rs/tracing
- Stripe webhook delivery docs: https://docs.stripe.com/webhooks
- Stripe thin-event migration idempotency guidance: https://docs.stripe.com/webhooks/migrate-snapshot-to-thin-events
- PostgreSQL JSONB docs: https://www.postgresql.org/docs/current/datatype-json.html
- Meilisearch GitHub issue on silent indexing failures:
  - https://github.com/meilisearch/meilisearch/issues/4438

## Current Repo Findings

1. Panic/tracing baseline is already present.
   - `orignabase/crates/orignabase/src/main.rs`
   - The server initializes a global JSON `tracing_subscriber` near process start.
   - `install_panic_hook()` is already registered and logs panic payload + location through `tracing::error!`.
   - Practical implication:
     - if production still shows vague `500` behavior with no panic evidence, suspect stale runtime, crash-before-init, or a non-panic logic error before rewriting panic infrastructure.

2. Search sync already retries and logs.
   - `orignabase/crates/ob-search/src/sync.rs`
   - Upserts retry three times with exponential backoff and emit `meilisearch_sync_retry` plus `meilisearch_sync_permanent_failure`.
   - Practical implication:
     - if DB-backed list queries are healthy but Meilisearch-backed search is empty, inspect sync logs and Meilisearch task state before changing frontend search callers.

3. Search/category live failures were likely deploy/runtime drift, not a still-broken source tree.
   - Live verification against `https://api.dev.orignagta.ca/graphql` passed on 2026-04-23 for:
     - category-filtered browse
     - keyword search
     - combined category + search
     - cursor pagination
     - active catalog coverage across all 21 storefront categories
   - Practical implication:
     - if UI still shows intermittent browse failures, focus on stale frontend bundle, malformed product rendering, or environment drift before reworking the query translator again.

4. Query-translation drift remains a historically high-risk area.
   - `orignabase/crates/ob-database/src/query.rs`
   - PostgreSQL translation around `OFFSET`, typed casts, JSONB field extraction, and `_contains` behavior has been a recent source of live breakage.
   - Practical implication:
     - any new browse/search 500 should be reproed first with the exact GraphQL payload, then matched to generated SQL behavior.

5. Stripe duplicate-event handling pattern is already the right model for internal webhook work.
   - Official Stripe docs still emphasize fast `2xx` acknowledgment and durable idempotency.
   - Thin-event migration docs explicitly recommend a unique idempotency table/key when the same logical event can arrive twice.
   - Practical implication:
     - prefer durable event tables / unique keys over in-memory duplicate suppression for backend payment or webhook flows.

6. Meilisearch can fail in ways that look healthier than they are.
   - The referenced GitHub issue shows accepted tasks and “successful” batches can still leave indexes effectively empty or misleadingly healthy.
   - Practical implication:
     - for search incidents, check:
       - application logs
       - Meilisearch task state
       - actual index contents
       - whether DB list endpoints are still returning correct rows

## Current Recommended Debug Order

1. Reproduce with the smallest failing HTTP call or targeted Cargo test.
2. Confirm whether the repo source already contains the likely fix.
3. Compare runtime/deploy state to source state.
4. Inspect logs around the exact timestamp.
5. If search is involved, separate:
   - DB listing
   - GraphQL filter translation
   - Meilisearch sync
   - frontend rendering/data-shape issues

## Current High-Signal Files

- `orignabase/crates/orignabase/src/main.rs`
- `orignabase/crates/ob-database/src/query.rs`
- `orignabase/crates/ob-database/src/pg_store.rs`
- `orignabase/crates/ob-search/src/client.rs`
- `orignabase/crates/ob-search/src/sync.rs`
- `orignabase/crates/ob-handlers/src/rest_api.rs`
- `orignabase/crates/ob-handlers/src/products/`
