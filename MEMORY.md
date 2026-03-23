# MEMORY.md — OrignaGTA Project Memory

> Auto-updated by AI agents. Keep under 200 lines. Decisions + learnings only, NOT instructions.
> CLAUDE.md has rules. This has context.

## Identity
- **Project:** OrignaGTA — Canada-first multi-vendor e-commerce marketplace
- **Stack:** Flutter (Dart) frontend + Rust backend (OrignaBase)
- **Owner:** Yunior Rodriguez Osorio, Toronto, Canada
- **Repo:** `~/Documents/GitHub/origna_gta` (monorepo: Flutter app + OrignaBase backend)

## Architecture Decisions (Why We Did Things)
- **Money = integer cents** — never `double`/`float` for money. Display via `(cents / 100).toStringAsFixed(2)`. Migration done 2026-03-22.
- **Firebase removed** — backend is OrignaBase (Rust VPS + SurrealDB + Meilisearch). Zero Firebase SDK calls remain.
- **setState → Riverpod** — 92 setState calls eliminated. Only 16 remain (animations/mascots/glassmorphism — acceptable).
- **Embedded RocksDB** for local dev — no Docker/SurrealDB needed. `orignabase.toml` uses `rocksdb://./local_test_data`.
- **Freezed for all state classes** — 22 state classes use `@freezed`. Manual `copyWith` with sentinel pattern (migration pending).
- **Image compression evolution:** for loop → `Future.wait` → back to sequential for loop (compression is CPU-bound, parallel wastes memory on 8GB).
- **Serde aliases** on Rust structs for backward compat with old DB field names (e.g., `#[serde(alias = "title")]` for `name`).
- **Meilisearch optional** — server warns but starts without it. Not required for local dev.
- **Release LTO OOMs on 8GB** — use debug/dev profile for local builds. Add 4GB swap for release builds.
- **SurrealDB v2 required** — v3 has compatibility issues. Docker uses `surrealdb/surrealdb:v2`.

## Key Gotchas
- **SurrealDB Ws format:** `host:port` only (no `ws://` prefix) — silent hang otherwise
- **SurrealDB IDs contain `:`** — sanitize to `_` for Meilisearch document IDs
- **GraphQL filters:** OBJECT format `{field: {_op: val}}` NOT array — server calls `filters.as_object()`
- **Auth refresh:** via `{"refresh_token": "..."}` body, NOT Bearer header
- **8GB RAM constraint:** sequential heavy tasks. No parallel Flutter build + Playwright + tests. Chrome concurrency max 4.
- **stripe-cli-env.sh** had field name mismatch: Stripe CLI uses `test_mode_pub_key`, not `test_mode_publishable_key`. Fixed 2026-03-23.
- **Edit product test failures** were from parallel session WIP changes — already resolved, STATE.md note was stale.

## Current State (2026-03-23)
- **Rust tests:** 2,424 unit pass, 1 ignored (needs SurrealDB). Integration tests all `#[ignore]` (need running server).
- **Rust clippy:** Clean (1 collapsible_if in ob-handlers/rest_api.rs fixed).
- **Rust coverage:** ob-core 91.41% lines, 90.59% functions. ob-handlers is largest crate (1694 tests).
- **Rust coverage tools:** `cargo-llvm-cov` (0.8.4) + `cargo-tarpaulin` both installed. Use `./scripts/coverage.sh`.
- **Rust crates (15):** ob-admin, ob-analytics, ob-auth, ob-core, ob-database, ob-functions, ob-graphql, ob-handlers, ob-mcp, ob-notifications, ob-realtime, ob-search, ob-security, ob-storage, orignabase.
- **Flutter tests:** Timeout at 600s+ even with compact reporter. Needs investigation — likely too many widget tests or test setup issue.
- **Flutter warnings:** 4 info-level only (no errors). Generated code has use_null_aware_elements hints.
- **Flutter test dirs:** live/, unit/, widget/, models/, screens/ under `origna_gta/origna_gta/test/`.
- **E2E:** 112 spec files across 6 phases (agent-browser, not Playwright)
- **Seed:** 2400+ products via `e2e/lib/seed-dev.ts`. Gaps: disputes, coupons, MFA, multi-user favorites/addresses/cart
- **VPS:** 204.168.137.16, api.dev.orignagta.ca, Caddy reverse proxy
- **CI:** 4 workflows (Flutter web, Rust, E2E, quality audit)
- **Stripe:** Connected, 13 webhook events configured, HMAC verified
- **Disk space:** 8GB Mac, target dir was 44GB — cleaned 2026-03-23. Always `cargo clean` before coverage runs.

## Quick Reference
| What | Command |
|------|---------|
| Flutter analyze | `cd origna_gta && flutter analyze --no-fatal-infos` |
| Flutter tests | `flutter test --exclude-tags golden` |
| Flutter live tests | `flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev --exclude-tags golden` |
| Rust lint | `cd orignabase && cargo clippy -D warnings` |
| Rust tests | `cargo test --workspace` |
| Local backend | `cargo build -p orignabase && ./target/debug/orignabase serve --config orignabase.toml` |
| E2E API | `cd e2e && bun test specs/phase1-api/` |
| E2E all | `bun test` |
| Seed DB | `cd e2e && bun run lib/seed-dev.ts` |
| Codegen | `cd origna_gta && flutter pub run build_runner build --delete-conflicting-outputs` |
| Clean Rust | `cd orignabase && ./scripts/clean_rust_artifacts.sh` |
| Clean Flutter | `cd origna_gta && flutter clean` |
| Coverage Rust | `cd orignabase && ./scripts/coverage.sh --html` |
| Coverage Flutter | `cd origna_gta && flutter test --coverage --exclude-tags golden` |

## Delegation System
| Model | Best For |
|-------|----------|
| codex (gpt-5.4) | Code tasks, reasoning |
| gemini (Playwright) | Bulk analysis, doc gen |
| opencode | Free models (Grok 4.2) |
| Task tool | Subagents within session |
