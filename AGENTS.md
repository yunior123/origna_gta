# AGENTS.md — OrignaGTA Coding Agent Guide

> **Source of truth:** `CLAUDE.md` + `.claude/rules/` — read those for full context.
> Firebase is GONE. Backend is OrignaBase (Rust VPS + PostgreSQL + Meilisearch).

## Repo Structure

```
origna_gta/               ← repo root
├── origna_gta/           ← Flutter e-commerce app (GTA)
├── origna_ventures/      ← Flutter services app (Ventures)
├── e2e/                  ← Bun/Playwright E2E tests
├── .claude/skills/       ← Claude skills
└── AGENTS.md, CLAUDE.md
```

## Build / Lint / Test Commands

```bash
# ── OrignaGTA Flutter (run from origna_gta/) ─────────────────────────────
cd origna_gta

flutter analyze --no-fatal-infos
flutter test --exclude-tags golden
flutter test --name "should calculate subtotal correctly"
flutter test --coverage --reporter=compact --exclude-tags golden
flutter test test/golden/
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --debug --dart-define=ENVIRONMENT=dev
flutter run --dart-define=ENVIRONMENT=dev

# ── OrignaVentures Flutter (run from origna_ventures/) ───────────────────
cd origna_ventures

flutter analyze --no-fatal-infos
flutter test
flutter build web --debug
flutter run

# ── OrignaVentures Backend (Python FastAPI) ──────────────────────────────
cd origna_ventures/backend
source venv/bin/activate  # or .venv
uvicorn app:app --reload --port 8001

# ── E2E (run from e2e/) ──────────────────────────────────────────────────
cd e2e
bun test specs/phase1-api/        # API smoke tests (35 files)
bun test specs/phase2-smoke/      # UI smoke tests (13 files)
bun test specs/phase3-auth-nav/   # Auth flow tests (11 files)
bun test specs/phase4-product-flows/  # Product tests (21 files)
bun test specs/phase5-complex-flows/  # Order lifecycle, returns, chat (23 files)
bun test specs/phase6-stripe/     # Stripe payments, webhooks (13 files)
bun x tsc --noEmit

# ── Pre-commit checklist ──────────────────────────────────────────────────
cd origna_gta && flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
cd origna_ventures && flutter analyze --no-fatal-infos
```

## Code Style — Flutter/Dart

### Architecture (MVVM — strictly enforced)
- **Screens** → **ViewModels** → **Services** → **OrignaBase SDK**
- No business logic in Widgets or Screens
- ViewModels in `lib/viewmodels/` — use `AsyncNotifier` or `StateNotifier`
- All state in Riverpod providers (`lib/providers/`)
- Services in `lib/services/` — stateless, pure functions + SDK calls

### Imports & Formatting
- Use `package:origna_gta/...` absolute imports (never relative `../`)
- Group imports: dart → flutter → packages → project
- Use `const` constructors everywhere possible
- `final` by default; only `var` when type is obvious
- No `dynamic` — use generics or `Object?` if truly needed
- Named parameters for functions with 3+ params

### Naming Conventions
- **Classes:** PascalCase (`CartViewModel`, `DesignTokens`)
- **Files:** snake_case (`cart_viewmodel.dart`, `design_tokens.dart`)
- **Variables/functions:** camelCase (`subtotalCents`, `fetchProducts()`)
- **Constants:** camelCase (`freeShippingThresholdCents`)
- **Test files:** `_test.dart` suffix, mirror source path (`test/unit/cart_viewmodel_test.dart`)

### Types & Models
- Use `freezed` for all value types, API models, and states
- Money: **always integer cents** — `priceCents`, `subtotalCents`, `totalAmountCents`
- Display money: `'\$${(cents / 100).toStringAsFixed(2)}'`
- Never use `double`/`float` for money

### Riverpod Patterns
- `ref.watch()` for reactive state, `ref.read()` for one-time actions
- Use `select()` to avoid unnecessary rebuilds
- Prefer `AsyncNotifierProvider` over `FutureProvider` for mutable async state
- Never call `ref.watch()` inside `build()` conditionally

### Theme & Design
- **ONLY** use `DesignTokens.*` — never `Colors.blue`, never hex literals
- Never `Theme.of(context).colorScheme.primary` — use `DesignTokens`
- Dark mode: check `Theme.of(context).brightness == Brightness.dark`

### Error Handling
- Use `AppError` for all domain errors
- Every async action handles loading / error / success states
- Transient errors → `SnackBar`; form errors → inline
- Never `print()` — use `AppLogger`

### Semantics (required for Playwright E2E)
- All interactive elements: `Semantics(label: 'btn-*')` or `tooltip:`
- Conventions: `btn-`, `input-`, `nav-`, `product-card-<id>`

