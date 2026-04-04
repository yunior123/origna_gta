# OrignaGTA Architecture

## Overview

OrignaGTA is a Canada-first multi-vendor e-commerce marketplace built with Flutter (Web + Mobile). It supports product listings, multi-seller checkout with Stripe, order management, real-time chat, digital product delivery, and a premium subscription tier.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Web, iOS, Android) |
| State Management | Riverpod (StateNotifier + providers) |
| Models | Freezed + json_serializable |
| Backend | OrignaBase (Rust VPS — axum + PostgreSQL + Meilisearch) |
| Payments | Stripe (Connect for multi-seller payouts) |
| Storage | Cloudflare R2 (presigned URLs) |
| Error Tracking | Sentry |
| i18n | easy_localization (EN + FR-CA) |
| E2E Testing | Bun + agent-browser (agent-browser) |

### Key Constraints

- **8GB RAM Mac**: Sequential heavy tasks only. No parallel Flutter builds + agent-browser + tests.
- **Canada-first**: All shipping to Canada. Sellers can be international. Quebec Bill 96 (Loi 96) requires French translations.
- **Firebase is GONE**: All backend goes through OrignaBase SDK. Never `FirebaseAuth.instance`.
- **main only**: No branches. All commits to main.

---

## MVVM Architecture

### Layer Diagram

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────────┐
│   Screen    │────▶│  ViewModel   │────▶│   Service   │────▶│ OrignaBase SDK   │
│  (Widget)   │     │(StateNotifier)│    │ (stateless) │     │  (Rust backend)  │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────────┘
       │                    │
       │              ┌─────┴──────┐
       │              │  Repository │ (abstract interface)
       │              └────────────┘
       │                    │
       └────────────────────┘
          ref.watch(provider)
```

### Data Flow: Add to Cart

```
1. Screen: CartScreen reads cartItemsProvider via ref.watch()
2. Provider: cartControllerProvider returns CartController(ref)
3. CartController calls CartRepository.addItem(userId, productId, quantity)
4. CartRepository (OrignaBaseCartRepository) calls ob.request('POST', '/cart/add', body: {...})
5. OrignaBase SDK sends authenticated HTTP request to Rust backend
6. Backend validates, writes to PostgreSQL, returns result
7. StreamProvider (cartItemsProvider) auto-updates via PostgreSQL subscription
8. Screen rebuilds with new cart state
```

### Rules

- **Screens** contain ONLY widget tree + `ref.watch()` / `ref.read()`. No business logic.
- **ViewModels** (`StateNotifier` subclasses) own state mutations and async orchestration.
- **Repositories** are abstract classes. Concrete `OrignaBase*Repository` implementations talk to the SDK.
- **Services** are stateless utilities (analytics, notifications, session timeout).
- Never pass `BuildContext` into ViewModels or Services.

---

## Decision Log

### 1. Money = Integer Cents (Never double/float)

**What**: All monetary values stored and transmitted as `int` cents (e.g., `$24.99` = `2499`).

**Why**: IEEE 754 floating-point arithmetic introduces rounding errors. `$0.1 + $0.2 ≠ $0.3` in double precision. For a marketplace dealing with real money, this is unacceptable.

**Anti-pattern**: Using `double price = 24.99` and rounding at display time. We had rounding mismatches between cart totals and Stripe charges.

**Display formula**:
```dart
// Correct: cents → dollars for display
'\$${(priceCents / 100).toStringAsFixed(2)}'

