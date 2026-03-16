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
