# Security Infrastructure Audit

## Trigger
Use when asked to 'audit security infra', 'check latest threats', 'security news audit', 'real-world vulnerability check', or before any release/deploy.

## What It Does
1. Searches latest security news for attack patterns affecting our stack (e-commerce, Rust, Flutter, SurrealDB, Stripe, Cloudflare, axum)
2. Cross-references real-world incidents against our codebase
3. Reports ONLY critical issues with evidence — zero false positives
4. Uses quorum verification (3-agent consensus) for any P0/P1 finding

## Execution

### Phase 1: Threat Intelligence Gathering (WebSearch)
```
Search queries (run all):
- "e-commerce vulnerability 2026" site:bleepingcomputer.com OR site:thehackernews.com
- "Rust axum security vulnerability" -tutorial
- "SurrealDB CVE" OR "SurrealDB security"
- "Stripe payment bypass 2026"
- "Flutter web vulnerability XSS"
- "supply chain attack npm bun cargo 2026"
- "bot attack e-commerce 2026" credential stuffing
```

### Phase 2: Codebase Cross-Reference (Grep/Read)
For each threat found, check if origna_gta is vulnerable:

```bash
# Dependency audit
cd orignabase && cargo audit 2>&1
cd origna_gta && flutter pub audit 2>&1

# Check for known vulnerable patterns — unsafe code, raw HTML injection, eval
grep -rn "unsafe\|transmute" orignabase/crates/ --include="*.rs" | grep -v test | grep -v "// safe:"

# Check rate limiting coverage
grep -rn "rate_limit\|governor\|throttle" orignabase/crates/ --include="*.rs" | wc -l

# Check for hardcoded secrets
grep -rn "sk_live\|sk_test" orignabase/ --include="*.rs" | grep -v test | grep -v "example\|placeholder\|CHANGE_ME"
```

### Phase 3: Quorum Verification (for any P0/P1 finding)
Launch 3 independent verification agents:
- Agent 1: Reproduce the vulnerability path
- Agent 2: Check if existing mitigations apply
- Agent 3: Verify the fix would work

Only report findings where 2/3+ agents agree it's real.

### Phase 4: Report
Output format:
```markdown
## Security Infrastructure Audit — [DATE]

### Threat Landscape
- [N] new CVEs checked
- [N] real-world incidents reviewed
- [N] applicable to our stack

### Findings
#### [SEVERITY] [TITLE]
- **Source:** [URL of threat report]
- **Our exposure:** [how it applies to origna_gta]
- **Evidence:** [grep/code showing vulnerability]
- **Fix:** [specific remediation]
- **Quorum:** [3/3 CONFIRMED | 2/3 CONFIRMED | REJECTED]

### Dependencies
- cargo audit: [PASS/FAIL]
- flutter pub audit: [PASS/FAIL]
- [N] outdated packages

### Recommendations
- [Prioritized action items]
```

## Anti-False-Positive Rules
- Every finding MUST have a reproducible code path
- "Theoretical" risks without code evidence = NOT reported
- If a mitigation exists (rate limiting, input validation, auth check), verify it works before reporting
- Test code vulnerabilities are NOT reported (test files excluded)
- Known accepted risks documented in STATE.md are NOT re-reported
