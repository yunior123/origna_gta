import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';

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
        print('🔍 Using repository: $repoType');
        if (state.searchQuery.isNotEmpty) {
          print('   Search query: "${state.searchQuery}"');
        }
        if (state.selectedCategoryId != null) {
          print('   Category filter: ${state.selectedCategoryId}');
        }
      }
      
      final result = await repository.fetchProducts(
        searchQuery: state.searchQuery,
        categoryId: state.selectedCategoryId,
        lastDocument: state.lastDocument,
      );

      if (kDebugMode) print('✅ Loaded ${result.products.length} products');

      if (!mounted) return; // Check mounted after async operation
      state = state.copyWith(
        products: isInitialLoad ? result.products : [...state.products, ...result.products],
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading products: $e');
      if (!mounted) return; // Check mounted after async operation
      state = state.copyWith(isLoading: false, isLoadingMore: false, errorMessage: e.toString());
    }
  }

  void onCategorySelected(int? categoryId) {
    if (!mounted) return;
    state = state.copyWith(selectedCategoryId: categoryId, products: [], lastDocument: null, hasMore: true);
    loadProducts();
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(searchQuery: value, products: [], lastDocument: null, hasMore: true);
      loadProducts();
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(products: [], lastDocument: null, hasMore: true);
    await loadProducts();
  }
}
