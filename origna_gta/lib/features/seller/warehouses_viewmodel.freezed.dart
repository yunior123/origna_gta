// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'warehouses_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WarehousesState {

 List<SellerWarehouse> get warehouses; bool get isLoading; String? get errorMessage; bool get isSuccess;
/// Create a copy of WarehousesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarehousesStateCopyWith<WarehousesState> get copyWith => _$WarehousesStateCopyWithImpl<WarehousesState>(this as WarehousesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarehousesState&&const DeepCollectionEquality().equals(other.warehouses, warehouses)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(warehouses),isLoading,errorMessage,isSuccess);

@override
String toString() {
  return 'WarehousesState(warehouses: $warehouses, isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class $WarehousesStateCopyWith<$Res>  {
  factory $WarehousesStateCopyWith(WarehousesState value, $Res Function(WarehousesState) _then) = _$WarehousesStateCopyWithImpl;
@useResult
$Res call({
 List<SellerWarehouse> warehouses, bool isLoading, String? errorMessage, bool isSuccess
});




}
/// @nodoc
class _$WarehousesStateCopyWithImpl<$Res>
    implements $WarehousesStateCopyWith<$Res> {
  _$WarehousesStateCopyWithImpl(this._self, this._then);

  final WarehousesState _self;
  final $Res Function(WarehousesState) _then;

/// Create a copy of WarehousesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? warehouses = null,Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,}) {
  return _then(_self.copyWith(
warehouses: null == warehouses ? _self.warehouses : warehouses // ignore: cast_nullable_to_non_nullable
as List<SellerWarehouse>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WarehousesState].
extension WarehousesStatePatterns on WarehousesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarehousesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarehousesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarehousesState value)  $default,){
final _that = this;
switch (_that) {
case _WarehousesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarehousesState value)?  $default,){
final _that = this;
switch (_that) {
case _WarehousesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SellerWarehouse> warehouses,  bool isLoading,  String? errorMessage,  bool isSuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarehousesState() when $default != null:
return $default(_that.warehouses,_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SellerWarehouse> warehouses,  bool isLoading,  String? errorMessage,  bool isSuccess)  $default,) {final _that = this;
switch (_that) {
case _WarehousesState():
return $default(_that.warehouses,_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SellerWarehouse> warehouses,  bool isLoading,  String? errorMessage,  bool isSuccess)?  $default,) {final _that = this;
switch (_that) {
case _WarehousesState() when $default != null:
return $default(_that.warehouses,_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
  return null;

}
}

}

/// @nodoc


class _WarehousesState implements WarehousesState {
  const _WarehousesState({final  List<SellerWarehouse> warehouses = const [], this.isLoading = false, this.errorMessage, this.isSuccess = false}): _warehouses = warehouses;
  

 final  List<SellerWarehouse> _warehouses;
@override@JsonKey() List<SellerWarehouse> get warehouses {
  if (_warehouses is EqualUnmodifiableListView) return _warehouses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warehouses);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override@JsonKey() final  bool isSuccess;

/// Create a copy of WarehousesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarehousesStateCopyWith<_WarehousesState> get copyWith => __$WarehousesStateCopyWithImpl<_WarehousesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarehousesState&&const DeepCollectionEquality().equals(other._warehouses, _warehouses)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_warehouses),isLoading,errorMessage,isSuccess);

@override
String toString() {
  return 'WarehousesState(warehouses: $warehouses, isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class _$WarehousesStateCopyWith<$Res> implements $WarehousesStateCopyWith<$Res> {
  factory _$WarehousesStateCopyWith(_WarehousesState value, $Res Function(_WarehousesState) _then) = __$WarehousesStateCopyWithImpl;
@override @useResult
$Res call({
 List<SellerWarehouse> warehouses, bool isLoading, String? errorMessage, bool isSuccess
});




}
/// @nodoc
class __$WarehousesStateCopyWithImpl<$Res>
    implements _$WarehousesStateCopyWith<$Res> {
  __$WarehousesStateCopyWithImpl(this._self, this._then);

  final _WarehousesState _self;
  final $Res Function(_WarehousesState) _then;

/// Create a copy of WarehousesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? warehouses = null,Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,}) {
  return _then(_WarehousesState(
warehouses: null == warehouses ? _self._warehouses : warehouses // ignore: cast_nullable_to_non_nullable
as List<SellerWarehouse>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
