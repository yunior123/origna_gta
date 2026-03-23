# /verify — Run Verification Loop

**Usage**: `/verify [flutter|rust|all]`

Run the verification-loop skill to check project health before commits or PRs.

## What It Does

Executes 6 phases sequentially (8GB RAM — no parallel):

1. **Flutter Analyze** — `flutter analyze --no-fatal-infos`
2. **Rust Clippy** — `cd orignabase && cargo clippy -D warnings`
3. **Flutter Tests** — `flutter test --exclude-tags golden`
4. **Rust Tests** — `cd orignabase && cargo test`
5. **Security Scan** — grep for forbidden patterns (print(), Colors., Firebase, float money, setState, secrets)
6. **Diff Review** — `git diff --stat` + review changed files

If `$ARGUMENTS` is "flutter" — run phases 1, 3, 5, 6 only.
If `$ARGUMENTS` is "rust" — run phases 2, 4, 5, 6 only.
Otherwise run all 6 phases.

## Output

Produce a VERIFICATION REPORT table:
```
VERIFICATION REPORT
===================
Flutter Analyze:  [PASS/FAIL] (X issues)
Rust Clippy:      [PASS/FAIL] (X warnings)
Flutter Tests:    [PASS/FAIL] (X/Y passed)
Rust Tests:       [PASS/FAIL] (X/Y passed)
Security Scan:    [PASS/FAIL] (X issues found)
Diff Review:      [X files changed]

Overall: [READY/NOT READY]
```

If any phase FAILS, list the issues to fix below the report.

## Rules
- Stop and fix if flutter analyze or cargo clippy fails — don't continue to tests
- Never use `flutter test --coverage` (8GB RAM — overwrites lcov.info)
- Golden tests excluded in all environments
- If no Rust changes detected, skip Rust phases
