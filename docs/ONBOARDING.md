# OrignaGTA Developer Onboarding Guide

> **Time to first PR**: ~30 minutes
> **Prerequisites**: macOS or Linux, Git, basic Flutter/Dart knowledge

---

## What You're Building

OrignaGTA is a **Canada-first multi-vendor e-commerce platform** — think Etsy meets Shopify, but built for Canadian sellers and buyers with:

- **Multi-seller orders**: One checkout, multiple sellers, split payouts
- **Digital products**: Software licenses and ebooks
- **Local delivery**: 50km radius for same-day shipping
- **Bilingual**: English + French (Quebec Bill 96 compliance)
- **Modern stack**: Flutter + Rust (OrignaBase) + PostgreSQL

---

## 30-Minute Setup

### 1. Clone and Verify (5 min)

```bash
# Clone the monorepo
git clone https://github.com/yunior123/origna_gta.git
cd origna_gta

# Verify Flutter
cd origna_gta
flutter --version  # Requires Flutter 3.x stable

# Run static analysis (catches errors fast)
flutter analyze --no-fatal-infos
```

**What just happened?**
- The repo is a monorepo: `origna_gta/` (Flutter), `orignabase/` (Rust backend), `e2e/` (Playwright tests)
- `flutter analyze` checks for compile errors, unused imports, and style violations
- `--no-fatal-infos` treats warnings as non-fatal (stricter than default)

### 2. Install Dependencies (5 min)

```bash
# Flutter dependencies
flutter pub get

# Generate Freezed models (immutable data classes)
flutter pub run build_runner build --delete-conflicting-outputs

# Verify tests pass
flutter test --exclude-tags golden
```

**What just happened?**
- `flutter pub get` downloads all Dart packages from `pubspec.yaml`
- `build_runner` generates `*.freezed.dart` and `*.g.dart` files from model annotations
- Tests run against mocked SDK — no backend needed

### 3. Run the App (5 min)

```bash
# Development environment (emulator backend)
flutter run --dart-define=ENVIRONMENT=emulator

# Or for web (Chrome)
flutter run -d chrome --dart-define=ENVIRONMENT=emulator
```

**What you should see:**
- Dark-themed home screen with product grid
- Environment banner showing "EMULATOR" (dev/staging only)
- Bottom navigation: Home, Search, Cart, Favorites, Profile

### 4. Explore the Architecture (10 min)

Open these files in order — they're your mental model:

#### 1. Entry Point: `lib/main.dart`

```dart
// Key sections:
// - Line 60: usePathUrlStrategy() — clean URLs without #
// - Line 82-87: Semantics forcing for E2E accessibility testing
// - Line 90: OrignaBase SDK initialization
// - Line 107-114: EasyLocalization + ProviderScope wrapper
```

**Key insight**: The app renders immediately (line 107), then fetches config in background (line 118). This prevents white-screen on slow networks.

#### 2. App Shell: `lib/origna_app.dart`

```dart
// Key components:
// - OrignaApp: Root widget with theme, routing, localization
// - Router: GoRouter configuration in lib/core/routes.dart
// - Theme: DesignTokens in lib/utils/design_tokens.dart
```

#### 3. State Management: `lib/core/providers.dart`

```dart
// Riverpod providers live here:
// - authProvider: Current user state
// - themeProvider: Dark/light mode
// - cartProvider: Shopping cart state
```

#### 4. A Screen + ViewModel: `lib/screens/home_screen.dart`

```dart
// Screens are UI-only. Business logic is in ViewModels.
// This screen:
// - Watches productsProvider for product list
// - Renders ModernProductCard widgets
// - Handles pull-to-refresh
```

### 5. Understand the Layer Cake (5 min)

```
┌─────────────────────────────────────────────────────────┐
│                     SCREENS (UI)                         │
│  Widgets, layouts, user interactions                    │
│  lib/screens/*_screen.dart                              │
├─────────────────────────────────────────────────────────┤
│                   VIEWMODELS (State)                     │
│  Business logic, state management, side effects         │
│  lib/features/*/viewmodel.dart                          │
│  Uses Riverpod AsyncNotifier/StateNotifier              │
├─────────────────────────────────────────────────────────┤
│                   SERVICES (Logic)                       │
│  Platform integrations, API wrappers, analytics         │
│  lib/services/*_service.dart                            │
├─────────────────────────────────────────────────────────┤
│                  REPOSITORIES (Data)                     │
│  Data access, CRUD operations, query builders           │
│  lib/core/repositories/*_repository.dart                │
├─────────────────────────────────────────────────────────┤
│                ORIGNABASE SDK (Network)                  │
│  GraphQL/REST communication, caching, realtime          │
│  orignabase/sdks/flutter/orignabase/                    │
└─────────────────────────────────────────────────────────┘
```

**Critical rule**: Data flows **down** (via providers), events flow **up** (via callbacks). Never call services directly from screens.

---

## Your First PR: Add a "New" Badge

