// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bulk_upload_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BulkProductError {

 int get index; String get message;
/// Create a copy of BulkProductError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BulkProductErrorCopyWith<BulkProductError> get copyWith => _$BulkProductErrorCopyWithImpl<BulkProductError>(this as BulkProductError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BulkProductError&&(identical(other.index, index) || other.index == index)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,index,message);

@override
String toString() {
  return 'BulkProductError(index: $index, message: $message)';
}


}

/// @nodoc
abstract mixin class $BulkProductErrorCopyWith<$Res>  {
  factory $BulkProductErrorCopyWith(BulkProductError value, $Res Function(BulkProductError) _then) = _$BulkProductErrorCopyWithImpl;
@useResult
$Res call({
 int index, String message
});




}
/// @nodoc
class _$BulkProductErrorCopyWithImpl<$Res>
    implements $BulkProductErrorCopyWith<$Res> {
  _$BulkProductErrorCopyWithImpl(this._self, this._then);

  final BulkProductError _self;
  final $Res Function(BulkProductError) _then;

/// Create a copy of BulkProductError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? message = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BulkProductError].
extension BulkProductErrorPatterns on BulkProductError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BulkProductError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BulkProductError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BulkProductError value)  $default,){
final _that = this;
switch (_that) {
case _BulkProductError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BulkProductError value)?  $default,){
final _that = this;
switch (_that) {
case _BulkProductError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BulkProductError() when $default != null:
return $default(_that.index,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String message)  $default,) {final _that = this;
switch (_that) {
case _BulkProductError():
return $default(_that.index,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String message)?  $default,) {final _that = this;
switch (_that) {
case _BulkProductError() when $default != null:
return $default(_that.index,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _BulkProductError implements BulkProductError {
  const _BulkProductError({required this.index, required this.message});
  

@override final  int index;
@override final  String message;

/// Create a copy of BulkProductError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BulkProductErrorCopyWith<_BulkProductError> get copyWith => __$BulkProductErrorCopyWithImpl<_BulkProductError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BulkProductError&&(identical(other.index, index) || other.index == index)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,index,message);

@override
String toString() {
  return 'BulkProductError(index: $index, message: $message)';
}


}

/// @nodoc
abstract mixin class _$BulkProductErrorCopyWith<$Res> implements $BulkProductErrorCopyWith<$Res> {
  factory _$BulkProductErrorCopyWith(_BulkProductError value, $Res Function(_BulkProductError) _then) = __$BulkProductErrorCopyWithImpl;
@override @useResult
$Res call({
 int index, String message
});




}
/// @nodoc
class __$BulkProductErrorCopyWithImpl<$Res>
    implements _$BulkProductErrorCopyWith<$Res> {
  __$BulkProductErrorCopyWithImpl(this._self, this._then);

  final _BulkProductError _self;
  final $Res Function(_BulkProductError) _then;

/// Create a copy of BulkProductError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? message = null,}) {
  return _then(_BulkProductError(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CreatedProduct {

 int get index; String get productId; String get title;
/// Create a copy of CreatedProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedProductCopyWith<CreatedProduct> get copyWith => _$CreatedProductCopyWithImpl<CreatedProduct>(this as CreatedProduct, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedProduct&&(identical(other.index, index) || other.index == index)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,index,productId,title);

@override
String toString() {
  return 'CreatedProduct(index: $index, productId: $productId, title: $title)';
}


}

/// @nodoc
abstract mixin class $CreatedProductCopyWith<$Res>  {
  factory $CreatedProductCopyWith(CreatedProduct value, $Res Function(CreatedProduct) _then) = _$CreatedProductCopyWithImpl;
@useResult
$Res call({
 int index, String productId, String title
});




}
/// @nodoc
class _$CreatedProductCopyWithImpl<$Res>
    implements $CreatedProductCopyWith<$Res> {
  _$CreatedProductCopyWithImpl(this._self, this._then);

  final CreatedProduct _self;
  final $Res Function(CreatedProduct) _then;

/// Create a copy of CreatedProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? productId = null,Object? title = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatedProduct].
extension CreatedProductPatterns on CreatedProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatedProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatedProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatedProduct value)  $default,){
final _that = this;
switch (_that) {
case _CreatedProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatedProduct value)?  $default,){
final _that = this;
switch (_that) {
case _CreatedProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String productId,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatedProduct() when $default != null:
return $default(_that.index,_that.productId,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String productId,  String title)  $default,) {final _that = this;
switch (_that) {
case _CreatedProduct():
return $default(_that.index,_that.productId,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String productId,  String title)?  $default,) {final _that = this;
switch (_that) {
case _CreatedProduct() when $default != null:
return $default(_that.index,_that.productId,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _CreatedProduct implements CreatedProduct {
  const _CreatedProduct({required this.index, required this.productId, required this.title});
  

@override final  int index;
@override final  String productId;
@override final  String title;

/// Create a copy of CreatedProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatedProductCopyWith<_CreatedProduct> get copyWith => __$CreatedProductCopyWithImpl<_CreatedProduct>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatedProduct&&(identical(other.index, index) || other.index == index)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,index,productId,title);

@override
String toString() {
  return 'CreatedProduct(index: $index, productId: $productId, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CreatedProductCopyWith<$Res> implements $CreatedProductCopyWith<$Res> {
  factory _$CreatedProductCopyWith(_CreatedProduct value, $Res Function(_CreatedProduct) _then) = __$CreatedProductCopyWithImpl;
@override @useResult
$Res call({
 int index, String productId, String title
});




}
/// @nodoc
class __$CreatedProductCopyWithImpl<$Res>
    implements _$CreatedProductCopyWith<$Res> {
  __$CreatedProductCopyWithImpl(this._self, this._then);

  final _CreatedProduct _self;
  final $Res Function(_CreatedProduct) _then;

/// Create a copy of CreatedProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? productId = null,Object? title = null,}) {
  return _then(_CreatedProduct(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BulkUploadState {

/// CSV content (raw text)
 String get csvContent;/// Parsed products (List<Map<String, dynamic>>)
 List<Map<String, dynamic>> get parsedProducts;/// Validation errors from CSV parsing
 List<BulkProductError> get parseErrors;/// Whether currently uploading to backend
 bool get isUploading;/// Products successfully created
 List<CreatedProduct> get createdProducts;/// Errors from bulk API call
 List<BulkProductError> get uploadErrors;/// Error message (general)
 String get errorMessage;/// Success indicator
 bool get isSuccess;/// Total product count attempted
 int get totalCount;
/// Create a copy of BulkUploadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BulkUploadStateCopyWith<BulkUploadState> get copyWith => _$BulkUploadStateCopyWithImpl<BulkUploadState>(this as BulkUploadState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BulkUploadState&&(identical(other.csvContent, csvContent) || other.csvContent == csvContent)&&const DeepCollectionEquality().equals(other.parsedProducts, parsedProducts)&&const DeepCollectionEquality().equals(other.parseErrors, parseErrors)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&const DeepCollectionEquality().equals(other.createdProducts, createdProducts)&&const DeepCollectionEquality().equals(other.uploadErrors, uploadErrors)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount));
}


@override
int get hashCode => Object.hash(runtimeType,csvContent,const DeepCollectionEquality().hash(parsedProducts),const DeepCollectionEquality().hash(parseErrors),isUploading,const DeepCollectionEquality().hash(createdProducts),const DeepCollectionEquality().hash(uploadErrors),errorMessage,isSuccess,totalCount);

@override
String toString() {
  return 'BulkUploadState(csvContent: $csvContent, parsedProducts: $parsedProducts, parseErrors: $parseErrors, isUploading: $isUploading, createdProducts: $createdProducts, uploadErrors: $uploadErrors, errorMessage: $errorMessage, isSuccess: $isSuccess, totalCount: $totalCount)';
}


}

/// @nodoc
abstract mixin class $BulkUploadStateCopyWith<$Res>  {
  factory $BulkUploadStateCopyWith(BulkUploadState value, $Res Function(BulkUploadState) _then) = _$BulkUploadStateCopyWithImpl;
@useResult
$Res call({
 String csvContent, List<Map<String, dynamic>> parsedProducts, List<BulkProductError> parseErrors, bool isUploading, List<CreatedProduct> createdProducts, List<BulkProductError> uploadErrors, String errorMessage, bool isSuccess, int totalCount
});




}
/// @nodoc
class _$BulkUploadStateCopyWithImpl<$Res>
    implements $BulkUploadStateCopyWith<$Res> {
  _$BulkUploadStateCopyWithImpl(this._self, this._then);

  final BulkUploadState _self;
  final $Res Function(BulkUploadState) _then;

/// Create a copy of BulkUploadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? csvContent = null,Object? parsedProducts = null,Object? parseErrors = null,Object? isUploading = null,Object? createdProducts = null,Object? uploadErrors = null,Object? errorMessage = null,Object? isSuccess = null,Object? totalCount = null,}) {
  return _then(_self.copyWith(
csvContent: null == csvContent ? _self.csvContent : csvContent // ignore: cast_nullable_to_non_nullable
as String,parsedProducts: null == parsedProducts ? _self.parsedProducts : parsedProducts // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,parseErrors: null == parseErrors ? _self.parseErrors : parseErrors // ignore: cast_nullable_to_non_nullable
as List<BulkProductError>,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,createdProducts: null == createdProducts ? _self.createdProducts : createdProducts // ignore: cast_nullable_to_non_nullable
as List<CreatedProduct>,uploadErrors: null == uploadErrors ? _self.uploadErrors : uploadErrors // ignore: cast_nullable_to_non_nullable
as List<BulkProductError>,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BulkUploadState].
extension BulkUploadStatePatterns on BulkUploadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BulkUploadState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BulkUploadState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BulkUploadState value)  $default,){
final _that = this;
switch (_that) {
case _BulkUploadState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BulkUploadState value)?  $default,){
final _that = this;
switch (_that) {
case _BulkUploadState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String csvContent,  List<Map<String, dynamic>> parsedProducts,  List<BulkProductError> parseErrors,  bool isUploading,  List<CreatedProduct> createdProducts,  List<BulkProductError> uploadErrors,  String errorMessage,  bool isSuccess,  int totalCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BulkUploadState() when $default != null:
return $default(_that.csvContent,_that.parsedProducts,_that.parseErrors,_that.isUploading,_that.createdProducts,_that.uploadErrors,_that.errorMessage,_that.isSuccess,_that.totalCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String csvContent,  List<Map<String, dynamic>> parsedProducts,  List<BulkProductError> parseErrors,  bool isUploading,  List<CreatedProduct> createdProducts,  List<BulkProductError> uploadErrors,  String errorMessage,  bool isSuccess,  int totalCount)  $default,) {final _that = this;
switch (_that) {
case _BulkUploadState():
return $default(_that.csvContent,_that.parsedProducts,_that.parseErrors,_that.isUploading,_that.createdProducts,_that.uploadErrors,_that.errorMessage,_that.isSuccess,_that.totalCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String csvContent,  List<Map<String, dynamic>> parsedProducts,  List<BulkProductError> parseErrors,  bool isUploading,  List<CreatedProduct> createdProducts,  List<BulkProductError> uploadErrors,  String errorMessage,  bool isSuccess,  int totalCount)?  $default,) {final _that = this;
switch (_that) {
case _BulkUploadState() when $default != null:
return $default(_that.csvContent,_that.parsedProducts,_that.parseErrors,_that.isUploading,_that.createdProducts,_that.uploadErrors,_that.errorMessage,_that.isSuccess,_that.totalCount);case _:
  return null;

}
}

}

/// @nodoc


class _BulkUploadState implements BulkUploadState {
  const _BulkUploadState({this.csvContent = '', final  List<Map<String, dynamic>> parsedProducts = const [], final  List<BulkProductError> parseErrors = const [], this.isUploading = false, final  List<CreatedProduct> createdProducts = const [], final  List<BulkProductError> uploadErrors = const [], this.errorMessage = '', this.isSuccess = false, this.totalCount = 0}): _parsedProducts = parsedProducts,_parseErrors = parseErrors,_createdProducts = createdProducts,_uploadErrors = uploadErrors;
  

/// CSV content (raw text)
@override@JsonKey() final  String csvContent;
/// Parsed products (List<Map<String, dynamic>>)
 final  List<Map<String, dynamic>> _parsedProducts;
/// Parsed products (List<Map<String, dynamic>>)
@override@JsonKey() List<Map<String, dynamic>> get parsedProducts {
  if (_parsedProducts is EqualUnmodifiableListView) return _parsedProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parsedProducts);
}

/// Validation errors from CSV parsing
 final  List<BulkProductError> _parseErrors;
/// Validation errors from CSV parsing
@override@JsonKey() List<BulkProductError> get parseErrors {
  if (_parseErrors is EqualUnmodifiableListView) return _parseErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parseErrors);
}

/// Whether currently uploading to backend
@override@JsonKey() final  bool isUploading;
/// Products successfully created
 final  List<CreatedProduct> _createdProducts;
/// Products successfully created
@override@JsonKey() List<CreatedProduct> get createdProducts {
  if (_createdProducts is EqualUnmodifiableListView) return _createdProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_createdProducts);
}

/// Errors from bulk API call
 final  List<BulkProductError> _uploadErrors;
/// Errors from bulk API call
@override@JsonKey() List<BulkProductError> get uploadErrors {
  if (_uploadErrors is EqualUnmodifiableListView) return _uploadErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uploadErrors);
}

/// Error message (general)
@override@JsonKey() final  String errorMessage;
/// Success indicator
@override@JsonKey() final  bool isSuccess;
/// Total product count attempted
@override@JsonKey() final  int totalCount;

/// Create a copy of BulkUploadState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BulkUploadStateCopyWith<_BulkUploadState> get copyWith => __$BulkUploadStateCopyWithImpl<_BulkUploadState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BulkUploadState&&(identical(other.csvContent, csvContent) || other.csvContent == csvContent)&&const DeepCollectionEquality().equals(other._parsedProducts, _parsedProducts)&&const DeepCollectionEquality().equals(other._parseErrors, _parseErrors)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&const DeepCollectionEquality().equals(other._createdProducts, _createdProducts)&&const DeepCollectionEquality().equals(other._uploadErrors, _uploadErrors)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount));
}


@override
int get hashCode => Object.hash(runtimeType,csvContent,const DeepCollectionEquality().hash(_parsedProducts),const DeepCollectionEquality().hash(_parseErrors),isUploading,const DeepCollectionEquality().hash(_createdProducts),const DeepCollectionEquality().hash(_uploadErrors),errorMessage,isSuccess,totalCount);

@override
String toString() {
  return 'BulkUploadState(csvContent: $csvContent, parsedProducts: $parsedProducts, parseErrors: $parseErrors, isUploading: $isUploading, createdProducts: $createdProducts, uploadErrors: $uploadErrors, errorMessage: $errorMessage, isSuccess: $isSuccess, totalCount: $totalCount)';
}


}

/// @nodoc
abstract mixin class _$BulkUploadStateCopyWith<$Res> implements $BulkUploadStateCopyWith<$Res> {
  factory _$BulkUploadStateCopyWith(_BulkUploadState value, $Res Function(_BulkUploadState) _then) = __$BulkUploadStateCopyWithImpl;
@override @useResult
$Res call({
 String csvContent, List<Map<String, dynamic>> parsedProducts, List<BulkProductError> parseErrors, bool isUploading, List<CreatedProduct> createdProducts, List<BulkProductError> uploadErrors, String errorMessage, bool isSuccess, int totalCount
});




}
/// @nodoc
class __$BulkUploadStateCopyWithImpl<$Res>
    implements _$BulkUploadStateCopyWith<$Res> {
  __$BulkUploadStateCopyWithImpl(this._self, this._then);

  final _BulkUploadState _self;
  final $Res Function(_BulkUploadState) _then;

/// Create a copy of BulkUploadState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? csvContent = null,Object? parsedProducts = null,Object? parseErrors = null,Object? isUploading = null,Object? createdProducts = null,Object? uploadErrors = null,Object? errorMessage = null,Object? isSuccess = null,Object? totalCount = null,}) {
  return _then(_BulkUploadState(
csvContent: null == csvContent ? _self.csvContent : csvContent // ignore: cast_nullable_to_non_nullable
as String,parsedProducts: null == parsedProducts ? _self._parsedProducts : parsedProducts // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,parseErrors: null == parseErrors ? _self._parseErrors : parseErrors // ignore: cast_nullable_to_non_nullable
as List<BulkProductError>,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,createdProducts: null == createdProducts ? _self._createdProducts : createdProducts // ignore: cast_nullable_to_non_nullable
as List<CreatedProduct>,uploadErrors: null == uploadErrors ? _self._uploadErrors : uploadErrors // ignore: cast_nullable_to_non_nullable
as List<BulkProductError>,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
