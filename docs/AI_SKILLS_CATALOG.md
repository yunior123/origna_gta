# AI Skills & Tools Catalog — OrignaGTA

> Definitive reference for all AI agents: Claude, Codex, Gemini, Copilot, OpenCode, Kilo.
> Last updated: 2026-03-23

## How to Use

- **Skills** auto-activate based on context (Claude reads descriptions to decide)
- **Commands** are invoked with `/command-name` (slash commands)
- **Agents** are dispatched as subagents for specialized tasks
- **Rules** are always loaded and enforced automatically
- **Plugin systems** (CCG, GSD, gstack) provide orchestrated workflows

## Counts

| Category | Count |
|----------|-------|
| Project Skills | 30 |
| Global Skills | 34+ |
| gstack Skills | 28 |
| Project Commands | 37 |
| Global Commands | 28 |
| CCG Commands | 28 |
| GSD Commands | 32 |
| Project Agents | 17 |
| Global Agents | 22 |
| Rules | 12 |
| MCP Servers | 34 |
| Model Aliases | 6 |

---

## Project Commands (37)

| Command | Purpose |
|---------|---------|
| `/add-semantics` | Add Playwright semantics labels to Flutter screens |
| `/agent-heartbeat` | Agent email monitoring loop (Gmail, Sentry, Stripe) |
| `/audit-security` | Run comprehensive security audit |
| `/audit-workflow` | Deep logic audit on a specific workflow (checkout, orders, etc.) |
| `/channels-setup` | Set up Telegram/Discord channels for Claude Code |
| `/check-schema-sync` | Verify all schema layers are in sync (Dart, Rust, SurrealDB) |
| `/clear-context` | Pre-clear checklist and context hygiene |
| `/code-review` | Multi-agent code review (4 parallel reviewers) |
| `/commit-push` | Commit and push changes with intelligent message |
| `/create-skill` | Capture a workflow approach as a reusable skill |
| `/cross-stack-check` | Cross-stack field name consistency check |
| `/customer-support-agent` | Claude Agent SDK support integration |
| `/deep-research` | Multi-source deep research with structured findings |
| `/deploy` | Deploy Flutter Web to VPS (Caddy) — dev/staging/production |
| `/design-screen` | Design a new screen with premium UI/UX |
| `/diagnose` | Systematic bug investigation |
| `/execute-plan` | Execute the current plan phase by phase |
| `/fix-tests` | Fix failing tests |
| `/investigate` | Delegate research to a subagent |
| `/latest-features` | Claude Code latest features quick reference |
| `/office-hours` | Problem framing before code (6 forcing questions) |
| `/optimize-db` | Optimize database queries and costs |
| `/pause-work` | Save session state for later resume |
| `/permissions` | Set safe permissions without repeating |
| `/plan-task` | Break a complex task into executable phases |
| `/ralph-loop` | Autonomous multi-hour coding loop |
| `/resume-work` | Restore session state and continue |
| `/retro` | Session retrospective |
| `/reverse-engineer` | Generate docs from code |
| `/seed-dev` | Seed the dev environment (products, reviews) |
| `/swarm` | Coordinated agent swarm for complex tasks |
| `/tdd` | Test-driven development workflow |
| `/team-builder` | Agent team composer (pick up to 5 agents) |
| `/test-all` | Run all tests (Flutter, E2E, or all) |
| `/ui-premium` | Premium UI/UX workflow |
| `/ui-review` | UI review with visual inspection |
| `/understand` | Analyze codebase architecture |
| `/verify` | Run verification loop (Flutter, Rust, or all) |

### Global Commands (28)

