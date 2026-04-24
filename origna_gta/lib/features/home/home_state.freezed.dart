// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {

 List<Product> get products; bool get isLoading; bool get isLoadingMore; bool get hasMore; String? get lastDocumentId; String get searchQuery; int? get selectedCategoryId; String? get selectedSubcategory; String? get errorMessage;// GAP #1 — Sort
 SortOption get selectedSort;// GAP #2 — Price range filter (null = no filter applied)
 int? get minPriceCents; int? get maxPriceCents;// GAP #7 — Recent searches (persisted in SharedPreferences)
 List<String> get recentSearches;// GAP #7 — Search autocomplete suggestions (transient, not persisted)
 List<String> get searchSuggestions;// GAP #7 — Whether the search overlay is visible
 bool get showSearchOverlay;// Made-in-Canada toggle: client-side filter for products whose origin is Canada
 bool get canadaOnly;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&const DeepCollectionEquality().equals(other.products, products)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.lastDocumentId, lastDocumentId) || other.lastDocumentId == lastDocumentId)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.selectedSubcategory, selectedSubcategory) || other.selectedSubcategory == selectedSubcategory)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.selectedSort, selectedSort) || other.selectedSort == selectedSort)&&(identical(other.minPriceCents, minPriceCents) || other.minPriceCents == minPriceCents)&&(identical(other.maxPriceCents, maxPriceCents) || other.maxPriceCents == maxPriceCents)&&const DeepCollectionEquality().equals(other.recentSearches, recentSearches)&&const DeepCollectionEquality().equals(other.searchSuggestions, searchSuggestions)&&(identical(other.showSearchOverlay, showSearchOverlay) || other.showSearchOverlay == showSearchOverlay)&&(identical(other.canadaOnly, canadaOnly) || other.canadaOnly == canadaOnly));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(products),isLoading,isLoadingMore,hasMore,lastDocumentId,searchQuery,selectedCategoryId,selectedSubcategory,errorMessage,selectedSort,minPriceCents,maxPriceCents,const DeepCollectionEquality().hash(recentSearches),const DeepCollectionEquality().hash(searchSuggestions),showSearchOverlay,canadaOnly);

