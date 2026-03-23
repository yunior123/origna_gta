---
name: santa-method
description: "Fun but thorough code review using Naughty/Nice lists. Catches anti-patterns, bugs, and security issues while praising good patterns. Use for code review or pre-commit checks."
---

# Santa Method Code Review

A thorough code review methodology that categorizes findings into Naughty (issues) and Nice (good patterns) lists. Makes reviews engaging while maintaining rigor.

## When to Use

- Pre-commit review of staged changes
- Reviewing a set of files after a feature implementation
- Quick quality check on recently modified code
- Fun alternative to standard code review

## Workflow

### Step 1: Identify Code to Review

Determine the scope. Options:
- **Staged changes:** `git diff --cached --name-only`
- **Uncommitted changes:** `git diff --name-only`
- **Specific files:** User-provided list
- **Recent commits:** `git diff <ref>..HEAD --name-only`

Read all changed files and their diffs.

### Step 2: Build the Naughty List

Scan for issues across these categories. Each item gets a severity and suggested fix.

#### Security (P0)
- Hardcoded credentials, API keys, tokens
- SQL injection (string concatenation in queries)
- Missing input validation
- Exposed PII in logs (`print()` with emails, names, addresses)
- Bypassed auth checks
- Missing webhook signature verification

#### Bug Risks (P0-P1)
- Null safety issues (force unwrap `!` without null check)
- Race conditions (shared mutable state without synchronization)
- Missing edge cases (empty lists, zero values, negative numbers)
- Uncaught exceptions in async code
- Memory leaks (undisposed controllers, listeners)
- Off-by-one errors in pagination or indexing

#### Anti-Patterns (P1-P2) — per origna_gta rules
- `setState()` in screens (use Riverpod)
- `BuildContext` in ViewModels or Services
- `Colors.blue` or hex literals (use DesignTokens)
- `print()` or `debugPrint()` (use AppLogger)
- Relative imports `../` (use `package:origna_gta/`)
- `MediaQuery.of(context).size.width` (use ResponsiveBreakpoints)
- Business logic in `build()` methods
- `Image.network()` (use CachedNetworkImage)
- `ListView(children: [...])` (use ListView.builder)
- `double` for money (use integer cents)
- Hardcoded strings for field names (use schema_constants)
- Missing Semantics labels on interactive elements
- `FutureProvider` for mutable state (use AsyncNotifierProvider)
- `ref.watch()` without `.select()` when only one field is used
- Firebase SDK calls (Firebase is gone)

#### Missing Error Handling (P1-P2)
- Async operations without loading/error/success states
- Missing try-catch on SDK calls
- Swallowed exceptions (empty catch blocks)
- Missing user feedback on errors

#### Performance (P2)
- Unnecessary rebuilds (missing `.select()`)
- Large widgets without `const` constructors
- Missing `const` on static widgets
- Network images without dimensions
- Unbounded lists without lazy loading

#### Accessibility (P2)
- Interactive elements without semantic labels
- Missing `ExcludeSemantics` on decorative icons
- Poor contrast (light text on light background)

### Step 3: Build the Nice List

Recognize good patterns. Look for:

- **Clean MVVM separation** — Screen only renders, ViewModel handles logic
- **Proper Riverpod usage** — `.select()`, `AsyncNotifier`, clean disposal
- **Consistent DesignTokens** — No hardcoded colors or spacing
- **Good error handling** — Loading/error/success states, user feedback
- **Semantic labels** — All interactive elements properly labeled
- **Performance-conscious code** — `const` constructors, `ListView.builder`, cached images
- **Well-structured tests** — Mirrors source structure, proper mocking, no magic values
- **Clean Freezed models** — Immutable, well-typed, no `dynamic`
- **Integer cents for money** — Proper formatting at display layer
- **Package imports** — No relative imports

### Step 4: Output the Report

```markdown
## Santa Method Review

### Naughty List (X issues)

| # | Severity | File:Line | Category | Description | Suggested Fix |
|---|----------|-----------|----------|-------------|---------------|
| 1 | P0 | auth_service.dart:45 | Security | Hardcoded API key | Move to EnvConfig |
| 2 | P1 | cart_screen.dart:78 | Anti-Pattern | setState() in screen | Use Riverpod provider |

### Nice List (Y good patterns)

| # | File:Line | Category | What's Good |
|---|-----------|----------|-------------|
| 1 | order_viewmodel.dart:30 | MVVM | Clean state machine with AsyncNotifier |
| 2 | product_card.dart:15 | Semantics | Proper product-card-<id> label |

### Verdict

**Naughty/Nice Ratio:** X/Y

- **P0 issues:** N (must fix before merge)
- **P1 issues:** N (should fix before merge)
- **P2 issues:** N (fix when convenient)
- **P3 issues:** N (suggestions)

**Overall:** SHIP IT / NEEDS WORK / BLOCK

### Action Items (prioritized)

1. [P0] Fix hardcoded API key in auth_service.dart:45
2. [P1] Replace setState with Riverpod in cart_screen.dart:78
...
```

### Verdict Criteria

| Verdict | Criteria |
|---------|----------|
| **SHIP IT** | 0 P0, 0 P1, Nice list longer than Naughty |
| **NEEDS WORK** | 0 P0, some P1s, or Naughty list is concerning |
| **BLOCK** | Any P0, or multiple P1 security issues |

## Tips

- Be generous with the Nice list — good patterns deserve recognition
- P0 security issues are always blockers, no exceptions
- When in doubt about severity, round up (P2 -> P1)
- For large reviews (10+ files), group issues by file
- Run `flutter analyze --no-fatal-infos` as part of the review