| Command | Purpose |
|---------|---------|
| `/channels-setup` | Set up Telegram/Discord channels for Claude Code |
| `/chromadb-search` | Search locally-indexed knowledge base via ChromaDB |
| `/code-review` | Multi-agent code review (global version) |
| `/content-writer` | Generate SEO blog post, social captions, newsletter blurb |
| `/daily-brief` | Morning/afternoon/night brief with puzzles, news, learning |
| `/deep-research` | Multi-source research (global version) |
| `/github-router` | Poll GitHub for issues tagged 'claude-code' |
| `/invoicer` | Generate professional invoice with HST 13% Ontario |
| `/job-apply` | Fetch job description, match CV, draft cover letter |
| `/lead-generator` | Find companies by industry/location/size |
| `/memory-recall` | Semantic memory recall via Pinecone |
| `/office-hours` | Problem framing (global version) |
| `/playwright-flutter` | Testing Flutter Web apps using Playwright |
| `/ralph-loop` | Autonomous coding loop (global version) |
| `/retro` | Session retrospective (global version) |
| `/sandbox-bash` | Wrap dangerous bash commands in Docker container |
| `/seo-auditor` | Analyze SEO health of a URL, score 0-100 |
| `/session-restore` | Restore work context from saved session |
| `/session-save` | Save current work context for later |
| `/slack-poll` | Scan Slack for unread DMs/mentions tagged for Claude |
| `/swarm` | Coordinated agent swarm (global version) |
| `/tdd` | TDD workflow (global version, auto-detects stack) |
| `/team-builder` | Agent team composer (global version) |
| `/verify` | Verification loop (global version, auto-detects stack) |
| `/web-research` | Fetch URL/topic, summarize, save to memory |

### CCG Commands (28) — Multi-Model Orchestration

| Command | Purpose |
|---------|---------|
| `/ccg:analyze` | Multi-model technical analysis (Codex backend + Gemini frontend, cross-validated) |
| `/ccg:backend` | Backend workflow (research, ideate, plan, execute, optimize, review) — Codex-led |
| `/ccg:clean-branches` | Safe Git branch cleanup (dry-run by default) |
| `/ccg:codex-exec` | Codex executes a plan (MCP search + code + tests, multi-model review) |
| `/ccg:commit` | Smart Git commit with Conventional Commit message generation |
| `/ccg:context` | Project context management (.context dir, decision log, archive) |
| `/ccg:debug` | Multi-model debugging (Codex backend + Gemini frontend diagnosis) |
| `/ccg:enhance` | Prompt enhancement — convert vague requirements to structured tasks |
| `/ccg:execute` | Multi-model collaborative execution (prototype, refactor, audit) |
| `/ccg:feat` | Smart feature development — auto-identifies input type, full workflow |
| `/ccg:frontend` | Frontend workflow (research, ideate, plan, execute, optimize, review) — Gemini-led |
| `/ccg:init` | Initialize project AI context (root + module CLAUDE.md index) |
| `/ccg:optimize` | Multi-model performance optimization (Codex backend + Gemini frontend) |
| `/ccg:plan` | Multi-model collaborative planning with step-by-step implementation plan |
| `/ccg:review` | Multi-model code review (auto-reviews git diff, dual-model cross-validation) |
| `/ccg:rollback` | Interactive Git rollback (reset/revert mode) |
| `/ccg:spec-impl` | Execute by spec + multi-model collaboration + archive |
| `/ccg:spec-init` | Initialize OpenSpec (OPSX) environment + verify multi-model MCP tools |
| `/ccg:spec-plan` | Multi-model analysis, disambiguate, zero-decision executable plan |
| `/ccg:spec-research` | Requirements to constraint set (parallel exploration + OPSX proposal) |
| `/ccg:spec-review` | Dual-model cross-review (standalone, use anytime) |
| `/ccg:team-exec` | Agent Teams parallel implementation — spawn Builder teammates |
| `/ccg:team-plan` | Agent Teams planning — Lead calls Codex/Gemini in parallel |
| `/ccg:team-research` | Agent Teams requirements research — parallel codebase exploration |
| `/ccg:team-review` | Agent Teams review — dual-model cross-review with severity levels |
| `/ccg:test` | Multi-model test generation (routes Codex backend / Gemini frontend) |
| `/ccg:workflow` | Full multi-model dev workflow (research, ideate, plan, execute, optimize, review) |
| `/ccg:worktree` | Manage Git Worktree in ../.ccg/ directory |

### GSD Commands (32) — Project Management & Execution

