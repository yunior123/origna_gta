---
name: app-flow-manager
description: "Orchestrate multi-pass audits of OrignaGTA app flows. Runs design audit, CEO review, engineering review, security audit, and code review in sequence or parallel. Like gstack but for app-level quality gates. Use when asked to 'full audit', 'audit everything', 'run all reviews', 'ship readiness check', or similar."
---

# App Flow Manager — OrignaGTA

Multi-pass audit orchestrator. Runs the right skills in the right order to produce a complete ship-readiness assessment of any OrignaGTA flow or feature.

## When To Use

- Before shipping a feature to production
- After completing a major refactor
- When asked to "audit everything" or "full review"
- Pre-release quality gate
- Weekly engineering review

## Orchestration Modes

### Mode 1: Single Flow Audit
Audit one specific flow end-to-end:
```
/app-flow-manager checkout
/app-flow-manager auth
/app-flow-manager orders
```

### Mode 2: Full App Audit
Audit all critical flows:
```
/app-flow-manager all
```

### Mode 3: Ship Readiness
Quick check before deploying:
```
/app-flow-manager ship
```

---

## Audit Passes (5 Parallel Agents)

Each pass is an independent agent. Run all 5 in parallel for maximum speed.

### Pass 1: Design Audit
**Skill:** `design-review` (from gstack)
**Focus:** Visual consistency, UX, responsiveness
**Checks:**
- Visual hierarchy correct?
- Spacing consistent with DesignTokens?
- Responsive on mobile/tablet/desktop?
- Loading states present?
- Error states present?
- Empty states present?
- Animations smooth?
- Accessibility: Semantics labels on all interactive elements?
- No hardcoded colors (only DesignTokens.*)?

### Pass 2: CEO/Product Review
**Skill:** `plan-ceo-review` (from gstack)
**Focus:** Product-market fit, scope, user value
**Checks:**
- Does this solve the user's actual problem?
- Is scope correct? Too much? Too little?
- Are edge cases handled from user perspective?
- Is the UX intuitive without docs?
- Would a new user understand this flow?
- Are conversion funnels optimized? (checkout, signup)
- Is the feature differentiated from competitors?

### Pass 3: Engineering Review
**Skill:** `plan-eng-review` (from gstack)
**Focus:** Architecture, data flow, edge cases
**Checks:**
- MVVM compliance (no business logic in screens)?
- Data flow traceable (Screen → ViewModel → Repository → SDK → Server)?
- Error handling at every step?
- Race conditions identified and handled?
- State machine transitions enforced?
- Database queries parameterized (no format!())?
- Pagination implemented (no unbounded fetches)?
- Idempotency on critical operations?

### Pass 4: Security Audit
**Skill:** `security-review` or `flow-audit`
**Focus:** OWASP, auth, payment security
**Checks:**
- Broken Access Control (OWASP A01): IDOR, privilege escalation
- Injection (OWASP A03): SQL injection, XSS
- Authentication (OWASP A07): session fixation, MFA bypass
- SSRF (OWASP A10): image URL validation
- Mishandling Exceptional Conditions (OWASP A10 2025)
- Stripe security: webhook signature, idempotency, amount integrity
- No secrets in code
- Rate limiting on sensitive endpoints

### Pass 5: Code Quality Review
**Skill:** `flutter-code-review` + `code-review-multi`
**Focus:** Standards, performance, conventions
**Checks:**
- `flutter analyze` passes clean
- `flutter test` passes
- No `print()` — use AppLogger
- No hardcoded strings — use schema_constants
- No hardcoded colors — use DesignTokens
- `const` constructors everywhere
- Money in integer cents
- Riverpod patterns correct (ref.watch vs ref.read)
- Freezed models used for state
- Semantics labels present

---

## Execution Flow

### For Single Flow

```
1. Load skill: flow-audit
   → Read all files for the target flow
   → Trace data path

2. Run 5 passes in parallel:
   ├─ Pass 1: Design audit (screens + widgets)
   ├─ Pass 2: CEO review (product perspective)
   ├─ Pass 3: Eng review (architecture + data flow)
   ├─ Pass 4: Security audit (OWASP + Stripe)
   └─ Pass 5: Code quality (standards + tests)

3. Merge findings:
   → Deduplicate across passes
   → Boost severity if 2+ passes flag same issue
   → Prioritize by business impact

4. Produce report:
   → Per-pass findings
   → Combined severity counts
   → Top 5 priorities
   → Ship readiness verdict
```

### For Full App Audit (all)