### Forbidden
- ❌ `setState()` in screens — use Riverpod
- ❌ `BuildContext` in ViewModels or Services
- ❌ Hardcoded colors, strings, routes, field names
- ❌ `print()` — use `AppLogger`
- ❌ `MediaQuery.of(context).size.width` for layout decisions
- ❌ Non-paginated data fetching (always limit + offset)
- ❌ Any Firebase SDK calls

## Code Style — OrignaVentures

### Architecture
- Single-page Flutter web app — `StatefulWidget` + `setState`
- No Riverpod, no MVVM — simpler structure than OrignaGTA
- All UI in `lib/main.dart` (3317+ lines, single file)
- Backend: Python FastAPI in `backend/app.py`
- Theme: `ThemeConfig` class in `lib/theme_config.dart` (unified blue-violet palette with OrignaGTA)
- Tiers: `TiersConfig` in `lib/tiers_config.dart`

### Conventions
- Languages: EN/FR/ES via inline `loc.tr(enString, frString, esString)` pattern
- Money: integer cents, display with `$` prefix
- No contract signing — 3 tappable service cards → Stripe checkout directly
- Seller onboarding disabled — OrignaVentures IS the seller (support@orignaventures.ca)
- Never hardcode colors — use `ThemeConfig.*`
- Never `print()` — use `debugPrint()` or proper logging

## Backend (OrignaBase)
- All data, auth, search through OrignaBase SDK — never raw HTTP
- Environments: emulator / dev / staging / production
- Config: `lib/utils/env_config.dart` — never hardcode URLs
- PostgreSQL timestamp fields: orders use `createdAt`, products use `dateCreated`

## Backend (OrignaVentures)
- Python FastAPI at `origna_ventures/backend/app.py`
- Stripe checkout sessions, PDF generation, webhook handling
- Supports `service_code` (direct) and `contract_id` (legacy) for checkout
- API base: `https://api.orignagta.ca/ventures/api`
- Seller: OrignaVentures (support@orignaventures.ca)

## Key Files Reference

### OrignaGTA
| Purpose | Path |
|---------|------|
| Environment config | `origna_gta/lib/utils/env_config.dart` |
| Auth providers | `origna_gta/lib/core/providers.dart` |
| Design tokens | `origna_gta/lib/utils/design_tokens.dart` |
| Schema constants | `origna_gta/lib/core/schema/schema_constants.dart` |
| Quality gate | `origna_gta/scripts/run_quality_gate.sh` |
| Deploy | `origna_gta/scripts/deploy_web.sh` |

### OrignaVentures
| Purpose | Path |
|---------|------|
| Main app (all UI) | `origna_ventures/lib/main.dart` |
| Theme config | `origna_ventures/lib/theme_config.dart` |
| Tiers config | `origna_ventures/lib/tiers_config.dart` |
| Backend API | `origna_ventures/backend/app.py` |
| Deploy | `origna_ventures/deploy.sh` |

## Agent Rules
- Use subagents aggressively (10+ per session) to keep context clean
- Kill orphan/stale Chrome processes before E2E tests
- Run smoke tests before full test suite
- If you find a problem, fix it — never silence it
- Create anti-alzheimer memos as you work (document decisions)
- Search web for best practices before fixing issues
- use repo map for context
















<!-- AI-SYNC -->
> Below auto-generated by ai-sync. Do NOT edit below this line.

# AI Context — Yunior Rodriguez Osorio
> Auto-generated by ai-sync from Claude Code memory. Do NOT edit — changes overwritten on next sync.
> Last sync: 2026-04-18 16:12

## Identity
- **Name**: Yunior Rodriguez Osorio | Toronto, Canada
- **Chess**: ~1840 Elo | **Languages**: EN/FR/ES native; learning DE, ZH
- **GitHub**: yunior123
- **macOS**: Apple Silicon, 8GB RAM, zsh

## Working Style — CRITICAL
- Yunior reviews, AI executes. No approval-seeking.
- **Tokens = money.** Actions + results only. No preamble, no summaries, no filler.
- Match language (EN/FR/ES). Ask before deferrable tasks.
- **8GB RAM**: sequential heavy tasks. No emulators. No parallel heavy processes.
- **main only** — no branches, all commits to main.
- Run analyze + test before every commit.
- Small, focused, atomic changes.

## Projects

