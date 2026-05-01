@~/CLAUDE.md

# OrignaGTA — AI Agent Routing File

Flutter e-commerce app (Canada-first multi-vendor marketplace). Backend: OrignaBase (Rust VPS). **Firebase is GONE.**

```
origna_gta/              ← repo root
├── origna_gta/          ← Flutter e-commerce app (GTA)
├── origna_ventures/     ← Flutter services app (Ventures)
├── e2e/                 ← Bun/Playwright E2E tests
├── .claude/skills/      ← Claude skills
└── AGENTS.md, CLAUDE.md
```

> This is a routing file. Detailed rules auto-load from `.claude/rules/`. Read `docs/REPO_MAP.md` for full architecture.

---

## Commands

```bash
# CRITICAL: Always cd to the right subdirectory first!
# Repo root has NO Cargo.toml and NO pubspec.yaml.

# Flutter (from repo_root/origna_gta/ — NOT repo root)
cd origna_gta
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
flutter test test/unit/auth_provider_test.dart          # single test
flutter test --name "should calculate subtotal"         # pattern match
flutter pub run build_runner build --delete-conflicting-outputs  # codegen
# Widget previews: REMOVED. start-preview.sh deleted. @Preview annotations stay in code but don't run the preview server — it dumps all widgets into one messy page. Previews should work per-view like SwiftUI, not all-at-once.

# E2E (from e2e/)
bun test specs/phase1-api/
bun x tsc --noEmit

# OrignaVentures Flutter (from origna_ventures/)
cd origna_ventures
flutter analyze --no-fatal-infos
flutter build web --release --dart-define=ENVIRONMENT=production
./deploy.sh [--skip-build] [--backend-only] [--frontend-only]

# OrignaVentures FastAPI Backend (from origna_ventures/backend/)
cd origna_ventures/backend
source venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --port 8001

# OrignaBase Rust (from repo_root/orignabase/)
cd orignabase
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

### OrignaVentures Key Files

| Purpose | Path |
|---------|------|
| Main app | `origna_ventures/lib/main.dart` |
| Theme config | `origna_ventures/lib/theme_config.dart` |
| Tiers config | `origna_ventures/lib/tiers_config.dart` |
| Backend API | `origna_ventures/backend/app.py` |
| Deploy script | `origna_ventures/deploy.sh` |

## Architecture

- MVVM: Screens → ViewModels → Services → OrignaBase SDK
- State: Riverpod providers (`lib/providers/`), AsyncNotifier for async state
- Models: `freezed` for all value types. Money = integer cents, never float.
- Backend: OrignaBase SDK only — never raw HTTP to PostgreSQL/Meilisearch

### OrignaVentures

- Single-page Flutter web app — `StatefulWidget` + `setState`
- No Riverpod, no MVVM — simpler structure
- Languages: EN/FR/ES via inline `loc.tr(en, fr, es)` pattern
- Money: integer cents, display with `$` prefix
- 3 tiers: OrignaCode ($500 CAD), OrignaLaunch ($3,000 CAD), OrignaTeam ($1,000 CAD/month)
- Never hardcode colors — use `ThemeConfig.*`
- Never `print()` — use `debugPrint()`
- Backend: Python FastAPI — Stripe checkout, PDF generation (reportlab), Postal email

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
- ✅ Hosted web builds must replace both `__TURNSTILE_SITE_KEY__` and `__GOOGLE_WEB_CLIENT_ID__` in `origna_gta/web/index.html`
- ✅ Google web OAuth is only considered configured when the client ID is a real `.apps.googleusercontent.com` value and the secret is present

## Agent Rules

- Use max 5 subagents per session (8GB RAM constraint)
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
- fix stale data issues, resseed db if needed
- always monitor disk space in my mac:256gb
- always document your sources: ex. stripe docs, flutter pub dev, rust lang docs, etc
- bonus points if u increase security while working on particular tasks, bonus also for improving the code
- before saying or claiming to have completed a task first run e2e tests on it to make sure it was solved and mark as done if so.
- fix errors instead of hiding them. at least log the errors if its a real error
- we might add more countries for delivery in the future so make sure the architecture is strong
- use get by label and get by role for testing e2e with either agent-browser cli or playwright
- use at least this:use real yr62813@gmail.com for testing e2e ui interactions live.
- we are a mixture of amazon + instacart
- surreal is gone, mailjet is gone. make sure there are no references to those in whole repo
- always prefer AgentBrowser, update if needed, playwright is secondary

## Current Hot Path

- `dev.orignagta.ca` search/category failures map to backend deploy/runtime drift until a fresh live recheck proves otherwise. The current repo fix is the PostgreSQL query translator cast/contains update plus full dev catalog reseed.
- Google web auth is still an active live issue until both conditions are true:
  - `/auth/providers` only reports Google enabled for a valid `.apps.googleusercontent.com` client ID
  - the deployed login page no longer contains the literal `__GOOGLE_WEB_CLIENT_ID__`
- Email/password login API works on dev; registration still needs a fresh browser-level verification because direct API probes without Turnstile are not representative of the web flow.
- OrignaVentures contact/email sending is live-green again; direct live API responses report support + confirmation emails with `status=sent`.
- Production checkout/payment verification remains a manual final gate; use non-destructive probes unless explicit approval is given for a real charge.
- Remaining active investigation item: home cart badge update after add-to-cart still needs deeper live audit.
-dont fucking use spam fabricated email that could ban us with gmail

## Observability

- User-facing codes: `ORIGNA-{DOMAIN}-{NUMBER}`
- Internal support/debug IDs: `SE-YYYYMMDD-XXXXXX`
- Flutter app writes structured internal events to OrignaBase `error_events` via `AppError.log()` and also forwards errors to self-hosted GlitchTip.
- Reference docs: `docs/ERROR_CODES.md` and `docs/REPO_MAP.md`

## MCP

Project `.mcp.json`: dart-mcp, flutter-pilot, github. Cloudflare MCP available via user-level config.

## Parallel AI Coordination

- Before editing, read `WORK_CLAIMS.md`.
- Claim exact paths, not broad themes.
- Active backlog lives in `CORE.md`.
- Verified outcomes go to `STATE.md`.
- Coordination rules live in `docs/AI_COORDINATION.md`.
- `CLAUDE.md`, `AGENTS.md`, `CORE.md`, `STATE.md`, and `WORK_CLAIMS.md` are single-owner files; never let multiple agents edit them concurrently.

## AI Skills Catalog

See `docs/AI_SKILLS_CATALOG.md` for the complete inventory of all skills, commands, agents, rules, and workflows available to all AI agents.


APIs:
Postal-email
Meilisearch-search
Glitchtip-error logging