---
name: flutter-code-review
description: "Reviews Flutter/Dart code for MVVM compliance, Riverpod patterns, DesignTokens usage, Semantics labels, performance, and origna_gta conventions. Use after any Dart code change."
---

# Flutter Code Review

Performs a comprehensive review of Flutter/Dart code changes against origna_gta project conventions.

## When to Use

- After any Dart/Flutter code change
- Before committing Flutter code
- When reviewing PRs that touch `lib/` or `test/`

## Workflow

### Step 1: Identify Changed Files

Determine which Dart files were changed. Use one of:
- `git diff --name-only HEAD` for uncommitted changes
- `git diff --name-only <base>..HEAD` for branch changes
- User-specified files

Filter to `.dart` files only.

### Step 2: Read Each Changed File

Read the full content of each changed file. For large diffs, read the diff instead.

### Step 3: Run the Checklist

For each file, check every item in `references/review-checklist.md`. Use Grep to verify patterns across the codebase when needed.

#### Architecture (MVVM)

- **No business logic in Widgets/Screens.** Screens should only call ViewModel methods and render state. If you see calculations, filtering, sorting, or API calls in a `build()` method or Screen file, flag it.
- **No `setState()` in screens.** All state must go through Riverpod providers. `setState` is only acceptable in self-contained leaf widgets (e.g., animation controllers).
- **No `BuildContext` in ViewModels or Services.** These layers must be context-free. Navigation, dialogs, and theme access belong in the Screen/Widget layer.
- **Correct layer boundaries:** Screen -> ViewModel -> Service -> OrignaBase SDK. No skipping layers.

#### Riverpod Patterns

- **Use `ref.watch()` for reactive state** in `build()` methods. Use `ref.read()` for one-time actions (button callbacks, init).
- **Use `.select()` for granular rebuilds.** Flag any `ref.watch(provider)` that only uses one field from the state — it should be `ref.watch(provider.select((s) => s.field))`.
- **No conditional `ref.watch()`.** Never call `ref.watch()` inside an `if` block within `build()`.
- **`AsyncNotifierProvider` for mutable async state.** `FutureProvider` is only for read-only one-shot data.
- **Dispose subscriptions.** Check that listeners and stream subscriptions are cleaned up.

#### Styling & Design Tokens

- **`DesignTokens.*` only.** Flag any use of:
  - `Colors.blue`, `Colors.red`, or any `Colors.*` literal
  - Hex color literals like `Color(0xFF...)` or `Color.fromRGBO(...)`
  - `Theme.of(context).colorScheme.primary` — use `DesignTokens.primary` instead
- **No magic spacing/sizing values.** Use DesignTokens spacing constants.

#### String Constants

- **`schema_constants.dart` for all DB/API field names.** Flag any hardcoded field name strings like `'createdAt'`, `'priceCents'`, etc.
- **`AppRoutes` for route names.** No hardcoded route strings.
- **`EnvConfig` for URLs.** No hardcoded API URLs.

#### Semantics & Accessibility

- **All interactive elements need semantic labels.** Check for `Semantics(label: 'btn-*')`, `tooltip:`, or `semanticsLabel:` on buttons, tappable areas, form fields.
- **Naming conventions:** `btn-*`, `input-*`, `nav-*`, `product-card-<id>`, `order-card-<id>`.
- **Decorative icons:** Should be wrapped in `ExcludeSemantics(child: Icon(...))`.

#### Performance

- **`ListView.builder` only.** Flag any `ListView(children: [...])` or `Column` with many children that should be a lazy list.
- **`CachedNetworkImage` for network images.** Flag any `Image.network()` or `NetworkImage()`.
- **Images must specify `width`, `height`, `fit: BoxFit.cover`.** Missing dimensions cause layout thrashing.
- **No unnecessary parent rebuilds.** Child state changes should not trigger parent rebuilds.

#### Error Handling

- **`AppLogger` instead of `print()`.** Flag any `print()`, `debugPrint()`, or `log()` calls.
- **Handle all async states.** Every async operation must handle loading, error, and success states.
- **Use `AppError` for domain errors.** No raw exceptions for business logic errors.

#### Imports

- **Package imports only.** Use `package:origna_gta/...` — flag any relative imports (`../`).

#### Responsive Design

- **Use `ResponsiveBreakpoints`.** Flag any `MediaQuery.of(context).size.width` for layout decisions.
- **No fixed pixel widths** on layout containers.

#### Money

- **Integer cents only.** Flag any `double` or `float` used for monetary values.
- **Display format:** `'\$${(cents / 100).toStringAsFixed(2)}'` — flag any other money formatting.

### Step 4: Run Static Analysis

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta && flutter analyze --no-fatal-infos
```

### Step 5: Report

Output a structured report:

```
## Flutter Code Review Results

### Files Reviewed
- `lib/path/to/file.dart`

### Issues Found
| # | Severity | File:Line | Rule | Description | Suggested Fix |
|---|----------|-----------|------|-------------|---------------|
| 1 | P0 | file.dart:42 | MVVM | Business logic in build() | Move to ViewModel |

### Passed Checks
- [x] No setState in screens
- [x] DesignTokens used consistently
...

### Summary
X issues found (Y critical). Z checks passed.
```

Severity levels:
- **P0**: Will cause bugs or security issues — must fix
- **P1**: Violates architecture — should fix before merge
- **P2**: Style/convention issue — fix when convenient
- **P3**: Suggestion/improvement — optional