// Model field naming convention:
int get subtotalDollars => subtotalCents ~/ 100;
```

**Example** (from `lib/models/generated/product_models.dart:105`):
```dart
@Freezed(toJson: true, fromJson: true)
abstract class Product with _$Product {
  const factory Product({
    required String productId,
    required int priceCents,  // Always integer cents
    int? compareAtPriceCents, // Sale price in cents
    // ...
  });
}
```

---

### 2. Image Compression: Sequential with compute() Isolates

**What**: Image compression uses `compute()` (Flutter isolates) per image, but images are compressed sequentially — NOT with `Future.wait`.

**Why**: On 8GB RAM Mac, running 5 image compressions in parallel via `Future.wait` + `compute()` spawns 5 isolates simultaneously, each allocating ~50MB for decoded image buffers. This causes OOM crashes. Sequential `compute()` keeps memory to one image at a time.

**Anti-pattern**: `Future.wait(images.map((img) => compute(compress, img)))` — crashes on 8GB.

**Example** (from `lib/utils/image_compression_utils.dart`):
```dart
Future<Uint8List?> validateAndCompressImage(Uint8List bytes) async {
  if (bytes.length > maxImageSize) {
    throw Exception('product.image_too_large'.tr());
  }
  return compute(compressImageIsolate, bytes);  // One isolate per call
}
```

**Note**: Product image upload helpers in `lib/features/products/product_image_helpers.dart` do use `Future.wait` for the upload step (I/O-bound, not CPU-bound). The distinction is: CPU-bound compression = sequential, I/O-bound upload = parallel.

---

### 3. setState → Riverpod Migration

**What**: All mutable UI state moved from `setState()` in screens to Riverpod `StateNotifier` providers.

**Why**: `setState()` couples state to widget lifecycle, making state sharing between widgets impossible and causing unnecessary full-widget rebuilds. Riverpod enables testability, dependency injection, and fine-grained rebuilds.

**Anti-pattern**: `setState(() { _isLoading = true; })` inside a screen. This was the pattern before migration — 92 instances eliminated.

**Example** (from `lib/features/home/home_viewmodel.dart`):
```dart
final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref);
});

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;
  HomeViewModel(this._ref) : super(const HomeState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    // ... fetch logic ...
    state = state.copyWith(isLoading: false, products: result.products);
  }
}
```

---

### 4. Freezed for All State Classes

**What**: All value types, API models, and ViewModel states use `@freezed` with code generation.

**Why**: Freezed provides immutability, `copyWith`, `==`/`hashCode`, `toString()`, and JSON serialization for free. Without it, we had manual `copyWith` methods with bugs (missing fields).

**Anti-pattern**: Plain Dart classes with manual `copyWith` and `fromJson` — error-prone and verbose.

**Sentinel copyWith pattern** (for nullable fields that can be explicitly set to null):
```dart
@freezed
abstract class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    String? couponCode,
    @Default(0) int couponDiscountCents,
    // ...
  }) = _CheckoutState;
}

// Usage:
state = state.copyWith(couponCode: null); // Explicitly clear coupon
```

**Example** (from `lib/features/home/home_state.dart`):
```dart
@freezed
abstract class HomeState with _$HomeState {
  const HomeState._();
  const factory HomeState({
    @Default([]) List<Product> products,
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default(SortOption.relevance) SortOption selectedSort,
    int? minPriceCents,
    int? maxPriceCents,
  }) = _HomeState;

  bool get hasPriceFilter => minPriceCents != null || maxPriceCents != null;
}
```

---

### 5. DesignTokens ONLY (No Colors.blue, No Theme.of(context).colorScheme)

**What**: All colors, spacing, typography, shadows, and animations defined in `DesignTokens` class. No inline color literals.

**Why**: Centralized design system prevents visual drift, enables dark mode support via `isDark` checks, and makes global theme changes a single-file edit.

**Anti-pattern**: `Color(0xFF2196F3)` or `Theme.of(context).colorScheme.primary` scattered across 200+ files.

**Example** (from `lib/utils/design_tokens.dart`):
```dart
class DesignTokens {
  static const Color primary = Color(0xFF7B93FF);
  static const Color error = Color(0xFFEF4444);
  static const double spacing16 = 16;
  static const double radius16 = 16;

  static LinearGradient backgroundGradient({required bool isDark}) {
    return LinearGradient(
      colors: isDark
          ? [darkBackground, darkSurface]
          : [const Color(0xFFF0F2FF), white],
    );
  }
}

// Usage in widgets:
Container(
  color: DesignTokens.surface,
  padding: const EdgeInsets.all(DesignTokens.spacing16),
  child: Text('Hello', style: TextStyle(color: DesignTokens.textPrimary)),
)
```

---

### 6. AppError for All Domain Errors

**What**: Centralized error handling via `AppError.getMessage()` and `AppError.log()`.

**Why**: Raw error messages leak stack traces and server internals. `AppError` sanitizes messages, adds error codes for support, and routes to Sentry.

**Error display rules**:
- **Transient errors** (network, timeout) → `SnackBar` (auto-dismiss)
- **Form validation errors** → inline text below the field
- **Fatal errors** → error screen with retry

**Example** (from `lib/utils/utils.dart:852`):
```dart
class AppError {
  static String getMessage(dynamic error, [String? fallback, String? code]) {
    if (error is OrignaBaseException) {
      rawMsg = error.message;  // Backend already sanitizes
    } else {
      rawMsg = fallback ?? 'errors.generic_error'.tr();
    }
    final displayCode = code ?? _inferCode(error);
    return displayCode != null ? '$rawMsg [$displayCode]' : rawMsg;
  }

