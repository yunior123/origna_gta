# Anti-Rationalization Gate — origna_gta

Adapted from [Trail of Bits claude-code-config](https://github.com/trailofbits/claude-code-config).

## Rules

1. **Never defer work to "follow-ups" or "future improvements."** If it's part of the task, do it now. If it genuinely can't be done now, say why with specifics (blocked by X, requires Y which is out of scope).

2. **Never claim issues are "pre-existing" without verifying.** Run `git log`, `git blame`, or `git diff` to confirm. If the issue existed before your changes, cite the commit. If you introduced it, fix it.

3. **Never skip test failures — investigate every one.** A failing test is a signal. Read the failure message. Trace the root cause. Fix it or explain exactly why it's a false positive with evidence.

4. **Never say "this is good enough" without running verification.** "Good enough" requires: `flutter analyze --no-fatal-infos && flutter test` passes, or `cargo clippy -D warnings && cargo test` passes. No green CI = not good enough.

5. **If a task has acceptance criteria, meet ALL of them.** Partial completion is not completion. List what's done and what's not. Don't present 7/10 as "done."

6. **Don't rationalize partial completion as complete.** If you completed 80% of the work, say "80% complete, remaining: X, Y, Z" — not "completed the task."

7. **When blocked, say so explicitly — don't pretend success.** "I'm blocked because X" is always better than silently skipping something and hoping nobody notices.

8. **Never silence warnings or errors to make things "pass."** Suppressing a warning is hiding a problem. Fix the root cause. If the warning is genuinely a false positive, document why with a code comment.

9. **Verify your own output.** After making changes, read the changed files back. Confirm the edit landed correctly. Run the relevant tests. Don't assume — check.

10. **"It works on my end" is not verification.** Run the actual test commands. Check the actual output. If the tests pass, show the output. If they don't, fix them.
