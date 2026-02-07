import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/models/generated/models.dart';

class HomeState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String searchQuery;
  final int? selectedCategoryId;
  final String? errorMessage;

  HomeState({
    this.products = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocument,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.errorMessage,
  });

  HomeState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    int? selectedCategoryId,
    String? errorMessage,
  }) {
    return HomeState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument, // Note: Always use the new one or null
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId, // Note: Explicitly passed
      errorMessage: errorMessage,
    );
  }
}