  static void log(dynamic error, {StackTrace? stackTrace, String? context}) {
    AppLogger.e('[$context] $error', error: error, stackTrace: stackTrace);
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}

// Usage in ViewModel:
catch (e) {
  state = state.copyWith(
    errorMessage: AppError.getMessage(e, 'Failed to load products'),
  );
}

// Usage in Screen (SnackBar):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(AppError.getMessage(e))),
);
```

**Error codes** follow `ORIGNA-{DOMAIN}-{NUMBER}` format (defined in `lib/core/errors/error_codes.dart`).

---

### 7. Absolute Imports Only

**What**: All imports use `package:origna_gta/...` — never relative `../` paths.

**Why**: Relative imports break when files are moved. Absolute imports are stable and make the dependency graph immediately visible.

**Anti-pattern**: `import '../../utils/utils.dart'` — breaks on refactor.

**Example**:
```dart
// Correct
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/design_tokens.dart';

// Wrong
import '../core/providers.dart';
import '../../utils/design_tokens.dart';
```

---

### 8. Named Parameters for 3+ Param Functions

**What**: Functions with 3+ parameters use named parameters `{required ...}`.

**Why**: Prevents argument-order bugs. Self-documenting at call sites.

**Example** (from `lib/core/repositories/product_repository.dart`):
```dart
Future<ProductQueryResult> fetchProducts({
  String? searchQuery,
  int? categoryId,
  String? subcategory,
  String? lastDocumentId,
  int pageSize = 20,
  SortOption sortOption = SortOption.relevance,
  int? minPriceCents,
  int? maxPriceCents,
});
```

---

### 9. const Constructors Everywhere Possible

**What**: Use `const` constructors for widgets and value objects.

**Why**: Flutter's widget rebuild optimization relies on `const`. A `const` widget is never rebuilt if its parent rebuilds — Flutter skips the entire subtree.

**Example**:
```dart
const Padding(
  padding: EdgeInsets.all(DesignTokens.spacing16),
  child: Icon(Icons.search, color: DesignTokens.textSecondary),
)
```

---

### 10. Semantics Labels for agent-browser E2E

**What**: All interactive elements have `Semantics(label: 'btn-*')` or `tooltip:` for agent-browser selectors.

**Why**: E2E tests use `page.locator('[aria-label="btn-add-to-cart"]')` to find elements. Without semantic labels, tests use fragile CSS selectors or coordinates.

**Conventions**:
- Buttons: `Semantics(label: 'btn-action-name')`
- Inputs: `Semantics(label: 'input-field-name')`
- Navigation: `Semantics(label: 'nav-destination')`
- Product cards: `Semantics(label: 'product-card-{productId}')`

**Example** (from 276 usages across the codebase):
```dart
Semantics(
  label: 'btn-add-to-cart',
  child: ElevatedButton(
    onPressed: () => cartController.addItem(productId),
    child: Text('Add to Cart'),
  ),
)
```

---

## Module Map

| Path | Purpose | Key Files |
|------|---------|-----------|
| `lib/core/` | Foundation: providers, repositories, routing, schema constants | `providers.dart`, `routes.dart`, `orignabase_provider.dart` |
| `lib/core/repositories/` | Abstract repository interfaces + OrignaBase implementations | `auth_repository.dart`, `product_repository.dart`, `cart_repository.dart` |
| `lib/core/schema/` | Database field names, enums, business rules (single source of truth) | `schema_constants.dart` |
| `lib/core/errors/` | Standardized error codes (ORIGNA-*) | `error_codes.dart` |
| `lib/features/` | Feature-sliced MVVM modules (15 features) | `home/`, `products/`, `checkout/`, `orders/`, `cart/`, `chat/`, `admin/`, `seller/`, `auth/`, `profile/`, `subscription/`, `support/`, `qa/`, `notifications/`, `terms/` |
| `lib/screens/` | Screen widgets (thin UI layer) | `home_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`, `productdetails_screen.dart` |
| `lib/models/` | Data models (Freezed-generated + hand-written) | `generated/product_models.dart`, `generated/order_models.dart`, `models.dart` |
| `lib/services/` | Stateless services (notifications, analytics, session timeout) | `orignabase_notification_service.dart`, `session_timeout_service.dart` |
| `lib/widgets/` | Reusable UI components | `modern_product_card.dart`, `modern_button.dart`, `modern_card.dart` |
| `lib/utils/` | Utilities (design tokens, logging, compression, responsive) | `design_tokens.dart`, `app_logger.dart`, `env_config.dart`, `responsive_layout.dart` |
| `lib/previews/` | Widget previews for development | |

### Feature Module Structure

Each feature in `lib/features/{name}/` follows this pattern:
```
features/{name}/
├── {name}_state.dart          # @freezed state class
├── {name}_state.freezed.dart  # Generated
├── {name}_viewmodel.dart      # StateNotifier + provider
├── {name}_provider.dart       # Additional providers (if needed)
└── orignabase_{name}_*.dart   # OrignaBase-specific implementations
```

---

## Provider Patterns

### Provider Organization

- **Core providers** in `lib/core/providers.dart` — auth state, repositories, env config
- **Feature providers** co-located with their feature module in `lib/features/{name}/`
- **Cart/checkout providers** in their respective feature directories

### StateNotifier vs StateNotifierProvider

All ViewModels use `StateNotifierProvider.autoDispose`:

```dart
final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref);
});
```

`autoDispose` ensures state is cleared when no longer watched — prevents memory leaks on screen navigation.

### ref.watch vs ref.read Rules

| Context | Use | Rule |
|---------|-----|------|
| `build()` method | `ref.watch()` | Reactive — rebuilds when value changes |
| Event handlers (`onPressed`) | `ref.read()` | One-time read — no rebuild needed |
| ViewModel constructor | `ref.read()` | One-time dependency injection |
| Stream subscriptions | `ref.read()` | Inside callbacks, not reactive |

```dart
// Correct — reactive rebuild
Widget build(BuildContext context, WidgetRef ref) {
  final cart = ref.watch(cartItemsProvider);  // Rebuilds on cart change
}

