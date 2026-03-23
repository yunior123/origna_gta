@~/CLAUDE.md

# OrignaGTA — AI Agent Routing File

Flutter e-commerce app (Canada-first multi-vendor marketplace). Backend: OrignaBase (Rust VPS). **Firebase is GONE.**

> This is a routing file. Detailed rules auto-load from `.claude/rules/`. Read `docs/REPO_MAP.md` for full architecture.

---

## Commands

```bash
# Flutter (from origna_gta/)
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
flutter test test/unit/auth_provider_test.dart          # single test
flutter test --name "should calculate subtotal"         # pattern match
flutter pub run build_runner build --delete-conflicting-outputs  # codegen
./start-preview.sh                                      # widget previews (ALWAYS this script)

# E2E (from e2e-agent-browser/)
bun test specs/phase1-api/
bun x tsc --noEmit

# OrignaBase Rust (from orignabase/)
cargo clippy -D warnings && cargo test
cargo test -p ob-auth                                   # single crate
```

## Key Files

| Purpose | Path |
|---------|------|
| Environment config | `lib/utils/env_config.dart` |
| Auth providers | `lib/core/providers.dart` |
| Design tokens | `lib/utils/design_tokens.dart` |
| Schema constants | `lib/core/schema/schema_constants.dart` |
| Repo map | `docs/REPO_MAP.md` |
| Quality gate | `scripts/run_quality_gate.sh` |

## Architecture

- MVVM: Screens → ViewModels → Services → OrignaBase SDK
- State: Riverpod providers (`lib/providers/`), AsyncNotifier for async state
- Models: `freezed` for all value types. Money = integer cents, never float.
- Backend: OrignaBase SDK only — never raw HTTP to SurrealDB/Meilisearch

## Common Pitfalls (DO NOT)

- ❌ `Colors.blue` or hex literals — use `DesignTokens.*`
- ❌ `setState()` in screens — use Riverpod
- ❌ `BuildContext` in ViewModels or Services
- ❌ `double`/`float` for money — always integer cents
- ❌ `print()` — use `AppLogger`
- ❌ `FirebaseAuth.instance` — Firebase is gone, use OrignaBase SDK
- ❌ Hardcoded strings, routes, or field names — use `schema_constants.dart`
- ❌ `flutter widget-preview start` — always `./start-preview.sh`
- ❌ Relative imports (`../`) — use `package:origna_gta/...`
- ❌ `MediaQuery.of(context).size.width` for layout — use responsive utilities

## Agent Rules

- Use 10+ subagents per session to keep main context clean
- Kill orphan Chrome processes before E2E tests
- Run smoke tests before full test suite
- If you find a problem, fix it — never silence it
- Create anti-alzheimer memos as you work (document decisions in STATE.md)
- No migration or backward compatibility — wipe dev DB and reseed if needed
- Both OrignaBase backend and Flutter frontend can be modified to fix issues
- Cloudflare MCP exists — search for it, you always forget
- Prefer Rust over TypeScript for server code
- Read `docs/REPO_MAP.md` for context before starting work
- no skipping tests, implement and run instead
- avoid mocks for live integration tests
- no backward compatibility
- solve warnings like a pro

## MCP

Project `.mcp.json`: dart-mcp, flutter-pilot, github. Cloudflare MCP available via user-level config.