Let's add a badge that shows "NEW" for products created in the last 7 days.

### Step 1: Find the Widget

Products are displayed in `ModernProductCard`:

```bash
# Find the widget
lib/widgets/modern_product_card.dart
```

### Step 2: Read the Code

```dart
// lib/widgets/modern_product_card.dart (simplified)
class ModernProductCard extends ConsumerWidget {
  final Product product;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernCard(
      child: Column(
        children: [
          _ProductImage(product: product),
          _ProductInfo(product: product),
          _ProductPrice(product: product),
        ],
      ),
    );
  }
}
```

### Step 3: Add the Badge Logic

```dart
// Add at top of file
import 'package:origna_gta/utils/design_tokens.dart';

// Add helper function
bool _isNewProduct(Product product) {
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  return product.createdAt.isAfter(sevenDaysAgo);
}

// Modify build method
Widget build(BuildContext context, WidgetRef ref) {
  return ModernCard(
    child: Stack(
      children: [
        Column(
          children: [
            _ProductImage(product: product),
            _ProductInfo(product: product),
            _ProductPrice(product: product),
          ],
        ),
        if (_isNewProduct(product))
          Positioned(
            top: DesignTokens.spacing8,
            left: DesignTokens.spacing8,
            child: _NewBadge(),
          ),
      ],
    ),
  );
}

// Add badge widget
class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing8,
        vertical: DesignTokens.spacing4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          color: DesignTokens.textOnPrimary,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

### Step 4: Test It

```bash
# Create test file
touch test/widget/modern_product_card_new_badge_test.dart
```

```dart
// test/widget/modern_product_card_new_badge_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/widgets/modern_product_card.dart';
import 'package:origna_gta/models/models.dart';

void main() {
  group('_isNewProduct', () {
    test('returns true for product created yesterday', () {
      final product = Product(
        id: 'test',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(_isNewProduct(product), isTrue);
    });

    test('returns false for product created 8 days ago', () {
      final product = Product(
        id: 'test',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(_isNewProduct(product), isFalse);
    });
  });
}
```

```bash
# Run the test
flutter test test/widget/modern_product_card_new_badge_test.dart

# Run all tests to ensure nothing broke
flutter test --exclude-tags golden
```

### Step 5: Check Quality

```bash
# Static analysis
flutter analyze --no-fatal-infos

# Expected: No issues found
```

### Step 6: Commit

```bash
git add lib/widgets/modern_product_card.dart test/widget/modern_product_card_new_badge_test.dart
git commit -m "feat: add NEW badge for products created within 7 days

- Add _isNewProduct helper to check product age
- Add _NewBadge widget styled with DesignTokens
- Add unit tests for badge visibility logic
- Use DesignTokens.primary for badge color (no hardcoded colors)"
```

---

## Common Patterns You'll See

### 1. Money Handling (Integer Cents)

```dart
// ❌ NEVER do this
double price = 75.00;  // Floating point errors!

// ✅ ALWAYS do this
int priceCents = 7500;  // $75.00

// Display
Text('\$${(priceCents / 100).toStringAsFixed(2)}')  // "$75.00"

// Arithmetic
int totalCents = subtotalCents + shippingCents + taxCents;
```

**Why?** Floating point math is imprecise. `0.1 + 0.2 != 0.3` in IEEE 754. Cents avoid this.

### 2. Design Tokens (No Magic Colors)

```dart
// ❌ NEVER do this
Container(color: Colors.blue)
Container(color: Color(0xFF7B93FF))

// ✅ ALWAYS do this
Container(color: DesignTokens.primary)
Container(color: DesignTokens.error)
```

**Why?** Design changes in one file (`design_tokens.dart`) propagate everywhere.

### 3. Schema Constants (No Magic Strings)

```dart
// ❌ NEVER do this
db.collection('products').where('priceCents', '>', 1000)

// ✅ ALWAYS do this
db.collection(Collections.products)
  .where(Fields.priceCents, '>', 1000)
```

**Why?** Typos like `'priceCentz'` fail at runtime. `Fields.priceCents` fails at compile time.

### 4. Error Handling

```dart
// In ViewModel
try {
  await repository.fetchProducts();
} catch (e, st) {
  AppError.log(e, stackTrace: st, context: 'ProductViewModel.fetch');
  state = AsyncValue.error(
    AppError.getMessage(e, 'products.fetch_error'.tr()),
    st,
  );
}

// In Screen (automatically handled by AsyncValue)
ref.watch(productsProvider).when(
  data: (products) => ProductList(products),
  loading: () => LoadingIndicator(),
  error: (e, st) => ErrorWidget(message: e.toString()),
)
```

### 5. Riverpod Provider Pattern

```dart
// Provider definition
final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

// Notifier implementation
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    // Initial load
    return _fetchProducts();
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }
  
  Future<List<Product>> _fetchProducts() async {
    final repo = ref.read(productRepositoryProvider);
    return repo.fetchProducts();
  }
}