// Correct — one-time read in action
void onCheckoutPressed(WidgetRef ref) {
  final cart = ref.read(cartItemsProvider);  // Snapshot, no rebuild
}

// Wrong — conditional watch in build
Widget build(BuildContext context, WidgetRef ref) {
  if (condition) {
    final x = ref.watch(someProvider);  // NEVER do this
  }
}
```

### StreamProvider for Real-time Data

Auth state and cart items use `StreamProvider` backed by OrignaBase subscriptions:

```dart
final authStateProvider = StreamProvider<AppAuthUser?>((ref) async* {
  final ob = ref.watch(orignabaseProvider);
  await for (final state in ob.auth.authStateChanges) {
    yield state.isAuthenticated ? AppAuthUser.fromAuthState(state) : null;
  }
});
```

---

## Service Layer

| Service | File | Purpose |
|---------|------|---------|
| `OrignaBaseNotificationService` | `services/orignabase_notification_service.dart` | Push notifications, deep link handling |
| `SessionTimeoutService` | `services/session_timeout_service.dart` | 15-min idle timeout, auto sign-out |
| `OrignaBaseAnalyticsService` | `services/orignabase_analytics_service.dart` | Event tracking (page views, purchases) |
| `OrignaBaseConfigService` | `services/orignabase_conf_service.dart` | Remote config (feature flags, keys) |
| `OrignaBaseDigitalService` | `services/orignabase_digital_service.dart` | Digital product license management |
| `TurnstileService` | `services/turnstile_service.dart` | Cloudflare Turnstile CAPTCHA (web-only) |

Services are stateless. They receive dependencies via constructor or `ref.read()` and never hold mutable state.

---

## Error Handling Pattern

### AppError Hierarchy

```
AppError.getMessage(error, fallback, code)
  ├── OrignaBaseException → backend message (sanitized)
  ├── OrignaBaseAuthException → generic "service unavailable"
  └── Other → fallback message (never leak internals)

AppError.log(error, stackTrace, context)
  ├── debugPrint (debug mode)
  └── Sentry.captureException (release mode)
