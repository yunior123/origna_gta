# Flutter Code Review Checklist — origna_gta

Use this checklist for every Dart/Flutter code review.

## Architecture (MVVM)

- [ ] No business logic in Widgets or Screens (calculations, filtering, sorting, API calls)
- [ ] No `setState()` in Screen files (use Riverpod)
- [ ] No `BuildContext` passed to ViewModels or Services
- [ ] Correct layer boundaries: Screen -> ViewModel -> Service -> OrignaBase SDK
- [ ] ViewModels use `AsyncNotifier` or `StateNotifier` (in `lib/viewmodels/`)
- [ ] Services are stateless (in `lib/services/`)

## Riverpod

- [ ] `ref.watch()` used in `build()` for reactive state
- [ ] `ref.read()` used in callbacks for one-time actions
- [ ] `.select()` used when only one field from state is needed
- [ ] No conditional `ref.watch()` inside `if` blocks in `build()`
- [ ] `AsyncNotifierProvider` used for mutable async state (not `FutureProvider`)
- [ ] Subscriptions and listeners disposed properly

## Styling & Design Tokens

- [ ] No `Colors.*` literals (use `DesignTokens.*`)
- [ ] No hex color literals (`Color(0xFF...)`, `Color.fromRGBO(...)`)
- [ ] No `Theme.of(context).colorScheme.primary` (use `DesignTokens.primary`)
- [ ] Spacing values from DesignTokens constants

## String Constants

- [ ] DB/API field names from `schema_constants.dart`
- [ ] Route names from `AppRoutes`
- [ ] URLs from `EnvConfig` (no hardcoded URLs)
- [ ] No other magic strings

## Semantics & Accessibility

- [ ] All buttons have `Semantics(label: 'btn-*')` or `tooltip:`
- [ ] All form fields have `semanticsLabel:` or `Semantics(label: 'input-*')`
- [ ] Navigation items labeled `nav-*`
- [ ] Product cards labeled `product-card-<id>`
- [ ] Order cards labeled `order-card-<id>`
- [ ] Decorative icons wrapped in `ExcludeSemantics`

## Performance

- [ ] `ListView.builder` used (never `ListView(children: [...])`)
- [ ] `CachedNetworkImage` for all network images (no `Image.network()`)
- [ ] Images specify `width`, `height`, `fit: BoxFit.cover`
- [ ] No unnecessary parent rebuilds from child state changes

## Error Handling

- [ ] `AppLogger` used (no `print()`, `debugPrint()`)
- [ ] All async operations handle loading/error/success states
- [ ] `AppError` used for domain errors
- [ ] Transient errors shown via `SnackBar`
- [ ] Form errors shown inline
- [ ] Unexpected errors logged to Sentry

## Imports

- [ ] Package imports only (`package:origna_gta/...`)
- [ ] No relative imports (`../`)

## Responsive Design

- [ ] No `MediaQuery.of(context).size.width` for layout decisions
- [ ] `ResponsiveBreakpoints` used for responsive logic
- [ ] No fixed pixel widths on layout containers
- [ ] Content wrapped with `maxWidth: ResponsiveBreakpoints.contentMaxWidth`

## Money

- [ ] All monetary values in integer cents (no `double`/`float`)
- [ ] Display format: `'\$${(cents / 100).toStringAsFixed(2)}'`
- [ ] Field names: `priceCents`, `subtotalCents`, `taxAmountCents`, `totalAmountCents`
- [ ] Platform fee: `platformFeeTotalCents / subtotalCents`

## Testing

- [ ] Test file mirrors source path (`lib/x/y.dart` -> `test/x/y_test.dart`)
- [ ] Widget tests use `ProviderScope(overrides: [...])`
- [ ] No `print()` or `debugPrint()` in test files
- [ ] No `sleep()` or `Future.delayed()` in tests
- [ ] No hardcoded UIDs or tokens

## Models

- [ ] `freezed` used for all value types and API models
- [ ] All constructors are `const` where possible
- [ ] `final` used by default (only `var` when type is obvious)
- [ ] No `dynamic` type (use generics or `Object?`)
- [ ] Named parameters for functions with 3+ params
