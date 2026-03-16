# Flutter/Dart Coding Rules — origna_gta

## Architecture (MVVM — strictly enforced)
- No business logic in Widgets or Screens
- Screens → ViewModels → Services → OrignaBase SDK
- All state in Riverpod providers (`lib/providers/`)
- ViewModels in `lib/viewmodels/` — use `AsyncNotifier` or `StateNotifier`
- Services in `lib/services/` — stateless, pure functions + SDK calls

## Riverpod Patterns
- `ref.watch()` for reactive state, `ref.read()` for one-time actions
- Use `select()` to avoid unnecessary rebuilds: `ref.watch(provider.select((s) => s.field))`
- Never call `ref.watch()` inside `build()` conditionally
- Prefer `AsyncNotifierProvider` over `FutureProvider` for mutable async state
- Dispose subscriptions in `dispose()` — never leak listeners

## Dart Style
- All `const` constructors where possible
- `final` by default; only use `var` when type is obvious
- No `dynamic` — use generics or `Object?` if truly needed
- Named parameters for functions with 3+ params
- Use `freezed` for all value types, API models, and states

## No Magic Strings
- Route names → `AppRoutes` class in `lib/routes.dart`
- DB/API field names → `schema_constants.dart`
- Design values → `DesignTokens` class in `lib/core/`
- API keys / config → `EnvConfig` in `lib/utils/env_config.dart`
- Never hardcode: colors, spacing, route strings, field names, URLs

## Theme / Colors
- ONLY use `DesignTokens.*` — never `Colors.blue`, never hex literals
- Dark theme: `DesignTokens.darkBackground` (`#0F0F1E`), `DesignTokens.primary` (`#667EEA`)
- Always verify contrast ratio in dark mode (≥ 4.5:1 for text)
- Use `isDark = Theme.of(context).brightness == Brightness.dark` for conditional styling
- Never use `Theme.of(context).colorScheme.primary` — use DesignTokens

## Responsive Design
- `lib/utils/responsive_layout.dart` — Mobile < 768px, Tablet 768–1023px, Desktop ≥ 1024px
- Content max width: `ResponsiveBreakpoints.contentMaxWidth` (1200px)
- Wrap list screens: `ConstrainedBox(constraints: BoxConstraints(maxWidth: ResponsiveBreakpoints.contentMaxWidth))`
- Never use fixed pixel widths for layout containers

## Semantics (required for Playwright E2E)
- ALL interactive elements: `Semantics(label: 'btn-*')` or `tooltip:` / `semanticsLabel:`
- Conventions: `btn-`, `input-`, `nav-`, `product-card-<id>`, `order-card-<id>`
- Decorative icons: `ExcludeSemantics(child: Icon(...))`
- Without semantics, Playwright CI tests will fail

## Performance
- Always use `ListView.builder` — never `ListView(children: [...])`
- `CachedNetworkImage` for all product/user images
- Always specify `width`, `height`, `fit: BoxFit.cover` on images
- Never trigger parent rebuilds when only child state changes

## Error Handling
- Use `AppError` for all domain errors
- Every async action handles loading / error / success states
- Transient errors → `SnackBar`; form errors → inline
- Unexpected errors → log to Sentry via `SentryService`

## Money
- All monetary values in **integer cents** — no floats for money
- Field names: `priceCents`, `subtotalCents`, `taxAmountCents`, `totalAmountCents`
- Display: `'\$${(cents / 100).toStringAsFixed(2)}'`

## Testing
- Before every commit: `flutter analyze --no-fatal-infos && flutter test`
- Widget tests in `test/widgets/`, unit tests in `test/unit/`
- Wrap with `ProviderScope(overrides: [...])` for Riverpod tests
- Test against dev OrignaBase (`api.dev.orignagta.ca`) — NO emulators (8GB RAM — use OrignaBase dev at api.dev.orignagta.ca)

## Forbidden
- ❌ `setState()` in screens — use Riverpod
- ❌ `BuildContext` in ViewModels or Services
- ❌ Hardcoded colors, strings, routes, field names
- ❌ `print()` — use `AppLogger`
- ❌ `MediaQuery.of(context).size.width` for layout decisions
- ❌ Nested `FutureBuilder` inside `StreamBuilder`
- ❌ Business logic in `build()` methods
- ❌ Non-paginated data fetching (always limit + offset)
