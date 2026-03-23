---
name: team-builder
description: "Interactive agent team composer. Discovers project and global agents, groups by domain, lets you pick a team of up to 5, dispatches them in parallel, and synthesizes results. Use for multi-perspective analysis."
---

# Team Builder

Interactive agent team composer that discovers available agents, groups them by domain, lets the user pick a team, dispatches them in parallel on a task, and synthesizes the results.

## When to Use

- Multi-perspective code review or audit
- Complex problems that benefit from different expert viewpoints
- Large changes that touch multiple domains (frontend + backend + security)
- Pre-release quality checks

## Workflow

### Step 1: Discover Available Agents

Glob these directories and merge results:

```
.claude/agents/*.md          (project agents)
~/.claude/agents/*.md        (global agents)
```

For each `.md` file found:
1. Read the first 10 lines
2. Extract the agent name from the first `# Heading`
3. Extract the description from the first paragraph after the heading
4. Record the file path

### Step 2: Group by Domain

Classify each agent into one of these domains based on its name and description:

| Domain | Typical Agents |
|--------|---------------|
| **Security** | security-auditor, crypto-reviewer |
| **Payments** | payment-auditor |
| **Frontend** | frontend-auditor, uiux-expert, dart-reviewer |
| **Backend** | database-engineer, rust-senior-dev, systems-architect |
| **Testing** | flutter-tester |
| **Quality** | logic-auditor, cross-stack-auditor, performance-auditor, legacy-code-auditor |
| **Compliance** | legal-compliance-auditor |
| **Ops** | orchestrator-agent, heartbeat-agent, repomix-analyzer-agent |
| **Architecture** | perf-engineer, concurrency-specialist |
| **AI Delegation** | codexcli, geminicli |
| **GSD** | gsd-planner, gsd-executor, gsd-verifier, and similar |
| **Other** | Anything that doesn't fit above |

Agents that fit multiple domains: pick the most specific one.

### Step 3: Present Menu

Display the grouped agents to the user:

```
Available agent domains:

 1. Security (2)     — security-auditor, crypto-reviewer
 2. Payments (1)     — payment-auditor
 3. Frontend (3)     — frontend-auditor, uiux-expert, dart-reviewer
 4. Backend (3)      — database-engineer, rust-senior-dev, systems-architect
 5. Testing (1)      — flutter-tester
 6. Quality (4)      — logic-auditor, cross-stack-auditor, performance-auditor, legacy-code-auditor
 7. Compliance (1)   — legal-compliance-auditor
 8. Ops (3)          — orchestrator-agent, heartbeat-agent, repomix-analyzer-agent
 9. Architecture (2) — perf-engineer, concurrency-specialist
10. AI Delegation (2) — codexcli, geminicli
11. GSD (N)          — gsd-planner, gsd-executor, ...

Pick domains or name specific agents.
Examples: "1,3" or "security + dart-reviewer" or "all quality"
```

### Step 4: Handle Selection

Parse the user's input:

- **Numbers:** "1,3" selects all agents from domains 1 and 3
- **Names:** "security + dart" fuzzy-matches agent names
- **Domain names:** "security" selects all agents in that domain
- **"all":** Selects everything (will likely exceed limit)

#### Enforce the 5-Agent Limit

The 8GB RAM constraint means no more than 5 agents can run in parallel.

If the selection exceeds 5 agents:
```
You selected 8 agents but the limit is 5 (8GB RAM).
Current selection:
  1. security-auditor
  2. crypto-reviewer
  3. frontend-auditor
  4. uiux-expert
  5. dart-reviewer
  6. logic-auditor
  7. cross-stack-auditor
  8. performance-auditor

Which 5 should I keep? (e.g., "1-5" or "1,3,4,6,8")
```

### Step 5: Get the Task

Once the team is selected, ask what they should work on:

```
Selected team (3 agents):
  - Security Auditor
  - Dart Reviewer
  - Payment Auditor

What should they work on?
(e.g., "Review the checkout flow changes" or "Audit lib/services/")
```

If the user already provided the task in their initial message, skip this step.

### Step 6: Dispatch Agents in Parallel

For each selected agent:

1. Read the full agent markdown file
2. Construct a prompt combining:
   - The agent's role/instructions from its markdown
   - The user's task description
   - Relevant context (file paths, recent changes, etc.)
3. Use the Agent tool to spawn each agent in parallel

Important constraints:
- Max 5 agents (8GB RAM)
- Each agent gets `maxTurns: 20`
- Pass `memory: "project"` for project context

### Step 7: Synthesize Results

After all agents complete, produce a unified report:

```markdown
## Team Report

### Team
| Agent | Domain | Status |
|-------|--------|--------|
| Security Auditor | Security | Completed |
| Dart Reviewer | Frontend | Completed |
| Payment Auditor | Payments | Completed |

### Agreements (all agents agree)
- [Finding that multiple agents flagged]

### Unique Findings
| Agent | Finding | Severity |
|-------|---------|----------|
| Security Auditor | Missing HMAC check on webhook | P0 |
| Dart Reviewer | setState in checkout screen | P1 |

### Conflicts / Tensions
- [Any findings where agents disagree or recommend conflicting approaches]
- [Resolution recommendation]

### Recommended Next Steps
1. [Prioritized action item]
2. [Prioritized action item]
3. [Prioritized action item]
```

## Tips

- For code review: Security + Dart Reviewer + relevant domain expert
- For architecture decisions: Systems Architect + Performance Auditor + Backend
- For pre-release: Security + Payment Auditor + Cross-Stack Auditor
- For refactoring: Legacy Code Auditor + Performance Auditor + Dart Reviewer
- Start with 2-3 agents for focused tasks, use 5 only for broad audits
