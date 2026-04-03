# Feature Spec: Backend-Live-First Remediation Wave

## Prompt
Execute the current runbook in `TODOS.md`: backend live first, then Flutter live, then E2E/design capture, then screenshot/name audit, then reliability/load/benchmarks. Keep `STATE.md` as the verified evidence ledger and do not skip blockers.

## User Stories
- As a maintainer, I want the active session to follow one critical path so effort is not diluted across stale priorities.
- As a backend owner, I want live backend failures fixed before frontend live or E2E work starts so downstream results are trustworthy.
- As a UI/design reviewer, I want screenshot filenames to match actual content so design audits are based on evidence instead of mislabeled artifacts.
- As a codebase owner, I want runtime magic strings, auth/payment/webhook drift, and unwired features audited only after core live validation is stable.
- As a reviewer, I want `STATE.md` and `.claude/harness/*` to reflect the current wave, not a previous one.

## Acceptance Criteria
- [ ] `.claude/harness/SPEC.md`, `.claude/harness/SPRINT.md`, and `.claude/harness/STATE.md` reflect the current backend-live-first wave
- [ ] Backend live wave continues from the current verified blocker: rerun `storage_integration_test` after the dev-only VPS rebuild and continue the Rust live queue in order
- [ ] `STATE.md` stays aligned with verified results from the backend live wave and any follow-up fixes
- [ ] Flutter live does not begin until backend live is stable enough to trust its results
- [ ] Screenshot/name audit remains blocked behind deterministic seed + manifest-driven capture, and that dependency is documented explicitly
- [ ] Magic-string work is tracked as a file-by-file runtime-contract audit, not a broad unbounded cleanup

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `.claude/harness/SPEC.md` | modify | Current planner spec for the active wave |
| `.claude/harness/SPRINT.md` | modify | Current sprint contract and verification order |
| `.claude/harness/STATE.md` | modify | Current round state, artifacts, blockers, and next queue |
| `STATE.md` | modify | Verified project-wide evidence ledger |
| `TODOS.md` | maintain | Execution runbook and ordering source of truth |
| Backend / Flutter / E2E files discovered during execution | maybe modify | Only as required by verified failures |

## Data Flow
- Runtime path: VPS image/build state -> live backend endpoints -> Rust live suites -> Flutter live suites -> E2E/browser capture -> screenshot audit
- Tracking path: verified result -> `.claude/harness/STATE.md` -> `STATE.md`
- Prioritization path: `TODOS.md` critical path -> harness sprint contract -> actual execution order

## Constraints
- 8GB local RAM: avoid overlapping heavy Flutter, Cargo, Playwright, and browser capture work
- Backend live validation has priority over Flutter live, E2E, screenshot audit, and reliability work
- No fake completion: blockers must be fixed or recorded with precise evidence
- Do not revert unrelated dirty worktree changes
- Avoid deleting good code; fix root causes instead

## Sprint Contract Proposal
### Round 1 Deliverables
- Refresh harness files to match the current runbook
- Finish the active dev-only VPS rebuild and verify the newest image is running
- Rerun `storage_integration_test` against the rebuilt dev image
- Continue the remaining backend live queue in order, fixing real failures as found
- Keep `STATE.md` synchronized with verified outcomes and blockers

### Round 1 Verification
- `docker compose ps` or equivalent VPS evidence confirms active env status
- `./scripts/run-live-tests.sh https://api.dev.orignagta.ca --file storage_integration_test`
- additional Rust live files run in order after storage passes or fails
- `STATE.md` and `.claude/harness/STATE.md` updated with only verified facts