// Usage in widget
class ProductList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    
    return productsAsync.when(
      data: (products) => ListView(children: products),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

---

## Testing Strategy

### Test Pyramid

```
         ┌─────────┐
         │   E2E   │  ← 114 Playwright specs (full flows)
         │  (slow) │
         ├─────────┤
       ┌─┴─────────┴─┐
       │ Integration │  ← 30 live tests (real backend)
       │   (medium)  │
       ├─────────────┤
     ┌─┴─────────────┴─┐
     │    Widget       │  ← 67 widget tests (UI behavior)
     │    (fast)       │
     ├─────────────────┤
   ┌─┴─────────────────┴─┐
   │       Unit          │  ← 131 unit tests (logic only)
   │     (fastest)       │
   └─────────────────────┘
```

### Running Tests

```bash
# Unit tests (fast, mocked)
flutter test test/unit/

# Widget tests (fast, mocked)
flutter test test/widget/

# Integration tests (slow, real backend)
flutter test test/live/ --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true

# E2E tests (slow, full app)
cd e2e-agent-browser && bun test specs/phase1-api/

# Pre-commit check
flutter analyze --no-fatal-infos && flutter test --exclude-tags golden
```

### Test Naming Convention

```dart
void main() {
  group('ProductRepository', () {
    group('fetchProducts', () {
      test('returns products when successful', () {});
      test('throws AppError when network fails', () {});
      test('returns empty list when no products exist', () {});
    });
    
    group('createProduct', () {
      test('creates product with valid data', () {});
      test('throws ValidationError when price is negative', () {});
      test('throws AuthError when user is not seller', () {});
    });
  });
}
```

---

## Project Conventions

### File Organization

```
lib/
├── core/           # Shared infrastructure
│   ├── constants/  # Validation limits, magic numbers
│   ├── errors/     # AppError types
│   ├── providers/  # Global Riverpod providers
│   ├── repositories/ # Data access layer
│   ├── routes.dart # GoRouter configuration
│   └── schema/     # schema_constants.dart (field names)
│
├── features/       # Feature-scoped logic
│   ├── auth/       # Login, register, MFA
│   ├── cart/       # Cart state, add/remove
│   ├── checkout/   # Payment, shipping
│   ├── orders/     # Order list, detail, tracking
│   ├── products/   # Product CRUD, search
│   ├── profile/    # User settings, addresses
│   └── seller/     # Seller dashboard, products
│
├── models/         # Freezed data models
├── screens/        # UI screens (Widgets only!)
├── services/       # Platform integrations
├── utils/          # Helpers, design tokens
└── widgets/        # Shared UI components
```

### Import Order (Mandatory)

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. External packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 4. Project imports (absolute package paths, NEVER relative)
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/design_tokens.dart';
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `ProductRepository` |
| Files | snake_case | `product_repository.dart` |
| Variables | camelCase | `productList`, `subtotalCents` |
| Constants | camelCase | `freeShippingThresholdCents` |
| Private members | _prefix | `_fetchProducts()`, `_productList` |
| Providers | xxxProvider | `productsProvider` |

---

## Next Steps

### Recommended Reading Order

1. [Architecture Reference](./ARCHITECTURE.md) — Deep dive into the system
2. [Design Tokens Reference](./reference/design-tokens.md) — UI constants
3. [Schema Constants Reference](./reference/schema-constants.md) — Database field names
4. [Testing Guide](./testing/TEST_STRATEGY.md) — Write your first test

### Hands-On Tutorials

1. [Add a New Screen](./how-to/add-screen.md)
2. [Add a New Widget](./how-to/add-widget.md)
3. [Implement a New ViewModel](./how-to/add-viewmodel.md)
4. [Handle Errors Properly](./how-to/error-handling.md)

### Ask for Help

- **Slack**: #orignagta-dev
- **GitHub Issues**: [origna_gta/issues](https://github.com/yunior123/origna_gta/issues)
- **Code Review**: Tag @yunior123 on PRs

---

## Troubleshooting

### "Flutter analyze shows errors"

Run `flutter pub get` and `flutter pub run build_runner build --delete-conflicting-outputs`.

### "Tests fail with 'No implementation found'"

Mock is missing. Add `@GenerateMocks([ClassName])` and run build_runner.

### "App shows white screen on launch"

Check browser console for errors. Common cause: missing `--dart-define=ENVIRONMENT=emulator`.

### "Cannot connect to backend"

Ensure OrignaBase is running on `localhost:8080` for emulator mode.

---

## Checklist: Ready to Code

Before your first PR, verify:

- [ ] `flutter analyze --no-fatal-infos` passes
- [ ] `flutter test --exclude-tags golden` passes
- [ ] You've read ARCHITECTURE.md
- [ ] You've read CLAUDE.md (AI agent rules)
- [ ] You understand the MVVM pattern
- [ ] You know where to find DesignTokens and SchemaConstants

---

*Last updated: 2026-03-25 | Questions? Ask in Slack #orignagta-dev*
