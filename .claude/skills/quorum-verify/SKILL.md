---
name: quorum-verify
description: "3-agent quorum verification for bug reports. Launches 3 independent agents to verify the same finding. Majority vote (2/3+) determines CONFIRMED or FALSE POSITIVE. Includes confidence scoring (HIGH/MEDIUM/LOW weighted by evidence quality). Eliminates false positives before wasting fix effort. Use when asked to 'verify this bug', 'check if real', 'quorum verify', 'agent consensus', '3-agent verify', or before applying fixes from audits."
---

# Quorum Verify — 3-Agent Consensus Verification

Launches 3 independent agents to verify a single finding. Majority vote determines the verdict. Confidence scoring weights votes by evidence quality. Designed to eliminate false positives from audit findings before applying fixes.

## When To Use

- After an audit produces findings — verify before fixing
- When a bug report seems suspicious
- Before applying changes to production code
- When you want confidence scoring on a finding
- After an initial agent claims a bug that seems too obvious

## How It Works

```
Finding → Agent A → verdict + confidence
         Agent B → verdict + confidence    → Quorum + Confidence → DECISION
         Agent C → verdict + confidence

Quorum rules (majority wins):
  3/3 CONFIRMED     → CONFIRMED (HIGH confidence)
  2/3 CONFIRMED     → CONFIRMED (MEDIUM confidence)
  1/2 split          → INCONCLUSIVE (escalate to human)
  2/3 FALSE POSITIVE → FALSE POSITIVE (MEDIUM confidence)
  3/3 FALSE POSITIVE → FALSE POSITIVE (HIGH confidence)
```

## Confidence Scoring

Each agent assigns confidence based on evidence quality:

| Confidence | Criteria |
|-----------|----------|
| **HIGH** | Read the exact code, found the exact line, can point to the specific query/statement |
| **MEDIUM** | Found the relevant code but couldn't trace the full execution path |
| **LOW** | Inferred from patterns/comments, didn't read the exact implementation |

**Final confidence** = weighted average:
- If 3/3 CONFIRMED with HIGH → CONFIRMED, HIGH
- If 2/3 CONFIRMED (1 HIGH + 1 MEDIUM) → CONFIRMED, MEDIUM
- If 2/3 CONFIRMED (both LOW) → CONFIRMED, LOW (may need re-verification)

## Execution

### Step 1: Prepare the Finding

Format the finding for verification:

```
CLAIM: [one-line description of the bug]
FILES: [list of files to read]
PROOF NEEDED: [what specifically to check]
```

### Step 2: Launch 3 Agents in Parallel

Each agent independently:
1. Reads the relevant code
2. Determines CONFIRMED or FALSE POSITIVE
3. Assigns confidence (HIGH/MEDIUM/LOW)
4. Provides evidence (line numbers, code snippets)
5. No agent sees other agents' work

### Step 3: Tally Votes + Confidence

```
Agent A: CONFIRMED     — HIGH — "stock decremented at line 761, no WHERE guard"
Agent B: FALSE POSITIVE — HIGH — "IF/THEN guard at line 762 prevents negative stock"
Agent C: CONFIRMED     — MEDIUM — "pre-check outside transaction is TOCTOU"

Vote: 2/3 CONFIRMED → CONFIRMED
BUT: 1 HIGH-confidence FALSE POSITIVE agent found specific evidence
Action: Fix the Transaction to use BEGIN/COMMIT for safety
```

### Step 4: Apply Fix Only if CONFIRMED

- If 2+/3 CONFIRMED → apply the fix
- If 3/3 FALSE POSITIVE → mark as verified, no action
- If 1/1 split (1 agent failed) → escalate to human review

## Agent Prompt Template

Each agent receives the SAME prompt:

```
You are an independent verification agent. Your ONLY job is to verify
whether a claimed bug exists in the code. Do NOT fix anything. Do NOT
read other agents' work.

CLAIM: {claim}

Read these files:
{file_list}

Check for:
{specific_checks}

Return EXACTLY:
VERDICT: CONFIRMED or FALSE POSITIVE
CONFIDENCE: HIGH or MEDIUM or LOW
EVIDENCE: [line numbers and code snippets that prove your verdict]
REASONING: [why you believe this is confirmed or false positive]
```

## Report Format

```
═══════════════════════════════════════════════
QUORUM VERIFY REPORT (3-AGENT)
═══════════════════════════════════════════════
Finding: [claim]
Files checked: [list]

Agent A: [CONFIRMED/FALSE POSITIVE] — [HIGH/MEDIUM/LOW] — [1-line reason]
Agent B: [CONFIRMED/FALSE POSITIVE] — [HIGH/MEDIUM/LOW] — [1-line reason]
Agent C: [CONFIRMED/FALSE POSITIVE] — [HIGH/MEDIUM/LOW] — [1-line reason]

QUORUM: [N/3 CONFIRMED]
VERDICT: [CONFIRMED / FALSE POSITIVE / INCONCLUSIVE]
CONFIDENCE: [HIGH / MEDIUM / LOW]

IF CONFIRMED:
  Fix applied: [yes/no]
  Files changed: [list]

IF FALSE POSITIVE:
  Why it appeared as a bug: [explanation]
  Marked as: VERIFIED CLEAN

IF INCONCLUSIVE:
  Reason: [why agents couldn't agree]
  Escalated to: human review
═══════════════════════════════════════════════
```

## Batch Verification

For multiple findings, run them in batches:

```
Batch 1: Findings 1-5 (5 findings × 3 agents = 15 agents)
Batch 2: Findings 6-10
...
```

Between batches, update STATE.md with results.

## Integration with STATE.md

After each quorum verification, update the finding in STATE.md:

```markdown
- [x] Finding N: [description] ✅ VERIFIED CLEAN (3/3 FALSE POSITIVE, HIGH confidence)
- [x] Finding N: [description] ✅ FIXED (3/3 CONFIRMED, HIGH confidence) — commit abc123
- [x] Finding N: [description] ✅ FIXED (2/3 CONFIRMED, MEDIUM confidence) — commit def456
- [ ] Finding N: [description] ⚠️ INCONCLUSIVE (1/1 split) — needs human review
```

## Key Files Reference

| Purpose | Path |
|---------|------|
| Audit findings | `STATE.md` |
| Quality gate | `scripts/run_quality_gate.sh` |