@override
String toString() {
  return 'HomeState(products: $products, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, lastDocumentId: $lastDocumentId, searchQuery: $searchQuery, selectedCategoryId: $selectedCategoryId, selectedSubcategory: $selectedSubcategory, errorMessage: $errorMessage, selectedSort: $selectedSort, minPriceCents: $minPriceCents, maxPriceCents: $maxPriceCents, recentSearches: $recentSearches, searchSuggestions: $searchSuggestions, showSearchOverlay: $showSearchOverlay, canadaOnly: $canadaOnly)';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 List<Product> products, bool isLoading, bool isLoadingMore, bool hasMore, String? lastDocumentId, String searchQuery, int? selectedCategoryId, String? selectedSubcategory, String? errorMessage, SortOption selectedSort, int? minPriceCents, int? maxPriceCents, List<String> recentSearches, List<String> searchSuggestions, bool showSearchOverlay, bool canadaOnly
});




}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? products = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? lastDocumentId = freezed,Object? searchQuery = null,Object? selectedCategoryId = freezed,Object? selectedSubcategory = freezed,Object? errorMessage = freezed,Object? selectedSort = null,Object? minPriceCents = freezed,Object? maxPriceCents = freezed,Object? recentSearches = null,Object? searchSuggestions = null,Object? showSearchOverlay = null,Object? canadaOnly = null,}) {
  return _then(_self.copyWith(
products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<Product>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,lastDocumentId: freezed == lastDocumentId ? _self.lastDocumentId : lastDocumentId // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as int?,selectedSubcategory: freezed == selectedSubcategory ? _self.selectedSubcategory : selectedSubcategory // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,selectedSort: null == selectedSort ? _self.selectedSort : selectedSort // ignore: cast_nullable_to_non_nullable
as SortOption,minPriceCents: freezed == minPriceCents ? _self.minPriceCents : minPriceCents // ignore: cast_nullable_to_non_nullable
as int?,maxPriceCents: freezed == maxPriceCents ? _self.maxPriceCents : maxPriceCents // ignore: cast_nullable_to_non_nullable
as int?,recentSearches: null == recentSearches ? _self.recentSearches : recentSearches // ignore: cast_nullable_to_non_nullable
as List<String>,searchSuggestions: null == searchSuggestions ? _self.searchSuggestions : searchSuggestions // ignore: cast_nullable_to_non_nullable
as List<String>,showSearchOverlay: null == showSearchOverlay ? _self.showSearchOverlay : showSearchOverlay // ignore: cast_nullable_to_non_nullable
as bool,canadaOnly: null == canadaOnly ? _self.canadaOnly : canadaOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Product> products,  bool isLoading,  bool isLoadingMore,  bool hasMore,  String? lastDocumentId,  String searchQuery,  int? selectedCategoryId,  String? selectedSubcategory,  String? errorMessage,  SortOption selectedSort,  int? minPriceCents,  int? maxPriceCents,  List<String> recentSearches,  List<String> searchSuggestions,  bool showSearchOverlay,  bool canadaOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.products,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.lastDocumentId,_that.searchQuery,_that.selectedCategoryId,_that.selectedSubcategory,_that.errorMessage,_that.selectedSort,_that.minPriceCents,_that.maxPriceCents,_that.recentSearches,_that.searchSuggestions,_that.showSearchOverlay,_that.canadaOnly);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Product> products,  bool isLoading,  bool isLoadingMore,  bool hasMore,  String? lastDocumentId,  String searchQuery,  int? selectedCategoryId,  String? selectedSubcategory,  String? errorMessage,  SortOption selectedSort,  int? minPriceCents,  int? maxPriceCents,  List<String> recentSearches,  List<String> searchSuggestions,  bool showSearchOverlay,  bool canadaOnly)  $default,) {final _that = this;
switch (_that) {
case _HomeState():
return $default(_that.products,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.lastDocumentId,_that.searchQuery,_that.selectedCategoryId,_that.selectedSubcategory,_that.errorMessage,_that.selectedSort,_that.minPriceCents,_that.maxPriceCents,_that.recentSearches,_that.searchSuggestions,_that.showSearchOverlay,_that.canadaOnly);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Product> products,  bool isLoading,  bool isLoadingMore,  bool hasMore,  String? lastDocumentId,  String searchQuery,  int? selectedCategoryId,  String? selectedSubcategory,  String? errorMessage,  SortOption selectedSort,  int? minPriceCents,  int? maxPriceCents,  List<String> recentSearches,  List<String> searchSuggestions,  bool showSearchOverlay,  bool canadaOnly)?  $default,) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.products,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.lastDocumentId,_that.searchQuery,_that.selectedCategoryId,_that.selectedSubcategory,_that.errorMessage,_that.selectedSort,_that.minPriceCents,_that.maxPriceCents,_that.recentSearches,_that.searchSuggestions,_that.showSearchOverlay,_that.canadaOnly);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState extends HomeState {
  const _HomeState({final  List<Product> products = const [], this.isLoading = false, this.isLoadingMore = false, this.hasMore = true, this.lastDocumentId, this.searchQuery = '', this.selectedCategoryId, this.selectedSubcategory, this.errorMessage, this.selectedSort = SortOption.relevance, this.minPriceCents, this.maxPriceCents, final  List<String> recentSearches = const [], final  List<String> searchSuggestions = const [], this.showSearchOverlay = false, this.canadaOnly = false}): _products = products,_recentSearches = recentSearches,_searchSuggestions = searchSuggestions,super._();
  

 final  List<Product> _products;
@override@JsonKey() List<Product> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool hasMore;
@override final  String? lastDocumentId;
@override@JsonKey() final  String searchQuery;
@override final  int? selectedCategoryId;
@override final  String? selectedSubcategory;
@override final  String? errorMessage;
// GAP #1 — Sort
@override@JsonKey() final  SortOption selectedSort;
// GAP #2 — Price range filter (null = no filter applied)
@override final  int? minPriceCents;
@override final  int? maxPriceCents;
// GAP #7 — Recent searches (persisted in SharedPreferences)
 final  List<String> _recentSearches;
// GAP #7 — Recent searches (persisted in SharedPreferences)
@override@JsonKey() List<String> get recentSearches {
  if (_recentSearches is EqualUnmodifiableListView) return _recentSearches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentSearches);
}

// GAP #7 — Search autocomplete suggestions (transient, not persisted)
 final  List<String> _searchSuggestions;
