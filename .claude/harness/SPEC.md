# Feature Spec: TODOS Active Gate Harness

## Prompt
Use the harness loop on `TODOS.md` and keep the work aligned to the current verified gate instead of bouncing across the full parking lot. Finish the active long-running E2E wave, record authoritative evidence, and only then advance to the next gated block.

## User Stories
- As a maintainer, I want `TODOS.md` executed in order so that backend, Flutter live, and E2E validation do not drift out of sequence.
- As a buyer/seller/admin test persona, I want the full seeded E2E wrapper to complete without hidden auth/bootstrap regressions so that the cross-suite state is trustworthy.
- As an operator, I want `STATE.md` and `.claude/harness/*` to reflect the real active wave so that future rounds do not restart already-closed work or mix in parking-lot tasks prematurely.

## Acceptance Criteria
- [ ] The active `e2e/run-tests.sh all` rerun completes or exposes the next concrete failing spec/helper.
- [ ] If the rerun completes green, `STATE.md` records the final pass/skip/fail evidence and `TODOS.md` Phase 3B is updated to reflect closure of the all-up rerun.
- [ ] If a new failure appears, only the failing slice is patched and rerun before broader suite work resumes.
- [ ] `.claude/harness/SPRINT.md` scopes the current round to the active gate only.
- [ ] `.claude/harness/STATE.md` records what is actively running, what is already green, and what remains blocked by execution order.
- [ ] Parking-lot items from `TODOS.md` are preserved as deferred backlog, not mixed into the current sprint before Phases 1 through 3 are closed with evidence.

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `.claude/harness/SPEC.md` | modify | Re-anchor the harness to the current `TODOS.md` active gate |
| `.claude/harness/SPRINT.md` | modify | Scope-lock the current round to the all-up E2E completion/fix loop |
| `.claude/harness/STATE.md` | modify | Record active-wave status and deferred parking-lot backlog |
| `STATE.md` | modify | Ledger final authoritative evidence when the wrapper completes or fails |
| `TODOS.md` | modify | Reflect closure/progress for Phase 3B once evidence exists |
| `e2e/lib/auth.ts` | modify if needed | Patch future long-run auth/bootstrap defects surfaced by the wrapper |
| `e2e/lib/agent-browser.ts` | modify if needed | Patch future browser-state/bootstrap defects surfaced by the wrapper |
| `e2e/specs/**` | modify if needed | Patch only the next concretely failing spec slice |

## Data Flow
`TODOS.md` execution order -> active gate determined from `STATE.md` -> harness sprint scope -> running all-up seeded E2E wrapper -> log evidence in `/tmp/origna_e2e_run_all_after_deep_fix.log` -> either targeted fix and rerun, or direct ledger updates when green.

For failures: wrapper log -> failing spec/helper -> focused patch -> targeted rerun -> resume/redo wrapper as needed -> record evidence.

## Constraints
- 8GB RAM: keep heavy work sequential; do not start unrelated full-suite waves while the all-up wrapper is running.
- Respect `TODOS.md` execution order: do not pull parking-lot audit/coverage/design tasks ahead of unfinished Phase 3 evidence.
- Do not mark any checklist item done without captured command evidence.
- Preserve dirty-worktree safety; do not revert unrelated user changes.
- Use the harness as coordination metadata, not as an excuse to broaden scope.

## Sprint Contract Proposal
### Round 1 Deliverables
- Let the active all-up E2E rerun continue until completion or first failure.
- Capture the final browser/API wrapper summary from `/tmp/origna_e2e_run_all_after_deep_fix.log`.
- If green: update `STATE.md`, `TODOS.md`, and `.claude/harness/STATE.md` to mark the all-up rerun evidence.
- If red: fix only the newly failing slice, verify it in isolation, then resume the wrapper path.

## Deferred Backlog From Parking Lot
These items remain explicitly deferred until the active gated waves are green with evidence:
- repo/process improvements
- AI/model feedback loops for UI/UX review
- app lifecycle research and fixes
- VS Code warnings/TODO cleanup
- broader E2E API/live-test expansion
- `.claude/skills` / `CLAUDE.md` / `AGENTS.md` audits
- coverage pushes to 95%+
- screenshot expansion to 200+ desktop captures
- preview-gap improvements
- full codebase best-practices audits
- semantic-label expansion beyond currently tested gaps
- `e2e/ai` execution and visual-audit expansion