| Command | Purpose |
|---------|---------|
| `/gsd:add-phase` | Add phase to end of current milestone roadmap |
| `/gsd:add-tests` | Generate tests for completed phase based on UAT criteria |
| `/gsd:add-todo` | Capture idea or task as todo from conversation context |
| `/gsd:audit-milestone` | Audit milestone completion against original intent |
| `/gsd:check-todos` | List pending todos, select one to work on |
| `/gsd:cleanup` | Archive accumulated phase directories from completed milestones |
| `/gsd:complete-milestone` | Archive completed milestone, prepare for next version |
| `/gsd:debug` | Systematic debugging with persistent state across context resets |
| `/gsd:discuss-phase` | Gather phase context through adaptive questioning |
| `/gsd:execute-phase` | Execute all plans in a phase with wave-based parallelization |
| `/gsd:health` | Diagnose planning directory health, optionally repair |
| `/gsd:help` | Show available GSD commands and usage guide |
| `/gsd:insert-phase` | Insert urgent work as decimal phase (e.g., 72.1) |
| `/gsd:join-discord` | Join the GSD Discord community |
| `/gsd:list-phase-assumptions` | Surface Claude's assumptions about a phase approach |
| `/gsd:map-codebase` | Analyze codebase with parallel mapper agents |
| `/gsd:new-milestone` | Start new milestone cycle, update PROJECT.md |
| `/gsd:new-project` | Initialize new project with deep context gathering |
| `/gsd:pause-work` | Create context handoff when pausing work mid-phase |
| `/gsd:plan-milestone-gaps` | Create phases to close gaps from milestone audit |
| `/gsd:plan-phase` | Create detailed phase plan (PLAN.md) with verification loop |
| `/gsd:progress` | Check project progress, route to next action |
| `/gsd:quick` | Quick task with GSD guarantees (atomic commits, state tracking) |
| `/gsd:reapply-patches` | Reapply local modifications after a GSD update |
| `/gsd:remove-phase` | Remove future phase from roadmap, renumber subsequent |
| `/gsd:research-phase` | Research how to implement a phase |
| `/gsd:resume-work` | Resume work from previous session with full context |
| `/gsd:set-profile` | Switch model profile (quality/balanced/budget) |
| `/gsd:settings` | Configure GSD workflow toggles and model profile |
| `/gsd:update` | Update GSD to latest version with changelog |
| `/gsd:validate-phase` | Retroactively audit and fill Nyquist validation gaps |
| `/gsd:verify-work` | Validate built features through conversational UAT |

---

## Project Skills (31) — Auto-Invoked

| Skill | Description | When It Activates |
|-------|-------------|-------------------|
| `ccg` | CCG multi-model orchestration — quality gates, doc gen, agent teams | Multi-model workflows |
| `channels-setup` | Set up Telegram/Discord channels for Claude Code notifications | Communication setup |
| `code-review-multi` | 4 parallel reviewers (correctness, security, performance, standards) with confidence scoring | Before commits, PRs, releases |
| `coding-standards` | Enforces MVVM, Riverpod, DesignTokens, integer cents, Freezed, AppError/AppLogger | Writing or reviewing code |
| `deep-research` | Multi-source research (web, docs, codebase, memory) with confidence levels | Technical decisions, investigations |
| `e2e-testing` | E2E testing patterns for OrignaGTA (Bun, agent-browser, phased execution) | E2E test creation/debugging |
| `feature-dev` | 7-phase structured feature development (requirements through documentation) | Building new features |
| `flow-audit` | Deep audit of 12 critical app flows — traces full data path, finds bugs, race conditions, security gaps | Audit a flow, deep logic review, "find bugs in checkout/orders" |
| `flutter-code-review` | Reviews Dart code for MVVM, Riverpod, DesignTokens, Semantics, performance | After Dart code changes |
| `flutter-riverpod-patterns` | Riverpod state management: MVVM, provider patterns, AsyncNotifier, reactive state | State management tasks |
| `flutter-widget-previews` | Flutter Widget Previews: @Preview annotations, coverage, Riverpod/localization | Widget preview setup |
| `order-lifecycle` | Order state transitions, stock management, notifications, returns, multi-seller | Order-related work |
| `orignabase-dev` | OrignaBase Rust BaaS development (crate architecture, testing, GraphQL, SDK protocol) | Backend Rust development |
| `orignabase-devops` | OrignaBase VPS deployment (server setup, SurrealDB, nginx, TLS, backups, monitoring) | DevOps/deployment tasks |
| `orignabase-flutter-sdk` | OrignaBase Flutter/Dart SDK (Firestore-compatible API, GraphQL, FieldValue, Query builder) | SDK integration work |
| `ralph-loop` | Autonomous multi-hour coding loop with commits between iterations | Bulk implementation, overnight work |
| `responsive-design` | Responsive layouts (breakpoints, grid systems, responsive text, spacing) | Layout/responsive work |
| `rust-best-practices` | Rust ownership, error handling, async patterns, security, performance, idioms | Rust code writing |
| `rust-security-audit` | Rust security audit (injection, auth bypass, unsafe code, dependency CVEs, OWASP) | Security reviews |
| `santa-method` | Naughty/Nice list code review — catches anti-patterns while praising good patterns | Code review, pre-commit |
| `security-guidance` | Pre-edit security scanner (command injection, XSS, secrets, unsafe input) | Before code changes |
| `security-review` | Security review for Flutter + Rust e-commerce (Stripe, JWT, queries, OWASP) | Before releases, after auth/payment changes |
| `source-products` | Product sourcing for OrignaGTA — dropshipping research, product candidates | Product research |
| `stripe-integration` | Stripe payments (Checkout Sessions, webhooks, Connect payouts, refunds, idempotency) | Payment-related work |
| `surrealdb-patterns` | SurrealQL queries, SurrealDB v2 gotchas, transactions, FieldValue, parameterized safety | Database work |
| `swarm-orchestration` | Queen-led multi-agent hierarchy with task routing and consensus | Complex multi-file features |
| `tdd-workflow` | Test-driven development for Flutter/Dart and Rust with coverage targets | Implementing features, fixing bugs |
| `team-builder` | Interactive agent team composer — discover, pick up to 5, dispatch in parallel | Multi-perspective analysis |
| `token-optimizer` | Token and cost optimization — model routing, caching, context budgeting | API cost optimization |
| `verification-loop` | 6-phase verification (analyze, clippy, tests, security, diff review) for Flutter + Rust | After features, before commits |

