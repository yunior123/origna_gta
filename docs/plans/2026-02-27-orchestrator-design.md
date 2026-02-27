# Orchestrator Design — 2026-02-27

## What We Built

A multi-model AI orchestration layer for OrignaGTA development tooling.

## Architecture

**Files created:**
- `.claude/skills/orchestrator/SKILL.md` — routing protocol skill
- `.claude/agents/orchestrator-agent.md` — Claude Opus orchestrator agent

## Key Decisions

### Model Routing
- **Gemini Flash** (`gemini-2.0-flash`) → large codebase analysis, web research, >50 file dumps
- **Gemini Pro** (`gemini-1.5-pro`) → architecture synthesis, complex reasoning
- **Claude subagents** → domain expertise (project memory, logic audits, payment audits)
- **Bash tools** → direct CLI execution

### Architecture Pattern: Approach B
Skill + Dedicated Agent with role routing + filesystem-as-state (`.orch/` dir).
Chosen over:
- Approach A (too minimal, no routing)
- Approach C (Double Diamond too heavy for daily dev workflow)

### Gemini CLI Integration
`gemini` binary at `/Users/yuniorrodriguezosorio/.nvm/versions/node/v22.12.0/bin/gemini` (v0.30.0)
Invoked headlessly via `-p "prompt" --yolo` flags.

### Filesystem-as-State
`.orch/tasks/`, `.orch/results/`, `.orch/synthesis/` for async multi-step coordination.
Makes orchestration observable and debuggable.

## Usage Examples

```bash
# Ask Claude to use the orchestrator agent:
# "Use the orchestrator agent to: run all auditors in parallel and synthesize"
# "Use the orchestrator agent to: research Medusa returns flow with Gemini, then audit ours"
```

## Sources
- [claude-octopus](https://github.com/nyldn/claude-octopus) — Double Diamond pattern, 31 personas
- [claude_code_bridge](https://github.com/bfly123/claude_code_bridge) — real-time multi-AI collaboration
- [gemini-cli-subagent](https://aicodingtools.blog/en/claude-code/gemini-cli-as-subagent-of-claude-code) — Gemini headless pattern
- [Claude Code workflows](https://www.365iwebdesign.co.uk/news/2026/01/29/orchestrate-ai-agents-claude-code/) — orchestration best practices
