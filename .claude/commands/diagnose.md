# /diagnose — Systematic Bug Investigation

**Usage**: `/diagnose $ARGUMENTS`

Investigate a bug or unexpected behavior systematically.

## Process
1. **Collect evidence** — error messages, logs, git blame, reproduction steps
2. **Build hypothesis matrix** — list all possible causes ranked by likelihood
3. **Test hypotheses** — start with most likely, use targeted grep/read
4. **If complex** — use ACH (Analysis of Competing Hypotheses), eliminate possibilities
5. **Fix** — minimal targeted change
6. **Verify** — run analysis + tests, add regression test
7. **Document** — update STATE.md with root cause for future reference

## Rules
- Never guess — collect evidence first
- Test one hypothesis at a time
- Add a regression test for every fix
- If 3 hypotheses fail, step back and re-examine evidence
