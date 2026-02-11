import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

import 'home_state.dart';

final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref);
});

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;
  Timer? _debounce;

  HomeViewModel(this._ref) : super(HomeState()) {
    loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadProducts() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final isInitialLoad = state.products.isEmpty;

    if (isInitialLoad) {
      if (!mounted) return; // Check mounted before state change
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      if (!mounted) return; // Check mounted before state change
      state = state.copyWith(isLoadingMore: true, errorMessage: null);
    }

    try {
      final repository = _ref.read(productRepositoryProvider);
      
      // Log which repository is being used
      if (kDebugMode) {
        final repoType = repository.runtimeType.toString();
        debugPrint('🔍 Using repository: $repoType');
        if (state.searchQuery.isNotEmpty) {
          debugPrint('   Search query: "${state.searchQuery}"');
        }
        if (state.selectedCategoryId != null) {
          debugPrint('   Category filter: ${state.selectedCategoryId}');
        }
      }
      
      final result = await repository.fetchProducts(
        searchQuery: state.searchQuery,
        categoryId: state.selectedCategoryId,
        lastDocument: state.lastDocument,
      );

      if (kDebugMode) debugPrint('✅ Loaded ${result.products.length} products');

      if (!mounted) return; // Check mounted after async operation

      // If initial load returned 0 products, force hasMore=false to prevent
      // scroll-triggered reload loops (shimmer flicker bug)
      final effectiveHasMore = (isInitialLoad && result.products.isEmpty)
          ? false
          : result.hasMore;

      // Deduplicate: filter out products already present (by productId)
      final existingIds = state.products.map((p) => p.productId).toSet();
      final newProducts = result.products
          .where((p) => !existingIds.contains(p.productId))
          .toList();

      state = state.copyWith(
        products: isInitialLoad ? result.products : [...state.products, ...newProducts],
        lastDocument: result.lastDocument ?? state.lastDocument,
        hasMore: effectiveHasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading products: $e');
      if (!mounted) return; // Check mounted after async operation
      // On error with empty products, set hasMore=false to prevent infinite
      // scroll-triggered retry loops. Category/search changes reset hasMore.
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: AppError.getMessage(e, 'Failed to load products'),
        hasMore: state.products.isEmpty ? false : state.hasMore,
      );
    }
  }

  void onCategorySelected(int? categoryId) {
    if (!mounted) return;
    state = state.copyWith(
      selectedCategoryId: categoryId,
      products: [],
      lastDocument: null,
      hasMore: true,
      isLoading: false,
      isLoadingMore: false,
      errorMessage: null,
    );
    loadProducts();
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(
        searchQuery: value,
        products: [],
        lastDocument: null,
        hasMore: true,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: null,
      );
      loadProducts();
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(products: [], lastDocument: null, hasMore: true);
    await loadProducts();
  }
}