| Project | Stack | Path | Test Command |
|---------|-------|------|-------------|
| **origna_gta** | Flutter/Dart, OrignaBase (Rust), Riverpod, Freezed | `~/Documents/GitHub/origna_gta/origna_gta` | `flutter analyze --no-fatal-infos && flutter test` |
| **origna_ventures** | Flutter/Dart, Python FastAPI, Stripe | `~/Documents/GitHub/origna_gta/origna_ventures` | `flutter analyze --no-fatal-infos` |
| **orignabase** | Rust (axum, SurrealDB, tower), Docker, Caddy | `~/Documents/GitHub/orignabase` | `cargo clippy -D warnings && cargo test` |
| **fxcleaner** | Swift/SwiftUI, macOS | `~/Documents/GitHub/fxcleaner` | `cd fxcleaner_swiftui && swift test` |
| **viral-video-pipeline** | Python 3.12+, Playwright, Google GenAI | `~/Documents/GitHub/viral-video-pipeline` | `pytest` |
| **aguara** | Go, security scanner (fork, OSS) | `~/Documents/GitHub/aguara` | `go test ./...` |
| **bitunix-bot** | Crypto perp trading bot | `~/Documents/GitHub/bitunix-bot` | — |

## Coding Standards
- Match existing code style 100%
- No magic strings — use DesignTokens, constants, enums, schema_constants
- Never commit print/console.log statements
- Handle errors with AppError/logging patterns in codebase

## Critical Rules (NEVER break)
1. NEVER `gemini-2.5-pro` or any 2.x — ONLY `gemini-3-pro-preview`
2. NEVER run simultaneous heavy processes (Flutter build + Playwright + tests)
3. NEVER `FirebaseAuth.instance` directly in Flutter screens — Firebase is GONE
4. NEVER manually edit `.pb.go` — always `make protos`
5. VERIFY agent fixes: run `pytest` / `flutter analyze` after agents complete
6. 8GB RAM = LOCAL Mac only — Cloud Functions use Google's servers
7. GitHub username: `yunior123`. NEVER put Co-Authored-By Claude/AI in commits.

## AI Delegation System
| Model | Method | Best For |
|-------|--------|----------|
| **codex** | `codex` CLI (gpt-5.4) | Code tasks, reasoning |
| **copilot** | `gh copilot` | Quick code/git questions ONLY |
| **gemini** | Playwright → gemini.google.com | Bulk analysis, doc gen |
| **grok** | Playwright → grok.com | Real-time info |
| **xchat** | Safari → x.com/i/grok | Deep reasoning (Grok 4.2 Beta) |
| **opencode** | `/opt/homebrew/bin/opencode run` | Free models (Grok 4.2) |
| **kilo** | `/opt/homebrew/bin/kilo run` | Free models (OpenCode fork) |

Usage: `delegate <model> "prompt"` from any terminal.

## OrignaBase Quick Facts
- VPS: 204.168.137.16 | ALL data via `/graphql` POST. NO REST endpoints.
- GraphQL filters: OBJECT format `{field: {_op: val}}` NOT ARRAY
- Auth: OrignaBase SDK issues JWTs — auto-attaches Authorization header
- Storage: 2-step presigned URL — POST /storage/presign/upload → PUT to signed URL

## OrignaGTA Quick Facts
- MVVM: Screens → ViewModels → Services → OrignaBase SDK
- State: Riverpod providers, AsyncNotifier for async state
- Models: `freezed` for all value types. Money = integer cents, never float.
- Design system: `lib/utils/design_tokens.dart` (no Figma) — ONLY use DesignTokens.*
- Deploy: `scripts/deploy_web.sh` + inject TURNSTILE_SITE_KEY
- Firebase is COMPLETELY GONE — backend is OrignaBase (Rust VPS)

## OrignaVentures Quick Facts
- Single-page Flutter web app — no Riverpod, no MVVM, just StatefulWidget
- Backend: Python FastAPI (`origna_ventures/backend/app.py`) — Stripe checkout sessions, PDF generation
- 3 service tiers: OrignaCode ($500 CAD one-time) · OrignaLaunch ($2,000 CAD one-time) · OrignaTeam ($1,000+/month subscription)
- Company email: support@orignaventures.ca — seller onboarding disabled, OrignaVentures IS the seller
- Theme: unified with OrignaGTA — blue-violet palette (`ThemeConfig` in `lib/theme_config.dart`)
- No contract signing — 3 tappable cards → Stripe payment directly
- Languages: EN/FR/ES (inline `loc.tr(en, fr, es)` pattern)
- Deploy: `origna_ventures/deploy.sh`

## Available Skills & Tools
- **Global catalog**: `~/.claude/AI_TOOLS_GLOBAL.md` — 33 global skills, 21 global agents, slash commands
- **Per-project catalog**: `docs/AI_SKILLS_CATALOG.md` in each project root
- Key commands: /verify, /tdd, /swarm, /code-review, /deep-research, /ralph-loop, /diagnose
- Run `delegate <model> "prompt"` to dispatch tasks to other AI agents
