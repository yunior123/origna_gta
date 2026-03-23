# /team-builder — Agent Team Composer

**Usage**: `/team-builder [$ARGUMENTS]`

Discover, select, and dispatch a team of specialized agents in parallel.

## Process

1. **Discover agents** — Glob `.claude/agents/*.md` and `~/.claude/agents/*.md`. Extract name + description from each file's heading and first paragraph.

2. **Group by domain** — Present menu:
```
Available agent domains:
1. Security (2) — security-auditor, crypto-reviewer
2. Frontend (3) — frontend-auditor, uiux-expert, dart-reviewer
3. Backend (3) — database-engineer, rust-senior-dev, systems-architect
4. Testing (1) — flutter-tester
5. Quality (4) — logic-auditor, cross-stack-auditor, performance-auditor, legacy-code-auditor
6. Payments (1) — payment-auditor
7. Compliance (1) — legal-compliance-auditor
8. Ops (3) — orchestrator-agent, heartbeat-agent, repomix-analyzer-agent
9. Architecture (2) — perf-engineer, concurrency-specialist
10. AI (2) — codexcli, geminicli

Pick domains or name specific agents (e.g., "1,3" or "security + dart"):
```

3. **Handle selection** — Accept numbers, names, or fuzzy match. **Max 5 agents** (8GB RAM).

4. **Get task** — If `$ARGUMENTS` provided, use as task. Otherwise ask: "What should they work on?"

5. **Spawn in parallel** — Use Agent tool for each. Prompt = agent file content + task description.

6. **Synthesize** — Unified report:
   - Results grouped by agent
   - Agreements across agents
   - Conflicts or tensions
   - Recommended next steps
