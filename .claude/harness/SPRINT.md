# Sprint Contract — Round 1

## Deliverables
- [ ] Align harness files with the current backend-live-first runbook
- [ ] Verify the active dev-only VPS rebuild status
- [ ] Re-run `storage_integration_test` against the rebuilt dev image
- [ ] Continue the backend live queue in order after storage
- [ ] Record every verified result or blocker in `.claude/harness/STATE.md` and `STATE.md`

## Verification Criteria
- [ ] Harness files no longer describe the stale March design-audit round
- [ ] VPS runtime state is summarized with concrete evidence
- [ ] `storage_integration_test` is rerun on the rebuilt dev image
- [ ] The next backend live file after storage is selected and executed unless storage still blocks
- [ ] `STATE.md` and harness state reflect the new evidence immediately

## Files to Touch
- `.claude/harness/SPEC.md`
- `.claude/harness/SPRINT.md`
- `.claude/harness/STATE.md`
- `STATE.md`
- additional backend files only if the rerun exposes a real defect
