# Agentic Engineering Rules — origna_gta

## Parallel Dispatch
- Always dispatch independent tasks in parallel using the Agent tool
- Group related tasks for a single agent; independent tasks get separate agents
- Max 5 agents per dispatch (8GB RAM constraint)

## Agent Prompt Quality
- Each agent gets: specific scope, clear goal, constraints, expected output format
- Include all necessary context — agents don't inherit session history
- Specify whether the agent should write code or just research

## When to Use Agents vs Direct Tools
- Simple file search → Glob/Grep directly
- Broad codebase exploration → Agent with subagent_type="Explore"
- Independent implementation tasks → Parallel agents
- Related failures → Single agent investigates all

## Synthesis
After parallel agents return:
- Read each summary
- Check for conflicts (same files edited differently)
- Highlight agreements across agents
- Note tensions between recommendations
- Produce unified action items

## Agent Types Available
- `general-purpose` — default, full tool access
- `Explore` — fast codebase exploration, read-only
- `Plan` — architecture and design, read-only
- Project-specific: dart-reviewer, security-auditor, payment-auditor, etc.

## Forbidden
- Dispatching agents for trivial tasks (single file read, simple grep)
- More than 5 agents at once on 8GB RAM
- Agents that edit the same files in parallel (merge conflicts)
- Duplicating work an agent is already doing
