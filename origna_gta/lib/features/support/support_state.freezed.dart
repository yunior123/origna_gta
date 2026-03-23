// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SupportState {

 List<SupportMessage> get messages; bool get isLoading; bool get isEscalated; String? get errorMessage;
/// Create a copy of SupportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportStateCopyWith<SupportState> get copyWith => _$SupportStateCopyWithImpl<SupportState>(this as SupportState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportState&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isEscalated, isEscalated) || other.isEscalated == isEscalated)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(messages),isLoading,isEscalated,errorMessage);

@override
String toString() {
  return 'SupportState(messages: $messages, isLoading: $isLoading, isEscalated: $isEscalated, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SupportStateCopyWith<$Res>  {
  factory $SupportStateCopyWith(SupportState value, $Res Function(SupportState) _then) = _$SupportStateCopyWithImpl;
@useResult
$Res call({
 List<SupportMessage> messages, bool isLoading, bool isEscalated, String? errorMessage
});




}
/// @nodoc
class _$SupportStateCopyWithImpl<$Res>
    implements $SupportStateCopyWith<$Res> {
  _$SupportStateCopyWithImpl(this._self, this._then);

  final SupportState _self;
  final $Res Function(SupportState) _then;

/// Create a copy of SupportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? isLoading = null,Object? isEscalated = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessage>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isEscalated: null == isEscalated ? _self.isEscalated : isEscalated // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportState].
extension SupportStatePatterns on SupportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportState value)  $default,){
final _that = this;
switch (_that) {
case _SupportState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportState value)?  $default,){
final _that = this;
switch (_that) {
case _SupportState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SupportMessage> messages,  bool isLoading,  bool isEscalated,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportState() when $default != null:
return $default(_that.messages,_that.isLoading,_that.isEscalated,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SupportMessage> messages,  bool isLoading,  bool isEscalated,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SupportState():
return $default(_that.messages,_that.isLoading,_that.isEscalated,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SupportMessage> messages,  bool isLoading,  bool isEscalated,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SupportState() when $default != null:
return $default(_that.messages,_that.isLoading,_that.isEscalated,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SupportState implements SupportState {
  const _SupportState({final  List<SupportMessage> messages = const [], this.isLoading = false, this.isEscalated = false, this.errorMessage}): _messages = messages;
  

 final  List<SupportMessage> _messages;
@override@JsonKey() List<SupportMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isEscalated;
@override final  String? errorMessage;

/// Create a copy of SupportState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportStateCopyWith<_SupportState> get copyWith => __$SupportStateCopyWithImpl<_SupportState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportState&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isEscalated, isEscalated) || other.isEscalated == isEscalated)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),isLoading,isEscalated,errorMessage);

@override
String toString() {
  return 'SupportState(messages: $messages, isLoading: $isLoading, isEscalated: $isEscalated, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SupportStateCopyWith<$Res> implements $SupportStateCopyWith<$Res> {
  factory _$SupportStateCopyWith(_SupportState value, $Res Function(_SupportState) _then) = __$SupportStateCopyWithImpl;
@override @useResult
$Res call({
 List<SupportMessage> messages, bool isLoading, bool isEscalated, String? errorMessage
});




}
/// @nodoc
class __$SupportStateCopyWithImpl<$Res>
    implements _$SupportStateCopyWith<$Res> {
  __$SupportStateCopyWithImpl(this._self, this._then);

  final _SupportState _self;
  final $Res Function(_SupportState) _then;

/// Create a copy of SupportState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? isLoading = null,Object? isEscalated = null,Object? errorMessage = freezed,}) {
  return _then(_SupportState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessage>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isEscalated: null == isEscalated ? _self.isEscalated : isEscalated // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