// GAP #7 — Search autocomplete suggestions (transient, not persisted)
@override@JsonKey() List<String> get searchSuggestions {
  if (_searchSuggestions is EqualUnmodifiableListView) return _searchSuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchSuggestions);
}

// GAP #7 — Whether the search overlay is visible
@override@JsonKey() final  bool showSearchOverlay;
// Made-in-Canada toggle: client-side filter for products whose origin is Canada
@override@JsonKey() final  bool canadaOnly;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&const DeepCollectionEquality().equals(other._products, _products)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.lastDocumentId, lastDocumentId) || other.lastDocumentId == lastDocumentId)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.selectedSubcategory, selectedSubcategory) || other.selectedSubcategory == selectedSubcategory)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.selectedSort, selectedSort) || other.selectedSort == selectedSort)&&(identical(other.minPriceCents, minPriceCents) || other.minPriceCents == minPriceCents)&&(identical(other.maxPriceCents, maxPriceCents) || other.maxPriceCents == maxPriceCents)&&const DeepCollectionEquality().equals(other._recentSearches, _recentSearches)&&const DeepCollectionEquality().equals(other._searchSuggestions, _searchSuggestions)&&(identical(other.showSearchOverlay, showSearchOverlay) || other.showSearchOverlay == showSearchOverlay)&&(identical(other.canadaOnly, canadaOnly) || other.canadaOnly == canadaOnly));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_products),isLoading,isLoadingMore,hasMore,lastDocumentId,searchQuery,selectedCategoryId,selectedSubcategory,errorMessage,selectedSort,minPriceCents,maxPriceCents,const DeepCollectionEquality().hash(_recentSearches),const DeepCollectionEquality().hash(_searchSuggestions),showSearchOverlay,canadaOnly);

@override
String toString() {
  return 'HomeState(products: $products, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, lastDocumentId: $lastDocumentId, searchQuery: $searchQuery, selectedCategoryId: $selectedCategoryId, selectedSubcategory: $selectedSubcategory, errorMessage: $errorMessage, selectedSort: $selectedSort, minPriceCents: $minPriceCents, maxPriceCents: $maxPriceCents, recentSearches: $recentSearches, searchSuggestions: $searchSuggestions, showSearchOverlay: $showSearchOverlay, canadaOnly: $canadaOnly)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 List<Product> products, bool isLoading, bool isLoadingMore, bool hasMore, String? lastDocumentId, String searchQuery, int? selectedCategoryId, String? selectedSubcategory, String? errorMessage, SortOption selectedSort, int? minPriceCents, int? maxPriceCents, List<String> recentSearches, List<String> searchSuggestions, bool showSearchOverlay, bool canadaOnly
});




}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? products = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? lastDocumentId = freezed,Object? searchQuery = null,Object? selectedCategoryId = freezed,Object? selectedSubcategory = freezed,Object? errorMessage = freezed,Object? selectedSort = null,Object? minPriceCents = freezed,Object? maxPriceCents = freezed,Object? recentSearches = null,Object? searchSuggestions = null,Object? showSearchOverlay = null,Object? canadaOnly = null,}) {
  return _then(_HomeState(
products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<Product>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,lastDocumentId: freezed == lastDocumentId ? _self.lastDocumentId : lastDocumentId // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as int?,selectedSubcategory: freezed == selectedSubcategory ? _self.selectedSubcategory : selectedSubcategory // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,selectedSort: null == selectedSort ? _self.selectedSort : selectedSort // ignore: cast_nullable_to_non_nullable
as SortOption,minPriceCents: freezed == minPriceCents ? _self.minPriceCents : minPriceCents // ignore: cast_nullable_to_non_nullable
as int?,maxPriceCents: freezed == maxPriceCents ? _self.maxPriceCents : maxPriceCents // ignore: cast_nullable_to_non_nullable
as int?,recentSearches: null == recentSearches ? _self._recentSearches : recentSearches // ignore: cast_nullable_to_non_nullable
as List<String>,searchSuggestions: null == searchSuggestions ? _self._searchSuggestions : searchSuggestions // ignore: cast_nullable_to_non_nullable
as List<String>,showSearchOverlay: null == showSearchOverlay ? _self.showSearchOverlay : showSearchOverlay // ignore: cast_nullable_to_non_nullable
as bool,canadaOnly: null == canadaOnly ? _self.canadaOnly : canadaOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