```

### Error Display by Context

| Error Type | Display Method | Example |
|-----------|---------------|---------|
| Network timeout | SnackBar | "Network error. Check your connection. [ORIGNA-SYS-001]" |
| Cart validation | Inline card | "Prices have changed. Please review your cart. [ORIGNA-CART-004]" |
| Form validation | Inline text | Below the specific form field |
| Auth failure | SnackBar | "Incorrect password. [ORIGNA-AUTH-002]" |
| Checkout failure | Error state in button | "Card was declined. [ORIGNA-PAY-001]" |
| Fatal error | Error screen | Full-page with retry button |

---

## Testing Patterns

### Test Directory Structure

```
test/
├── unit/                    # ViewModel + Repository + Service tests (~181 files)
├── widget/                  # Widget tests
├── screen/                  # Screen integration tests
├── models/                  # Model serialization tests
├── live/                    # Live integration tests (real OrignaBase)
├── golden/                  # Golden file tests (run separately)
├── helpers/                 # Shared test utilities
└── test_utils.dart          # Common test setup
```

### Mock Patterns

Tests use `mockito` with `@GenerateMocks`:

```dart
@GenerateMocks([ProductRepository, CartRepository])
void main() {
  late MockProductRepository mockRepo;

  setUp(() {
    mockRepo = MockProductRepository();
  });

  test('should load products', () async {
    when(mockRepo.fetchProducts()).thenAnswer(
      (_) async => ProductQueryResult(products: [], hasMore: false),
    );
    // ...
  });
}
```

### Live vs Unit Test Separation

- **Unit tests** (`test/unit/`): Use mocks. Run with `flutter test --exclude-tags golden`.
- **Live tests** (`test/live/`): Hit real OrignaBase backend. Run separately.
- **Golden tests** (`test/golden/`): Visual regression. Run with `flutter test test/golden/`.

### Running Tests

```bash
# All unit + widget tests (excludes golden)
flutter test --exclude-tags golden

# Single test file
flutter test test/unit/auth_provider_test.dart

# Single test by name pattern
flutter test --name "should calculate subtotal correctly"

# With coverage
flutter test --coverage --reporter=compact --exclude-tags golden
```

---

## Anti-Patterns (NEVER Do These)

| Anti-Pattern | Correct Alternative |
|-------------|-------------------|
| `Colors.blue` or hex literals | `DesignTokens.primary` |
| `Theme.of(context).colorScheme.primary` | `DesignTokens.primary` |
| `setState()` in screens | Riverpod `StateNotifier` |
| `BuildContext` in ViewModels/Services | Pass data via providers |
| `double`/`float` for money | `int` cents (`priceCents`) |
| `print()` | `AppLogger.d()` / `AppLogger.e()` |
| `FirebaseAuth.instance` | OrignaBase SDK via `orignabaseProvider` |
| Relative imports (`../`) | `package:origna_gta/...` |
| Hardcoded strings/routes/field names | `schema_constants.dart` |
| `MediaQuery.of(context).size.width` for layout | `ResponsiveBreakpoints.*` |
| `Future.wait` for CPU-bound operations | Sequential with `compute()` isolates |
| Raw HTTP calls to backend | OrignaBase SDK methods |
| `StateProvider` for logic | `StateNotifierProvider` |
| Non-paginated data fetching | Always `limit` + `offset` / cursor |
| Ignoring `mounted` check after async | Always `if (!mounted) return;` |
| `flutter widget-preview start` | `./start-preview.sh` |
| Magic strings for endpoints | `CloudFunctionEndpoints.*` |
| Manual `copyWith` on state classes | `@freezed` code generation |
| Nullable params as positional (3+) | Named parameters `{required ...}` |

---

## Responsive Layout

Breakpoints defined in `lib/utils/responsive_layout.dart`:

| Breakpoint | Width | Columns | Use Case |
|-----------|-------|---------|----------|
| mobile | 320px | 1-2 | Small phones |
| mobilePlus | 480px | 2 | Medium phones |
| tablet | 768px | 3 | Tablets |
| desktop | 1024px | 4-5 | Desktop/web |
| desktopLg | 1280px | 5 | Large monitors |
| desktopXl | 1440px | 6 | Ultra-wide |

Use `ResponsiveLayout` widget or `ResponsiveBreakpoints.getValue()` for responsive values. Never raw `MediaQuery.of(context).size.width` comparisons.

---

## Environment Configuration

Environments are compile-time constants passed via `--dart-define=ENVIRONMENT=dev`:

| Environment | Frontend URL | Backend URL |
|------------|-------------|-------------|
| emulator | `http://localhost:5001` | `http://localhost:8080` |
| dev | `https://dev.orignagta.ca` | `https://api.dev.orignagta.ca` |
| staging | `https://staging.orignagta.ca` | `https://api.staging.orignagta.ca` |
| production | `https://orignagta.ca` | `https://api.orignagta.ca` |

Config singleton: `EnvConfig()` in `lib/utils/env_config.dart`. The `orignabaseProvider` reads `EnvConfig.orignabaseUrl` to initialize the SDK client.

---

## Code Generation

Freezed and json_serializable models require code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Generated files:
- `*.freezed.dart` — immutable classes, copyWith, ==, hashCode
- `*.g.dart` — JSON serialization

**Never edit generated files manually.** Re-run build_runner after changing `@freezed` or `@JsonSerializable` annotations.
