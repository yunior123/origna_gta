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
- **Firebase removed** — backend is OrignaBase (Rust VPS + PostgreSQL + Meilisearch). Zero Firebase SDK calls remain.
- **setState → Riverpod** — 92 setState calls eliminated. Only 16 remain (animations/mascots/glassmorphism — acceptable).
- **Freezed for all state classes** — 22 state classes use `@freezed`. Manual `copyWith` with sentinel pattern (migration pending).
- **Release LTO OOMs on 8GB** — use debug/dev profile for local builds. Add 4GB swap for release builds.
- **PostgreSQL v2 required** — v3 has compatibility issues. Docker uses `postgresql/postgresql:v2`.

## Key Gotchas
- **PostgreSQL Ws format:** `host:port` only (no `ws://` prefix) — silent hang otherwise
- **PostgreSQL IDs contain `:`** — sanitize to `_` for Meilisearch document IDs
- **GraphQL filters:** OBJECT format `{field: {_op: val}}` NOT array — server calls `filters.as_object()`
- **Auth refresh:** via `{"refresh_token": "..."}` body, NOT Bearer header
- **8GB RAM constraint:** sequential heavy tasks. No parallel Flutter build + Playwright + tests. Chrome concurrency max 4.


- **Flutter tests:** ~4,511 non-live tests pass. Run per dir: `test/unit/` (2749), `test/widget/` (974), `test/screens/` (181), top-level (594). Full suite times out at 15min — run by directory.
- **Flutter coverage:** 76.9% lines (23,640/30,744). 22 files under 50%. Top gaps: editproduct_form (0%), editproduct_submit (0%), update_shipping_dialog (0%), origna_app (31%), cart_provider (42%).
- **Flutter warnings:** 3 info-level (2 generated code, 1 test file). No errors.
- **Flutter test dirs:** live/, unit/, widget/, models/, screens/ under `origna_gta/origna_gta/test/`.
- **Documentation:** `docs/ARCHITECTURE.md` created for both Flutter (636 lines) and Rust (791 lines). 15 key files have inline dartdoc comments.
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
