---
name: token-optimizer
description: "Token and cost optimization for Claude Code sessions. Model routing, caching, context budgeting, and cost tracking. Use when optimizing API costs or managing long sessions."
---

# Token Optimizer — origna_gta

Minimize API costs and maximize session efficiency. Every token spent should produce value.

## Cost-Aware Model Routing

Route tasks to the cheapest capable tier.

### Tier 1: No LLM (Direct Tool Use)
Zero token cost. Use for deterministic transforms.

| Transform | Tool | Example |
|-----------|------|---------|
| `var` to `const` | Edit (replace_all) | Convert mutable to immutable |
| Add type annotations | Edit | `var x = 5` -> `int x = 5` |
| Add error handling wrapper | Edit | Wrap in try-catch with AppError |
| Fix import paths | Edit (replace_all) | Relative to package imports |
| Add semantics labels | Edit | `Semantics(label: 'btn-x')` |
| Remove `print()` | Grep + Edit | Replace with `AppLogger` |
| Format code | Bash | `dart format` / `cargo fmt` |

### Tier 2: Subagent (Cheaper Model)
Low token cost. Use for focused, well-scoped tasks.

- Write a single unit test for a pure function
- Add missing `const` constructors across a file
- Fix a specific lint warning pattern
- Generate boilerplate (freezed model, provider stub)
- Add doc comments to public API

### Tier 3: Main Agent (Best Model)
Full token cost. Reserve for tasks requiring deep reasoning.

- Design new service architecture
- Debug race conditions or state management bugs
- Refactor complex state machines
- Cross-stack changes (Flutter + Rust simultaneously)
- Security-sensitive code (auth, payments, webhooks)

## ReasoningBank (Pattern Cache)

Cache successful reasoning patterns to avoid re-deriving them.

### How It Works
1. When solving a novel problem, note the reasoning chain
2. Store as a pattern: `trigger -> approach -> verification`
3. On similar future tasks, apply the cached pattern directly

### origna_gta Patterns (Pre-loaded)

| Trigger | Approach | Verify |
|---------|----------|--------|
| "money calculation bug" | Check for float usage, verify cents arithmetic | `grep -r "double.*price\|double.*cost\|double.*amount"` |
| "provider not updating" | Check `ref.watch` vs `ref.read`, verify `select()` usage | Run affected widget test |
| "API 403 error" | Check JWT sub format, verify RLS | Check PostgreSQL RLS policies |
| "Meilisearch not finding" | Check filterable/sortable attrs, verify `:` -> `_` sanitization | Query Meilisearch directly |
| "widget overflow" | Check `Expanded`/`Flexible` wrapping, verify `ConstrainedBox` | Widget test with small screen |

## Context Budget Management

### Rules
1. **Keep system prompt minimal**: Rules auto-load from `.claude/rules/`. Don't repeat them in conversation.
2. **Load skills on demand**: Skills load only when their description matches the task. Never pre-load all skills.
3. **File references over inlining**: Say "see `lib/utils/env_config.dart` lines 10-25" instead of pasting the content.
4. **Compact at phase boundaries**: After completing a phase (research, implement, test), summarize findings in 2-3 lines instead of carrying full context forward.
5. **Subagents for exploration**: Use subagents for reading/searching. They consume their own context window, protecting the main thread.

### Context Budget Allocation
| Phase | Budget Share | Notes |
|-------|-------------|-------|
| Research | 15% | Subagent handles most reads |
| Planning | 10% | Brief plan, file list, acceptance criteria |
| Implementation | 50% | Actual code changes |
| Testing | 15% | Run tests, fix failures |
| Review | 10% | Final verification |

## Trigger-Table Lazy Loading

Map keywords to skills. Load skill only when keyword appears in task.

| Keyword Pattern | Skill to Load |
|----------------|---------------|
| "swarm", "multi-agent", "coordinate", "team" | swarm-orchestration |
| "token", "cost", "budget", "optimize spend" | token-optimizer |
| "stripe", "payment", "checkout", "webhook" | (payments rule - already auto-loaded) |
| "test", "coverage", "e2e" | (testing rule - already auto-loaded) |

Skills in `.claude/rules/` auto-load always. Skills in `.claude/skills/` load on demand.

## Duplicate Instruction Detection

Before adding a new rule or instruction:
1. Grep existing rules: `.claude/rules/*.md`
2. Grep project CLAUDE.md
3. Grep global `~/CLAUDE.md`
4. If the instruction exists anywhere, do NOT duplicate it. Reference the existing location.

Common duplicates to watch for:
- Money/cents rules (in flutter.md, backend.md, payments.md, orders.md)
- DesignTokens rules (in flutter.md, CLAUDE.md)
- Test commands (in testing.md, CLAUDE.md)

## Per-Task Cost Tracking

Log for each task in a swarm or session:

```
Task: <description>
Model tier: T1/T2/T3
Tokens (est): input/output
Retries: N
Wall-clock: Xs
Result: success/failure
```

Use this data to calibrate future routing decisions. If T2 tasks frequently need retry at T3, adjust the routing table.

## 8GB RAM Constraints (origna_gta-specific)

- **Sequential only**: Never run `flutter build` + `cargo build` simultaneously
- **Max 5 agents**: In swarm mode, hard cap at 5 (including queen)
- **No emulators**: All tests against dev OrignaBase
- **Kill orphans**: Before E2E tests, kill orphan Chrome/Chromium processes
- **One build at a time**: Flutter analyze -> Flutter test -> Cargo clippy -> Cargo test (never parallel)

## Quick Reference: When to Use Each Tier

```
T1 (no LLM):  "add const" "fix imports" "remove prints" "format" "rename variable"
T2 (subagent): "write test for X" "add docs to Y" "fix lint in Z" "add semantics"
T3 (main):     "design" "debug" "refactor" "security" "cross-stack" "why is X broken"
```
