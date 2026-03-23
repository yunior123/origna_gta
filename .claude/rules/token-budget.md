# Token Budget Rules — origna_gta

## Model Routing
- **T1 (no LLM)**: Deterministic transforms — rename, add types, format, fix imports, add const, remove print
- **T2 (subagent)**: Single test, fix lint, add docs, generate boilerplate, add semantics
- **T3 (main agent)**: Design, debug, refactor, security, cross-stack, architecture decisions
- Escalate tier only when lower tier fails twice — don't retry at same tier

## Context Protection
- Use subagents for exploration and reading (protects main context window)
- Skills load on demand via description matching — never pre-load all skills
- Prefer file path + line range references over inlining content
- Compact at phase boundaries (after research, after implementation), not mid-work

## RAM Constraint (8GB)
- Max 5 parallel agents (including queen in swarm mode)
- Sequential builds only: analyze -> test -> build (never parallel)
- Kill orphan Chrome processes before E2E runs
- Never run flutter build + cargo build simultaneously

## Cost Awareness
- Track model tier per task: T1/T2/T3
- Avoid retry loops — diagnose root cause instead
- Check conversation history before re-reading files already in context
- Use `--bare` for scripted automation (skips hooks/plugins)
- Use `/effort` to adjust thinking depth per task
