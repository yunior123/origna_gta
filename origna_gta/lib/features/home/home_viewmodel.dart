import 'dart:async';
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

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(searchQuery: value, products: [], lastDocument: null, hasMore: true);
      loadProducts();
    });
  }

  void onCategorySelected(int? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId, products: [], lastDocument: null, hasMore: true);
    loadProducts();
  }

  Future<void> refresh() async {
    state = state.copyWith(products: [], lastDocument: null, hasMore: true);
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final isInitialLoad = state.products.isEmpty;
    
    if (isInitialLoad) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoadingMore: true, errorMessage: null);
    }

    try {
      final repository = _ref.read(productRepositoryProvider);
      final result = await repository.fetchProducts(
        searchQuery: state.searchQuery,
        categoryId: state.selectedCategoryId,
        lastDocument: state.lastDocument,
      );

      state = state.copyWith(
        products: isInitialLoad ? result.products : [...state.products, ...result.products],
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, errorMessage: e.toString());
    }
  }
}
