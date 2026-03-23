// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_rating_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductRatingState {

 bool get isLoading; bool get isSuccess; String? get errorMessage; String? get reviewText;
/// Create a copy of ProductRatingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductRatingStateCopyWith<ProductRatingState> get copyWith => _$ProductRatingStateCopyWithImpl<ProductRatingState>(this as ProductRatingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductRatingState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.reviewText, reviewText) || other.reviewText == reviewText));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage,reviewText);

@override
String toString() {
  return 'ProductRatingState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage, reviewText: $reviewText)';
}


}

/// @nodoc
abstract mixin class $ProductRatingStateCopyWith<$Res>  {
  factory $ProductRatingStateCopyWith(ProductRatingState value, $Res Function(ProductRatingState) _then) = _$ProductRatingStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage, String? reviewText
});




}
/// @nodoc
class _$ProductRatingStateCopyWithImpl<$Res>
    implements $ProductRatingStateCopyWith<$Res> {
  _$ProductRatingStateCopyWithImpl(this._self, this._then);

  final ProductRatingState _self;
  final $Res Function(ProductRatingState) _then;

/// Create a copy of ProductRatingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,Object? reviewText = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,reviewText: freezed == reviewText ? _self.reviewText : reviewText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductRatingState].
extension ProductRatingStatePatterns on ProductRatingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductRatingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductRatingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductRatingState value)  $default,){
final _that = this;
switch (_that) {
case _ProductRatingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductRatingState value)?  $default,){
final _that = this;
switch (_that) {
case _ProductRatingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  String? errorMessage,  String? reviewText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductRatingState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage,_that.reviewText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  String? errorMessage,  String? reviewText)  $default,) {final _that = this;
switch (_that) {
case _ProductRatingState():
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage,_that.reviewText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isSuccess,  String? errorMessage,  String? reviewText)?  $default,) {final _that = this;
switch (_that) {
case _ProductRatingState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage,_that.reviewText);case _:
  return null;

}
}

}

/// @nodoc


class _ProductRatingState implements ProductRatingState {
  const _ProductRatingState({this.isLoading = false, this.isSuccess = false, this.errorMessage, this.reviewText});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;
@override final  String? reviewText;

/// Create a copy of ProductRatingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductRatingStateCopyWith<_ProductRatingState> get copyWith => __$ProductRatingStateCopyWithImpl<_ProductRatingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductRatingState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.reviewText, reviewText) || other.reviewText == reviewText));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage,reviewText);

@override
String toString() {
  return 'ProductRatingState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage, reviewText: $reviewText)';
}


}

/// @nodoc
abstract mixin class _$ProductRatingStateCopyWith<$Res> implements $ProductRatingStateCopyWith<$Res> {
  factory _$ProductRatingStateCopyWith(_ProductRatingState value, $Res Function(_ProductRatingState) _then) = __$ProductRatingStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage, String? reviewText
});




}
/// @nodoc
class __$ProductRatingStateCopyWithImpl<$Res>
    implements _$ProductRatingStateCopyWith<$Res> {
  __$ProductRatingStateCopyWithImpl(this._self, this._then);

  final _ProductRatingState _self;
  final $Res Function(_ProductRatingState) _then;

/// Create a copy of ProductRatingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,Object? reviewText = freezed,}) {
  return _then(_ProductRatingState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,reviewText: freezed == reviewText ? _self.reviewText : reviewText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
