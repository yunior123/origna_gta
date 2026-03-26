---
name: harness-loop
description: "GAN-inspired Planner->Generator->Evaluator loop for high-quality feature development. Separates generation from evaluation using file-based handoff. Use for features where quality matters more than speed."
---

# Harness Loop

Multi-agent development loop inspired by [Anthropic's harness design research](https://www.anthropic.com/engineering/harness-design-long-running-apps). Separates generation from evaluation to overcome self-evaluation bias and produce higher-quality outputs.

## When to Use

- Feature development where quality matters (UI, checkout, payments)
- Tasks where self-evaluation has failed before (Codex agents saying "DONE" when work is incomplete)
- UI/design work requiring subjective quality grading
- Multi-file changes that need holistic verification
- NOT for: single-file fixes, trivial changes, test-only work

## Architecture

```
User prompt (1-4 sentences)
        |
   [PLANNER] ── writes ── .claude/harness/SPEC.md
        |
   [GENERATOR] ── reads SPEC.md + EVAL.md feedback
        |          writes code + .claude/harness/STATE.md
        |          proposes .claude/harness/SPRINT.md
        |
   [EVALUATOR] ── reads SPEC.md + STATE.md
        |          runs quality gates + live testing
        |          writes .claude/harness/EVAL.md
        |
   if avg_grade < 8 AND round < max_rounds:
        └── back to GENERATOR with EVAL.md feedback
   else:
        └── DONE
```

## Handoff Directory

Created fresh at the start of each harness run:

```
.claude/harness/
  SPEC.md       -- Planner output: user stories, acceptance criteria, file list
  SPRINT.md     -- Sprint contract: what Generator will build, how to verify
  STATE.md      -- Cross-round state: what changed, what's left
  EVAL.md       -- Evaluator grades + specific improvement feedback
```

## Phase 1: Planner (main context)

The Planner runs in the main conversation context (no subagent). It transforms the user's brief prompt into a structured spec.

### Instructions

1. Create `.claude/harness/` directory
2. Explore the codebase to understand relevant patterns, existing code, and constraints
   - Reuse `feature-dev` Phase 1-2 pattern: identify affected layers, existing utilities, test patterns
3. Write `.claude/harness/SPEC.md` with these sections:

```markdown
# Feature Spec: [name]

## Prompt
[Original user prompt]

## User Stories
- As a [role], I want [capability] so that [benefit]

## Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Each must be independently verifiable]

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| path | create/modify | what and why |

## Data Flow
[How data moves through the system: UI -> ViewModel -> Service -> OrignaBase]

## Constraints
- [RAM, existing patterns, DesignTokens, schema_constants]
- [Money in integer cents, no setState, no magic strings]

## Sprint Contract Proposal
### Round 1 Deliverables
- [What will be built]
- [How success will be verified]
```

4. Review the spec for scope — be ambitious but realistic for 1-3 rounds

## Phase 2: Generator (subagent)

The Generator is a **separate subagent** with write access. It implements features based on the spec and evaluator feedback.

### Instructions

1. Read `.claude/harness/SPEC.md`
2. If round > 1: read `.claude/harness/EVAL.md` for previous feedback — address every item scored < 8
3. Write sprint contract to `.claude/harness/SPRINT.md`:

```markdown
# Sprint Contract — Round [N]

## Deliverables
- [ ] [Specific thing to build/fix]

## Verification Criteria
- [ ] [How evaluator should test this]

## Files to Touch
- [explicit list — scope lock]
```

4. Implement using ralph-loop pattern:
   - For each deliverable: implement -> `flutter analyze` -> `flutter test` -> next
   - If Rust changed: `cargo clippy -D warnings && cargo test`
   - Can delegate bulk work: `delegate codex "specific task"`
5. Write changes summary to `.claude/harness/STATE.md`:

```markdown
# State — Round [N]

## Changes Made
- [file]: [what changed and why]

## Tests Added/Modified
- [test file]: [what it covers]

## Known Issues
- [anything unfinished or concerning]

## Git
- [commit hash]: [message]
```

### Generator Rules
- Never skip `flutter analyze` between changes
- Never report "done" without running tests
- Follow all project rules: DesignTokens, schema_constants, MVVM, Riverpod, integer cents
- If blocked: write blocker to STATE.md and stop — don't hack around it

## Phase 3: Evaluator (separate subagent)

The Evaluator is a **separate subagent** — never the same agent that wrote the code. This is the key insight: external evaluation > self-evaluation.

### Instructions

1. Read `.claude/harness/SPEC.md` (acceptance criteria) and `.claude/harness/STATE.md` (what changed)
2. Run quality gates:

```bash
cd origna_gta/origna_gta && flutter analyze --no-fatal-infos
cd origna_gta/origna_gta && flutter test --exclude-tags golden
# If Rust changed:
cd orignabase && cargo clippy -D warnings && cargo test
```

3. If the app is running, use Flutter Pilot MCP for live testing:
   - `flutter_connect` to running app
   - Navigate to affected screens
   - `flutter_screenshot` each screen
   - `flutter_tap`, `flutter_scroll` to test interactions
   - Verify acceptance criteria from SPEC.md

4. Grade on 5 criteria (1-10 scale):

| Criterion | What to Check | Weight |
|-----------|---------------|--------|
| **Functionality** | Acceptance criteria met? Features work end-to-end? | 30% |
| **DesignTokens Compliance** | No hardcoded colors, spacing, strings? Uses DesignTokens, schema_constants, AppRoutes? | 20% |
| **Visual Coherence** | Consistent with existing app style? Dark theme contrast >= 4.5:1? | 15% |
| **Code Quality** | MVVM separation? Riverpod (no setState)? No BuildContext in VMs? AppLogger not print()? | 20% |
| **Test Coverage** | New code has unit/widget tests? ViewModels >= 80%? | 15% |

5. Write evaluation to `.claude/harness/EVAL.md`:

```markdown
# Evaluation — Round [N]

## Quality Gates
- flutter analyze: PASS/FAIL
- flutter test: PASS/FAIL ([X] pass, [Y] fail)
- cargo test: PASS/FAIL/N/A

## Grades
| Criterion | Score | Notes |
|-----------|-------|-------|
| Functionality | X/10 | [specific findings] |
| DesignTokens | X/10 | [specific findings] |
| Visual Coherence | X/10 | [specific findings] |
| Code Quality | X/10 | [specific findings] |
| Test Coverage | X/10 | [specific findings] |
| **Weighted Average** | **X/10** | |

## Verdict
PASS (avg >= 8) / ITERATE (avg < 8) / FAIL (quality gates failed)

## Improvements for Next Round
[Only if ITERATE — specific, actionable items]
1. [File:line] — [what to fix and why]
2. [File:line] — [what to fix and why]
```

### Evaluator Rules
- Be skeptical — do NOT rationalize issues as "minor" or "acceptable"
- Every acceptance criterion must be individually verified
- If a feature is stubbed/placeholder, score Functionality as <= 5
- If hardcoded colors/strings found, score DesignTokens as <= 5
- Screenshots are evidence — take them before scoring Visual Coherence
- Grade what IS, not what was intended

## Loop Control

```
max_rounds = 3 (configurable)

for round in 1..=max_rounds:
  if round == 1:
    run PLANNER (main context)

  run GENERATOR (subagent — reads SPEC + previous EVAL)
  run EVALUATOR (separate subagent — reads SPEC + STATE)

  if evaluator weighted_average >= 8:
    STOP — quality target met

  if round == max_rounds:
    STOP — report final state, let user decide next steps
```

### Early Stop Conditions
- All 5 grades >= 8 → quality target met
- Quality gates fail 2 rounds in a row → structural issue, ask user
- Generator reports blocker in STATE.md → escalate to user

### RAM Budget (8GB constraint)
- Generator and Evaluator NEVER run concurrently
- Max agents at any time: 2 (main + 1 subagent)
- Sequential: Plan → Generate → Evaluate → Generate → Evaluate → ...
- Kill zombie flutter_test processes between rounds

## Composing Existing Infrastructure

This skill composes existing patterns — it does NOT duplicate them:

| Need | Reuses |
|------|--------|
| Codebase exploration | `feature-dev` Phase 1-2 pattern |
| Task-by-task implementation | `ralph-loop` iteration pattern |
| Bulk delegation | `delegate codex/gemini` commands |
| Auto-validation | PostToolUse hooks (7 validators already active) |
| Design grading criteria | `uiux-expert` agent checklist |
| Anti-drift rules | `swarm-orchestration` scope lock + hierarchical reporting |
| Code review | `code-review-multi` confidence scoring |

## Example Usage

```
User: /harness-loop "add wishlist feature with heart icon toggle on product cards"

→ Planner: explores existing product card code, DesignTokens, schema
→ SPEC.md: 4 user stories, 8 acceptance criteria, 6 files to modify
→ Generator Round 1: implements wishlist provider, UI toggle, tests
→ Evaluator Round 1: Functionality 7, DesignTokens 9, Visual 6, Code 8, Tests 7 → avg 7.4 → ITERATE
→ Generator Round 2: fixes visual coherence (heart animation), adds missing tests
→ Evaluator Round 2: Functionality 9, DesignTokens 9, Visual 8, Code 9, Tests 8 → avg 8.6 → PASS
→ Done in 2 rounds
```

## Progressive Simplification

Per the Anthropic blog: "Every component encodes a model limitation assumption worth stress-testing."

- Opus 4.6 handles long sessions without context anxiety → no sprint decomposition needed
- If evaluator consistently passes Round 1 → consider removing the loop for that task type
- If quality gates catch everything → evaluator design grading may be optional
- Re-evaluate harness complexity with each model upgrade
