import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/models/generated/models.dart';

/// Sentinel used to distinguish "not passed" from "explicitly set to null".
class _Sentinel {
  const _Sentinel();
}

class HomeState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String searchQuery;
  final int? selectedCategoryId;
  final String? selectedSubcategory;
  final String? errorMessage;

  HomeState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocument,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedSubcategory,
    this.errorMessage,
  });

  HomeState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? lastDocument = const _Sentinel(),
    String? searchQuery,
    Object? selectedCategoryId = const _Sentinel(),
    Object? selectedSubcategory = const _Sentinel(),
    Object? errorMessage = const _Sentinel(),
  }) {
    return HomeState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument is _Sentinel
          ? this.lastDocument
          : lastDocument as DocumentSnapshot?,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId is _Sentinel
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      selectedSubcategory: selectedSubcategory is _Sentinel
          ? this.selectedSubcategory
          : selectedSubcategory as String?,
      errorMessage: errorMessage is _Sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
