---
name: orignabase-rust-debug
description: Debug OrignaBase Rust server failures in this repo, especially panic/500 regressions, auth/session bugs, async request-body mistakes, SQL/query drift, and Meilisearch sync issues. Use when a route, deploy, or targeted test is failing and you need a repeatable evidence-first workflow.
---

# OrignaBase Rust Debug

Use this skill for `orignabase/` runtime failures. Stay evidence-first: reproduce, isolate the layer, fix the narrowest cause, and verify with targeted tests before wider gates.

## Primary References

- Rust panic hooks: https://doc.rust-lang.org/std/panic/fn.set_hook.html
- Rust panic capture: https://doc.rust-lang.org/std/panic/fn.catch_unwind.html
- Tokio tracing guide: https://tokio.rs/tokio/topics/tracing
- `tracing-panic` hook reference: https://docs.rs/tracing-panic/latest/tracing_panic/fn.panic_hook.html
- PostgreSQL JSONB docs: https://www.postgresql.org/docs/current/datatype-json.html
- Stripe webhook delivery semantics: https://docs.stripe.com/webhooks

Open `references/current-audit.md` when you need the repo-specific 2026-04-23 audit notes, current hot spots, or the source-backed rationale behind this workflow.

## Triage Order

1. Reproduce with the smallest real surface.
   - Start with a focused `cargo test` if one exists.
   - Then use `curl` against `localhost`, `api.dev.orignagta.ca`, or the exact failing environment.
2. Capture an evidence pack before editing.
   - exact command
   - exact HTTP status/body
   - fresh container log lines from the same timestamp window
   - direct SQL or Meilisearch probe if the failure smells data-related
3. Identify the failing layer before changing code.
   - route/input parsing: `crates/ob-auth`, `crates/ob-handlers`
   - query/storage: `crates/ob-database`
   - search indexing/sync: `crates/ob-search`, `crates/ob-handlers/src/products`
   - auth/session/JWT/OAuth: `crates/ob-auth`
4. Prove whether the runtime is stale.
   - check `/opt/orignabase/source`
   - compare with the running container before changing code already present on the VPS

## Evidence Workflow

- Prefer first-party evidence over assumptions:
  - failing request
  - log excerpt
  - SQL result
  - Meilisearch result
  - targeted test result
- When logs are vague, reproduce again immediately and re-check logs. `500 DATABASE_ERROR` and `response failed` are symptoms, not root causes.
- If the app is red but the source tree already contains the fix, treat deploy drift as the primary suspect until disproven.

## Symptom Map

### Auth and session defects

- Check `crates/ob-auth/src/routes.rs`, middleware, JWT claims, refresh flow, cookie/header handling, and OAuth redirect validation.
- Watch for:
  - stale role/email fields moved into `data->>'field'`
  - refresh-token rotation lock or missing persistence
  - Turnstile required on web flows but missing in live requests
  - provider config valid locally but invalid in deployed env
  - session/user hydration mismatch after login succeeds

### Async/body mistakes

- Inspect handlers for `Request` body usage, webhook endpoints, and middleware that reads the body.
- Red flags:
  - sync handler calling async body methods
  - body consumed twice
  - body bytes parsed in one layer and expected again downstream
  - webhook signature code changed to use parsed JSON instead of raw bytes

### SQL/query drift

- Check `crates/ob-database/src/query.rs`, `pg_store.rs`, and handler raw SQL.
- Red flags:
  - Surreal-style syntax leaking into PostgreSQL (`START` vs `OFFSET`)
  - top-level fields used where data lives in `data->>'field'`
  - casts on nullable/missing values
  - query succeeds in `psql` but fails in row mapping
  - GraphQL/filter contract changed but SQL translator still expects the old shape

### Meilisearch and product search

- Check:
  - `crates/ob-handlers/src/rest_api.rs`
  - `crates/ob-handlers/src/products/triggers.rs`
  - `crates/ob-search/src/client.rs`
  - `crates/ob-search/src/sync.rs`