```
1. List all 12 flows from flow-audit skill
2. For each flow, run the 5-pass audit
3. Between flows: clear context to stay fresh
4. Produce summary:
   → Per-flow health score (0-100)
   → Weakest flow identified
   → Critical findings across all flows
   → Recommended fix order
```

### For Ship Readiness

```
1. Run: flutter analyze --no-fatal-infos
2. Run: flutter test --exclude-tags golden
3. Run: flow-audit on the changed flows only
4. Run: security-review on the changed files only
5. Quick design check (screens changed?)
6. Produce verdict: SAFE / CHANGES REQUESTED / BLOCKED
```

---

## Report Format

```
═══════════════════════════════════════════════════════════════
APP FLOW AUDIT REPORT
═══════════════════════════════════════════════════════════════
Flow: [flow name]
Date: [ISO 8601]
Passes: 5 (Design, CEO, Engineering, Security, Code Quality)

───────────────────────────────────────────────────────────────
PASS 1 — DESIGN AUDIT                   Score: [0-10]
  [findings]

PASS 2 — CEO/PRODUCT REVIEW             Score: [0-10]
  [findings]

PASS 3 — ENGINEERING REVIEW             Score: [0-10]
  [findings]

PASS 4 — SECURITY AUDIT                 Score: [0-10]
  [findings]

PASS 5 — CODE QUALITY                   Score: [0-10]
  [findings]

───────────────────────────────────────────────────────────────
COMBINED SCORE: [average]/10

CROSS-PASS FINDINGS (flagged by 2+ passes):
1. [finding] — flagged by: Security + Engineering

TOP 5 PRIORITIES:
1. [CRITICAL] [pass] [file:line] Description
2. [HIGH] [pass] [file:line] Description
3. [HIGH] [pass] [file:line] Description
4. [MEDIUM] [pass] [file:line] Description
5. [MEDIUM] [pass] [file:line] Description

VERDICT: SHIP / CHANGES REQUESTED / BLOCKED
═══════════════════════════════════════════════════════════════
```

### Full App Summary (mode: all)

```
═══════════════════════════════════════════════════════════════
FULL APP AUDIT SUMMARY
═══════════════════════════════════════════════════════════════
Date: [ISO 8601]
Flows audited: 12

FLOW HEALTH SCORES:
  Auth & Account:         [score]/10
  Product Browsing:       [score]/10
  Search & Filtering:     [score]/10
  Shopping Cart:          [score]/10
  Checkout & Payment:     [score]/10
  Order Lifecycle:        [score]/10
  Returns & Refunds:      [score]/10
  Seller Onboarding:      [score]/10
  Seller Products:        [score]/10
  Seller Fulfillment:     [score]/10
  Notifications:          [score]/10
  Profile & Settings:     [score]/10

OVERALL HEALTH: [average]/10
WEAKEST FLOW: [name] — [why]
STRONGEST FLOW: [name] — [why]

CRITICAL FINDINGS: [count]
HIGH FINDINGS: [count]
MEDIUM FINDINGS: [count]
LOW FINDINGS: [count]

RECOMMENDED FIX ORDER:
1. [CRITICAL] [flow] → [finding]
2. [CRITICAL] [flow] → [finding]
3. [HIGH] [flow] → [finding]

SHIP READINESS: READY / NEEDS WORK / NOT READY
═══════════════════════════════════════════════════════════════
```

---

## Skill Dependencies

This skill orchestrates these other skills:

| Pass | Skill | Location |
|------|-------|----------|
| Design | `design-review` | `~/.claude/skills/gstack/design-review/` |
| CEO | `plan-ceo-review` | `~/.claude/skills/gstack/plan-ceo-review/` |
| Engineering | `plan-eng-review` | `~/.claude/skills/gstack/plan-eng-review/` |
| Security | `flow-audit` | `.claude/skills/flow-audit/` |
| Security | `stripe-audit` | `.claude/skills/stripe-audit/` |
| Code | `flutter-code-review` | `.claude/skills/flutter-code-review/` |
| Code | `code-review-multi` | `.claude/skills/code-review-multi/` |

If a skill is not available, skip that pass and note it in the report.

---

## Key Files Reference

| Purpose | Path |
|---------|------|
| Environment config | `lib/utils/env_config.dart` |
| Auth providers | `lib/core/providers.dart` |
| Design tokens | `lib/utils/design_tokens.dart` |
| Schema constants | `lib/core/schema/schema_constants.dart` |
| Quality gate | `scripts/run_quality_gate.sh` |
