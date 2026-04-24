import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

part 'home_state.freezed.dart';

// ignore_for_file: unused_element

@freezed
abstract class HomeState with _$HomeState {
  const HomeState._();

  const factory HomeState({
    @Default([]) List<Product> products,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    String? lastDocumentId,
    @Default('') String searchQuery,
    int? selectedCategoryId,
    String? selectedSubcategory,
    String? errorMessage,

    // GAP #1 — Sort
    @Default(SortOption.relevance) SortOption selectedSort,

    // GAP #2 — Price range filter (null = no filter applied)
    int? minPriceCents,
    int? maxPriceCents,

    // GAP #7 — Recent searches (persisted in SharedPreferences)
    @Default([]) List<String> recentSearches,

    // GAP #7 — Search autocomplete suggestions (transient, not persisted)
    @Default([]) List<String> searchSuggestions,

    // GAP #7 — Whether the search overlay is visible
    @Default(false) bool showSearchOverlay,

    // Made-in-Canada toggle: client-side filter for products whose origin is Canada
    @Default(false) bool canadaOnly,
  }) = _HomeState;

  /// Whether a price range filter is currently active.
  bool get hasPriceFilter => minPriceCents != null || maxPriceCents != null;

  static bool _isCanadaOrigin(String? value) {
    final normalized = value?.trim().toUpperCase();
    return normalized == 'CA' || normalized == 'CANADA';
  }

  /// Returns products filtered by the made-in-Canada toggle (client-side).
  List<Product> get displayedProducts {
    if (!canadaOnly) return products;
    return products.where((p) => _isCanadaOrigin(p.madeInCountry)).toList();
  }
}
