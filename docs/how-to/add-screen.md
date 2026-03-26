# How-to: Add a New Screen

> **Time**: ~30 minutes
> **Difficulty**: Intermediate
> **Prerequisites**: Understanding of MVVM, Riverpod basics

---

## Overview

This guide walks through adding a complete new screen with:
1. Screen widget (UI)
2. ViewModel (state + logic)
3. Repository integration
4. Routing
5. Tests

---

## Example: Add a "Wishlist" Screen

We'll create a screen that displays the user's wishlist with pagination.

---

## Step 1: Create the State Model

Define the state in a separate file for testability.

### `lib/features/wishlist/wishlist_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:origna_gta/models/models.dart';

part 'wishlist_state.freezed.dart';

@freezed
class WishlistState with _$WishlistState {
  const factory WishlistState({
    required List<Product> products,
    required bool isLoading,
    required bool hasMore,
    required String? errorMessage,
  }) = _WishlistState;

  factory WishlistState.initial() => const WishlistState(
    products: [],
    isLoading: false,
    hasMore: true,
    errorMessage: null,
  );
}
```

---

## Step 2: Create the ViewModel

### `lib/features/wishlist/wishlist_viewmodel.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/wishlist/wishlist_state.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/app_error.dart';
import 'package:orignabase/orignabase.dart';

/// Provider for the wishlist viewmodel
final wishlistViewModelProvider =
    StateNotifierProvider<WishlistViewModel, WishlistState>(
  WishlistViewModel.new,
);

class WishlistViewModel extends StateNotifier<WishlistState> {
  WishlistViewModel(this.ref) : super(WishlistState.initial());

  final Ref ref;
  String? _lastDocumentId;

  /// Load initial wishlist
  Future<void> load() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = ref.read(authProvider).value?.uid;
      if (userId == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Not logged in');
        return;
      }

      final ob = ref.read(orignabaseProvider);
      final result = await _fetchWishlist(ob, userId);

      state = WishlistState(
        products: result.products,
        isLoading: false,
        hasMore: result.hasMore,
        errorMessage: null,
      );