---

## Global Skills (34+) — Available in Any Project

| Skill | Description |
|-------|-------------|
| `agent-harness-construction` | Guide for building Claude Code agent harnesses (skills, agents, commands, rules, hooks, plugins) |
| `ccg` | CCG Skills — quality gates, doc generator, multi-agent orchestration |
| `channels-setup` | Set up Claude Code Channels for Telegram/Discord integration |
| `code-review-multi` | Multi-agent code review with 4 parallel reviewers, confidence scoring |
| `coding-standards` | Universal coding standards (naming, structure, error handling, testing) — language-agnostic |
| `continuous-learning` | Auto-extract patterns, failures, learnings from each session to memory files |
| `deep-research` | Multi-source deep research (web, docs, codebase, memory) with confidence levels |
| `e2e-testing` | E2E testing patterns (Bun, agent-browser, phased execution) |
| `feature-dev` | 7-phase structured feature development (requirements through documentation) |
| `flutter-riverpod-patterns` | Riverpod state management: MVVM, provider patterns, AsyncNotifier, reactive state |
| `flutter-widget-previews` | Flutter Widget Previews: @Preview annotations, coverage, Riverpod/localization |
| `gstack` | Headless browser for QA testing and site dogfooding (navigate, interact, screenshot) |
| `hooks-patterns` | Reference for all 13 Claude Code hook events with production patterns |
| `mcp-server-patterns` | Patterns for building and configuring MCP servers |
| `office-hours` | Problem framing through 6 forcing questions before any code |
| `order-lifecycle` | Order state transitions, stock management, notifications, returns, multi-seller |
| `orignabase-dev` | OrignaBase Rust BaaS development (crate architecture, testing, GraphQL, SDK protocol) |
| `orignabase-devops` | OrignaBase VPS deployment (server setup, SurrealDB, nginx, TLS, backups, monitoring) |
| `orignabase-flutter-sdk` | OrignaBase Flutter/Dart SDK (Firestore-compatible API, GraphQL, FieldValue, Query builder) |
| `ralph-loop` | Autonomous multi-hour coding loop with atomic commits |
| `responsive-design` | Responsive layouts (breakpoints, grid systems, responsive text, spacing) |
| `rust-best-practices` | Rust ownership, error handling, async patterns, security, performance, idioms |
| `rust-security-audit` | Rust security audit (injection, auth bypass, unsafe code, dependency CVEs, OWASP) |
| `santa-method` | Naughty/Nice list code review — works with any language or framework |
| `source-products` | Product sourcing — dropshipping research, product candidates |
| `strategic-compact` | Context window management — when and how to compact to prevent quality degradation |
| `stripe-integration` | Stripe payments (Checkout Sessions, webhooks, Connect payouts, refunds, idempotency) |
| `surrealdb-patterns` | SurrealQL queries, SurrealDB v2 gotchas, transactions, FieldValue, parameterized safety |
| `swarm-orchestration` | Multi-agent swarm orchestration (queen-led hierarchy, task routing, consensus) |
| `tdd-workflow` | Generic TDD workflow — auto-detects stack, applies appropriate test patterns |
| `team-builder` | Interactive agent team composer — discover, pick, dispatch, synthesize |
| `token-optimizer` | Token and cost optimization — model routing, caching, context budgeting |
| `understand-codebase` | Analyze any codebase into architecture map with dependency graphs |
| `verification-loop` | Auto-detecting verification loop — detects stack, runs analysis/tests/security/diff review |

