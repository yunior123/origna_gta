# AGENTS.md — OrignaGTA Coding Agent Guide

> **Source of truth:** `CLAUDE.md` + `.claude/rules/` — read those for full context.
> Firebase is GONE. Backend is OrignaBase (Rust VPS + SurrealDB + Meilisearch).

## Build / Lint / Test Commands

```bash
# ── Flutter (run from origna_gta/) ────────────────────────────────────────
cd origna_gta

# Static analysis (always run first — catches compile errors fast)
flutter analyze --no-fatal-infos

# All unit + widget tests (exclude golden tests)
flutter test --exclude-tags golden

# Single test file
flutter test test/unit/auth_provider_test.dart

# Single test by name pattern
flutter test --name "should calculate subtotal correctly"

# Tests with coverage
flutter test --coverage --reporter=compact --exclude-tags golden

# Golden tests (slow, run separately)
flutter test test/golden/

# Code generation (freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Build for dev
flutter build web --debug --dart-define=ENVIRONMENT=dev

# Run app
flutter run --dart-define=ENVIRONMENT=dev

# Widget previews (ALWAYS use this script, never direct command)
./start-preview.sh

# ── E2E (run from e2e-agent-browser/) ─────────────────────────────────────
cd e2e-agent-browser
bun test specs/phase1-api/          # API smoke tests
bun test specs/phase2-auth/         # Auth flow tests
bun test specs/phase3-products/     # Product tests
bun x tsc --noEmit                  # TypeScript check

# ── Pre-commit checklist ──────────────────────────────────────────────────
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
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

## Backend (OrignaBase)
- All data, auth, search through OrignaBase SDK — never raw HTTP
- Environments: emulator / dev / staging / production
- Config: `lib/utils/env_config.dart` — never hardcode URLs
- SurrealDB timestamp fields: orders use `createdAt`, products use `dateCreated`

## Key Files Reference
| Purpose | Path |
|---------|------|
| Environment config | `lib/utils/env_config.dart` |
| Auth providers | `lib/core/providers.dart` |
| Design tokens | `lib/utils/design_tokens.dart` |
| Schema constants | `lib/core/schema/schema_constants.dart` |
| Quality gate | `scripts/run_quality_gate.sh` |
| Deploy | `scripts/deploy_web.sh` |

## Agent Rules
- Use subagents aggressively (10+ per session) to keep context clean
- Kill orphan/stale Chrome processes before E2E tests
- Run smoke tests before full test suite
- If you find a problem, fix it — never silence it
- Create anti-alzheimer memos as you work (document decisions)
- Search web for best practices before fixing issues
- use repo map for context
