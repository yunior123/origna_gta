# .github/claude.md — AI Agent Context

> Source of truth: [`CLAUDE.md`](../CLAUDE.md). Read it before any changes.

**OrignaGTA** — E-commerce marketplace, Canadian buyers, worldwide sellers.
Flutter/Riverpod + OrignaBase (Rust VPS) + SurrealDB + Stripe Connect.

## Rules
- MVVM only — no business logic in screens
- Cross-stack sync mandatory (Rust ↔ Dart ↔ Schema)
- No new markdown files unless explicitly asked
- Fix all compiler warnings

## Commands
```bash
cd origna_gta && flutter analyze --no-fatal-infos  # Static analysis
cd origna_gta && flutter test --exclude-tags golden # Unit + widget tests
cd e2e-agent-browser && bun test specs/phase1-api/  # E2E API tests
```
