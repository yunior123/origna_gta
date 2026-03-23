---
name: code-review-multi
description: "Multi-agent code review with 4 parallel reviewers, confidence scoring, and prioritized findings. Use before commits, PRs, or releases for thorough review."
---

# Multi-Agent Code Review

4 independent review agents analyze code changes in parallel, each from a different angle. Findings are scored by confidence and prioritized.

## When to Use

- Before committing significant changes
- Before creating PRs
- After completing a feature
- Pre-release quality gate

## Instructions

### Step 1: Identify Changes

```bash
git diff --stat
git diff HEAD
```

If no staged changes, review the last commit: `git diff HEAD~1`.

### Step 2: Dispatch 4 Reviewers in Parallel

Spawn 4 agents simultaneously, each with a different focus:

**Reviewer 1 — Correctness & Logic**
- Does the code do what it claims?
- Are there logic errors, off-by-one, null safety gaps?
- Are edge cases handled?
- Are state transitions valid?

**Reviewer 2 — Security & Safety**
- Input validation present?
- No hardcoded secrets?
- No SQL/SurrealQL injection risks?
- Authentication/authorization correct?
- No PII logging?

**Reviewer 3 — Performance & Efficiency**
- Unnecessary rebuilds (missing `select()`, missing `const`)?
- N+1 queries?
- Large lists without `ListView.builder`?
- Missing `CachedNetworkImage`?
- Unbounded fetches without pagination?

**Reviewer 4 — Standards & Conventions**
- MVVM compliance (no business logic in widgets)?
- `DesignTokens` used (no hardcoded colors)?
- `schema_constants` used (no magic strings)?
- Money in integer cents?
- Semantics labels on interactive elements?
- `AppLogger` used (no `print()`)?

### Step 3: Confidence Scoring

Each finding gets a confidence score:

| Score | Meaning | Action |
|-------|---------|--------|
| **9-10** | Definite bug or violation | Must fix before commit |
| **7-8** | Very likely issue | Should fix |
| **5-6** | Possible issue, needs context | Review and decide |
| **3-4** | Style preference or minor | Optional improvement |
| **1-2** | Nitpick | Ignore unless trivial to fix |

### Step 4: Synthesize Report

```
CODE REVIEW REPORT
===================
Files reviewed: X
Reviewers: 4 (Correctness, Security, Performance, Standards)

CRITICAL (confidence ≥9):
- [file:line] Description — Reviewer: X

HIGH (confidence 7-8):
- [file:line] Description — Reviewer: X

MEDIUM (confidence 5-6):
- [file:line] Description — Reviewer: X

LOW (confidence ≤4):
- [count] minor findings (details available on request)

VERDICT: APPROVE / CHANGES REQUESTED / BLOCK
```

### Step 5: Auto-Fix

For findings with confidence ≥7 and clear fixes:
- Apply the fix
- Re-run analysis and tests
- Show diff of auto-fixes

## Rules

- Max 4 agents (8GB RAM — each gets focused scope)
- Confidence ≥9 findings block the commit
- Don't flag style issues that linters/formatters handle
- Cross-reference: if 2+ reviewers flag the same issue, boost confidence
- Skip reviewing generated files (`.g.dart`, `.freezed.dart`)
