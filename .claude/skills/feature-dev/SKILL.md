---
name: feature-dev
description: "7-phase structured feature development: requirements, exploration, architecture, implementation, testing, review, documentation. Use when building new features or significant functionality."
---

# Feature Development

Structured 7-phase workflow for building features properly. Ensures nothing is missed.

## When to Use

- Building a new feature end-to-end
- Adding significant functionality to existing code
- Any change touching 3+ files across multiple layers

## The 7 Phases

### Phase 1: Requirements Gathering

Before touching code:
- What is the user story? "As a [role], I want [action], so that [benefit]"
- What are the acceptance criteria?
- What are the constraints? (8GB RAM, main-only, integer cents for money)
- Are there edge cases to handle?
- What existing code/patterns should be reused?

**Output**: Clear requirements with acceptance criteria.

### Phase 2: Codebase Exploration

Use Explore agents to understand:
- Existing patterns in the area being modified
- Related code that might be affected
- Existing tests to extend
- DesignTokens, schema_constants, and other shared resources

**Output**: List of files to modify, patterns to follow, reusable code found.

### Phase 3: Architecture Design

Design the implementation:
- Which layers need changes? (Screen → ViewModel → Service → SDK)
- Data flow: how does data move through the system?
- State management: which providers/notifiers?
- API changes needed in OrignaBase?
- Database schema changes?

**Output**: Architecture decision with file list and data flow.

### Phase 4: Implementation (TDD)

Follow TDD workflow:
1. Write tests first (invoke tdd-workflow skill)
2. Implement minimal code to pass
3. Refactor while green
4. Follow coding-standards skill rules

**Rules**:
- MVVM: business logic in ViewModels/Services, NOT in widgets
- Riverpod for state, `AsyncNotifier` for async
- `DesignTokens.*` for all colors
- `schema_constants.dart` for all field names
- Money in integer cents
- `Semantics(label: 'btn-*')` on interactive elements

### Phase 5: Testing

Verify comprehensively:
- Unit tests for ViewModels and Services (≥80% coverage)
- Widget smoke tests for new screens
- Integration with existing test suite
- `flutter analyze --no-fatal-infos`
- `flutter test --exclude-tags golden`
- If Rust changed: `cargo clippy -D warnings && cargo test`

### Phase 6: Review

Run review checks:
- Invoke flutter-code-review skill for Dart changes
- Invoke security-review skill if auth/payment touched
- Check for anti-patterns from quality-gates rule
- Run santa-method for fun Naughty/Nice review

### Phase 7: Documentation

Update as needed:
- Add Semantics labels for Playwright E2E
- Update STATE.md with decisions made
- Add to MEMORY.md if significant patterns discovered
- No separate documentation files unless explicitly requested

## Complexity-Based Routing

Auto-detect scope and skip unnecessary phases:

| Scope | Files | Path |
|-------|-------|------|
| **Large** (6+ files) | Full 7-phase workflow | All phases |
| **Medium** (3-5 files) | Skip Phase 1 PRD, go to Phase 2-7 | Explore → Design → TDD → Review |
| **Small** (1-2 files) | Direct TDD | Phase 4-6 only |

## Additional Recipes

### Diagnose (bug investigation)
1. Collect evidence (logs, errors, git blame)
2. Build hypothesis matrix (what could cause this?)
3. Test hypotheses systematically (most likely first)
4. If complex: use ACH (Analysis of Competing Hypotheses)
5. Fix → verify → regression test

### Reverse Engineer (generate docs from code)
1. Trace execution paths from entry points
2. Map architecture layers and data flow
3. Generate PRD from observed behavior
4. Generate Design Doc from code structure
5. Identify undocumented edge cases

## Phase Checklist

```
- [ ] Phase 1: Requirements clear, acceptance criteria defined
- [ ] Phase 2: Codebase explored, patterns identified
- [ ] Phase 3: Architecture designed, files listed
- [ ] Phase 4: Tests written first, implementation complete
- [ ] Phase 5: All tests pass, analysis clean
- [ ] Phase 6: Code reviewed, no anti-patterns
- [ ] Phase 7: Documentation updated
```
