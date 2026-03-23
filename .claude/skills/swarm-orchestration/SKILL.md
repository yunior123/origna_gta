---
name: swarm-orchestration
description: "Multi-agent swarm orchestration with queen-led hierarchy, task routing, consensus, and anti-drift patterns. Adapted from Ruflo. Use for complex multi-file features requiring coordinated agent teams."
---

# Swarm Orchestration — origna_gta

Multi-agent coordination for complex tasks spanning Flutter/Dart frontend, Rust backend (OrignaBase), and E2E tests. Adapted from Ruflo (claude-flow) patterns for 8GB RAM constraint.

## Queen-Led Hierarchy

Three queen types lead swarms. Only one queen per task.

### Strategic Queen
- Plans multi-phase features (new checkout flow, new entity type, cross-stack migration)
- Decomposes into subtasks, assigns worker types, defines acceptance criteria
- Reviews final output before marking complete
- Use for: features touching 10+ files, new architecture patterns

### Tactical Queen
- Executes well-defined implementation plans
- Manages worker coordination, resolves conflicts, enforces sequencing
- Use for: bug fixes spanning multiple files, focused refactors, test coverage campaigns

### Adaptive Queen
- Monitors execution and adjusts strategy mid-flight
- Detects drift (scope creep, off-target changes), re-routes workers
- Use for: performance optimization, audit remediation, exploratory debugging

## Worker Types (8 roles)

| Worker | Responsibility | Tools |
|--------|---------------|-------|
| **Researcher** | Read code, search patterns, gather context | Grep, Glob, Read |
| **Coder** | Write/edit production code | Edit, Write, Bash (build) |
| **Analyst** | Analyze architecture, identify risks, trace data flow | Read, Grep, Glob |
| **Tester** | Write tests, run test suites, verify fixes | Write, Bash (test) |
| **Architect** | Design interfaces, define contracts, plan structure | Read, Write |
| **Reviewer** | Code review, enforce standards, catch regressions | Read, Grep |
| **Optimizer** | Profile performance, reduce bundle size, optimize queries | Bash, Read, Edit |
| **Documenter** | Update docs, add comments, write migration guides | Write, Edit |

## Task Routing

Match task type to team composition. Queen auto-selects based on task description.

| Task Type | Team | Max Agents |
|-----------|------|------------|
| **Bug Fix** | Tactical Queen + Researcher + Coder + Tester | 4 |
| **Feature** | Strategic Queen + Architect + Coder + Tester + Reviewer | 5 |
| **Refactor** | Tactical Queen + Architect + Coder + Reviewer | 4 |
| **Performance** | Adaptive Queen + Optimizer + Coder | 3 |
| **Security** | Strategic Queen + Researcher + Reviewer | 3 |
| **Test Coverage** | Tactical Queen + Tester + Coder | 3 |

## Anti-Drift Rules

Drift = agents diverging from the task, introducing scope creep, or making unrelated changes.

1. **Hierarchical topology**: Workers report to queen only. No peer-to-peer task delegation.
2. **Max 5 agents**: Hard limit for 8GB RAM. Queen counts as one agent.
3. **Specialized roles**: Each worker does ONE thing. A Coder does not review. A Tester does not architect.
4. **Frequent checkpoints**: Queen reviews progress after every file change. Halt if off-track.
5. **Scope lock**: Define changed-file list upfront. Any file outside the list requires queen approval.
6. **No cascading fixes**: If a fix introduces a new issue, log it and continue. Do not chase side effects beyond the original scope.

## Consensus Protocol

For decisions requiring agreement (API design, naming, architecture choice):

### Simple Decisions (naming, formatting, minor refactors)
- Majority voting: each agent gets 1 vote
- Queen breaks ties

### Architecture Decisions (interfaces, data flow, schema changes)
- Weighted voting: Architect/Reviewer get 3x weight, others 1x
- Queen has veto power
- Decision logged with rationale

## Shared Memory

All agents in a swarm share context via:
- **Task brief**: Queen writes task description, acceptance criteria, file scope
- **Progress log**: Each worker appends completed actions
- **Decision log**: Architecture decisions with rationale
- **Blockers**: Any agent can flag a blocker for queen to resolve

Namespace: use a single scratchpad file per swarm session. Do not pollute project files.

## Token Optimization in Swarms

| Complexity | Strategy | Example |
|------------|----------|---------|
| Simple transform | Skip LLM, direct tool use | `var` to `const`, add type annotations, add error handling |
| Medium task | Use subagent (Haiku-tier) | Write a single test, add semantics labels, fix lint warning |
| Complex task | Use subagent (Opus-tier) | Design new service, refactor state management, debug race condition |

## origna_gta-Specific Adaptations

- **Flutter + Rust**: Swarms can span both stacks. Researcher reads Dart AND Rust. Coder edits both.
- **OrignaBase SDK**: Changes to Rust backend may require SDK regeneration. Queen must sequence: Rust change -> SDK update -> Flutter update.
- **8GB RAM**: Never run `flutter build` and `cargo build` simultaneously. Sequential only.
- **Test commands**: Flutter: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden`. Rust: `cargo clippy -D warnings && cargo test`.
- **Design tokens**: Coder must use `DesignTokens.*`, never raw colors. Reviewer enforces this.
- **Money**: Always integer cents. Reviewer checks for any `double` usage in money paths.
- **Riverpod**: No `setState()`. Reviewer checks for MVVM violations.

## Swarm Lifecycle

```
1. INIT      — Queen analyzes task, selects team, defines scope
2. RESEARCH  — Researcher gathers context, maps affected files
3. PLAN      — Architect (if present) designs solution, queen approves
4. EXECUTE   — Coder implements, Tester writes tests in parallel (if RAM allows, else sequential)
5. REVIEW    — Reviewer checks standards, queen checks scope adherence
6. VERIFY    — Tester runs full test suite, queen validates acceptance criteria
7. COMPLETE  — Queen summarizes changes, lists files modified
```

## Invoking a Swarm

Use `/swarm <task description>` or reference this skill directly. The queen will:
1. Classify the task type
2. Assemble the minimal team
3. Execute the lifecycle
4. Report results

## Failure Modes and Recovery

| Failure | Recovery |
|---------|----------|
| Agent produces off-scope change | Queen reverts, re-issues narrower instruction |
| Test suite fails after changes | Coder fixes; if > 2 attempts, queen escalates to human |
| RAM pressure (builds stalling) | Queen serializes all operations, reduces team to 3 agents |
| Consensus deadlock | Queen makes final decision, logs rationale |
