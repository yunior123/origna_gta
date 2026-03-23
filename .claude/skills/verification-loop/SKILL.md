---
name: verification-loop
description: "Runs 6-phase verification (analyze, clippy, tests, security scan, diff review) for Flutter + Rust projects. Use after completing features, before commits, or before PRs."
---

# Verification Loop

6-phase sequential verification for the origna_gta monorepo (Flutter + Rust). Sequential because 8GB RAM = one heavy process at a time.

## When to Use

- After completing a feature or bug fix
- Before creating a commit
- Before creating a PR
- When asked to "verify", "check", or "validate" the codebase

## Phases

Run each phase sequentially. Stop and report if a phase fails critically.

### Phase 1: Flutter Static Analysis

```bash
flutter analyze --no-fatal-infos
```

- PASS: zero errors (warnings/infos OK)
- FAIL: any error-level issue

### Phase 2: Rust Clippy

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/orignabase && cargo clippy -D warnings
```

- PASS: zero warnings
- FAIL: any warning (treated as error via `-D warnings`)

### Phase 3: Flutter Tests

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta && flutter test --exclude-tags golden
```

- Golden tests excluded (Ubuntu renderer differs from macOS)
- PASS: all tests pass, zero failures
- FAIL: any test failure

### Phase 4: Rust Tests

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/orignabase && cargo test
```

- PASS: all tests pass
- FAIL: any test failure

### Phase 5: Security Scan

Grep for forbidden patterns in the codebase. Each match is a security/quality issue.

#### 5a. Forbidden print statements in Dart

```
Pattern: `print(` or `debugPrint(` in .dart files (excluding test files)
Fix: Use AppLogger instead
```

#### 5b. Hardcoded colors in Dart

```
Pattern: `Colors.` (e.g., Colors.blue) or hex color literals `#[0-9a-fA-F]{6}` in .dart files
Fix: Use DesignTokens.* constants
```

#### 5c. Firebase imports (Firebase is GONE)

```
Pattern: `FirebaseAuth` or `Firestore` or `FirebaseStorage` or `firebase_` in .dart files
Fix: Use OrignaBase SDK instead
```

#### 5d. Float money (must be integer cents)

```
Pattern: `double` near money-related field names (price, total, fee, subtotal, amount, cost, payout)
Fix: Use int cents — priceCents, totalAmountCents, etc.
```

#### 5e. setState in screens

```
Pattern: `setState(` in lib/screens/ or lib/pages/
Fix: Use Riverpod providers
```

#### 5f. Hardcoded API keys or secrets

```
Pattern: `sk_live_`, `sk_test_`, `whsec_`, API key patterns in source code (not .env files)
Fix: Use environment variables, Secret Manager, or macOS Keychain
```

#### 5g. console.log in non-JS files

```
Pattern: `console.log` in .dart or .rs files
Fix: Use AppLogger (Dart) or tracing (Rust)
```

### Phase 6: Diff Review

```bash
git diff --stat
git diff --name-only
```

- Review changed files for completeness
- Check that test files accompany new source files
- Flag any suspicious additions (credentials, large binaries, .env files)

## Output Format

After running all phases, produce this exact report format:

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

Issues to Fix:
1. ...
```

## Rules

- Run phases sequentially (8GB RAM constraint)
- Do NOT skip any phase
- If a phase fails, still run remaining phases to collect all issues
- Security scan issues are blockers for commits
- `flutter analyze` infos are OK, errors are not
- Never use `--no-fatal-infos` on clippy (use `-D warnings` instead)