---

## gstack Skills (28) — Browser-Based QA & Workflow

| Skill | Description |
|-------|-------------|
| `office-hours` | YC Office Hours — six forcing questions (startup mode or engineering mode) |
| `plan-ceo-review` | CEO/founder-mode plan review — rethink the problem, find the 10-star product |
| `plan-eng-review` | Eng manager-mode plan review — lock in architecture, dependencies, timeline |
| `plan-design-review` | Designer's eye plan review — interactive, like CEO and Eng review |
| `design-consultation` | Design consultation — understand product, research landscape, propose design system |
| `autoplan` | Auto-review pipeline — reads full CEO, design, and eng review skills from disk |
| `review` | Pre-landing PR review — analyzes diff for SQL safety, LLM trust, security |
| `design-review` | Designer's eye QA — finds visual inconsistency, spacing, hierarchy problems |
| `qa` | Systematically QA test a web app and fix bugs found |
| `qa-only` | Report-only QA testing — produces report without fixing |
| `ship` | Ship workflow: merge base, test, review, bump VERSION, CHANGELOG, commit, push, PR |
| `land-and-deploy` | Land and deploy — merge PR, wait for CI/deploy, run canary |
| `canary` | Post-deploy canary monitoring — watches for console errors, regressions |
| `document-release` | Post-ship documentation update — reads all docs, cross-references changes |
| `browse` | Fast headless browser for navigating and interacting with any URL |
| `setup-browser-cookies` | Import cookies from real browser (Chrome, Arc, Brave, Edge) into headless |
| `setup-deploy` | Configure deployment settings for /land-and-deploy |
| `investigate` | Systematic debugging with root cause investigation (4 phases) |
| `codex` | OpenAI Codex CLI wrapper — code review, independent diff review |
| `benchmark` | Performance regression detection using the browse daemon |
| `careful` | Safety guardrails for destructive commands (rm -rf, DROP TABLE, etc.) |
| `freeze` | Restrict file edits to a specific directory for the session |
| `guard` | Full safety mode: destructive command warnings + directory-scoped edits |
| `unfreeze` | Clear the freeze boundary, allowing edits to all directories |
| `retro` | Weekly engineering retrospective — analyzes commit history, work patterns |
| `cso` | Chief Security Officer mode — OWASP Top 10, STRIDE threat modeling |
| `test` | Auto-detect and run project tests |
| `supabase` | Supabase integration patterns |

---

## Project Agents (17)

| Agent | Role | Domain |
|-------|------|--------|
| `orchestrator-agent` | Master audit orchestrator — dispatches subagents, returns prioritized report | Cross-domain |
| `rival-agent` | Competitive intelligence — compare against Amazon, Shopify, eBay, etc. | Business |
| `security-auditor` | Security audit — JWT, Stripe HMAC, input sanitization, rate limiting, CORS | Security |
| `cross-stack-auditor` | Cross-stack field name consistency (Dart vs Rust vs SurrealDB) | Schema |
| `repomix-analyzer-agent` | Codebase structure analyzer — dependency maps, import graphs, dead code | Architecture |
| `logic-auditor` | Business logic audit — money cents, shipping thresholds, platform fees | Business Logic |
| `payment-auditor` | Stripe payment flow audit — webhooks, refunds, payouts, Connect | Payments |
| `performance-auditor` | Flutter performance — Riverpod select(), ListView.builder, CachedNetworkImage | Performance |
| `legacy-code-auditor` | Deprecated/dead code patterns — banned APIs, obsolete syntax, stale TODOs | Code Quality |
| `legal-compliance-auditor` | Canadian legal compliance — CASL, PIPEDA, Bill 96, terms acceptance | Legal |
| `dart-reviewer` | Senior Dart/Flutter code reviewer — MVVM, Riverpod, null safety | Flutter |
| `flutter-tester` | Flutter test runner/fixer — analyze + test, identify and fix failures | Testing |
| `frontend-auditor` | Flutter UI/UX audit — responsive layout, DesignTokens, Semantics | UI/UX |
| `heartbeat-agent` | Monitoring/triage — Stripe webhooks, Sentry, GitHub Actions, support emails | Operations |
| `uiux-expert` | Elite UI/UX designer/implementor — world-class design patterns | Design |
| `code-explorer` | Deep codebase analysis — trace execution paths, map architecture layers | Analysis |
| `code-architect` | Feature architecture design — implementation blueprints, data flows | Architecture |

