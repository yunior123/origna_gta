# Harness Swarm QA Engineers

Spawns a swarm of AI QA engineers (mimo, codex, gemini, subagents) that continuously audit, test, fix, and document the codebase using the harness loop pattern. Never stops — when one task completes, the next launches immediately.

## When to Use
- Pre-release quality gates
- Continuous background QA during development
- After major refactors or feature additions
- When the user says "audit everything" or "keep working"

## Architecture

```
ORCHESTRATOR (Claude — main context)
    |
    ├── MIMO SWARM (3-5 parallel via opencode/OpenRouter)
    |   ├── QA Engineer 1: Flutter code audit (real evidence, no false positives)
    |   ├── QA Engineer 2: Documentation (/// doc comments)
    |   ├── QA Engineer 3: Widget test creation
    |   ├── QA Engineer 4: Web research (CVEs, best practices)
    |   └── QA Engineer 5: Responsive/theme/a11y audit
    |
    ├── CODEX (1-3 parallel, gpt-5.4 FULL only)
    |   ├── Senior QA: E2E test execution + fix
    |   ├── Senior QA: Rust backend tests + coverage push
    |   └── Senior QA: Load/stress testing + deploy
    |
    ├── GEMINI (1 instance, gemini-3-pro-preview)
    |   └── Architect QA: Cross-stack audit, schema consistency
    |
    └── SLEEP MONITOR (continuous loop)
        └── Every 5 min: check all workers, launch replacements, collect findings
```

## Execution Flow

### Phase 1: Launch Swarm
```bash
# Mimo workers (free via OpenRouter)
/opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free "TASK" > /tmp/mimo-qa-{N}.log 2>&1 &

# Codex workers (gpt-5.4 only)
codex exec -m gpt-5.4 -s danger-full-access "TASK" > /tmp/codex-qa-{N}.log 2>&1 &

# Gemini (if available)
gemini -m gemini-3-pro-preview -y -p "TASK" > /tmp/gemini-qa.log 2>&1 &
```

### Phase 2: Sleep Monitor Loop
```
while true:
  sleep 300  # 5 minutes
  for each worker:
    if worker.done:
      collect_findings(worker.output)
      add_to_STATE_md(findings)
      launch_next_task(worker.type)
    else:
      log_progress(worker)
```

### Phase 3: Harness Evaluation
After each batch completes:
1. Run flutter analyze — must be zero issues
2. Run flutter test — must all pass
3. Run cargo clippy + cargo test — must pass
4. If any break: revert and fix before next batch

## QA Task Queue (rotate through these)

### Code Quality
- [ ] Audit ALL Riverpod providers (circular deps, missing dispose, leaked listeners)
- [ ] Audit ALL Freezed models (missing fields, wrong types)
- [ ] Audit ALL GoRouter routes (unprotected admin, missing redirects)
- [ ] Audit ALL form validations (client matches server)
- [ ] Audit ALL async code (unawaited futures, missing cancellation)
- [ ] Audit ALL money calculations (cents only, no doubles)

### Security
- [ ] Search web for latest ecommerce CVEs — check if we're affected
- [ ] Audit auth flow (JWT lifecycle, token refresh, MFA)
- [ ] Audit Stripe webhooks (HMAC, idempotency, replay protection)
- [ ] Audit input validation (XSS, SQL injection, IDOR)
- [ ] Audit CORS, rate limiting, CSP headers

### Testing
- [ ] Create widget tests for uncovered screens
- [ ] Create integration tests for uncovered Rust modules
- [ ] Create E2E tests for uncovered user flows
- [ ] Run load tests (k6) against dev API
- [ ] Run stress tests (concurrent checkouts)

### Documentation
- [ ] Add /// doc comments to all public APIs
- [ ] Document complex data flows
- [ ] Document environment configuration
- [ ] Document error handling patterns

### Design
- [ ] Audit responsive layouts (mobile/tablet/desktop)
- [ ] Audit dark theme (DesignTokens only, contrast >= 4.5:1)
- [ ] Audit Semantics labels (all interactive elements)
- [ ] Capture screenshots of all screens/states/variants
- [ ] Compare UX against Amazon/Shopify/Etsy

## Rules
- **NO FALSE POSITIVES**: Every finding must include file:line + code snippet as evidence
- **NO SKIPPING**: Fix root causes, not workarounds
- **PIPE ALL RESULTS**: to /tmp/ files — never lose output
- **KILL ZOMBIES**: between test phases (flutter_test, dart, chrome)
- **8GB RAM**: max 5 workers total, sequential builds
- **VERIFY AFTER EACH BATCH**: flutter analyze + flutter test must pass
- **DELEGATE AGGRESSIVELY**: mimo for bulk work, codex for complex tasks
- **CONTINUOUS**: when a worker finishes, launch the next task immediately

## Findings Format
All findings go to STATE.md:
```
| Sev | File:Line | Issue | Evidence | Status |
|-----|-----------|-------|----------|--------|
| P0  | checkout.rs:686 | Double payout | transfer_data + cron transfer | FIXED |
```

## Integration
- Composes with: harness-loop, code-review, pentest-swarm, flow-audit
- Uses: sleep monitor technique, delegation (mimo/codex/gemini)
- Outputs: STATE.md findings, /tmp/ result files, fixed code
