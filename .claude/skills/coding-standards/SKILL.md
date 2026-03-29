---
name: coding-standards
description: "Enforces origna_gta coding standards: MVVM, Riverpod, DesignTokens, integer cents for money, Freezed models, AppError/AppLogger. Use when writing or reviewing code."
---

# Coding Standards — origna_gta

Quality gates and conventions for all Flutter/Dart and Rust code in the origna_gta monorepo.

## When to Use

- Writing new code (features, fixes, refactors)
- Reviewing code (PRs, diffs, agent output)
- When asked to "review", "check standards", or "enforce quality"

## Architecture: MVVM (Strictly Enforced)

```
Screen (Widget) → ViewModel (AsyncNotifier) → Service → OrignaBase SDK
```

- **Screens**: UI only. No business logic. No direct SDK calls.
- **ViewModels**: State management via Riverpod. In `lib/viewmodels/`.
- **Services**: Stateless. Pure functions + SDK calls. In `lib/services/`.
- **OrignaBase SDK**: The only way to talk to the backend.

## Riverpod State Management

### Do

- `ref.watch()` for reactive state in `build()` methods
- `ref.read()` for one-time actions (button handlers, init)
- `ref.watch(provider.select((s) => s.field))` to minimize rebuilds
- `AsyncNotifierProvider` for mutable async state
- Dispose subscriptions in `dispose()`

### Do NOT

- `setState()` in screens — use Riverpod
- `ref.watch()` inside conditionals in `build()`
- `BuildContext` in ViewModels or Services
- Nested `FutureBuilder` inside `StreamBuilder`
- Business logic in `build()` methods

## Dart Style

- `const` constructors wherever possible
- `final` by default; `var` only when type is obvious
- No `dynamic` — use generics or `Object?`
- Named parameters for functions with 3+ params
- `freezed` for all value types and API models
- `package:origna_gta/...` imports only (no relative `../`)

## Design Tokens (Colors & Theming)

```dart
// CORRECT
color: DesignTokens.primary,
backgroundColor: DesignTokens.darkBackground,

// FORBIDDEN
color: Colors.blue,           // Magic color
color: Color(0xFF667EEA),     // Hex literal
color: Theme.of(context).colorScheme.primary, // Use DesignTokens
```

Key tokens:
- Primary: `DesignTokens.primary` (#667EEA)
- Secondary: `DesignTokens.secondary` (#764BA2)
- Dark background: `DesignTokens.darkBackground` (#0F0F1E)
- Dark card: `DesignTokens.darkCard` (#1E1E32)

Dark mode check: `isDark = Theme.of(context).brightness == Brightness.dark`

## Schema Constants

All field names come from `lib/core/schema/schema_constants.dart`:

```dart
// CORRECT
SchemaConstants.createdAt
SchemaConstants.priceCents

// FORBIDDEN
'createdAt'   // Hardcoded string
'price_cents' // Wrong field name
```

## Money: Integer Cents (Non-Negotiable)

```dart
// CORRECT
int priceCents = 7500;           // $75.00
int totalAmountCents = 8625;     // $86.25
String display = '\$${(cents / 100).toStringAsFixed(2)}';

// FORBIDDEN
double price = 75.00;            // Float money
double total = 86.25;            // Float money
```

Field names: `priceCents`, `subtotalCents`, `taxAmountCents`, `totalAmountCents`, `shippingCostCents`, `platformFeeTotalCents`.

## Error Handling (See also: error-handling-expert skill)

### Error Code System

All errors use structured codes — never string matching:

```
AUTH_*     — Authentication errors (REQUIRED, EXPIRED, INVALID, MFA_REQUIRED)
ORDER_*    — Order lifecycle (NOT_FOUND, INVALID_TRANS, ALREADY_PAID, CANCELLED)
STOCK_*    — Inventory (INSUFFICIENT, LOCKED)
PAY_*      — Payment (FAILED, AMOUNT_MISMATCH, IDEMPOTENT)
VALID_*    — Validation (REQUIRED, INVALID_FORMAT, OUT_OF_RANGE)
RATE_*     — Rate limiting
INTERNAL_* — Server errors (ERROR, DB_ERROR)
```

### Dart Error Handling

- `AppError` hierarchy — typed errors, no generic `Exception`
- Repository: map SDK exceptions to domain errors via typed catch
- ViewModel: `AsyncValue.guard()` — errors in state, never silent
- UI: `.when(error:)` handles ALL error types — no `SizedBox()` in error branch
- Never catch generic `Exception` — catch specific types
- Never `catch (e) { if (e.toString().contains(...)) }` — use typed codes

### Rust Error Handling

- `Result<T, AppError>` on all handler functions
- `map_err()` with context for error chaining
- No `unwrap()` in production code (tests OK)
- HTTP status codes: 400 validation, 401 auth, 403 forbidden, 404 not found, 409 conflict, 429 rate limited, 500 internal
- Structured error responses: `{ "error": { "code": "...", "message": "..." } }`

### Logging

- `AppLogger` for logging (never `print()` or `debugPrint()`)
- Transient errors: `SnackBar`
- Form errors: inline
- Unexpected errors: log to Sentry via `SentryService`
- No PII in logs (emails, addresses, tokens)

## Responsive Design

- Mobile: < 768px
- Tablet: 768-1023px
- Desktop: >= 1024px
- Content max width: 1200px (`ResponsiveBreakpoints.contentMaxWidth`)
- Never use fixed pixel widths for layout containers
- Never use `MediaQuery.of(context).size.width` for layout decisions

## Semantics (Required for E2E)

All interactive elements need semantic labels:
- Buttons: `Semantics(label: 'btn-action-name')`
- Inputs: `Semantics(label: 'input-field-name')`
- Navigation: `Semantics(label: 'nav-item-name')`
- Cards: `Semantics(label: 'product-card-$id')`
- Decorative icons: `ExcludeSemantics(child: Icon(...))`

## Performance

- `ListView.builder` always (never `ListView(children: [...])`)
- `CachedNetworkImage` for all remote images
- Always specify `width`, `height`, `fit: BoxFit.cover` on images
- Never trigger parent rebuilds when only child state changes

## Forbidden Patterns Summary

| Pattern | Fix |
|---------|-----|
| `Colors.blue` or hex | `DesignTokens.*` |
| `setState()` in screens | Riverpod |
| `print()` / `debugPrint()` | `AppLogger` |
| `double` for money | `int` cents |
| `BuildContext` in VM/Service | Pass data, not context |
| `FirebaseAuth.instance` | OrignaBase SDK |
| `'fieldName'` hardcoded | `SchemaConstants.*` |
| `../` relative imports | `package:origna_gta/` |
| `MediaQuery.of(context).size.width` | Responsive utilities |

## References

See `references/dart-standards.md` for Dart-specific examples.
See `references/rust-standards.md` for Rust-specific examples.