## Global Agents (22)

| Agent | Role |
|-------|------|
| `codexcli` | Delegate tasks to OpenAI Codex CLI (gpt-5.4, full-auto, exec mode) |
| `geminicli` | Delegate tasks to Google Gemini 3.1 Pro via headless CLI |
| `concurrency-specialist` | Audit for race conditions, deadlocks, TOCTOU, channel misuse (via Codex) |
| `crypto-reviewer` | Cryptography/auth review — JWT, TOTP/MFA, password hashing, HMAC (via Codex) |
| `database-engineer` | Database audit — SQL/SurrealQL injection, query performance, transactions (via Codex) |
| `perf-engineer` | Performance profiling — allocation hotspots, lock contention, async overhead (via Codex) |
| `rust-senior-dev` | Senior Rust developer — idiomatic patterns, ownership, lifetimes, unsafe (via Codex) |
| `security-auditor` | OWASP-style security review — injection, auth bypass, RLS/RBAC, crypto (via Codex) |
| `systems-architect` | Architecture review — API design, module boundaries, scalability, deployment (via Codex) |
| `gsd-codebase-mapper` | Codebase structure analysis, writes documents to reduce orchestrator context |
| `gsd-debugger` | Systematic debugging with scientific method, checkpoints |
| `gsd-executor` | Executes GSD plans with atomic commits and deviation handling |
| `gsd-integration-checker` | Cross-phase integration and E2E flow verification |
| `gsd-nyquist-auditor` | Fills Nyquist validation gaps with generated tests |
| `gsd-phase-researcher` | Researches phase implementation, produces RESEARCH.md |
| `gsd-plan-checker` | Goal-backward analysis of plan quality before execution |
| `gsd-planner` | Creates executable phase plans with task breakdown and dependencies |
| `gsd-project-researcher` | Researches domain ecosystem before roadmap creation |
| `gsd-research-synthesizer` | Synthesizes parallel researcher outputs into SUMMARY.md |
| `gsd-roadmapper` | Creates project roadmaps with phase breakdown and success criteria |
| `gsd-verifier` | Goal-backward verification — checks codebase delivers what phase promised |
| CCG agents | `get-current-datetime`, `init-architect`, `planner`, `ui-ux-designer` |

---

## Rules (12) — Always Enforced

| Rule | Enforces |
|------|----------|
| `flutter.md` | MVVM architecture, Riverpod patterns, Dart style, DesignTokens, Semantics, money as cents |
| `backend.md` | OrignaBase as sole backend, environment URLs, auth via OrignaBase, schema timestamp fields, SurrealDB IDs |
| `payments.md` | Integer cents everywhere, Stripe Checkout flow, webhook HMAC, idempotency, platform fee, Connect payouts |
| `orders.md` | Order state machine (pending-confirmed-shipped-delivered), stock management, notifications, returns |
| `testing.md` | No emulators (8GB RAM), unit/widget/E2E test patterns, coverage targets, forbidden test patterns |
| `security.md` | No secrets in code, Cloudflare Turnstile, OrignaBase auth, rate limiting, input validation, Stripe security |
| `agentic-engineering.md` | Agent coordination rules, subagent usage, context management |
| `quality-gates.md` | Quality gates for commits, PRs, and releases |
| `hooks-recommended.md` | Recommended pre-commit and post-commit hooks |
| `token-budget.md` | Token budget constraints and optimization rules |
| `anti-rationalization.md` | Never defer, never claim "good enough" without verification |
| `security-deny.md` | Never read credentials, never rm -rf, never push without approval |

---

## MCP Servers (34)

