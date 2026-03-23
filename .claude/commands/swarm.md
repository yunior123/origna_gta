# /swarm — Coordinated Agent Swarm

**Usage**: `/swarm $ARGUMENTS`

Assemble a coordinated agent swarm for the given task. Load the **swarm-orchestration** skill, then:

1. Classify the task type: Bug Fix, Feature, Refactor, Performance, Security, or Test Coverage
2. Select the queen type (Strategic, Tactical, or Adaptive)
3. Assemble the worker team (max 5 agents total for 8GB RAM)
4. Execute the full swarm lifecycle: INIT → RESEARCH → PLAN → EXECUTE → REVIEW → VERIFY → COMPLETE

## Task Routing
| Type | Queen | Workers |
|------|-------|---------|
| Bug Fix | Tactical | Researcher + Coder + Tester |
| Feature | Strategic | Architect + Coder + Tester + Reviewer |
| Refactor | Tactical | Architect + Coder + Reviewer |
| Performance | Adaptive | Optimizer + Coder |
| Security | Strategic | Researcher + Reviewer |
| Test Coverage | Tactical | Tester + Coder |

## Anti-Drift
- Scope-lock file list before execution
- Checkpoint after every file change
- No cascading fixes — log new issues, stay on target

## origna_gta Stack
- Flutter: `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden`
- Rust: `cargo clippy -D warnings && cargo test`
- Sequential builds only (8GB RAM)