      if (result.products.isNotEmpty) {
        _lastDocumentId = result.products.last.id;
      }
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'WishlistViewModel.load');
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'wishlist.load_failed'.tr()),
      );
    }
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final userId = ref.read(authProvider).value?.uid;
      if (userId == null) return;

      final ob = ref.read(orignabaseProvider);
      final result = await _fetchWishlist(
        ob,
        userId,
        startAfterId: _lastDocumentId,
      );

      state = state.copyWith(
        products: [...state.products, ...result.products],
        isLoading: false,
        hasMore: result.hasMore,
      );

      if (result.products.isNotEmpty) {
        _lastDocumentId = result.products.last.id;
      }
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'WishlistViewModel.loadMore');
      // Don't fail the whole list for pagination error
      state = state.copyWith(isLoading: false);
    }
  }

  /// Remove from wishlist
  Future<void> remove(String productId) async {
    final previousProducts = state.products;

    // Optimistic update
    state = state.copyWith(
      products: state.products.where((p) => p.id != productId).toList(),
    );

    try {
      final userId = ref.read(authProvider).value?.uid;
      if (userId == null) return;

      final ob = ref.read(orignabaseProvider);
      await ob
          .collection(Collections.users)
          .doc(userId)
          .collection(Collections.favorites)
          .where(Fields.productId, '==', productId)
          .get()
          .then((snapshot) {
            for (final doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e, st) {
      // Rollback on failure
      state = state.copyWith(products: previousProducts);
      AppError.log(e, stackTrace: st, context: 'WishlistViewModel.remove');
      rethrow;
    }
  }

  /// Refresh wishlist
  Future<void> refresh() async {
    _lastDocumentId = null;
    state = WishlistState.initial();
    await load();
  }

  Future<_WishlistResult> _fetchWishlist(
    OrignaBase ob,
    String userId, {
    String? startAfterId,
  }) async {
    const pageSize = BusinessRules.favoritesPageSize;

    var query = ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.favorites)
        .orderBy(Fields.dateFavorited, descending: true)
        .limit(pageSize + 1);

    if (startAfterId != null) {
      query = query.startAfterId(startAfterId);
    }

    final snapshot = await query.get();

    final hasMore = snapshot.docs.length > pageSize;
    final docsToProcess = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

    final products = <Product>[];
    for (final doc in docsToProcess) {
      final productId = doc.data()[Fields.productId] as String;
      final productDoc = await ob
          .collection(Collections.products)
          .doc(productId)
          .get();
      if (productDoc.exists) {
        products.add(Product.fromMap(productDoc.data()!, id: productDoc.id));
      }
    }

    return _WishlistResult(products: products, hasMore: hasMore);
  }
}

class _WishlistResult {
  final List<Product> products;
  final bool hasMore;

  _WishlistResult({required this.products, required this.hasMore});
}
```

---

## Step 3: Create the Screen

### `lib/screens/wishlist_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/wishlist/wishlist_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_appbar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_card.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/animations.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load wishlist on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(wishlistViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'wishlist.title'.tr(),
        actions: [
          if (state.products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(wishlistViewModelProvider.notifier).refresh(),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildBody(WishlistState state, bool isDark) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: ModernLoadingIndicator());
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return _buildError(state.errorMessage!);
    }

    if (state.products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductList(state, isDark);
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.error,
            ),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: DesignTokens.fontSizeMd,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),
            ModernButton(
              label: 'Retry',
              onPressed: () =>
                  ref.read(wishlistViewModelProvider.notifier).load(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: DesignTokens.textTertiary,
            ),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              'wishlist.empty_title'.tr(),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              'wishlist.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: DesignTokens.fontSizeMd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(WishlistState state, bool isDark) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(wishlistViewModelProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return const Padding(
              padding: EdgeInsets.all(DesignTokens.spacing16),
              child: Center(child: ModernLoadingIndicator()),
            );
          }

          final product = state.products[index];
          return AnimatedListItem(
            index: index,
            child: _WishlistItem(
              product: product,
              onRemove: () => _removeProduct(product.id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeProduct(String productId) async {
    try {
      await ref.read(wishlistViewModelProvider.notifier).remove(productId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wishlist.removed'.tr()),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Re-add to favorites
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wishlist.remove_failed'.tr())),
        );
      }
    }
  }
}

class _WishlistItem extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;

  const _WishlistItem({
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            child: Image.network(
              product.imageUrls.firstOrNull ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: DesignTokens.surfaceVariant,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  '\$${(product.priceCents / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
            tooltip: 'Remove',
            color: DesignTokens.error,
          ),
        ],
      ),
    );
  }
}
```

---

## Step 4: Add Routing

### Update `lib/core/routes.dart`

```dart
// Add to the routes list
GoRoute(
  path: '/wishlist',
  name: 'wishlist',
  builder: (context, state) => const WishlistScreen(),
),
```

---

## Step 5: Add Translations

### Update `assets/translations/en.json`

```json
{
  "wishlist": {
    "title": "Wishlist",
    "empty_title": "Your wishlist is empty",
    "empty_subtitle": "Save products you love by tapping the heart icon",
    "removed": "Removed from wishlist",
    "remove_failed": "Failed to remove from wishlist",
    "load_failed": "Failed to load wishlist"
  }
}
```

### Update `assets/translations/fr.json`

```json
{
  "wishlist": {
    "title": "Liste de souhaits",
    "empty_title": "Votre liste de souhaits est vide",
    "empty_subtitle": "Enregistrez les produits que vous aimez en appuyant sur l'icône cœur",
    "removed": "Supprimé de la liste de souhaits",
    "remove_failed": "Échec de la suppression de la liste de souhaits",
    "load_failed": "Échec du chargement de la liste de souhaits"
  }
}
```

---

## Step 6: Write Tests

### `test/unit/wishlist_viewmodel_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/wishlist/wishlist_viewmodel.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/models.dart';

class MockAuth extends Mock implements AsyncNotifier<User?> {
  @override
  AsyncValue<User?> get state => AsyncValue.data(User(id: 'test-user'));
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => MockAuth()),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('WishlistViewModel', () {
    test('initial state is correct', () {
      final state = container.read(wishlistViewModelProvider);
      expect(state.products, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('load() fetches products', () async {
      // Add integration test for actual data fetching
    });

    test('remove() removes product from list', () async {
      // Add test for removal
    });
  });
}
```

---

## Step 7: Verify

```bash
# Static analysis
flutter analyze --no-fatal-infos

# Run tests
flutter test test/unit/wishlist_viewmodel_test.dart

# Run app
flutter run --dart-define=ENVIRONMENT=emulator

# Navigate to /wishlist and verify:
# - Empty state shows correctly
# - Loading state shows
# - Products display
# - Scroll pagination works
# - Remove works
# - Refresh works
# - Dark mode adapts
```

---

## Checklist

Before submitting PR:

- [ ] State uses freezed
- [ ] ViewModel uses schema constants (no magic strings)
- [ ] Screen uses DesignTokens (no magic colors/spacing)
- [ ] Semantic labels added for E2E
- [ ] Error handling with AppError
- [ ] Loading states handled
- [ ] Empty state handled
- [ ] Dark mode supported
- [ ] Translations added (EN + FR)
- [ ] Tests written
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

---

*Last updated: 2026-03-25*