### Project-Level (`.mcp.json`)

| Server | Tools | Description |
|--------|-------|-------------|
| `dart-mcp` | 10 | Dart SDK: analyze, compile, test, format, fix, run, info, package, doc, create |
| `flutter-pilot` | 17 | Flutter: live app debugging, widget tree, screenshots, hot reload, tap, scroll |
| `github` | 50+ | GitHub: repos, issues, PRs, actions, code search, releases, branches |
| `claude-context` | — | Zilliz semantic code search + NVIDIA embeddings for codebase context |

### Global (User-Level)

| Server | Description |
|--------|-------------|
| `exa` | Free web search API |
| `tavily` | Search, extract, and crawl web content |
| `cloudflare` | Cloudflare Workers, KV, R2, D1, DNS management |
| `colab-exec` | Execute Python code/notebooks in Google Colab |
| `figma` | Figma design file access |
| `stitch` | Stitch design system sync |

### Plugin MCP Servers

| Server | Description |
|--------|-------------|
| `context7` | Context7 library documentation lookup |
| `pinecone` | Pinecone vector DB: search, upsert, rerank |
| `playwright` | Browser automation: navigate, click, fill, screenshot, evaluate |
| `stripe` | Stripe API: customers, products, prices, invoices, subscriptions, refunds |
| `firebase` | Firebase: auth, Firestore, RTDB, storage, functions, messaging, remote config |
| `bio-research` | bioRxiv, ChEMBL, clinical trials, PubMed, Open Targets |
| `slack` | Slack workspace integration |
| `sentry` | Sentry error tracking |

### claude.ai Built-in MCP

| Server | Description |
|--------|-------------|
| `Gmail` | Gmail: read, search, draft, list labels |
| `Excalidraw` | Excalidraw: create views, export, checkpoints |
| `bioRxiv` | bioRxiv preprint search and metadata |
| `ChEMBL` | ChEMBL compound/drug/target search, bioactivity, ADMET |
| `PubMed` | PubMed article search, metadata, full text, citations |

---

## Model Routing Aliases

| Alias | Model | Provider | Cost |
|-------|-------|----------|------|
| `claude` | Opus 4.6 / Sonnet 4.6 | Anthropic | Paid |
| `claude-kimi` | Kimi K2.5 | NVIDIA NIM | Free |
| `claude-mimo` | Mimo V2 Pro | NVIDIA NIM | Free |
| `claude-minimax` | MiniMax M2.5 | NVIDIA NIM | Free |
| `claude-nemotron` | Nemotron 3 Super | NVIDIA NIM | Free |
| `claude-local` | LM Studio local | Local | Free |

Configuration: Set `ANTHROPIC_BASE_URL` + `ANTHROPIC_API_KEY` + `ANTHROPIC_MODEL` for each alias. All skills, hooks, and commands work identically across aliases.

Additional routing:
- `opencode` → Kimi K2.5 via NVIDIA NIM (`/opt/homebrew/bin/opencode`)
- `kilo` → Kimi K2.5 via NVIDIA NIM

---

## AI Delegation System

| Model | Command | Best For |
|-------|---------|----------|
| **Codex** (gpt-5) | `delegate codex "task"` | Code tasks, reasoning, refactoring |
| **Copilot** | `delegate copilot "question"` | Quick code/git questions |
| **Gemini** (3.1 Pro) | `delegate gemini "task"` | Bulk analysis, doc generation |
| **Grok** | `delegate grok "question"` | Real-time info |
| **xChat** (Grok 4.2 Beta) | `delegate xchat "task"` | Deep reasoning |
| **OpenCode** | `/opt/homebrew/bin/opencode run -m MODEL` | Free models (see below) |

### OpenCode Free Models

| Model | ID |
|-------|----|
| Mimo V2 Pro | `opencode/mimo-v2-pro-free` |
| Mimo V2 Omni | `opencode/mimo-v2-omni-free` |
| MiniMax M2.5 | `opencode/minimax-m2.5-free` |
| Nemotron 3 Super | `opencode/nemotron-3-super-free` |
| GLM-5 | `opencode/glm-5` |
| Kimi K2.5 | `opencode/kimi-k2.5` |

---

## Workflows

### 1. Think-Plan-Build-Review-Test-Ship (gstack pipeline)

