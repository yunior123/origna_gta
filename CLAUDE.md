@~/CLAUDE.md

# OrignaGTA — Project Rules

Flutter e-commerce app. Backend: OrignaBase (Rust VPS, **Firebase is COMPLETELY GONE**).

## Rules
1. Always use subagents and delegation to gemini cli or codex cli latest models
2. Detailed rules in `.claude/rules/` — loaded automatically per file type

## Quick Reference

- **Backend**: `https://api.orignagta.ca` (prod) / `https://api.dev.orignagta.ca` (dev)
- **Design tokens**: `lib/utils/design_tokens.dart` — NEVER `Colors.*` or hex literals
- **Auth**: Riverpod providers only — NEVER `FirebaseAuth.instance` directly
- **Money**: always integer cents — NEVER float/double
- **Testing**: `flutter analyze --no-fatal-infos && flutter test` before every commit
- **Deploy**: `scripts/deploy_web.sh` — injects `TURNSTILE_SITE_KEY` + `ORIGNABASE_URL`
- **Previews**: ALWAYS `./start-preview.sh` — never `flutter widget-preview start` directly

## Key files
- `lib/utils/env_config.dart` — environment + URL config
- `lib/core/providers.dart` — Riverpod auth providers
- `lib/utils/design_tokens.dart` — all design constants
- `lib/core/schema_constants.dart` — field names, routes, constants
- `e2e/playwright.config.dev.ts` — E2E config (workers: 2, 8GB constraint)

Rules:
-use many subagents in each session to keep main context window as clean as possible. more than 10+ agents
-u can use concurrency or parralel tasks, u just need to be careful with ram. specially with tests e2e
-no migration or backward compatibility please,  u can always wipe out entire dev db and seed again if needed
-autolearn:before running the test suite u run some smoke test first
-autolearn:always monitor test suite, avoid wasting time, fix as needed
-always kill orphan or zombie or stale chromes when testing e2e
-when testing both the orignabase backend and the flutter frontend can be modified to fix the issues
-if u find a problem u fix it, u cannot silence that problem
-before fixing search the web for best practices if needed
-as u work create anti-alzheimer memos so that u remember in fresh sessions
-autolearn:u estimate time as if u were human, u are ai from anthropics, the best in the world
-avoid typescript for server, prefer rust, its better for memory
-cloudflare mcp exist, u always forget that, search deep in memory
-read repo map for context
