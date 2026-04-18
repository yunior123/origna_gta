# Sprint Contract — Round 1

## Deliverables
- [ ] Let the active seeded `e2e/run-tests.sh all` rerun continue until it finishes or surfaces the next concrete failing file.
- [ ] Capture the authoritative aggregate result from `/tmp/origna_e2e_run_all_after_deep_fix.log`.
- [ ] If a new failure appears, patch only that failing slice and verify it with a focused rerun.
- [ ] If the wrapper completes green, update `STATE.md`, `TODOS.md`, and `.claude/harness/STATE.md` with the final evidence and next gate.

## Verification Criteria
- [ ] `/tmp/origna_e2e_run_all_after_deep_fix.log` contains either the final wrapper summary or a concrete failing spec trace.
- [ ] Any new patch is followed by `cd e2e && bun x tsc --noEmit`.
- [ ] Any new failing spec/helper fix is followed by a focused `bun test ... --timeout 120000`.
- [ ] Ledger docs are updated only after command evidence exists.

## Files to Touch
- `.claude/harness/SPEC.md`
- `.claude/harness/SPRINT.md`
- `.claude/harness/STATE.md`
- `STATE.md`
- `TODOS.md`
- `e2e/lib/auth.ts` if a new auth/bootstrap defect appears
- `e2e/lib/agent-browser.ts` if a new browser-state defect appears
- the next concretely failing `e2e/specs/**` file only if needed