- Distinguish:
  - DB listing failure
  - search index sync failure
  - stale deployed container vs current source
  - seed/data gap rather than code defect

### Panic or 500 with weak logs

- Check container logs first, then reproduce again immediately to get fresh lines.
- Audit `crates/orignabase/src/main.rs` before adding new panic work:
  - JSON tracing subscriber should be initialized at process start.
  - panic hook should emit through `tracing`, include panic location, and keep
    the prior/default hook unless you have a strong reason not to.
- VPS commands:
```bash
ssh root@204.168.137.16 "docker logs --tail 200 orignabase-orignabase-dev-1 2>&1 | tail -200"
ssh root@204.168.137.16 "docker exec -i orignabase-postgres-1 psql -U orignabase -d orignabase_dev -c \"SELECT 1\""
```
- If logs only show `response failed`, probe the underlying DB/search query directly.
- Search for:
  - `panicked at`
  - `called Result::unwrap()`
  - `db error`
  - `invalid type`
  - `column does not exist`
  - `meilisearch`

## High-Value Verification Commands

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/orignabase

cargo test -p ob-auth <test_name> -- --nocapture
cargo test -p ob-handlers <test_name> -- --nocapture
cargo test -p ob-database <test_name> -- --nocapture
cargo clippy -p ob-auth -- -D warnings
cargo clippy -p ob-handlers -- -D warnings

curl -sS https://api.dev.orignagta.ca/health
curl -sS "https://api.dev.orignagta.ca/products?limit=2&offset=0"
curl -sS "https://api.dev.orignagta.ca/products?limit=2&offset=0&q=solar"
curl -sS -X POST https://api.dev.orignagta.ca/auth/login -H 'content-type: application/json' --data '{"email":"nobody@example.com","password":"bad"}'
curl -sS -X POST https://api.dev.orignagta.ca/auth/refresh -H 'content-type: application/json' --data '{"refresh_token":"bogus"}'
ssh root@204.168.137.16 "docker compose -f /opt/orignabase/docker-compose.yml ps"
ssh root@204.168.137.16 "docker logs --tail 200 orignabase-orignabase-dev-1 2>&1 | tail -200"
ssh root@204.168.137.16 "docker exec -i orignabase-postgres-1 psql -U orignabase -d orignabase_dev -c \"SELECT COUNT(*) FROM products\""
```

## Verification Order

1. Targeted `cargo test` for the exact module or regression.
2. `cargo clippy -p <crate> -- -D warnings` for touched crates.
3. Focused live probe (`curl` or targeted E2E).
4. Only then broader suites.

## Current Audit Notes

- Current repo state already contains the PostgreSQL query translator fixes that
  unblocked `list(... offset/startAfter ...)` search/category browsing on dev.
- Current repo state already initializes a JSON tracing subscriber and a panic
  hook in `crates/orignabase/src/main.rs`; treat deploy drift as plausible
  before rewriting query code that already tests green locally.
- For product browse regressions, prove whether the failure is:
  - GraphQL translator/runtime
  - seeded catalog gap
  - stale frontend bundle
  - stale deployed backend container

## Deploy and Environment Checks

- VPS source: `/opt/orignabase/source`
- Compose root: `/opt/orignabase`
- Rebuild dev only:
```bash
ssh root@204.168.137.16 "cd /opt/orignabase && docker compose build orignabase-dev && docker compose up -d orignabase-dev"
```
- Confirm whether the running container is stale before editing code already present in `/opt/orignabase/source`.

## Rules

- Do not “fix” by hiding 500s with empty responses.
- Do not trust historical green notes without a fresh repro.
- Prefer exact failing route/test coverage over broad speculative refactors.
- If the source is already fixed and the runtime is red, prove stale deploy before changing code again.
- Keep evidence in the task notes or `STATE.md`: request, response, log line, root cause, verification command.