1. `/office-hours` — Frame the problem with 6 forcing questions
2. `/plan-task` or `/gsd:plan-phase` — Break into executable phases
3. `/tdd` or `/ralph-loop` — Implement with tests first or autonomous loop
4. `/code-review` or `/santa-method` — Multi-agent or Naughty/Nice review
5. `/verify` or `/test-all` — Run verification loop or all tests
6. `/commit-push` then `/deploy` — Commit, push, deploy to VPS

### 2. TDD Cycle (`/tdd`)

1. Write failing test first (Red)
2. Implement minimum code to pass (Green)
3. Refactor while keeping tests green (Refactor)
4. Coverage targets: ViewModels 80%, Services 70%, Payment paths 100%

### 3. Multi-Agent Swarm (`/swarm`)

1. Queen agent decomposes task into subtasks
2. Worker agents execute in parallel (respecting 8GB RAM)
3. Queen synthesizes results, resolves conflicts

### 4. Autonomous Coding (`/ralph-loop`)

1. Define task list in STATE.md or pass as argument
2. Claude works through tasks sequentially with fresh context
3. Atomic commits between iterations
4. Review with `/retro`

### 5. Feature Development 7-Phase (`/feature-dev`)

1. Requirements gathering with complexity routing (simple/medium/complex)
2. Architecture design
3. Implementation (TDD)
4. Integration
5. Testing
6. Review
7. Documentation

### 6. Deep Research (`/deep-research`)

1. Searches web, documentation, codebase, and memory in parallel
2. Produces structured report with confidence levels and sources
3. Saves findings to memory

### 7. Bug Investigation (`/diagnose`)

1. Systematic investigation with hypothesis formation
2. Root cause analysis
3. Fix verification
4. Or `/gsd:debug` for persistent state across context resets

### 8. Code Review (`/code-review` — 4 parallel agents)

1. Correctness reviewer
2. Security reviewer
3. Performance reviewer
4. Standards reviewer
5. Synthesized report with confidence scoring

### 9. Codebase Understanding (`/understand`)

1. Analyze architecture into dependency graphs
2. Map module boundaries and data flows
3. Output architecture document

### 10. Session Management

| Action | Command |
|--------|---------|
| Save session | `/pause-work` or `/session-save` |
| Restore session | `/resume-work` or `/session-restore` |
| Retrospective | `/retro` |
| Strategic compaction | `strategic-compact` skill |
| Clear context | `/clear-context` |

### CCG Multi-Model Workflow

1. `/ccg:plan` — Codex + Gemini analyze in parallel
2. `/ccg:execute` — Fetch prototype, refactor, multi-model audit
3. `/ccg:review` — Dual-model cross-validation
4. `/ccg:test` — Auto-route backend to Codex, frontend to Gemini
5. `/ccg:commit` — Conventional Commit message

### GSD Project Management

1. `/gsd:new-project` — Initialize with deep context
2. `/gsd:plan-phase` — Create PLAN.md with verification loop
3. `/gsd:execute-phase` — Wave-based parallel execution
4. `/gsd:verify-work` — Conversational UAT
5. `/gsd:complete-milestone` — Archive and prepare next

---

## Sources

| Source | What It Provides |
|--------|-----------------|
| [ECC](https://github.com/anthropics/claude-code) | Anthropic official Claude Code patterns |
| [gstack](https://github.com/gstack-ai/gstack) | 28 browser-based QA/workflow skills |
| [GSD](https://github.com/gsd-ai/gsd) | 32 project management commands |
| [Ruflo](https://github.com/ruflo/claude-code-skills) | Feature-dev, santa-method, ralph-loop |
| [AgentSys](https://github.com/agentsys/claude-harness) | Agent harness construction patterns |
| [claude-mem](https://github.com/anthropics/claude-mem) | Memory and continuous learning |
| [flutter-claude-skills](https://github.com/anthropics/flutter-claude-skills) | Flutter/Riverpod/widget preview skills |
| [Trail of Bits](https://github.com/trailofbits/claude-code-config) | Anti-rationalization, security-deny rules |
| [Understand-Anything](https://github.com/Lum1104/Understand-Anything) | Knowledge graph codebase analysis |
| [hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) | 13-hook lifecycle patterns |
| [VoltAgent](https://github.com/voltagent/voltagent) | Agent framework patterns |
| [CCG](https://github.com/codex-cli-generator/ccg) | Multi-model orchestration (28 commands) |
