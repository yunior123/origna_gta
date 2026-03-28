@~/CLAUDE.md

# OrignaGTA — AI Agent Routing File

Flutter e-commerce app (Canada-first multi-vendor marketplace). Backend: OrignaBase (Rust VPS). **Firebase is GONE.**

> This is a routing file. Detailed rules auto-load from `.claude/rules/`. Read `docs/REPO_MAP.md` for full architecture.

---

## Commands

```bash
# CRITICAL: Always cd to the right subdirectory first!
# Repo root has NO Cargo.toml and NO pubspec.yaml.

# Flutter (from origna_gta/origna_gta/ — NOT repo root)
cd origna_gta/origna_gta  # or use absolute path
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
flutter test test/unit/auth_provider_test.dart          # single test
flutter test --name "should calculate subtotal"         # pattern match
flutter pub run build_runner build --delete-conflicting-outputs  # codegen
# Widget previews: REMOVED. start-preview.sh deleted. @Preview annotations stay in code but don't run the preview server — it dumps all widgets into one messy page. Previews should work per-view like SwiftUI, not all-at-once.

# E2E (from e2e-agent-browser/)
bun test specs/phase1-api/
bun x tsc --noEmit

# OrignaBase Rust (from orignabase/)
cargo clippy -D warnings && cargo test
cargo test -p ob-auth # single crate
cargo test -- --ignored # run #[ignore] integration tests

# Live Tests (Flutter)
# Requires: OrignaBase running on localhost:8080 + seeded database
cd origna_gta && flutter test test/live/ \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=emulator

# Run single live test
flutter test test/live/orignabase_live_smoke_test.dart \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=emulator

# Seed local database (from e2e/ folder)
cd e2e && ORIGNABASE_URL=http://127.0.0.1:8080 bun run lib/seed-dev.ts
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
- ✅ Flutter Widget Previews — SwiftUI-style per-view in VS Code sidebar. Open a .dart file → sidebar auto-shows @Preview widgets for THAT file only. Toggle "Filter previews by selected file" at bottom-left. Each preview has own Hot Restart. Embedded Inspector via gear icon. No terminal commands needed. Old `start-preview.sh` deleted.
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
- avoid ignoring live tests
- fix instead of cheating, implement like pro instead of creating temporary workaround
- if u have blockers then stop all and ask user
- use when auditing, before fixing:.claude/skills/quorum-verify/SKILL.md
- avoid launching too many claude code in bash. why?:it consumes too many tokens, subagents are prefered.ex:last time u called 5+ claude and consumed 10% of tokens in 2 minutes.
- no magic strings, it leads to errors in production
- always kill zombie flutter_test consuming ram
- autolearn:if u find an issue while solving other then solve it or added to state.md
- avoid simple unprofessional fixes. if u encounter an issue make sure to solve like pro.
- codex delegation: ONLY gpt-5.4 (full). NEVER gpt-5.4-mini, o4-mini, o3, or any model < 5.3. Lower models destroy the codebase.
- codex flag (v0.117.0+): `codex exec -m gpt-5.4 -s danger-full-access "prompt"` — OLD syntax `--dangerously-bypass-approvals-and-sandbox -c 'model="gpt-5.4"'` is deprecated
- codex batches: launch 3+ parallel codex for non-conflicting tasks (different directories), divide and conquer
- codex temp files: pipe output to `/tmp/codex-batch{N}-output.log` — never lose results
- gemini flag (v0.35.2+): `gemini -m gemini-3-pro-preview -y -p "prompt"` — `-p` for headless, `-y` for yolo. Be patient with 429 retries (2-3 min)
- gemini temp files: MUST use `/tmp/gemini-workspace/` — NEVER create temp files in project root
- mimo/free models: available via OpenRouter inside opencode (`/opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free`) and kilocode. OpenRouter API key already configured. Prefer mimo over subagents for delegation — saves Claude tokens
- after ANY codex run: verify `flutter analyze` + `flutter test` PASS before accepting changes. Revert if broken.
- codex cannot verify screenshots match filenames — always audit screenshots manually after codex captures them.
- codex/gemini monitoring: launch with `> /tmp/codex-output.log 2>&1 &` then monitor via `nohup /tmp/monitor-codex.sh &`. Script checks every 5min: process alive, screenshot count, last output line.
- before commit: always run `/code-review` (4 parallel reviewers: correctness, security, performance, standards). Score ≥9 blocks commit.
- before push: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden && cargo clippy -D warnings && cargo test`
- use sleep as monitor technique
- there might be false positives in audits, be carefull
- use sleep monitor technique to always keep mimo,gemini,codex, etc busy doing audit based on real evidence and no false positive, creating more tests, documenting, fixing issues, searching web for common bugs on github or internet for ecommerce stores and see how we can prevent those in our app, use the harness loop constatntly. in the case of mimo alternate opencode, kilo, openrouter. Search web on how to better always keep working non stop on a project, like infinite work, non stop, always on. check gstack for ideas, skills catalog, etc.
Make them audit full codebase in depth. Use all agents and skills for it.

## MCP

Project `.mcp.json`: dart-mcp, flutter-pilot, github. Cloudflare MCP available via user-level config.

## AI Skills Catalog

See `docs/AI_SKILLS_CATALOG.md` for the complete inventory of all skills, commands, agents, rules, and workflows available to all AI agents.
