// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryConfig {

/// Whether inventory is actively managed (false for dropship products)
 bool get managed;/// Track stock quantity (false = unlimited)
 bool get trackQuantity;/// Allow orders when out of stock
 bool get allowBackorder;/// Alert threshold for low stock
 int get lowStockThreshold;/// When the last low-stock alert was sent
 DateTime? get lastLowStockAlertAt;/// How long to hold inventory during checkout (minutes)
 int get reservationHoldMinutes;
/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<InventoryConfig> get copyWith => _$InventoryConfigCopyWithImpl<InventoryConfig>(this as InventoryConfig, _$identity);

  /// Serializes this InventoryConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryConfig&&(identical(other.managed, managed) || other.managed == managed)&&(identical(other.trackQuantity, trackQuantity) || other.trackQuantity == trackQuantity)&&(identical(other.allowBackorder, allowBackorder) || other.allowBackorder == allowBackorder)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.lastLowStockAlertAt, lastLowStockAlertAt) || other.lastLowStockAlertAt == lastLowStockAlertAt)&&(identical(other.reservationHoldMinutes, reservationHoldMinutes) || other.reservationHoldMinutes == reservationHoldMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,managed,trackQuantity,allowBackorder,lowStockThreshold,lastLowStockAlertAt,reservationHoldMinutes);

@override
String toString() {
  return 'InventoryConfig(managed: $managed, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockThreshold: $lowStockThreshold, lastLowStockAlertAt: $lastLowStockAlertAt, reservationHoldMinutes: $reservationHoldMinutes)';
}


}

/// @nodoc
abstract mixin class $InventoryConfigCopyWith<$Res>  {
  factory $InventoryConfigCopyWith(InventoryConfig value, $Res Function(InventoryConfig) _then) = _$InventoryConfigCopyWithImpl;
@useResult
$Res call({
 bool managed, bool trackQuantity, bool allowBackorder, int lowStockThreshold, DateTime? lastLowStockAlertAt, int reservationHoldMinutes
});




}
/// @nodoc
class _$InventoryConfigCopyWithImpl<$Res>
    implements $InventoryConfigCopyWith<$Res> {
  _$InventoryConfigCopyWithImpl(this._self, this._then);

  final InventoryConfig _self;
  final $Res Function(InventoryConfig) _then;

/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? managed = null,Object? trackQuantity = null,Object? allowBackorder = null,Object? lowStockThreshold = null,Object? lastLowStockAlertAt = freezed,Object? reservationHoldMinutes = null,}) {
  return _then(_self.copyWith(
managed: null == managed ? _self.managed : managed // ignore: cast_nullable_to_non_nullable
as bool,trackQuantity: null == trackQuantity ? _self.trackQuantity : trackQuantity // ignore: cast_nullable_to_non_nullable
as bool,allowBackorder: null == allowBackorder ? _self.allowBackorder : allowBackorder // ignore: cast_nullable_to_non_nullable
as bool,lowStockThreshold: null == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int,lastLowStockAlertAt: freezed == lastLowStockAlertAt ? _self.lastLowStockAlertAt : lastLowStockAlertAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reservationHoldMinutes: null == reservationHoldMinutes ? _self.reservationHoldMinutes : reservationHoldMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryConfig].
extension InventoryConfigPatterns on InventoryConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryConfig value)  $default,){
final _that = this;
switch (_that) {
case _InventoryConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryConfig value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool managed,  bool trackQuantity,  bool allowBackorder,  int lowStockThreshold,  DateTime? lastLowStockAlertAt,  int reservationHoldMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
return $default(_that.managed,_that.trackQuantity,_that.allowBackorder,_that.lowStockThreshold,_that.lastLowStockAlertAt,_that.reservationHoldMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool managed,  bool trackQuantity,  bool allowBackorder,  int lowStockThreshold,  DateTime? lastLowStockAlertAt,  int reservationHoldMinutes)  $default,) {final _that = this;
switch (_that) {
case _InventoryConfig():
return $default(_that.managed,_that.trackQuantity,_that.allowBackorder,_that.lowStockThreshold,_that.lastLowStockAlertAt,_that.reservationHoldMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool managed,  bool trackQuantity,  bool allowBackorder,  int lowStockThreshold,  DateTime? lastLowStockAlertAt,  int reservationHoldMinutes)?  $default,) {final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
return $default(_that.managed,_that.trackQuantity,_that.allowBackorder,_that.lowStockThreshold,_that.lastLowStockAlertAt,_that.reservationHoldMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InventoryConfig implements InventoryConfig {
  const _InventoryConfig({this.managed = true, this.trackQuantity = true, this.allowBackorder = false, this.lowStockThreshold = 5, this.lastLowStockAlertAt, this.reservationHoldMinutes = 30});
  factory _InventoryConfig.fromJson(Map<String, dynamic> json) => _$InventoryConfigFromJson(json);

/// Whether inventory is actively managed (false for dropship products)
@override@JsonKey() final  bool managed;
/// Track stock quantity (false = unlimited)
@override@JsonKey() final  bool trackQuantity;
/// Allow orders when out of stock
@override@JsonKey() final  bool allowBackorder;
/// Alert threshold for low stock
@override@JsonKey() final  int lowStockThreshold;
/// When the last low-stock alert was sent
@override final  DateTime? lastLowStockAlertAt;
/// How long to hold inventory during checkout (minutes)
@override@JsonKey() final  int reservationHoldMinutes;

/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryConfigCopyWith<_InventoryConfig> get copyWith => __$InventoryConfigCopyWithImpl<_InventoryConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InventoryConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryConfig&&(identical(other.managed, managed) || other.managed == managed)&&(identical(other.trackQuantity, trackQuantity) || other.trackQuantity == trackQuantity)&&(identical(other.allowBackorder, allowBackorder) || other.allowBackorder == allowBackorder)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.lastLowStockAlertAt, lastLowStockAlertAt) || other.lastLowStockAlertAt == lastLowStockAlertAt)&&(identical(other.reservationHoldMinutes, reservationHoldMinutes) || other.reservationHoldMinutes == reservationHoldMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,managed,trackQuantity,allowBackorder,lowStockThreshold,lastLowStockAlertAt,reservationHoldMinutes);

@override
String toString() {
  return 'InventoryConfig(managed: $managed, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockThreshold: $lowStockThreshold, lastLowStockAlertAt: $lastLowStockAlertAt, reservationHoldMinutes: $reservationHoldMinutes)';
}


}

/// @nodoc
abstract mixin class _$InventoryConfigCopyWith<$Res> implements $InventoryConfigCopyWith<$Res> {
  factory _$InventoryConfigCopyWith(_InventoryConfig value, $Res Function(_InventoryConfig) _then) = __$InventoryConfigCopyWithImpl;
@override @useResult
$Res call({
 bool managed, bool trackQuantity, bool allowBackorder, int lowStockThreshold, DateTime? lastLowStockAlertAt, int reservationHoldMinutes
});




}
/// @nodoc
class __$InventoryConfigCopyWithImpl<$Res>
    implements _$InventoryConfigCopyWith<$Res> {
  __$InventoryConfigCopyWithImpl(this._self, this._then);

  final _InventoryConfig _self;
  final $Res Function(_InventoryConfig) _then;

/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? managed = null,Object? trackQuantity = null,Object? allowBackorder = null,Object? lowStockThreshold = null,Object? lastLowStockAlertAt = freezed,Object? reservationHoldMinutes = null,}) {
  return _then(_InventoryConfig(
managed: null == managed ? _self.managed : managed // ignore: cast_nullable_to_non_nullable
as bool,trackQuantity: null == trackQuantity ? _self.trackQuantity : trackQuantity // ignore: cast_nullable_to_non_nullable
as bool,allowBackorder: null == allowBackorder ? _self.allowBackorder : allowBackorder // ignore: cast_nullable_to_non_nullable
as bool,lowStockThreshold: null == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int,lastLowStockAlertAt: freezed == lastLowStockAlertAt ? _self.lastLowStockAlertAt : lastLowStockAlertAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reservationHoldMinutes: null == reservationHoldMinutes ? _self.reservationHoldMinutes : reservationHoldMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NutritionFacts {

/// Serving size numeric amount (e.g., 250 for "250 mL")
 int get servingSizeAmount;/// Serving size unit: "g" or "mL"
 String get servingSizeUnit;/// Number of servings per container (null if not specified)
 int? get servingsPerContainer;// === Mandatory Health Canada nutrients ===
 int get caloriesKcal; int get totalFatMg; int get saturatedFatMg; int get transFatMg; int get cholesterolMg; int get sodiumMg; int get totalCarbohydrateMg; int get fibreMg; int get sugarsMg; int get proteinMg; int get vitaminAMcg; int get vitaminCMg; int get calciumMg; int get ironMg;// === Optional additional nutrients ===
/// Added sugars (newer Health Canada recommendation)
 int? get addedSugarsMg;/// Potassium (optional in standard NFT)
 int? get potassiumMg;/// Vitamin D (optional in standard NFT)
 int? get vitaminDMcg;
/// Create a copy of NutritionFacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NutritionFactsCopyWith<NutritionFacts> get copyWith => _$NutritionFactsCopyWithImpl<NutritionFacts>(this as NutritionFacts, _$identity);

  /// Serializes this NutritionFacts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NutritionFacts&&(identical(other.servingSizeAmount, servingSizeAmount) || other.servingSizeAmount == servingSizeAmount)&&(identical(other.servingSizeUnit, servingSizeUnit) || other.servingSizeUnit == servingSizeUnit)&&(identical(other.servingsPerContainer, servingsPerContainer) || other.servingsPerContainer == servingsPerContainer)&&(identical(other.caloriesKcal, caloriesKcal) || other.caloriesKcal == caloriesKcal)&&(identical(other.totalFatMg, totalFatMg) || other.totalFatMg == totalFatMg)&&(identical(other.saturatedFatMg, saturatedFatMg) || other.saturatedFatMg == saturatedFatMg)&&(identical(other.transFatMg, transFatMg) || other.transFatMg == transFatMg)&&(identical(other.cholesterolMg, cholesterolMg) || other.cholesterolMg == cholesterolMg)&&(identical(other.sodiumMg, sodiumMg) || other.sodiumMg == sodiumMg)&&(identical(other.totalCarbohydrateMg, totalCarbohydrateMg) || other.totalCarbohydrateMg == totalCarbohydrateMg)&&(identical(other.fibreMg, fibreMg) || other.fibreMg == fibreMg)&&(identical(other.sugarsMg, sugarsMg) || other.sugarsMg == sugarsMg)&&(identical(other.proteinMg, proteinMg) || other.proteinMg == proteinMg)&&(identical(other.vitaminAMcg, vitaminAMcg) || other.vitaminAMcg == vitaminAMcg)&&(identical(other.vitaminCMg, vitaminCMg) || other.vitaminCMg == vitaminCMg)&&(identical(other.calciumMg, calciumMg) || other.calciumMg == calciumMg)&&(identical(other.ironMg, ironMg) || other.ironMg == ironMg)&&(identical(other.addedSugarsMg, addedSugarsMg) || other.addedSugarsMg == addedSugarsMg)&&(identical(other.potassiumMg, potassiumMg) || other.potassiumMg == potassiumMg)&&(identical(other.vitaminDMcg, vitaminDMcg) || other.vitaminDMcg == vitaminDMcg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,servingSizeAmount,servingSizeUnit,servingsPerContainer,caloriesKcal,totalFatMg,saturatedFatMg,transFatMg,cholesterolMg,sodiumMg,totalCarbohydrateMg,fibreMg,sugarsMg,proteinMg,vitaminAMcg,vitaminCMg,calciumMg,ironMg,addedSugarsMg,potassiumMg,vitaminDMcg]);

@override
String toString() {
  return 'NutritionFacts(servingSizeAmount: $servingSizeAmount, servingSizeUnit: $servingSizeUnit, servingsPerContainer: $servingsPerContainer, caloriesKcal: $caloriesKcal, totalFatMg: $totalFatMg, saturatedFatMg: $saturatedFatMg, transFatMg: $transFatMg, cholesterolMg: $cholesterolMg, sodiumMg: $sodiumMg, totalCarbohydrateMg: $totalCarbohydrateMg, fibreMg: $fibreMg, sugarsMg: $sugarsMg, proteinMg: $proteinMg, vitaminAMcg: $vitaminAMcg, vitaminCMg: $vitaminCMg, calciumMg: $calciumMg, ironMg: $ironMg, addedSugarsMg: $addedSugarsMg, potassiumMg: $potassiumMg, vitaminDMcg: $vitaminDMcg)';
}


}

/// @nodoc
abstract mixin class $NutritionFactsCopyWith<$Res>  {
  factory $NutritionFactsCopyWith(NutritionFacts value, $Res Function(NutritionFacts) _then) = _$NutritionFactsCopyWithImpl;
@useResult
$Res call({
 int servingSizeAmount, String servingSizeUnit, int? servingsPerContainer, int caloriesKcal, int totalFatMg, int saturatedFatMg, int transFatMg, int cholesterolMg, int sodiumMg, int totalCarbohydrateMg, int fibreMg, int sugarsMg, int proteinMg, int vitaminAMcg, int vitaminCMg, int calciumMg, int ironMg, int? addedSugarsMg, int? potassiumMg, int? vitaminDMcg
});




}
/// @nodoc
class _$NutritionFactsCopyWithImpl<$Res>
    implements $NutritionFactsCopyWith<$Res> {
  _$NutritionFactsCopyWithImpl(this._self, this._then);

  final NutritionFacts _self;
  final $Res Function(NutritionFacts) _then;

/// Create a copy of NutritionFacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? servingSizeAmount = null,Object? servingSizeUnit = null,Object? servingsPerContainer = freezed,Object? caloriesKcal = null,Object? totalFatMg = null,Object? saturatedFatMg = null,Object? transFatMg = null,Object? cholesterolMg = null,Object? sodiumMg = null,Object? totalCarbohydrateMg = null,Object? fibreMg = null,Object? sugarsMg = null,Object? proteinMg = null,Object? vitaminAMcg = null,Object? vitaminCMg = null,Object? calciumMg = null,Object? ironMg = null,Object? addedSugarsMg = freezed,Object? potassiumMg = freezed,Object? vitaminDMcg = freezed,}) {
  return _then(_self.copyWith(
servingSizeAmount: null == servingSizeAmount ? _self.servingSizeAmount : servingSizeAmount // ignore: cast_nullable_to_non_nullable
as int,servingSizeUnit: null == servingSizeUnit ? _self.servingSizeUnit : servingSizeUnit // ignore: cast_nullable_to_non_nullable
as String,servingsPerContainer: freezed == servingsPerContainer ? _self.servingsPerContainer : servingsPerContainer // ignore: cast_nullable_to_non_nullable
as int?,caloriesKcal: null == caloriesKcal ? _self.caloriesKcal : caloriesKcal // ignore: cast_nullable_to_non_nullable
as int,totalFatMg: null == totalFatMg ? _self.totalFatMg : totalFatMg // ignore: cast_nullable_to_non_nullable
as int,saturatedFatMg: null == saturatedFatMg ? _self.saturatedFatMg : saturatedFatMg // ignore: cast_nullable_to_non_nullable
as int,transFatMg: null == transFatMg ? _self.transFatMg : transFatMg // ignore: cast_nullable_to_non_nullable
as int,cholesterolMg: null == cholesterolMg ? _self.cholesterolMg : cholesterolMg // ignore: cast_nullable_to_non_nullable
as int,sodiumMg: null == sodiumMg ? _self.sodiumMg : sodiumMg // ignore: cast_nullable_to_non_nullable
as int,totalCarbohydrateMg: null == totalCarbohydrateMg ? _self.totalCarbohydrateMg : totalCarbohydrateMg // ignore: cast_nullable_to_non_nullable
as int,fibreMg: null == fibreMg ? _self.fibreMg : fibreMg // ignore: cast_nullable_to_non_nullable
as int,sugarsMg: null == sugarsMg ? _self.sugarsMg : sugarsMg // ignore: cast_nullable_to_non_nullable
as int,proteinMg: null == proteinMg ? _self.proteinMg : proteinMg // ignore: cast_nullable_to_non_nullable
as int,vitaminAMcg: null == vitaminAMcg ? _self.vitaminAMcg : vitaminAMcg // ignore: cast_nullable_to_non_nullable
as int,vitaminCMg: null == vitaminCMg ? _self.vitaminCMg : vitaminCMg // ignore: cast_nullable_to_non_nullable
as int,calciumMg: null == calciumMg ? _self.calciumMg : calciumMg // ignore: cast_nullable_to_non_nullable
as int,ironMg: null == ironMg ? _self.ironMg : ironMg // ignore: cast_nullable_to_non_nullable
as int,addedSugarsMg: freezed == addedSugarsMg ? _self.addedSugarsMg : addedSugarsMg // ignore: cast_nullable_to_non_nullable
as int?,potassiumMg: freezed == potassiumMg ? _self.potassiumMg : potassiumMg // ignore: cast_nullable_to_non_nullable
as int?,vitaminDMcg: freezed == vitaminDMcg ? _self.vitaminDMcg : vitaminDMcg // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [NutritionFacts].
extension NutritionFactsPatterns on NutritionFacts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NutritionFacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NutritionFacts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NutritionFacts value)  $default,){
final _that = this;
switch (_that) {
case _NutritionFacts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NutritionFacts value)?  $default,){
final _that = this;
switch (_that) {
case _NutritionFacts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int servingSizeAmount,  String servingSizeUnit,  int? servingsPerContainer,  int caloriesKcal,  int totalFatMg,  int saturatedFatMg,  int transFatMg,  int cholesterolMg,  int sodiumMg,  int totalCarbohydrateMg,  int fibreMg,  int sugarsMg,  int proteinMg,  int vitaminAMcg,  int vitaminCMg,  int calciumMg,  int ironMg,  int? addedSugarsMg,  int? potassiumMg,  int? vitaminDMcg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NutritionFacts() when $default != null:
return $default(_that.servingSizeAmount,_that.servingSizeUnit,_that.servingsPerContainer,_that.caloriesKcal,_that.totalFatMg,_that.saturatedFatMg,_that.transFatMg,_that.cholesterolMg,_that.sodiumMg,_that.totalCarbohydrateMg,_that.fibreMg,_that.sugarsMg,_that.proteinMg,_that.vitaminAMcg,_that.vitaminCMg,_that.calciumMg,_that.ironMg,_that.addedSugarsMg,_that.potassiumMg,_that.vitaminDMcg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int servingSizeAmount,  String servingSizeUnit,  int? servingsPerContainer,  int caloriesKcal,  int totalFatMg,  int saturatedFatMg,  int transFatMg,  int cholesterolMg,  int sodiumMg,  int totalCarbohydrateMg,  int fibreMg,  int sugarsMg,  int proteinMg,  int vitaminAMcg,  int vitaminCMg,  int calciumMg,  int ironMg,  int? addedSugarsMg,  int? potassiumMg,  int? vitaminDMcg)  $default,) {final _that = this;
switch (_that) {
case _NutritionFacts():
return $default(_that.servingSizeAmount,_that.servingSizeUnit,_that.servingsPerContainer,_that.caloriesKcal,_that.totalFatMg,_that.saturatedFatMg,_that.transFatMg,_that.cholesterolMg,_that.sodiumMg,_that.totalCarbohydrateMg,_that.fibreMg,_that.sugarsMg,_that.proteinMg,_that.vitaminAMcg,_that.vitaminCMg,_that.calciumMg,_that.ironMg,_that.addedSugarsMg,_that.potassiumMg,_that.vitaminDMcg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int servingSizeAmount,  String servingSizeUnit,  int? servingsPerContainer,  int caloriesKcal,  int totalFatMg,  int saturatedFatMg,  int transFatMg,  int cholesterolMg,  int sodiumMg,  int totalCarbohydrateMg,  int fibreMg,  int sugarsMg,  int proteinMg,  int vitaminAMcg,  int vitaminCMg,  int calciumMg,  int ironMg,  int? addedSugarsMg,  int? potassiumMg,  int? vitaminDMcg)?  $default,) {final _that = this;
switch (_that) {
case _NutritionFacts() when $default != null:
return $default(_that.servingSizeAmount,_that.servingSizeUnit,_that.servingsPerContainer,_that.caloriesKcal,_that.totalFatMg,_that.saturatedFatMg,_that.transFatMg,_that.cholesterolMg,_that.sodiumMg,_that.totalCarbohydrateMg,_that.fibreMg,_that.sugarsMg,_that.proteinMg,_that.vitaminAMcg,_that.vitaminCMg,_that.calciumMg,_that.ironMg,_that.addedSugarsMg,_that.potassiumMg,_that.vitaminDMcg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NutritionFacts implements NutritionFacts {
  const _NutritionFacts({required this.servingSizeAmount, required this.servingSizeUnit, this.servingsPerContainer, required this.caloriesKcal, required this.totalFatMg, required this.saturatedFatMg, required this.transFatMg, required this.cholesterolMg, required this.sodiumMg, required this.totalCarbohydrateMg, required this.fibreMg, required this.sugarsMg, required this.proteinMg, required this.vitaminAMcg, required this.vitaminCMg, required this.calciumMg, required this.ironMg, this.addedSugarsMg, this.potassiumMg, this.vitaminDMcg});
  factory _NutritionFacts.fromJson(Map<String, dynamic> json) => _$NutritionFactsFromJson(json);

/// Serving size numeric amount (e.g., 250 for "250 mL")
@override final  int servingSizeAmount;
/// Serving size unit: "g" or "mL"
@override final  String servingSizeUnit;
/// Number of servings per container (null if not specified)
@override final  int? servingsPerContainer;
// === Mandatory Health Canada nutrients ===
@override final  int caloriesKcal;
@override final  int totalFatMg;
@override final  int saturatedFatMg;
@override final  int transFatMg;
@override final  int cholesterolMg;
@override final  int sodiumMg;
@override final  int totalCarbohydrateMg;
@override final  int fibreMg;
@override final  int sugarsMg;
@override final  int proteinMg;
@override final  int vitaminAMcg;
@override final  int vitaminCMg;
@override final  int calciumMg;
@override final  int ironMg;
// === Optional additional nutrients ===
/// Added sugars (newer Health Canada recommendation)
@override final  int? addedSugarsMg;
/// Potassium (optional in standard NFT)
@override final  int? potassiumMg;
/// Vitamin D (optional in standard NFT)
@override final  int? vitaminDMcg;

/// Create a copy of NutritionFacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NutritionFactsCopyWith<_NutritionFacts> get copyWith => __$NutritionFactsCopyWithImpl<_NutritionFacts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NutritionFactsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NutritionFacts&&(identical(other.servingSizeAmount, servingSizeAmount) || other.servingSizeAmount == servingSizeAmount)&&(identical(other.servingSizeUnit, servingSizeUnit) || other.servingSizeUnit == servingSizeUnit)&&(identical(other.servingsPerContainer, servingsPerContainer) || other.servingsPerContainer == servingsPerContainer)&&(identical(other.caloriesKcal, caloriesKcal) || other.caloriesKcal == caloriesKcal)&&(identical(other.totalFatMg, totalFatMg) || other.totalFatMg == totalFatMg)&&(identical(other.saturatedFatMg, saturatedFatMg) || other.saturatedFatMg == saturatedFatMg)&&(identical(other.transFatMg, transFatMg) || other.transFatMg == transFatMg)&&(identical(other.cholesterolMg, cholesterolMg) || other.cholesterolMg == cholesterolMg)&&(identical(other.sodiumMg, sodiumMg) || other.sodiumMg == sodiumMg)&&(identical(other.totalCarbohydrateMg, totalCarbohydrateMg) || other.totalCarbohydrateMg == totalCarbohydrateMg)&&(identical(other.fibreMg, fibreMg) || other.fibreMg == fibreMg)&&(identical(other.sugarsMg, sugarsMg) || other.sugarsMg == sugarsMg)&&(identical(other.proteinMg, proteinMg) || other.proteinMg == proteinMg)&&(identical(other.vitaminAMcg, vitaminAMcg) || other.vitaminAMcg == vitaminAMcg)&&(identical(other.vitaminCMg, vitaminCMg) || other.vitaminCMg == vitaminCMg)&&(identical(other.calciumMg, calciumMg) || other.calciumMg == calciumMg)&&(identical(other.ironMg, ironMg) || other.ironMg == ironMg)&&(identical(other.addedSugarsMg, addedSugarsMg) || other.addedSugarsMg == addedSugarsMg)&&(identical(other.potassiumMg, potassiumMg) || other.potassiumMg == potassiumMg)&&(identical(other.vitaminDMcg, vitaminDMcg) || other.vitaminDMcg == vitaminDMcg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,servingSizeAmount,servingSizeUnit,servingsPerContainer,caloriesKcal,totalFatMg,saturatedFatMg,transFatMg,cholesterolMg,sodiumMg,totalCarbohydrateMg,fibreMg,sugarsMg,proteinMg,vitaminAMcg,vitaminCMg,calciumMg,ironMg,addedSugarsMg,potassiumMg,vitaminDMcg]);

@override
String toString() {
  return 'NutritionFacts(servingSizeAmount: $servingSizeAmount, servingSizeUnit: $servingSizeUnit, servingsPerContainer: $servingsPerContainer, caloriesKcal: $caloriesKcal, totalFatMg: $totalFatMg, saturatedFatMg: $saturatedFatMg, transFatMg: $transFatMg, cholesterolMg: $cholesterolMg, sodiumMg: $sodiumMg, totalCarbohydrateMg: $totalCarbohydrateMg, fibreMg: $fibreMg, sugarsMg: $sugarsMg, proteinMg: $proteinMg, vitaminAMcg: $vitaminAMcg, vitaminCMg: $vitaminCMg, calciumMg: $calciumMg, ironMg: $ironMg, addedSugarsMg: $addedSugarsMg, potassiumMg: $potassiumMg, vitaminDMcg: $vitaminDMcg)';
}


}

/// @nodoc
abstract mixin class _$NutritionFactsCopyWith<$Res> implements $NutritionFactsCopyWith<$Res> {
  factory _$NutritionFactsCopyWith(_NutritionFacts value, $Res Function(_NutritionFacts) _then) = __$NutritionFactsCopyWithImpl;
@override @useResult
$Res call({
 int servingSizeAmount, String servingSizeUnit, int? servingsPerContainer, int caloriesKcal, int totalFatMg, int saturatedFatMg, int transFatMg, int cholesterolMg, int sodiumMg, int totalCarbohydrateMg, int fibreMg, int sugarsMg, int proteinMg, int vitaminAMcg, int vitaminCMg, int calciumMg, int ironMg, int? addedSugarsMg, int? potassiumMg, int? vitaminDMcg
});




}
/// @nodoc
class __$NutritionFactsCopyWithImpl<$Res>
    implements _$NutritionFactsCopyWith<$Res> {
  __$NutritionFactsCopyWithImpl(this._self, this._then);

  final _NutritionFacts _self;
  final $Res Function(_NutritionFacts) _then;

/// Create a copy of NutritionFacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? servingSizeAmount = null,Object? servingSizeUnit = null,Object? servingsPerContainer = freezed,Object? caloriesKcal = null,Object? totalFatMg = null,Object? saturatedFatMg = null,Object? transFatMg = null,Object? cholesterolMg = null,Object? sodiumMg = null,Object? totalCarbohydrateMg = null,Object? fibreMg = null,Object? sugarsMg = null,Object? proteinMg = null,Object? vitaminAMcg = null,Object? vitaminCMg = null,Object? calciumMg = null,Object? ironMg = null,Object? addedSugarsMg = freezed,Object? potassiumMg = freezed,Object? vitaminDMcg = freezed,}) {
  return _then(_NutritionFacts(
servingSizeAmount: null == servingSizeAmount ? _self.servingSizeAmount : servingSizeAmount // ignore: cast_nullable_to_non_nullable
as int,servingSizeUnit: null == servingSizeUnit ? _self.servingSizeUnit : servingSizeUnit // ignore: cast_nullable_to_non_nullable
as String,servingsPerContainer: freezed == servingsPerContainer ? _self.servingsPerContainer : servingsPerContainer // ignore: cast_nullable_to_non_nullable
as int?,caloriesKcal: null == caloriesKcal ? _self.caloriesKcal : caloriesKcal // ignore: cast_nullable_to_non_nullable
as int,totalFatMg: null == totalFatMg ? _self.totalFatMg : totalFatMg // ignore: cast_nullable_to_non_nullable
as int,saturatedFatMg: null == saturatedFatMg ? _self.saturatedFatMg : saturatedFatMg // ignore: cast_nullable_to_non_nullable
as int,transFatMg: null == transFatMg ? _self.transFatMg : transFatMg // ignore: cast_nullable_to_non_nullable
as int,cholesterolMg: null == cholesterolMg ? _self.cholesterolMg : cholesterolMg // ignore: cast_nullable_to_non_nullable
as int,sodiumMg: null == sodiumMg ? _self.sodiumMg : sodiumMg // ignore: cast_nullable_to_non_nullable
as int,totalCarbohydrateMg: null == totalCarbohydrateMg ? _self.totalCarbohydrateMg : totalCarbohydrateMg // ignore: cast_nullable_to_non_nullable
as int,fibreMg: null == fibreMg ? _self.fibreMg : fibreMg // ignore: cast_nullable_to_non_nullable
as int,sugarsMg: null == sugarsMg ? _self.sugarsMg : sugarsMg // ignore: cast_nullable_to_non_nullable
as int,proteinMg: null == proteinMg ? _self.proteinMg : proteinMg // ignore: cast_nullable_to_non_nullable
as int,vitaminAMcg: null == vitaminAMcg ? _self.vitaminAMcg : vitaminAMcg // ignore: cast_nullable_to_non_nullable
as int,vitaminCMg: null == vitaminCMg ? _self.vitaminCMg : vitaminCMg // ignore: cast_nullable_to_non_nullable
as int,calciumMg: null == calciumMg ? _self.calciumMg : calciumMg // ignore: cast_nullable_to_non_nullable
as int,ironMg: null == ironMg ? _self.ironMg : ironMg // ignore: cast_nullable_to_non_nullable
as int,addedSugarsMg: freezed == addedSugarsMg ? _self.addedSugarsMg : addedSugarsMg // ignore: cast_nullable_to_non_nullable
as int?,potassiumMg: freezed == potassiumMg ? _self.potassiumMg : potassiumMg // ignore: cast_nullable_to_non_nullable
as int?,vitaminDMcg: freezed == vitaminDMcg ? _self.vitaminDMcg : vitaminDMcg // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$FoodMetadata {

/// Ingredients in English (descending order of weight — CFIA requirement)
 String? get ingredientsEn;/// Ingredients in French (bilingual — CFIA / Bill 96 requirement)
 String? get ingredientsFr;/// Confirmed allergens from [AllergenValues] (11 Canadian priority categories)
 List<String> get allergens;/// "May contain" / trace allergens
 List<String> get mayContainAllergens;/// Storage instructions in English
 String? get storageInstructionsEn;/// Storage instructions in French
 String? get storageInstructionsFr;/// Shelf life in days from production date
 int? get bestBeforeDays;/// Dietary badges from [DietaryBadgeValues] (organic, vegan, etc.)
 List<String> get dietaryBadges;/// Health Canada FOP: product is high in sodium (>= 345mg/serving)
 bool get fopHighSodium;/// Health Canada FOP: product is high in sugars (>= 15g/serving)
 bool get fopHighSugars;/// Health Canada FOP: product is high in saturated fat (>= 3g/serving)
 bool get fopHighSaturatedFat;
/// Create a copy of FoodMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodMetadataCopyWith<FoodMetadata> get copyWith => _$FoodMetadataCopyWithImpl<FoodMetadata>(this as FoodMetadata, _$identity);

  /// Serializes this FoodMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodMetadata&&(identical(other.ingredientsEn, ingredientsEn) || other.ingredientsEn == ingredientsEn)&&(identical(other.ingredientsFr, ingredientsFr) || other.ingredientsFr == ingredientsFr)&&const DeepCollectionEquality().equals(other.allergens, allergens)&&const DeepCollectionEquality().equals(other.mayContainAllergens, mayContainAllergens)&&(identical(other.storageInstructionsEn, storageInstructionsEn) || other.storageInstructionsEn == storageInstructionsEn)&&(identical(other.storageInstructionsFr, storageInstructionsFr) || other.storageInstructionsFr == storageInstructionsFr)&&(identical(other.bestBeforeDays, bestBeforeDays) || other.bestBeforeDays == bestBeforeDays)&&const DeepCollectionEquality().equals(other.dietaryBadges, dietaryBadges)&&(identical(other.fopHighSodium, fopHighSodium) || other.fopHighSodium == fopHighSodium)&&(identical(other.fopHighSugars, fopHighSugars) || other.fopHighSugars == fopHighSugars)&&(identical(other.fopHighSaturatedFat, fopHighSaturatedFat) || other.fopHighSaturatedFat == fopHighSaturatedFat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ingredientsEn,ingredientsFr,const DeepCollectionEquality().hash(allergens),const DeepCollectionEquality().hash(mayContainAllergens),storageInstructionsEn,storageInstructionsFr,bestBeforeDays,const DeepCollectionEquality().hash(dietaryBadges),fopHighSodium,fopHighSugars,fopHighSaturatedFat);

@override
String toString() {
  return 'FoodMetadata(ingredientsEn: $ingredientsEn, ingredientsFr: $ingredientsFr, allergens: $allergens, mayContainAllergens: $mayContainAllergens, storageInstructionsEn: $storageInstructionsEn, storageInstructionsFr: $storageInstructionsFr, bestBeforeDays: $bestBeforeDays, dietaryBadges: $dietaryBadges, fopHighSodium: $fopHighSodium, fopHighSugars: $fopHighSugars, fopHighSaturatedFat: $fopHighSaturatedFat)';
}


}

/// @nodoc
abstract mixin class $FoodMetadataCopyWith<$Res>  {
  factory $FoodMetadataCopyWith(FoodMetadata value, $Res Function(FoodMetadata) _then) = _$FoodMetadataCopyWithImpl;
@useResult
$Res call({
 String? ingredientsEn, String? ingredientsFr, List<String> allergens, List<String> mayContainAllergens, String? storageInstructionsEn, String? storageInstructionsFr, int? bestBeforeDays, List<String> dietaryBadges, bool fopHighSodium, bool fopHighSugars, bool fopHighSaturatedFat
});




}
/// @nodoc
class _$FoodMetadataCopyWithImpl<$Res>
    implements $FoodMetadataCopyWith<$Res> {
  _$FoodMetadataCopyWithImpl(this._self, this._then);

  final FoodMetadata _self;
  final $Res Function(FoodMetadata) _then;

/// Create a copy of FoodMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ingredientsEn = freezed,Object? ingredientsFr = freezed,Object? allergens = null,Object? mayContainAllergens = null,Object? storageInstructionsEn = freezed,Object? storageInstructionsFr = freezed,Object? bestBeforeDays = freezed,Object? dietaryBadges = null,Object? fopHighSodium = null,Object? fopHighSugars = null,Object? fopHighSaturatedFat = null,}) {
  return _then(_self.copyWith(
ingredientsEn: freezed == ingredientsEn ? _self.ingredientsEn : ingredientsEn // ignore: cast_nullable_to_non_nullable
as String?,ingredientsFr: freezed == ingredientsFr ? _self.ingredientsFr : ingredientsFr // ignore: cast_nullable_to_non_nullable
as String?,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,mayContainAllergens: null == mayContainAllergens ? _self.mayContainAllergens : mayContainAllergens // ignore: cast_nullable_to_non_nullable
as List<String>,storageInstructionsEn: freezed == storageInstructionsEn ? _self.storageInstructionsEn : storageInstructionsEn // ignore: cast_nullable_to_non_nullable
as String?,storageInstructionsFr: freezed == storageInstructionsFr ? _self.storageInstructionsFr : storageInstructionsFr // ignore: cast_nullable_to_non_nullable
as String?,bestBeforeDays: freezed == bestBeforeDays ? _self.bestBeforeDays : bestBeforeDays // ignore: cast_nullable_to_non_nullable
as int?,dietaryBadges: null == dietaryBadges ? _self.dietaryBadges : dietaryBadges // ignore: cast_nullable_to_non_nullable
as List<String>,fopHighSodium: null == fopHighSodium ? _self.fopHighSodium : fopHighSodium // ignore: cast_nullable_to_non_nullable
as bool,fopHighSugars: null == fopHighSugars ? _self.fopHighSugars : fopHighSugars // ignore: cast_nullable_to_non_nullable
as bool,fopHighSaturatedFat: null == fopHighSaturatedFat ? _self.fopHighSaturatedFat : fopHighSaturatedFat // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodMetadata].
extension FoodMetadataPatterns on FoodMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodMetadata value)  $default,){
final _that = this;
switch (_that) {
case _FoodMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _FoodMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? ingredientsEn,  String? ingredientsFr,  List<String> allergens,  List<String> mayContainAllergens,  String? storageInstructionsEn,  String? storageInstructionsFr,  int? bestBeforeDays,  List<String> dietaryBadges,  bool fopHighSodium,  bool fopHighSugars,  bool fopHighSaturatedFat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodMetadata() when $default != null:
return $default(_that.ingredientsEn,_that.ingredientsFr,_that.allergens,_that.mayContainAllergens,_that.storageInstructionsEn,_that.storageInstructionsFr,_that.bestBeforeDays,_that.dietaryBadges,_that.fopHighSodium,_that.fopHighSugars,_that.fopHighSaturatedFat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? ingredientsEn,  String? ingredientsFr,  List<String> allergens,  List<String> mayContainAllergens,  String? storageInstructionsEn,  String? storageInstructionsFr,  int? bestBeforeDays,  List<String> dietaryBadges,  bool fopHighSodium,  bool fopHighSugars,  bool fopHighSaturatedFat)  $default,) {final _that = this;
switch (_that) {
case _FoodMetadata():
return $default(_that.ingredientsEn,_that.ingredientsFr,_that.allergens,_that.mayContainAllergens,_that.storageInstructionsEn,_that.storageInstructionsFr,_that.bestBeforeDays,_that.dietaryBadges,_that.fopHighSodium,_that.fopHighSugars,_that.fopHighSaturatedFat);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? ingredientsEn,  String? ingredientsFr,  List<String> allergens,  List<String> mayContainAllergens,  String? storageInstructionsEn,  String? storageInstructionsFr,  int? bestBeforeDays,  List<String> dietaryBadges,  bool fopHighSodium,  bool fopHighSugars,  bool fopHighSaturatedFat)?  $default,) {final _that = this;
switch (_that) {
case _FoodMetadata() when $default != null:
return $default(_that.ingredientsEn,_that.ingredientsFr,_that.allergens,_that.mayContainAllergens,_that.storageInstructionsEn,_that.storageInstructionsFr,_that.bestBeforeDays,_that.dietaryBadges,_that.fopHighSodium,_that.fopHighSugars,_that.fopHighSaturatedFat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FoodMetadata implements FoodMetadata {
  const _FoodMetadata({this.ingredientsEn, this.ingredientsFr, final  List<String> allergens = const [], final  List<String> mayContainAllergens = const [], this.storageInstructionsEn, this.storageInstructionsFr, this.bestBeforeDays, final  List<String> dietaryBadges = const [], this.fopHighSodium = false, this.fopHighSugars = false, this.fopHighSaturatedFat = false}): _allergens = allergens,_mayContainAllergens = mayContainAllergens,_dietaryBadges = dietaryBadges;
  factory _FoodMetadata.fromJson(Map<String, dynamic> json) => _$FoodMetadataFromJson(json);

/// Ingredients in English (descending order of weight — CFIA requirement)
@override final  String? ingredientsEn;
/// Ingredients in French (bilingual — CFIA / Bill 96 requirement)
@override final  String? ingredientsFr;
/// Confirmed allergens from [AllergenValues] (11 Canadian priority categories)
 final  List<String> _allergens;
/// Confirmed allergens from [AllergenValues] (11 Canadian priority categories)
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}

/// "May contain" / trace allergens
 final  List<String> _mayContainAllergens;
/// "May contain" / trace allergens
@override@JsonKey() List<String> get mayContainAllergens {
  if (_mayContainAllergens is EqualUnmodifiableListView) return _mayContainAllergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mayContainAllergens);
}

/// Storage instructions in English
@override final  String? storageInstructionsEn;
/// Storage instructions in French
@override final  String? storageInstructionsFr;
/// Shelf life in days from production date
@override final  int? bestBeforeDays;
/// Dietary badges from [DietaryBadgeValues] (organic, vegan, etc.)
 final  List<String> _dietaryBadges;
/// Dietary badges from [DietaryBadgeValues] (organic, vegan, etc.)
@override@JsonKey() List<String> get dietaryBadges {
  if (_dietaryBadges is EqualUnmodifiableListView) return _dietaryBadges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryBadges);
}

/// Health Canada FOP: product is high in sodium (>= 345mg/serving)
@override@JsonKey() final  bool fopHighSodium;
/// Health Canada FOP: product is high in sugars (>= 15g/serving)
@override@JsonKey() final  bool fopHighSugars;
/// Health Canada FOP: product is high in saturated fat (>= 3g/serving)
@override@JsonKey() final  bool fopHighSaturatedFat;

/// Create a copy of FoodMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodMetadataCopyWith<_FoodMetadata> get copyWith => __$FoodMetadataCopyWithImpl<_FoodMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FoodMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodMetadata&&(identical(other.ingredientsEn, ingredientsEn) || other.ingredientsEn == ingredientsEn)&&(identical(other.ingredientsFr, ingredientsFr) || other.ingredientsFr == ingredientsFr)&&const DeepCollectionEquality().equals(other._allergens, _allergens)&&const DeepCollectionEquality().equals(other._mayContainAllergens, _mayContainAllergens)&&(identical(other.storageInstructionsEn, storageInstructionsEn) || other.storageInstructionsEn == storageInstructionsEn)&&(identical(other.storageInstructionsFr, storageInstructionsFr) || other.storageInstructionsFr == storageInstructionsFr)&&(identical(other.bestBeforeDays, bestBeforeDays) || other.bestBeforeDays == bestBeforeDays)&&const DeepCollectionEquality().equals(other._dietaryBadges, _dietaryBadges)&&(identical(other.fopHighSodium, fopHighSodium) || other.fopHighSodium == fopHighSodium)&&(identical(other.fopHighSugars, fopHighSugars) || other.fopHighSugars == fopHighSugars)&&(identical(other.fopHighSaturatedFat, fopHighSaturatedFat) || other.fopHighSaturatedFat == fopHighSaturatedFat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ingredientsEn,ingredientsFr,const DeepCollectionEquality().hash(_allergens),const DeepCollectionEquality().hash(_mayContainAllergens),storageInstructionsEn,storageInstructionsFr,bestBeforeDays,const DeepCollectionEquality().hash(_dietaryBadges),fopHighSodium,fopHighSugars,fopHighSaturatedFat);

@override
String toString() {
  return 'FoodMetadata(ingredientsEn: $ingredientsEn, ingredientsFr: $ingredientsFr, allergens: $allergens, mayContainAllergens: $mayContainAllergens, storageInstructionsEn: $storageInstructionsEn, storageInstructionsFr: $storageInstructionsFr, bestBeforeDays: $bestBeforeDays, dietaryBadges: $dietaryBadges, fopHighSodium: $fopHighSodium, fopHighSugars: $fopHighSugars, fopHighSaturatedFat: $fopHighSaturatedFat)';
}


}

/// @nodoc
abstract mixin class _$FoodMetadataCopyWith<$Res> implements $FoodMetadataCopyWith<$Res> {
  factory _$FoodMetadataCopyWith(_FoodMetadata value, $Res Function(_FoodMetadata) _then) = __$FoodMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? ingredientsEn, String? ingredientsFr, List<String> allergens, List<String> mayContainAllergens, String? storageInstructionsEn, String? storageInstructionsFr, int? bestBeforeDays, List<String> dietaryBadges, bool fopHighSodium, bool fopHighSugars, bool fopHighSaturatedFat
});




}
/// @nodoc
class __$FoodMetadataCopyWithImpl<$Res>
    implements _$FoodMetadataCopyWith<$Res> {
  __$FoodMetadataCopyWithImpl(this._self, this._then);

  final _FoodMetadata _self;
  final $Res Function(_FoodMetadata) _then;

/// Create a copy of FoodMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ingredientsEn = freezed,Object? ingredientsFr = freezed,Object? allergens = null,Object? mayContainAllergens = null,Object? storageInstructionsEn = freezed,Object? storageInstructionsFr = freezed,Object? bestBeforeDays = freezed,Object? dietaryBadges = null,Object? fopHighSodium = null,Object? fopHighSugars = null,Object? fopHighSaturatedFat = null,}) {
  return _then(_FoodMetadata(
ingredientsEn: freezed == ingredientsEn ? _self.ingredientsEn : ingredientsEn // ignore: cast_nullable_to_non_nullable
as String?,ingredientsFr: freezed == ingredientsFr ? _self.ingredientsFr : ingredientsFr // ignore: cast_nullable_to_non_nullable
as String?,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,mayContainAllergens: null == mayContainAllergens ? _self._mayContainAllergens : mayContainAllergens // ignore: cast_nullable_to_non_nullable
as List<String>,storageInstructionsEn: freezed == storageInstructionsEn ? _self.storageInstructionsEn : storageInstructionsEn // ignore: cast_nullable_to_non_nullable
as String?,storageInstructionsFr: freezed == storageInstructionsFr ? _self.storageInstructionsFr : storageInstructionsFr // ignore: cast_nullable_to_non_nullable
as String?,bestBeforeDays: freezed == bestBeforeDays ? _self.bestBeforeDays : bestBeforeDays // ignore: cast_nullable_to_non_nullable
as int?,dietaryBadges: null == dietaryBadges ? _self._dietaryBadges : dietaryBadges // ignore: cast_nullable_to_non_nullable
as List<String>,fopHighSodium: null == fopHighSodium ? _self.fopHighSodium : fopHighSodium // ignore: cast_nullable_to_non_nullable
as bool,fopHighSugars: null == fopHighSugars ? _self.fopHighSugars : fopHighSugars // ignore: cast_nullable_to_non_nullable
as bool,fopHighSaturatedFat: null == fopHighSaturatedFat ? _self.fopHighSaturatedFat : fopHighSaturatedFat // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProductSpec {

 String get key; String get value; String get valueType; String? get unit; String? get group;
/// Create a copy of ProductSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductSpecCopyWith<ProductSpec> get copyWith => _$ProductSpecCopyWithImpl<ProductSpec>(this as ProductSpec, _$identity);

  /// Serializes this ProductSpec to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductSpec&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value)&&(identical(other.valueType, valueType) || other.valueType == valueType)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.group, group) || other.group == group));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,value,valueType,unit,group);

@override
String toString() {
  return 'ProductSpec(key: $key, value: $value, valueType: $valueType, unit: $unit, group: $group)';
}


}

/// @nodoc
abstract mixin class $ProductSpecCopyWith<$Res>  {
  factory $ProductSpecCopyWith(ProductSpec value, $Res Function(ProductSpec) _then) = _$ProductSpecCopyWithImpl;
@useResult
$Res call({
 String key, String value, String valueType, String? unit, String? group
});




}
/// @nodoc
class _$ProductSpecCopyWithImpl<$Res>
    implements $ProductSpecCopyWith<$Res> {
  _$ProductSpecCopyWithImpl(this._self, this._then);

  final ProductSpec _self;
  final $Res Function(ProductSpec) _then;

/// Create a copy of ProductSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? value = null,Object? valueType = null,Object? unit = freezed,Object? group = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,valueType: null == valueType ? _self.valueType : valueType // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductSpec].
extension ProductSpecPatterns on ProductSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductSpec value)  $default,){
final _that = this;
switch (_that) {
case _ProductSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductSpec value)?  $default,){
final _that = this;
switch (_that) {
case _ProductSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String value,  String valueType,  String? unit,  String? group)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductSpec() when $default != null:
return $default(_that.key,_that.value,_that.valueType,_that.unit,_that.group);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String value,  String valueType,  String? unit,  String? group)  $default,) {final _that = this;
switch (_that) {
case _ProductSpec():
return $default(_that.key,_that.value,_that.valueType,_that.unit,_that.group);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String value,  String valueType,  String? unit,  String? group)?  $default,) {final _that = this;
switch (_that) {
case _ProductSpec() when $default != null:
return $default(_that.key,_that.value,_that.valueType,_that.unit,_that.group);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductSpec implements ProductSpec {
  const _ProductSpec({required this.key, required this.value, this.valueType = 'text', this.unit, this.group});
  factory _ProductSpec.fromJson(Map<String, dynamic> json) => _$ProductSpecFromJson(json);

@override final  String key;
@override final  String value;
@override@JsonKey() final  String valueType;
@override final  String? unit;
@override final  String? group;

/// Create a copy of ProductSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductSpecCopyWith<_ProductSpec> get copyWith => __$ProductSpecCopyWithImpl<_ProductSpec>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductSpecToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductSpec&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value)&&(identical(other.valueType, valueType) || other.valueType == valueType)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.group, group) || other.group == group));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,value,valueType,unit,group);

@override
String toString() {
  return 'ProductSpec(key: $key, value: $value, valueType: $valueType, unit: $unit, group: $group)';
}


}

/// @nodoc
abstract mixin class _$ProductSpecCopyWith<$Res> implements $ProductSpecCopyWith<$Res> {
  factory _$ProductSpecCopyWith(_ProductSpec value, $Res Function(_ProductSpec) _then) = __$ProductSpecCopyWithImpl;
@override @useResult
$Res call({
 String key, String value, String valueType, String? unit, String? group
});




}
/// @nodoc
class __$ProductSpecCopyWithImpl<$Res>
    implements _$ProductSpecCopyWith<$Res> {
  __$ProductSpecCopyWithImpl(this._self, this._then);

  final _ProductSpec _self;
  final $Res Function(_ProductSpec) _then;

/// Create a copy of ProductSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,Object? valueType = null,Object? unit = freezed,Object? group = freezed,}) {
  return _then(_ProductSpec(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,valueType: null == valueType ? _self.valueType : valueType // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProductSpecs {

 List<ProductSpec> get specs; String? get brand; String? get color; String? get material;
/// Create a copy of ProductSpecs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductSpecsCopyWith<ProductSpecs> get copyWith => _$ProductSpecsCopyWithImpl<ProductSpecs>(this as ProductSpecs, _$identity);

  /// Serializes this ProductSpecs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductSpecs&&const DeepCollectionEquality().equals(other.specs, specs)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.color, color) || other.color == color)&&(identical(other.material, material) || other.material == material));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(specs),brand,color,material);

@override
String toString() {
  return 'ProductSpecs(specs: $specs, brand: $brand, color: $color, material: $material)';
}


}

/// @nodoc
abstract mixin class $ProductSpecsCopyWith<$Res>  {
  factory $ProductSpecsCopyWith(ProductSpecs value, $Res Function(ProductSpecs) _then) = _$ProductSpecsCopyWithImpl;
@useResult
$Res call({
 List<ProductSpec> specs, String? brand, String? color, String? material
});




}
/// @nodoc
class _$ProductSpecsCopyWithImpl<$Res>
    implements $ProductSpecsCopyWith<$Res> {
  _$ProductSpecsCopyWithImpl(this._self, this._then);

  final ProductSpecs _self;
  final $Res Function(ProductSpecs) _then;

/// Create a copy of ProductSpecs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? specs = null,Object? brand = freezed,Object? color = freezed,Object? material = freezed,}) {
  return _then(_self.copyWith(
specs: null == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as List<ProductSpec>,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductSpecs].
extension ProductSpecsPatterns on ProductSpecs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductSpecs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductSpecs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductSpecs value)  $default,){
final _that = this;
switch (_that) {
case _ProductSpecs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductSpecs value)?  $default,){
final _that = this;
switch (_that) {
case _ProductSpecs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProductSpec> specs,  String? brand,  String? color,  String? material)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductSpecs() when $default != null:
return $default(_that.specs,_that.brand,_that.color,_that.material);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProductSpec> specs,  String? brand,  String? color,  String? material)  $default,) {final _that = this;
switch (_that) {
case _ProductSpecs():
return $default(_that.specs,_that.brand,_that.color,_that.material);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProductSpec> specs,  String? brand,  String? color,  String? material)?  $default,) {final _that = this;
switch (_that) {
case _ProductSpecs() when $default != null:
return $default(_that.specs,_that.brand,_that.color,_that.material);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductSpecs implements ProductSpecs {
  const _ProductSpecs({final  List<ProductSpec> specs = const [], this.brand, this.color, this.material}): _specs = specs;
  factory _ProductSpecs.fromJson(Map<String, dynamic> json) => _$ProductSpecsFromJson(json);

 final  List<ProductSpec> _specs;
@override@JsonKey() List<ProductSpec> get specs {
  if (_specs is EqualUnmodifiableListView) return _specs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_specs);
}

@override final  String? brand;
@override final  String? color;
@override final  String? material;

/// Create a copy of ProductSpecs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductSpecsCopyWith<_ProductSpecs> get copyWith => __$ProductSpecsCopyWithImpl<_ProductSpecs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductSpecsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductSpecs&&const DeepCollectionEquality().equals(other._specs, _specs)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.color, color) || other.color == color)&&(identical(other.material, material) || other.material == material));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_specs),brand,color,material);

@override
String toString() {
  return 'ProductSpecs(specs: $specs, brand: $brand, color: $color, material: $material)';
}


}

/// @nodoc
abstract mixin class _$ProductSpecsCopyWith<$Res> implements $ProductSpecsCopyWith<$Res> {
  factory _$ProductSpecsCopyWith(_ProductSpecs value, $Res Function(_ProductSpecs) _then) = __$ProductSpecsCopyWithImpl;
@override @useResult
$Res call({
 List<ProductSpec> specs, String? brand, String? color, String? material
});




}
/// @nodoc
class __$ProductSpecsCopyWithImpl<$Res>
    implements _$ProductSpecsCopyWith<$Res> {
  __$ProductSpecsCopyWithImpl(this._self, this._then);

  final _ProductSpecs _self;
  final $Res Function(_ProductSpecs) _then;

/// Create a copy of ProductSpecs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? specs = null,Object? brand = freezed,Object? color = freezed,Object? material = freezed,}) {
  return _then(_ProductSpecs(
specs: null == specs ? _self._specs : specs // ignore: cast_nullable_to_non_nullable
as List<ProductSpec>,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Product {

 String get productId; String get name; String? get nameF; int get priceCents;/// Original/crossed-out price for discount display in cents (null = no sale, must be > priceCents)
 int? get compareAtPriceCents; String get description; String? get descriptionF; List<String> get imageUrls; String? get videoUrl; int? get videoDurationSeconds; String get sellerId; String? get madeInCountry;// sellerAddress is optional — products with warehouses use warehouseIds instead
 Address? get sellerAddress; int get categoryId; int get stockQuantity; double get rating; int get ratingCount; DateTime get createdAt;// Single lifecycle state replacing isActive + status + approvalStatus
 String get lifecycleStatus;// Optional shipping metadata
 double? get weightKg; String? get weightUnit; double? get lengthCm; double? get widthCm; double? get heightCm; String? get dimensionUnit;// Delivery options
 bool get isLocalDeliveryOnly; bool get isPerishable; int get estimatedShipDays; List<SellerDeliveryOption> get deliveryOptions; int get minimumOrderQuantity; bool get freeShipping;// Digital product flag
 bool get isDigital;// Age restriction flag — requires buyer age confirmation at checkout
 bool get isAgeRestricted; String? get digitalType; String? get slug; Map<String, String>? get digitalBuilds;// bookSourceUrl intentionally NOT included — buyer-protected: written by seller, never returned to client
 int? get deviceLimit;// Tax and metadata
 String? get taxCode; List<String> get keywords;// Admin rejection reason
 String? get approvalRejectionReason;// Flat supplier fields (used when supplier object is not provided)
 int? get costCents; String? get supplierSku; String? get supplierUrl;// Structured objects for scalability
/// Supplier information for dropshipping/marketplace products
 SupplierInfo? get supplier;/// Inventory management configuration
 InventoryConfig? get inventory;// Multi-warehouse support
/// Seller's unique product identifier — enforced unique per seller at write time
 String? get sellerSku;/// IDs of seller warehouses this product ships from
 List<String>? get warehouseIds;/// City of primary shipping warehouse (denormalized for O(1) card rendering)
 String? get shipFromCity;/// Province code of primary warehouse (denormalized for O(1) card rendering)
 String? get shipFromProvince;/// Country of primary warehouse (denormalized for O(1) card rendering)
 String? get shipFromCountry; List<String>? get shipFromCountries;// === TRENDING & ENGAGEMENT ===
 int get trendingScore; int get viewCount; int get purchaseCount; bool get isTrending; DateTime? get trendingAt;// === N-09: Product Variants ===
/// Whether this product has variants (size, color, etc.)
 bool get hasVariants;/// List of variant objects
 List<ProductVariant> get variants;/// Variant option definitions
 List<VariantOption> get variantOptions;// === N-11: Subcategories ===
/// Optional subcategory within the main category
 String? get subcategory;/// Product condition: new, like_new, good, fair, for_parts
 String? get condition;/// Per-warehouse stock allocation map: {warehouseId: stockQty}
/// Sum of values equals stockQuantity. Used for multi-warehouse inventory routing.
 Map<String, int>? get warehouseStockMap;/// Server-controlled last-updated timestamp
 DateTime? get updatedAt;// === FOOD & NUTRITION ===
/// Nutrition facts per serving (Health Canada NFT format)
 NutritionFacts? get nutritionFacts;/// Food metadata: ingredients, allergens, storage, dietary badges
 FoodMetadata? get foodMetadata;/// Structured product specifications (non-food categories)
 ProductSpecs? get specs;/// Seller-curated bundle: IDs of complementary products (max 5)
 List<String> get bundledProductIds;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameF, nameF) || other.nameF == nameF)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.compareAtPriceCents, compareAtPriceCents) || other.compareAtPriceCents == compareAtPriceCents)&&(identical(other.description, description) || other.description == description)&&(identical(other.descriptionF, descriptionF) || other.descriptionF == descriptionF)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.madeInCountry, madeInCountry) || other.madeInCountry == madeInCountry)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lifecycleStatus, lifecycleStatus) || other.lifecycleStatus == lifecycleStatus)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.weightUnit, weightUnit) || other.weightUnit == weightUnit)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.dimensionUnit, dimensionUnit) || other.dimensionUnit == dimensionUnit)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other.deliveryOptions, deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.isAgeRestricted, isAgeRestricted) || other.isAgeRestricted == isAgeRestricted)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other.digitalBuilds, digitalBuilds)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other.keywords, keywords)&&(identical(other.approvalRejectionReason, approvalRejectionReason) || other.approvalRejectionReason == approvalRejectionReason)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.sellerSku, sellerSku) || other.sellerSku == sellerSku)&&const DeepCollectionEquality().equals(other.warehouseIds, warehouseIds)&&(identical(other.shipFromCity, shipFromCity) || other.shipFromCity == shipFromCity)&&(identical(other.shipFromProvince, shipFromProvince) || other.shipFromProvince == shipFromProvince)&&(identical(other.shipFromCountry, shipFromCountry) || other.shipFromCountry == shipFromCountry)&&const DeepCollectionEquality().equals(other.shipFromCountries, shipFromCountries)&&(identical(other.trendingScore, trendingScore) || other.trendingScore == trendingScore)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount)&&(identical(other.isTrending, isTrending) || other.isTrending == isTrending)&&(identical(other.trendingAt, trendingAt) || other.trendingAt == trendingAt)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.variantOptions, variantOptions)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other.warehouseStockMap, warehouseStockMap)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.nutritionFacts, nutritionFacts) || other.nutritionFacts == nutritionFacts)&&(identical(other.foodMetadata, foodMetadata) || other.foodMetadata == foodMetadata)&&(identical(other.specs, specs) || other.specs == specs)&&const DeepCollectionEquality().equals(other.bundledProductIds, bundledProductIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,productId,name,nameF,priceCents,compareAtPriceCents,description,descriptionF,const DeepCollectionEquality().hash(imageUrls),videoUrl,videoDurationSeconds,sellerId,madeInCountry,sellerAddress,categoryId,stockQuantity,rating,ratingCount,createdAt,lifecycleStatus,weightKg,weightUnit,lengthCm,widthCm,heightCm,dimensionUnit,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,isAgeRestricted,digitalType,slug,const DeepCollectionEquality().hash(digitalBuilds),deviceLimit,taxCode,const DeepCollectionEquality().hash(keywords),approvalRejectionReason,costCents,supplierSku,supplierUrl,supplier,inventory,sellerSku,const DeepCollectionEquality().hash(warehouseIds),shipFromCity,shipFromProvince,shipFromCountry,const DeepCollectionEquality().hash(shipFromCountries),trendingScore,viewCount,purchaseCount,isTrending,trendingAt,hasVariants,const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(variantOptions),subcategory,condition,const DeepCollectionEquality().hash(warehouseStockMap),updatedAt,nutritionFacts,foodMetadata,specs,const DeepCollectionEquality().hash(bundledProductIds)]);

@override
String toString() {
  return 'Product(productId: $productId, name: $name, nameF: $nameF, priceCents: $priceCents, compareAtPriceCents: $compareAtPriceCents, description: $description, descriptionF: $descriptionF, imageUrls: $imageUrls, videoUrl: $videoUrl, videoDurationSeconds: $videoDurationSeconds, sellerId: $sellerId, madeInCountry: $madeInCountry, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, ratingCount: $ratingCount, createdAt: $createdAt, lifecycleStatus: $lifecycleStatus, weightKg: $weightKg, weightUnit: $weightUnit, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, dimensionUnit: $dimensionUnit, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, isAgeRestricted: $isAgeRestricted, digitalType: $digitalType, slug: $slug, digitalBuilds: $digitalBuilds, deviceLimit: $deviceLimit, taxCode: $taxCode, keywords: $keywords, approvalRejectionReason: $approvalRejectionReason, costCents: $costCents, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, sellerSku: $sellerSku, warehouseIds: $warehouseIds, shipFromCity: $shipFromCity, shipFromProvince: $shipFromProvince, shipFromCountry: $shipFromCountry, shipFromCountries: $shipFromCountries, trendingScore: $trendingScore, viewCount: $viewCount, purchaseCount: $purchaseCount, isTrending: $isTrending, trendingAt: $trendingAt, hasVariants: $hasVariants, variants: $variants, variantOptions: $variantOptions, subcategory: $subcategory, condition: $condition, warehouseStockMap: $warehouseStockMap, updatedAt: $updatedAt, nutritionFacts: $nutritionFacts, foodMetadata: $foodMetadata, specs: $specs, bundledProductIds: $bundledProductIds)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String productId, String name, String? nameF, int priceCents, int? compareAtPriceCents, String description, String? descriptionF, List<String> imageUrls, String? videoUrl, int? videoDurationSeconds, String sellerId, String? madeInCountry, Address? sellerAddress, int categoryId, int stockQuantity, double rating, int ratingCount, DateTime createdAt, String lifecycleStatus, double? weightKg, String? weightUnit, double? lengthCm, double? widthCm, double? heightCm, String? dimensionUnit, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, bool isAgeRestricted, String? digitalType, String? slug, Map<String, String>? digitalBuilds, int? deviceLimit, String? taxCode, List<String> keywords, String? approvalRejectionReason, int? costCents, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String? sellerSku, List<String>? warehouseIds, String? shipFromCity, String? shipFromProvince, String? shipFromCountry, List<String>? shipFromCountries, int trendingScore, int viewCount, int purchaseCount, bool isTrending, DateTime? trendingAt, bool hasVariants, List<ProductVariant> variants, List<VariantOption> variantOptions, String? subcategory, String? condition, Map<String, int>? warehouseStockMap, DateTime? updatedAt, NutritionFacts? nutritionFacts, FoodMetadata? foodMetadata, ProductSpecs? specs, List<String> bundledProductIds
});


$AddressCopyWith<$Res>? get sellerAddress;$SupplierInfoCopyWith<$Res>? get supplier;$InventoryConfigCopyWith<$Res>? get inventory;$NutritionFactsCopyWith<$Res>? get nutritionFacts;$FoodMetadataCopyWith<$Res>? get foodMetadata;$ProductSpecsCopyWith<$Res>? get specs;

}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? name = null,Object? nameF = freezed,Object? priceCents = null,Object? compareAtPriceCents = freezed,Object? description = null,Object? descriptionF = freezed,Object? imageUrls = null,Object? videoUrl = freezed,Object? videoDurationSeconds = freezed,Object? sellerId = null,Object? madeInCountry = freezed,Object? sellerAddress = freezed,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? ratingCount = null,Object? createdAt = null,Object? lifecycleStatus = null,Object? weightKg = freezed,Object? weightUnit = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? dimensionUnit = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? isAgeRestricted = null,Object? digitalType = freezed,Object? slug = freezed,Object? digitalBuilds = freezed,Object? deviceLimit = freezed,Object? taxCode = freezed,Object? keywords = null,Object? approvalRejectionReason = freezed,Object? costCents = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? sellerSku = freezed,Object? warehouseIds = freezed,Object? shipFromCity = freezed,Object? shipFromProvince = freezed,Object? shipFromCountry = freezed,Object? shipFromCountries = freezed,Object? trendingScore = null,Object? viewCount = null,Object? purchaseCount = null,Object? isTrending = null,Object? trendingAt = freezed,Object? hasVariants = null,Object? variants = null,Object? variantOptions = null,Object? subcategory = freezed,Object? condition = freezed,Object? warehouseStockMap = freezed,Object? updatedAt = freezed,Object? nutritionFacts = freezed,Object? foodMetadata = freezed,Object? specs = freezed,Object? bundledProductIds = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameF: freezed == nameF ? _self.nameF : nameF // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,compareAtPriceCents: freezed == compareAtPriceCents ? _self.compareAtPriceCents : compareAtPriceCents // ignore: cast_nullable_to_non_nullable
as int?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,descriptionF: freezed == descriptionF ? _self.descriptionF : descriptionF // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,madeInCountry: freezed == madeInCountry ? _self.madeInCountry : madeInCountry // ignore: cast_nullable_to_non_nullable
as String?,sellerAddress: freezed == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lifecycleStatus: null == lifecycleStatus ? _self.lifecycleStatus : lifecycleStatus // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,weightUnit: freezed == weightUnit ? _self.weightUnit : weightUnit // ignore: cast_nullable_to_non_nullable
as String?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,dimensionUnit: freezed == dimensionUnit ? _self.dimensionUnit : dimensionUnit // ignore: cast_nullable_to_non_nullable
as String?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self.deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,isAgeRestricted: null == isAgeRestricted ? _self.isAgeRestricted : isAgeRestricted // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,digitalBuilds: freezed == digitalBuilds ? _self.digitalBuilds : digitalBuilds // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,approvalRejectionReason: freezed == approvalRejectionReason ? _self.approvalRejectionReason : approvalRejectionReason // ignore: cast_nullable_to_non_nullable
as String?,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,sellerSku: freezed == sellerSku ? _self.sellerSku : sellerSku // ignore: cast_nullable_to_non_nullable
as String?,warehouseIds: freezed == warehouseIds ? _self.warehouseIds : warehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>?,shipFromCity: freezed == shipFromCity ? _self.shipFromCity : shipFromCity // ignore: cast_nullable_to_non_nullable
as String?,shipFromProvince: freezed == shipFromProvince ? _self.shipFromProvince : shipFromProvince // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountry: freezed == shipFromCountry ? _self.shipFromCountry : shipFromCountry // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountries: freezed == shipFromCountries ? _self.shipFromCountries : shipFromCountries // ignore: cast_nullable_to_non_nullable
as List<String>?,trendingScore: null == trendingScore ? _self.trendingScore : trendingScore // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,isTrending: null == isTrending ? _self.isTrending : isTrending // ignore: cast_nullable_to_non_nullable
as bool,trendingAt: freezed == trendingAt ? _self.trendingAt : trendingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,variantOptions: null == variantOptions ? _self.variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,subcategory: freezed == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,warehouseStockMap: freezed == warehouseStockMap ? _self.warehouseStockMap : warehouseStockMap // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,nutritionFacts: freezed == nutritionFacts ? _self.nutritionFacts : nutritionFacts // ignore: cast_nullable_to_non_nullable
as NutritionFacts?,foodMetadata: freezed == foodMetadata ? _self.foodMetadata : foodMetadata // ignore: cast_nullable_to_non_nullable
as FoodMetadata?,specs: freezed == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as ProductSpecs?,bundledProductIds: null == bundledProductIds ? _self.bundledProductIds : bundledProductIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get sellerAddress {
    if (_self.sellerAddress == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.sellerAddress!, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NutritionFactsCopyWith<$Res>? get nutritionFacts {
    if (_self.nutritionFacts == null) {
    return null;
  }

  return $NutritionFactsCopyWith<$Res>(_self.nutritionFacts!, (value) {
    return _then(_self.copyWith(nutritionFacts: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodMetadataCopyWith<$Res>? get foodMetadata {
    if (_self.foodMetadata == null) {
    return null;
  }

  return $FoodMetadataCopyWith<$Res>(_self.foodMetadata!, (value) {
    return _then(_self.copyWith(foodMetadata: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductSpecsCopyWith<$Res>? get specs {
    if (_self.specs == null) {
    return null;
  }

  return $ProductSpecsCopyWith<$Res>(_self.specs!, (value) {
    return _then(_self.copyWith(specs: value));
  });
}
}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String name,  String? nameF,  int priceCents,  int? compareAtPriceCents,  String description,  String? descriptionF,  List<String> imageUrls,  String? videoUrl,  int? videoDurationSeconds,  String sellerId,  String? madeInCountry,  Address? sellerAddress,  int categoryId,  int stockQuantity,  double rating,  int ratingCount,  DateTime createdAt,  String lifecycleStatus,  double? weightKg,  String? weightUnit,  double? lengthCm,  double? widthCm,  double? heightCm,  String? dimensionUnit,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? slug,  Map<String, String>? digitalBuilds,  int? deviceLimit,  String? taxCode,  List<String> keywords,  String? approvalRejectionReason,  int? costCents,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String? sellerSku,  List<String>? warehouseIds,  String? shipFromCity,  String? shipFromProvince,  String? shipFromCountry,  List<String>? shipFromCountries,  int trendingScore,  int viewCount,  int purchaseCount,  bool isTrending,  DateTime? trendingAt,  bool hasVariants,  List<ProductVariant> variants,  List<VariantOption> variantOptions,  String? subcategory,  String? condition,  Map<String, int>? warehouseStockMap,  DateTime? updatedAt,  NutritionFacts? nutritionFacts,  FoodMetadata? foodMetadata,  ProductSpecs? specs,  List<String> bundledProductIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.productId,_that.name,_that.nameF,_that.priceCents,_that.compareAtPriceCents,_that.description,_that.descriptionF,_that.imageUrls,_that.videoUrl,_that.videoDurationSeconds,_that.sellerId,_that.madeInCountry,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.ratingCount,_that.createdAt,_that.lifecycleStatus,_that.weightKg,_that.weightUnit,_that.lengthCm,_that.widthCm,_that.heightCm,_that.dimensionUnit,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.slug,_that.digitalBuilds,_that.deviceLimit,_that.taxCode,_that.keywords,_that.approvalRejectionReason,_that.costCents,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.sellerSku,_that.warehouseIds,_that.shipFromCity,_that.shipFromProvince,_that.shipFromCountry,_that.shipFromCountries,_that.trendingScore,_that.viewCount,_that.purchaseCount,_that.isTrending,_that.trendingAt,_that.hasVariants,_that.variants,_that.variantOptions,_that.subcategory,_that.condition,_that.warehouseStockMap,_that.updatedAt,_that.nutritionFacts,_that.foodMetadata,_that.specs,_that.bundledProductIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String name,  String? nameF,  int priceCents,  int? compareAtPriceCents,  String description,  String? descriptionF,  List<String> imageUrls,  String? videoUrl,  int? videoDurationSeconds,  String sellerId,  String? madeInCountry,  Address? sellerAddress,  int categoryId,  int stockQuantity,  double rating,  int ratingCount,  DateTime createdAt,  String lifecycleStatus,  double? weightKg,  String? weightUnit,  double? lengthCm,  double? widthCm,  double? heightCm,  String? dimensionUnit,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? slug,  Map<String, String>? digitalBuilds,  int? deviceLimit,  String? taxCode,  List<String> keywords,  String? approvalRejectionReason,  int? costCents,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String? sellerSku,  List<String>? warehouseIds,  String? shipFromCity,  String? shipFromProvince,  String? shipFromCountry,  List<String>? shipFromCountries,  int trendingScore,  int viewCount,  int purchaseCount,  bool isTrending,  DateTime? trendingAt,  bool hasVariants,  List<ProductVariant> variants,  List<VariantOption> variantOptions,  String? subcategory,  String? condition,  Map<String, int>? warehouseStockMap,  DateTime? updatedAt,  NutritionFacts? nutritionFacts,  FoodMetadata? foodMetadata,  ProductSpecs? specs,  List<String> bundledProductIds)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.productId,_that.name,_that.nameF,_that.priceCents,_that.compareAtPriceCents,_that.description,_that.descriptionF,_that.imageUrls,_that.videoUrl,_that.videoDurationSeconds,_that.sellerId,_that.madeInCountry,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.ratingCount,_that.createdAt,_that.lifecycleStatus,_that.weightKg,_that.weightUnit,_that.lengthCm,_that.widthCm,_that.heightCm,_that.dimensionUnit,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.slug,_that.digitalBuilds,_that.deviceLimit,_that.taxCode,_that.keywords,_that.approvalRejectionReason,_that.costCents,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.sellerSku,_that.warehouseIds,_that.shipFromCity,_that.shipFromProvince,_that.shipFromCountry,_that.shipFromCountries,_that.trendingScore,_that.viewCount,_that.purchaseCount,_that.isTrending,_that.trendingAt,_that.hasVariants,_that.variants,_that.variantOptions,_that.subcategory,_that.condition,_that.warehouseStockMap,_that.updatedAt,_that.nutritionFacts,_that.foodMetadata,_that.specs,_that.bundledProductIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String name,  String? nameF,  int priceCents,  int? compareAtPriceCents,  String description,  String? descriptionF,  List<String> imageUrls,  String? videoUrl,  int? videoDurationSeconds,  String sellerId,  String? madeInCountry,  Address? sellerAddress,  int categoryId,  int stockQuantity,  double rating,  int ratingCount,  DateTime createdAt,  String lifecycleStatus,  double? weightKg,  String? weightUnit,  double? lengthCm,  double? widthCm,  double? heightCm,  String? dimensionUnit,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? slug,  Map<String, String>? digitalBuilds,  int? deviceLimit,  String? taxCode,  List<String> keywords,  String? approvalRejectionReason,  int? costCents,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String? sellerSku,  List<String>? warehouseIds,  String? shipFromCity,  String? shipFromProvince,  String? shipFromCountry,  List<String>? shipFromCountries,  int trendingScore,  int viewCount,  int purchaseCount,  bool isTrending,  DateTime? trendingAt,  bool hasVariants,  List<ProductVariant> variants,  List<VariantOption> variantOptions,  String? subcategory,  String? condition,  Map<String, int>? warehouseStockMap,  DateTime? updatedAt,  NutritionFacts? nutritionFacts,  FoodMetadata? foodMetadata,  ProductSpecs? specs,  List<String> bundledProductIds)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.productId,_that.name,_that.nameF,_that.priceCents,_that.compareAtPriceCents,_that.description,_that.descriptionF,_that.imageUrls,_that.videoUrl,_that.videoDurationSeconds,_that.sellerId,_that.madeInCountry,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.ratingCount,_that.createdAt,_that.lifecycleStatus,_that.weightKg,_that.weightUnit,_that.lengthCm,_that.widthCm,_that.heightCm,_that.dimensionUnit,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.slug,_that.digitalBuilds,_that.deviceLimit,_that.taxCode,_that.keywords,_that.approvalRejectionReason,_that.costCents,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.sellerSku,_that.warehouseIds,_that.shipFromCity,_that.shipFromProvince,_that.shipFromCountry,_that.shipFromCountries,_that.trendingScore,_that.viewCount,_that.purchaseCount,_that.isTrending,_that.trendingAt,_that.hasVariants,_that.variants,_that.variantOptions,_that.subcategory,_that.condition,_that.warehouseStockMap,_that.updatedAt,_that.nutritionFacts,_that.foodMetadata,_that.specs,_that.bundledProductIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.productId, required this.name, this.nameF, required this.priceCents, this.compareAtPriceCents, required this.description, this.descriptionF, required final  List<String> imageUrls, this.videoUrl, this.videoDurationSeconds, required this.sellerId, this.madeInCountry, this.sellerAddress, required this.categoryId, required this.stockQuantity, this.rating = 0.0, this.ratingCount = 0, required this.createdAt, this.lifecycleStatus = ProductLifecycleStatusValues.draft, this.weightKg, this.weightUnit, this.lengthCm, this.widthCm, this.heightCm, this.dimensionUnit, this.isLocalDeliveryOnly = false, this.isPerishable = false, this.estimatedShipDays = 3, final  List<SellerDeliveryOption> deliveryOptions = const [], this.minimumOrderQuantity = 1, this.freeShipping = false, this.isDigital = false, this.isAgeRestricted = false, this.digitalType, this.slug, final  Map<String, String>? digitalBuilds, this.deviceLimit, this.taxCode, final  List<String> keywords = const [], this.approvalRejectionReason, this.costCents, this.supplierSku, this.supplierUrl, this.supplier, this.inventory, this.sellerSku, final  List<String>? warehouseIds, this.shipFromCity, this.shipFromProvince, this.shipFromCountry, final  List<String>? shipFromCountries, this.trendingScore = 0, this.viewCount = 0, this.purchaseCount = 0, this.isTrending = false, this.trendingAt, this.hasVariants = false, final  List<ProductVariant> variants = const [], final  List<VariantOption> variantOptions = const [], this.subcategory, this.condition, final  Map<String, int>? warehouseStockMap, this.updatedAt, this.nutritionFacts, this.foodMetadata, this.specs, final  List<String> bundledProductIds = const []}): _imageUrls = imageUrls,_deliveryOptions = deliveryOptions,_digitalBuilds = digitalBuilds,_keywords = keywords,_warehouseIds = warehouseIds,_shipFromCountries = shipFromCountries,_variants = variants,_variantOptions = variantOptions,_warehouseStockMap = warehouseStockMap,_bundledProductIds = bundledProductIds;
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String productId;
@override final  String name;
@override final  String? nameF;
@override final  int priceCents;
/// Original/crossed-out price for discount display in cents (null = no sale, must be > priceCents)
@override final  int? compareAtPriceCents;
@override final  String description;
@override final  String? descriptionF;
 final  List<String> _imageUrls;
@override List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override final  String? videoUrl;
@override final  int? videoDurationSeconds;
@override final  String sellerId;
@override final  String? madeInCountry;
// sellerAddress is optional — products with warehouses use warehouseIds instead
@override final  Address? sellerAddress;
@override final  int categoryId;
@override final  int stockQuantity;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int ratingCount;
@override final  DateTime createdAt;
// Single lifecycle state replacing isActive + status + approvalStatus
@override@JsonKey() final  String lifecycleStatus;
// Optional shipping metadata
@override final  double? weightKg;
@override final  String? weightUnit;
@override final  double? lengthCm;
@override final  double? widthCm;
@override final  double? heightCm;
@override final  String? dimensionUnit;
// Delivery options
@override@JsonKey() final  bool isLocalDeliveryOnly;
@override@JsonKey() final  bool isPerishable;
@override@JsonKey() final  int estimatedShipDays;
 final  List<SellerDeliveryOption> _deliveryOptions;
@override@JsonKey() List<SellerDeliveryOption> get deliveryOptions {
  if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryOptions);
}

@override@JsonKey() final  int minimumOrderQuantity;
@override@JsonKey() final  bool freeShipping;
// Digital product flag
@override@JsonKey() final  bool isDigital;
// Age restriction flag — requires buyer age confirmation at checkout
@override@JsonKey() final  bool isAgeRestricted;
@override final  String? digitalType;
@override final  String? slug;
 final  Map<String, String>? _digitalBuilds;
@override Map<String, String>? get digitalBuilds {
  final value = _digitalBuilds;
  if (value == null) return null;
  if (_digitalBuilds is EqualUnmodifiableMapView) return _digitalBuilds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// bookSourceUrl intentionally NOT included — buyer-protected: written by seller, never returned to client
@override final  int? deviceLimit;
// Tax and metadata
@override final  String? taxCode;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

// Admin rejection reason
@override final  String? approvalRejectionReason;
// Flat supplier fields (used when supplier object is not provided)
@override final  int? costCents;
@override final  String? supplierSku;
@override final  String? supplierUrl;
// Structured objects for scalability
/// Supplier information for dropshipping/marketplace products
@override final  SupplierInfo? supplier;
/// Inventory management configuration
@override final  InventoryConfig? inventory;
// Multi-warehouse support
/// Seller's unique product identifier — enforced unique per seller at write time
@override final  String? sellerSku;
/// IDs of seller warehouses this product ships from
 final  List<String>? _warehouseIds;
/// IDs of seller warehouses this product ships from
@override List<String>? get warehouseIds {
  final value = _warehouseIds;
  if (value == null) return null;
  if (_warehouseIds is EqualUnmodifiableListView) return _warehouseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// City of primary shipping warehouse (denormalized for O(1) card rendering)
@override final  String? shipFromCity;
/// Province code of primary warehouse (denormalized for O(1) card rendering)
@override final  String? shipFromProvince;
/// Country of primary warehouse (denormalized for O(1) card rendering)
@override final  String? shipFromCountry;
 final  List<String>? _shipFromCountries;
@override List<String>? get shipFromCountries {
  final value = _shipFromCountries;
  if (value == null) return null;
  if (_shipFromCountries is EqualUnmodifiableListView) return _shipFromCountries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// === TRENDING & ENGAGEMENT ===
@override@JsonKey() final  int trendingScore;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int purchaseCount;
@override@JsonKey() final  bool isTrending;
@override final  DateTime? trendingAt;
// === N-09: Product Variants ===
/// Whether this product has variants (size, color, etc.)
@override@JsonKey() final  bool hasVariants;
/// List of variant objects
 final  List<ProductVariant> _variants;
/// List of variant objects
@override@JsonKey() List<ProductVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

/// Variant option definitions
 final  List<VariantOption> _variantOptions;
/// Variant option definitions
@override@JsonKey() List<VariantOption> get variantOptions {
  if (_variantOptions is EqualUnmodifiableListView) return _variantOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variantOptions);
}

// === N-11: Subcategories ===
/// Optional subcategory within the main category
@override final  String? subcategory;
/// Product condition: new, like_new, good, fair, for_parts
@override final  String? condition;
/// Per-warehouse stock allocation map: {warehouseId: stockQty}
/// Sum of values equals stockQuantity. Used for multi-warehouse inventory routing.
 final  Map<String, int>? _warehouseStockMap;
/// Per-warehouse stock allocation map: {warehouseId: stockQty}
/// Sum of values equals stockQuantity. Used for multi-warehouse inventory routing.
@override Map<String, int>? get warehouseStockMap {
  final value = _warehouseStockMap;
  if (value == null) return null;
  if (_warehouseStockMap is EqualUnmodifiableMapView) return _warehouseStockMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Server-controlled last-updated timestamp
@override final  DateTime? updatedAt;
// === FOOD & NUTRITION ===
/// Nutrition facts per serving (Health Canada NFT format)
@override final  NutritionFacts? nutritionFacts;
/// Food metadata: ingredients, allergens, storage, dietary badges
@override final  FoodMetadata? foodMetadata;
/// Structured product specifications (non-food categories)
@override final  ProductSpecs? specs;
/// Seller-curated bundle: IDs of complementary products (max 5)
 final  List<String> _bundledProductIds;
/// Seller-curated bundle: IDs of complementary products (max 5)
@override@JsonKey() List<String> get bundledProductIds {
  if (_bundledProductIds is EqualUnmodifiableListView) return _bundledProductIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bundledProductIds);
}


/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameF, nameF) || other.nameF == nameF)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.compareAtPriceCents, compareAtPriceCents) || other.compareAtPriceCents == compareAtPriceCents)&&(identical(other.description, description) || other.description == description)&&(identical(other.descriptionF, descriptionF) || other.descriptionF == descriptionF)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.madeInCountry, madeInCountry) || other.madeInCountry == madeInCountry)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lifecycleStatus, lifecycleStatus) || other.lifecycleStatus == lifecycleStatus)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.weightUnit, weightUnit) || other.weightUnit == weightUnit)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.dimensionUnit, dimensionUnit) || other.dimensionUnit == dimensionUnit)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other._deliveryOptions, _deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.isAgeRestricted, isAgeRestricted) || other.isAgeRestricted == isAgeRestricted)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other._digitalBuilds, _digitalBuilds)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other._keywords, _keywords)&&(identical(other.approvalRejectionReason, approvalRejectionReason) || other.approvalRejectionReason == approvalRejectionReason)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.sellerSku, sellerSku) || other.sellerSku == sellerSku)&&const DeepCollectionEquality().equals(other._warehouseIds, _warehouseIds)&&(identical(other.shipFromCity, shipFromCity) || other.shipFromCity == shipFromCity)&&(identical(other.shipFromProvince, shipFromProvince) || other.shipFromProvince == shipFromProvince)&&(identical(other.shipFromCountry, shipFromCountry) || other.shipFromCountry == shipFromCountry)&&const DeepCollectionEquality().equals(other._shipFromCountries, _shipFromCountries)&&(identical(other.trendingScore, trendingScore) || other.trendingScore == trendingScore)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount)&&(identical(other.isTrending, isTrending) || other.isTrending == isTrending)&&(identical(other.trendingAt, trendingAt) || other.trendingAt == trendingAt)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._variantOptions, _variantOptions)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other._warehouseStockMap, _warehouseStockMap)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.nutritionFacts, nutritionFacts) || other.nutritionFacts == nutritionFacts)&&(identical(other.foodMetadata, foodMetadata) || other.foodMetadata == foodMetadata)&&(identical(other.specs, specs) || other.specs == specs)&&const DeepCollectionEquality().equals(other._bundledProductIds, _bundledProductIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,productId,name,nameF,priceCents,compareAtPriceCents,description,descriptionF,const DeepCollectionEquality().hash(_imageUrls),videoUrl,videoDurationSeconds,sellerId,madeInCountry,sellerAddress,categoryId,stockQuantity,rating,ratingCount,createdAt,lifecycleStatus,weightKg,weightUnit,lengthCm,widthCm,heightCm,dimensionUnit,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(_deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,isAgeRestricted,digitalType,slug,const DeepCollectionEquality().hash(_digitalBuilds),deviceLimit,taxCode,const DeepCollectionEquality().hash(_keywords),approvalRejectionReason,costCents,supplierSku,supplierUrl,supplier,inventory,sellerSku,const DeepCollectionEquality().hash(_warehouseIds),shipFromCity,shipFromProvince,shipFromCountry,const DeepCollectionEquality().hash(_shipFromCountries),trendingScore,viewCount,purchaseCount,isTrending,trendingAt,hasVariants,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_variantOptions),subcategory,condition,const DeepCollectionEquality().hash(_warehouseStockMap),updatedAt,nutritionFacts,foodMetadata,specs,const DeepCollectionEquality().hash(_bundledProductIds)]);

@override
String toString() {
  return 'Product(productId: $productId, name: $name, nameF: $nameF, priceCents: $priceCents, compareAtPriceCents: $compareAtPriceCents, description: $description, descriptionF: $descriptionF, imageUrls: $imageUrls, videoUrl: $videoUrl, videoDurationSeconds: $videoDurationSeconds, sellerId: $sellerId, madeInCountry: $madeInCountry, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, ratingCount: $ratingCount, createdAt: $createdAt, lifecycleStatus: $lifecycleStatus, weightKg: $weightKg, weightUnit: $weightUnit, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, dimensionUnit: $dimensionUnit, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, isAgeRestricted: $isAgeRestricted, digitalType: $digitalType, slug: $slug, digitalBuilds: $digitalBuilds, deviceLimit: $deviceLimit, taxCode: $taxCode, keywords: $keywords, approvalRejectionReason: $approvalRejectionReason, costCents: $costCents, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, sellerSku: $sellerSku, warehouseIds: $warehouseIds, shipFromCity: $shipFromCity, shipFromProvince: $shipFromProvince, shipFromCountry: $shipFromCountry, shipFromCountries: $shipFromCountries, trendingScore: $trendingScore, viewCount: $viewCount, purchaseCount: $purchaseCount, isTrending: $isTrending, trendingAt: $trendingAt, hasVariants: $hasVariants, variants: $variants, variantOptions: $variantOptions, subcategory: $subcategory, condition: $condition, warehouseStockMap: $warehouseStockMap, updatedAt: $updatedAt, nutritionFacts: $nutritionFacts, foodMetadata: $foodMetadata, specs: $specs, bundledProductIds: $bundledProductIds)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String productId, String name, String? nameF, int priceCents, int? compareAtPriceCents, String description, String? descriptionF, List<String> imageUrls, String? videoUrl, int? videoDurationSeconds, String sellerId, String? madeInCountry, Address? sellerAddress, int categoryId, int stockQuantity, double rating, int ratingCount, DateTime createdAt, String lifecycleStatus, double? weightKg, String? weightUnit, double? lengthCm, double? widthCm, double? heightCm, String? dimensionUnit, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, bool isAgeRestricted, String? digitalType, String? slug, Map<String, String>? digitalBuilds, int? deviceLimit, String? taxCode, List<String> keywords, String? approvalRejectionReason, int? costCents, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String? sellerSku, List<String>? warehouseIds, String? shipFromCity, String? shipFromProvince, String? shipFromCountry, List<String>? shipFromCountries, int trendingScore, int viewCount, int purchaseCount, bool isTrending, DateTime? trendingAt, bool hasVariants, List<ProductVariant> variants, List<VariantOption> variantOptions, String? subcategory, String? condition, Map<String, int>? warehouseStockMap, DateTime? updatedAt, NutritionFacts? nutritionFacts, FoodMetadata? foodMetadata, ProductSpecs? specs, List<String> bundledProductIds
});


@override $AddressCopyWith<$Res>? get sellerAddress;@override $SupplierInfoCopyWith<$Res>? get supplier;@override $InventoryConfigCopyWith<$Res>? get inventory;@override $NutritionFactsCopyWith<$Res>? get nutritionFacts;@override $FoodMetadataCopyWith<$Res>? get foodMetadata;@override $ProductSpecsCopyWith<$Res>? get specs;

}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? name = null,Object? nameF = freezed,Object? priceCents = null,Object? compareAtPriceCents = freezed,Object? description = null,Object? descriptionF = freezed,Object? imageUrls = null,Object? videoUrl = freezed,Object? videoDurationSeconds = freezed,Object? sellerId = null,Object? madeInCountry = freezed,Object? sellerAddress = freezed,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? ratingCount = null,Object? createdAt = null,Object? lifecycleStatus = null,Object? weightKg = freezed,Object? weightUnit = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? dimensionUnit = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? isAgeRestricted = null,Object? digitalType = freezed,Object? slug = freezed,Object? digitalBuilds = freezed,Object? deviceLimit = freezed,Object? taxCode = freezed,Object? keywords = null,Object? approvalRejectionReason = freezed,Object? costCents = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? sellerSku = freezed,Object? warehouseIds = freezed,Object? shipFromCity = freezed,Object? shipFromProvince = freezed,Object? shipFromCountry = freezed,Object? shipFromCountries = freezed,Object? trendingScore = null,Object? viewCount = null,Object? purchaseCount = null,Object? isTrending = null,Object? trendingAt = freezed,Object? hasVariants = null,Object? variants = null,Object? variantOptions = null,Object? subcategory = freezed,Object? condition = freezed,Object? warehouseStockMap = freezed,Object? updatedAt = freezed,Object? nutritionFacts = freezed,Object? foodMetadata = freezed,Object? specs = freezed,Object? bundledProductIds = null,}) {
  return _then(_Product(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameF: freezed == nameF ? _self.nameF : nameF // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,compareAtPriceCents: freezed == compareAtPriceCents ? _self.compareAtPriceCents : compareAtPriceCents // ignore: cast_nullable_to_non_nullable
as int?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,descriptionF: freezed == descriptionF ? _self.descriptionF : descriptionF // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,madeInCountry: freezed == madeInCountry ? _self.madeInCountry : madeInCountry // ignore: cast_nullable_to_non_nullable
as String?,sellerAddress: freezed == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lifecycleStatus: null == lifecycleStatus ? _self.lifecycleStatus : lifecycleStatus // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,weightUnit: freezed == weightUnit ? _self.weightUnit : weightUnit // ignore: cast_nullable_to_non_nullable
as String?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,dimensionUnit: freezed == dimensionUnit ? _self.dimensionUnit : dimensionUnit // ignore: cast_nullable_to_non_nullable
as String?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self._deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,isAgeRestricted: null == isAgeRestricted ? _self.isAgeRestricted : isAgeRestricted // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,digitalBuilds: freezed == digitalBuilds ? _self._digitalBuilds : digitalBuilds // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,approvalRejectionReason: freezed == approvalRejectionReason ? _self.approvalRejectionReason : approvalRejectionReason // ignore: cast_nullable_to_non_nullable
as String?,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,sellerSku: freezed == sellerSku ? _self.sellerSku : sellerSku // ignore: cast_nullable_to_non_nullable
as String?,warehouseIds: freezed == warehouseIds ? _self._warehouseIds : warehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>?,shipFromCity: freezed == shipFromCity ? _self.shipFromCity : shipFromCity // ignore: cast_nullable_to_non_nullable
as String?,shipFromProvince: freezed == shipFromProvince ? _self.shipFromProvince : shipFromProvince // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountry: freezed == shipFromCountry ? _self.shipFromCountry : shipFromCountry // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountries: freezed == shipFromCountries ? _self._shipFromCountries : shipFromCountries // ignore: cast_nullable_to_non_nullable
as List<String>?,trendingScore: null == trendingScore ? _self.trendingScore : trendingScore // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,isTrending: null == isTrending ? _self.isTrending : isTrending // ignore: cast_nullable_to_non_nullable
as bool,trendingAt: freezed == trendingAt ? _self.trendingAt : trendingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,variantOptions: null == variantOptions ? _self._variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,subcategory: freezed == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,warehouseStockMap: freezed == warehouseStockMap ? _self._warehouseStockMap : warehouseStockMap // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,nutritionFacts: freezed == nutritionFacts ? _self.nutritionFacts : nutritionFacts // ignore: cast_nullable_to_non_nullable
as NutritionFacts?,foodMetadata: freezed == foodMetadata ? _self.foodMetadata : foodMetadata // ignore: cast_nullable_to_non_nullable
as FoodMetadata?,specs: freezed == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as ProductSpecs?,bundledProductIds: null == bundledProductIds ? _self._bundledProductIds : bundledProductIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get sellerAddress {
    if (_self.sellerAddress == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.sellerAddress!, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NutritionFactsCopyWith<$Res>? get nutritionFacts {
    if (_self.nutritionFacts == null) {
    return null;
  }

  return $NutritionFactsCopyWith<$Res>(_self.nutritionFacts!, (value) {
    return _then(_self.copyWith(nutritionFacts: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodMetadataCopyWith<$Res>? get foodMetadata {
    if (_self.foodMetadata == null) {
    return null;
  }

  return $FoodMetadataCopyWith<$Res>(_self.foodMetadata!, (value) {
    return _then(_self.copyWith(foodMetadata: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductSpecsCopyWith<$Res>? get specs {
    if (_self.specs == null) {
    return null;
  }

  return $ProductSpecsCopyWith<$Res>(_self.specs!, (value) {
    return _then(_self.copyWith(specs: value));
  });
}
}


/// @nodoc
mixin _$ProductCreate {

 String get name; String? get nameF; int get priceCents;/// Original/crossed-out price for discount display in cents (null = no sale, must be > priceCents)
 int? get compareAtPriceCents; String get description; String? get descriptionF; List<String> get imageUrls; String? get videoUrl; String get sellerId;// sellerAddress is optional — required only when warehouseIds is not provided
 Address? get sellerAddress; int get categoryId; int get stockQuantity; double get rating; String get lifecycleStatus; double? get weightKg; double? get lengthCm; double? get widthCm; double? get heightCm; bool get isLocalDeliveryOnly; bool get isPerishable; int get estimatedShipDays; List<SellerDeliveryOption> get deliveryOptions; int get minimumOrderQuantity; bool get freeShipping; bool get isDigital; String? get digitalType; String? get slug; Map<String, String>? get digitalBuilds;// bookSourceUrl intentionally NOT included — buyer-protected: written by seller, never returned to client
 int? get deviceLimit; String? get taxCode; List<String> get keywords;// lifecycleStatus intentionally defaults to draft — backend sets under_review on creation
// Flat supplier fields (used when supplier object is not provided)
 int? get costCents; String? get supplierSku; String? get supplierUrl;// Structured objects
 SupplierInfo? get supplier; InventoryConfig? get inventory;// Multi-warehouse support
 String? get sellerSku; List<String>? get warehouseIds; String? get shipFromCity; String? get shipFromProvince; String? get shipFromCountry; List<String>? get shipFromCountries;// === N-09: Product Variants ===
 bool get hasVariants; List<ProductVariant> get variants; List<VariantOption> get variantOptions;// === N-11: Subcategories ===
 String? get subcategory;// === FOOD & NUTRITION ===
 NutritionFacts? get nutritionFacts; FoodMetadata? get foodMetadata; ProductSpecs? get specs; List<String> get bundledProductIds;
/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCreateCopyWith<ProductCreate> get copyWith => _$ProductCreateCopyWithImpl<ProductCreate>(this as ProductCreate, _$identity);

  /// Serializes this ProductCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.nameF, nameF) || other.nameF == nameF)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.compareAtPriceCents, compareAtPriceCents) || other.compareAtPriceCents == compareAtPriceCents)&&(identical(other.description, description) || other.description == description)&&(identical(other.descriptionF, descriptionF) || other.descriptionF == descriptionF)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.lifecycleStatus, lifecycleStatus) || other.lifecycleStatus == lifecycleStatus)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other.deliveryOptions, deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other.digitalBuilds, digitalBuilds)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other.keywords, keywords)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.sellerSku, sellerSku) || other.sellerSku == sellerSku)&&const DeepCollectionEquality().equals(other.warehouseIds, warehouseIds)&&(identical(other.shipFromCity, shipFromCity) || other.shipFromCity == shipFromCity)&&(identical(other.shipFromProvince, shipFromProvince) || other.shipFromProvince == shipFromProvince)&&(identical(other.shipFromCountry, shipFromCountry) || other.shipFromCountry == shipFromCountry)&&const DeepCollectionEquality().equals(other.shipFromCountries, shipFromCountries)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.variantOptions, variantOptions)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.nutritionFacts, nutritionFacts) || other.nutritionFacts == nutritionFacts)&&(identical(other.foodMetadata, foodMetadata) || other.foodMetadata == foodMetadata)&&(identical(other.specs, specs) || other.specs == specs)&&const DeepCollectionEquality().equals(other.bundledProductIds, bundledProductIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,nameF,priceCents,compareAtPriceCents,description,descriptionF,const DeepCollectionEquality().hash(imageUrls),videoUrl,sellerId,sellerAddress,categoryId,stockQuantity,rating,lifecycleStatus,weightKg,lengthCm,widthCm,heightCm,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,digitalType,slug,const DeepCollectionEquality().hash(digitalBuilds),deviceLimit,taxCode,const DeepCollectionEquality().hash(keywords),costCents,supplierSku,supplierUrl,supplier,inventory,sellerSku,const DeepCollectionEquality().hash(warehouseIds),shipFromCity,shipFromProvince,shipFromCountry,const DeepCollectionEquality().hash(shipFromCountries),hasVariants,const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(variantOptions),subcategory,nutritionFacts,foodMetadata,specs,const DeepCollectionEquality().hash(bundledProductIds)]);

@override
String toString() {
  return 'ProductCreate(name: $name, nameF: $nameF, priceCents: $priceCents, compareAtPriceCents: $compareAtPriceCents, description: $description, descriptionF: $descriptionF, imageUrls: $imageUrls, videoUrl: $videoUrl, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, lifecycleStatus: $lifecycleStatus, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, digitalType: $digitalType, slug: $slug, digitalBuilds: $digitalBuilds, deviceLimit: $deviceLimit, taxCode: $taxCode, keywords: $keywords, costCents: $costCents, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, sellerSku: $sellerSku, warehouseIds: $warehouseIds, shipFromCity: $shipFromCity, shipFromProvince: $shipFromProvince, shipFromCountry: $shipFromCountry, shipFromCountries: $shipFromCountries, hasVariants: $hasVariants, variants: $variants, variantOptions: $variantOptions, subcategory: $subcategory, nutritionFacts: $nutritionFacts, foodMetadata: $foodMetadata, specs: $specs, bundledProductIds: $bundledProductIds)';
}


}

/// @nodoc
abstract mixin class $ProductCreateCopyWith<$Res>  {
  factory $ProductCreateCopyWith(ProductCreate value, $Res Function(ProductCreate) _then) = _$ProductCreateCopyWithImpl;
@useResult
$Res call({
 String name, String? nameF, int priceCents, int? compareAtPriceCents, String description, String? descriptionF, List<String> imageUrls, String? videoUrl, String sellerId, Address? sellerAddress, int categoryId, int stockQuantity, double rating, String lifecycleStatus, double? weightKg, double? lengthCm, double? widthCm, double? heightCm, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, String? digitalType, String? slug, Map<String, String>? digitalBuilds, int? deviceLimit, String? taxCode, List<String> keywords, int? costCents, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String? sellerSku, List<String>? warehouseIds, String? shipFromCity, String? shipFromProvince, String? shipFromCountry, List<String>? shipFromCountries, bool hasVariants, List<ProductVariant> variants, List<VariantOption> variantOptions, String? subcategory, NutritionFacts? nutritionFacts, FoodMetadata? foodMetadata, ProductSpecs? specs, List<String> bundledProductIds
});


$AddressCopyWith<$Res>? get sellerAddress;$SupplierInfoCopyWith<$Res>? get supplier;$InventoryConfigCopyWith<$Res>? get inventory;$NutritionFactsCopyWith<$Res>? get nutritionFacts;$FoodMetadataCopyWith<$Res>? get foodMetadata;$ProductSpecsCopyWith<$Res>? get specs;

}
/// @nodoc
class _$ProductCreateCopyWithImpl<$Res>
    implements $ProductCreateCopyWith<$Res> {
  _$ProductCreateCopyWithImpl(this._self, this._then);

  final ProductCreate _self;
  final $Res Function(ProductCreate) _then;

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? nameF = freezed,Object? priceCents = null,Object? compareAtPriceCents = freezed,Object? description = null,Object? descriptionF = freezed,Object? imageUrls = null,Object? videoUrl = freezed,Object? sellerId = null,Object? sellerAddress = freezed,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? lifecycleStatus = null,Object? weightKg = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? digitalType = freezed,Object? slug = freezed,Object? digitalBuilds = freezed,Object? deviceLimit = freezed,Object? taxCode = freezed,Object? keywords = null,Object? costCents = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? sellerSku = freezed,Object? warehouseIds = freezed,Object? shipFromCity = freezed,Object? shipFromProvince = freezed,Object? shipFromCountry = freezed,Object? shipFromCountries = freezed,Object? hasVariants = null,Object? variants = null,Object? variantOptions = null,Object? subcategory = freezed,Object? nutritionFacts = freezed,Object? foodMetadata = freezed,Object? specs = freezed,Object? bundledProductIds = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameF: freezed == nameF ? _self.nameF : nameF // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,compareAtPriceCents: freezed == compareAtPriceCents ? _self.compareAtPriceCents : compareAtPriceCents // ignore: cast_nullable_to_non_nullable
as int?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,descriptionF: freezed == descriptionF ? _self.descriptionF : descriptionF // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: freezed == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,lifecycleStatus: null == lifecycleStatus ? _self.lifecycleStatus : lifecycleStatus // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self.deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,digitalBuilds: freezed == digitalBuilds ? _self.digitalBuilds : digitalBuilds // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,sellerSku: freezed == sellerSku ? _self.sellerSku : sellerSku // ignore: cast_nullable_to_non_nullable
as String?,warehouseIds: freezed == warehouseIds ? _self.warehouseIds : warehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>?,shipFromCity: freezed == shipFromCity ? _self.shipFromCity : shipFromCity // ignore: cast_nullable_to_non_nullable
as String?,shipFromProvince: freezed == shipFromProvince ? _self.shipFromProvince : shipFromProvince // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountry: freezed == shipFromCountry ? _self.shipFromCountry : shipFromCountry // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountries: freezed == shipFromCountries ? _self.shipFromCountries : shipFromCountries // ignore: cast_nullable_to_non_nullable
as List<String>?,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,variantOptions: null == variantOptions ? _self.variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,subcategory: freezed == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String?,nutritionFacts: freezed == nutritionFacts ? _self.nutritionFacts : nutritionFacts // ignore: cast_nullable_to_non_nullable
as NutritionFacts?,foodMetadata: freezed == foodMetadata ? _self.foodMetadata : foodMetadata // ignore: cast_nullable_to_non_nullable
as FoodMetadata?,specs: freezed == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as ProductSpecs?,bundledProductIds: null == bundledProductIds ? _self.bundledProductIds : bundledProductIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get sellerAddress {
    if (_self.sellerAddress == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.sellerAddress!, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NutritionFactsCopyWith<$Res>? get nutritionFacts {
    if (_self.nutritionFacts == null) {
    return null;
  }

  return $NutritionFactsCopyWith<$Res>(_self.nutritionFacts!, (value) {
    return _then(_self.copyWith(nutritionFacts: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodMetadataCopyWith<$Res>? get foodMetadata {
    if (_self.foodMetadata == null) {
    return null;
  }

  return $FoodMetadataCopyWith<$Res>(_self.foodMetadata!, (value) {
    return _then(_self.copyWith(foodMetadata: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductSpecsCopyWith<$Res>? get specs {
    if (_self.specs == null) {
    return null;
  }

  return $ProductSpecsCopyWith<$Res>(_self.specs!, (value) {
    return _then(_self.copyWith(specs: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductCreate].
extension ProductCreatePatterns on ProductCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCreate value)  $default,){
final _that = this;
switch (_that) {
case _ProductCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCreate value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? nameF,  int priceCents,  int? compareAtPriceCents,  String description,  String? descriptionF,  List<String> imageUrls,  String? videoUrl,  String sellerId,  Address? sellerAddress,  int categoryId,  int stockQuantity,  double rating,  String lifecycleStatus,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? digitalType,  String? slug,  Map<String, String>? digitalBuilds,  int? deviceLimit,  String? taxCode,  List<String> keywords,  int? costCents,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String? sellerSku,  List<String>? warehouseIds,  String? shipFromCity,  String? shipFromProvince,  String? shipFromCountry,  List<String>? shipFromCountries,  bool hasVariants,  List<ProductVariant> variants,  List<VariantOption> variantOptions,  String? subcategory,  NutritionFacts? nutritionFacts,  FoodMetadata? foodMetadata,  ProductSpecs? specs,  List<String> bundledProductIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
return $default(_that.name,_that.nameF,_that.priceCents,_that.compareAtPriceCents,_that.description,_that.descriptionF,_that.imageUrls,_that.videoUrl,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.lifecycleStatus,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.digitalType,_that.slug,_that.digitalBuilds,_that.deviceLimit,_that.taxCode,_that.keywords,_that.costCents,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.sellerSku,_that.warehouseIds,_that.shipFromCity,_that.shipFromProvince,_that.shipFromCountry,_that.shipFromCountries,_that.hasVariants,_that.variants,_that.variantOptions,_that.subcategory,_that.nutritionFacts,_that.foodMetadata,_that.specs,_that.bundledProductIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? nameF,  int priceCents,  int? compareAtPriceCents,  String description,  String? descriptionF,  List<String> imageUrls,  String? videoUrl,  String sellerId,  Address? sellerAddress,  int categoryId,  int stockQuantity,  double rating,  String lifecycleStatus,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? digitalType,  String? slug,  Map<String, String>? digitalBuilds,  int? deviceLimit,  String? taxCode,  List<String> keywords,  int? costCents,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String? sellerSku,  List<String>? warehouseIds,  String? shipFromCity,  String? shipFromProvince,  String? shipFromCountry,  List<String>? shipFromCountries,  bool hasVariants,  List<ProductVariant> variants,  List<VariantOption> variantOptions,  String? subcategory,  NutritionFacts? nutritionFacts,  FoodMetadata? foodMetadata,  ProductSpecs? specs,  List<String> bundledProductIds)  $default,) {final _that = this;
switch (_that) {
case _ProductCreate():
return $default(_that.name,_that.nameF,_that.priceCents,_that.compareAtPriceCents,_that.description,_that.descriptionF,_that.imageUrls,_that.videoUrl,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.lifecycleStatus,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.digitalType,_that.slug,_that.digitalBuilds,_that.deviceLimit,_that.taxCode,_that.keywords,_that.costCents,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.sellerSku,_that.warehouseIds,_that.shipFromCity,_that.shipFromProvince,_that.shipFromCountry,_that.shipFromCountries,_that.hasVariants,_that.variants,_that.variantOptions,_that.subcategory,_that.nutritionFacts,_that.foodMetadata,_that.specs,_that.bundledProductIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? nameF,  int priceCents,  int? compareAtPriceCents,  String description,  String? descriptionF,  List<String> imageUrls,  String? videoUrl,  String sellerId,  Address? sellerAddress,  int categoryId,  int stockQuantity,  double rating,  String lifecycleStatus,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? digitalType,  String? slug,  Map<String, String>? digitalBuilds,  int? deviceLimit,  String? taxCode,  List<String> keywords,  int? costCents,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String? sellerSku,  List<String>? warehouseIds,  String? shipFromCity,  String? shipFromProvince,  String? shipFromCountry,  List<String>? shipFromCountries,  bool hasVariants,  List<ProductVariant> variants,  List<VariantOption> variantOptions,  String? subcategory,  NutritionFacts? nutritionFacts,  FoodMetadata? foodMetadata,  ProductSpecs? specs,  List<String> bundledProductIds)?  $default,) {final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
return $default(_that.name,_that.nameF,_that.priceCents,_that.compareAtPriceCents,_that.description,_that.descriptionF,_that.imageUrls,_that.videoUrl,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.lifecycleStatus,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.digitalType,_that.slug,_that.digitalBuilds,_that.deviceLimit,_that.taxCode,_that.keywords,_that.costCents,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.sellerSku,_that.warehouseIds,_that.shipFromCity,_that.shipFromProvince,_that.shipFromCountry,_that.shipFromCountries,_that.hasVariants,_that.variants,_that.variantOptions,_that.subcategory,_that.nutritionFacts,_that.foodMetadata,_that.specs,_that.bundledProductIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductCreate implements ProductCreate {
  const _ProductCreate({required this.name, this.nameF, required this.priceCents, this.compareAtPriceCents, required this.description, this.descriptionF, required final  List<String> imageUrls, this.videoUrl, required this.sellerId, this.sellerAddress, required this.categoryId, required this.stockQuantity, this.rating = 0.0, this.lifecycleStatus = ProductLifecycleStatusValues.draft, this.weightKg, this.lengthCm, this.widthCm, this.heightCm, this.isLocalDeliveryOnly = false, this.isPerishable = false, this.estimatedShipDays = 3, final  List<SellerDeliveryOption> deliveryOptions = const [], this.minimumOrderQuantity = 1, this.freeShipping = false, this.isDigital = false, this.digitalType, this.slug, final  Map<String, String>? digitalBuilds, this.deviceLimit, this.taxCode, final  List<String> keywords = const [], this.costCents, this.supplierSku, this.supplierUrl, this.supplier, this.inventory, this.sellerSku, final  List<String>? warehouseIds, this.shipFromCity, this.shipFromProvince, this.shipFromCountry, final  List<String>? shipFromCountries, this.hasVariants = false, final  List<ProductVariant> variants = const [], final  List<VariantOption> variantOptions = const [], this.subcategory, this.nutritionFacts, this.foodMetadata, this.specs, final  List<String> bundledProductIds = const []}): _imageUrls = imageUrls,_deliveryOptions = deliveryOptions,_digitalBuilds = digitalBuilds,_keywords = keywords,_warehouseIds = warehouseIds,_shipFromCountries = shipFromCountries,_variants = variants,_variantOptions = variantOptions,_bundledProductIds = bundledProductIds;
  factory _ProductCreate.fromJson(Map<String, dynamic> json) => _$ProductCreateFromJson(json);

@override final  String name;
@override final  String? nameF;
@override final  int priceCents;
/// Original/crossed-out price for discount display in cents (null = no sale, must be > priceCents)
@override final  int? compareAtPriceCents;
@override final  String description;
@override final  String? descriptionF;
 final  List<String> _imageUrls;
@override List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override final  String? videoUrl;
@override final  String sellerId;
// sellerAddress is optional — required only when warehouseIds is not provided
@override final  Address? sellerAddress;
@override final  int categoryId;
@override final  int stockQuantity;
@override@JsonKey() final  double rating;
@override@JsonKey() final  String lifecycleStatus;
@override final  double? weightKg;
@override final  double? lengthCm;
@override final  double? widthCm;
@override final  double? heightCm;
@override@JsonKey() final  bool isLocalDeliveryOnly;
@override@JsonKey() final  bool isPerishable;
@override@JsonKey() final  int estimatedShipDays;
 final  List<SellerDeliveryOption> _deliveryOptions;
@override@JsonKey() List<SellerDeliveryOption> get deliveryOptions {
  if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryOptions);
}

@override@JsonKey() final  int minimumOrderQuantity;
@override@JsonKey() final  bool freeShipping;
@override@JsonKey() final  bool isDigital;
@override final  String? digitalType;
@override final  String? slug;
 final  Map<String, String>? _digitalBuilds;
@override Map<String, String>? get digitalBuilds {
  final value = _digitalBuilds;
  if (value == null) return null;
  if (_digitalBuilds is EqualUnmodifiableMapView) return _digitalBuilds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// bookSourceUrl intentionally NOT included — buyer-protected: written by seller, never returned to client
@override final  int? deviceLimit;
@override final  String? taxCode;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

// lifecycleStatus intentionally defaults to draft — backend sets under_review on creation
// Flat supplier fields (used when supplier object is not provided)
@override final  int? costCents;
@override final  String? supplierSku;
@override final  String? supplierUrl;
// Structured objects
@override final  SupplierInfo? supplier;
@override final  InventoryConfig? inventory;
// Multi-warehouse support
@override final  String? sellerSku;
 final  List<String>? _warehouseIds;
@override List<String>? get warehouseIds {
  final value = _warehouseIds;
  if (value == null) return null;
  if (_warehouseIds is EqualUnmodifiableListView) return _warehouseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? shipFromCity;
@override final  String? shipFromProvince;
@override final  String? shipFromCountry;
 final  List<String>? _shipFromCountries;
@override List<String>? get shipFromCountries {
  final value = _shipFromCountries;
  if (value == null) return null;
  if (_shipFromCountries is EqualUnmodifiableListView) return _shipFromCountries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// === N-09: Product Variants ===
@override@JsonKey() final  bool hasVariants;
 final  List<ProductVariant> _variants;
@override@JsonKey() List<ProductVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

 final  List<VariantOption> _variantOptions;
@override@JsonKey() List<VariantOption> get variantOptions {
  if (_variantOptions is EqualUnmodifiableListView) return _variantOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variantOptions);
}

// === N-11: Subcategories ===
@override final  String? subcategory;
// === FOOD & NUTRITION ===
@override final  NutritionFacts? nutritionFacts;
@override final  FoodMetadata? foodMetadata;
@override final  ProductSpecs? specs;
 final  List<String> _bundledProductIds;
@override@JsonKey() List<String> get bundledProductIds {
  if (_bundledProductIds is EqualUnmodifiableListView) return _bundledProductIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bundledProductIds);
}


/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCreateCopyWith<_ProductCreate> get copyWith => __$ProductCreateCopyWithImpl<_ProductCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.nameF, nameF) || other.nameF == nameF)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.compareAtPriceCents, compareAtPriceCents) || other.compareAtPriceCents == compareAtPriceCents)&&(identical(other.description, description) || other.description == description)&&(identical(other.descriptionF, descriptionF) || other.descriptionF == descriptionF)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.lifecycleStatus, lifecycleStatus) || other.lifecycleStatus == lifecycleStatus)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other._deliveryOptions, _deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other._digitalBuilds, _digitalBuilds)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other._keywords, _keywords)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.sellerSku, sellerSku) || other.sellerSku == sellerSku)&&const DeepCollectionEquality().equals(other._warehouseIds, _warehouseIds)&&(identical(other.shipFromCity, shipFromCity) || other.shipFromCity == shipFromCity)&&(identical(other.shipFromProvince, shipFromProvince) || other.shipFromProvince == shipFromProvince)&&(identical(other.shipFromCountry, shipFromCountry) || other.shipFromCountry == shipFromCountry)&&const DeepCollectionEquality().equals(other._shipFromCountries, _shipFromCountries)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._variantOptions, _variantOptions)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.nutritionFacts, nutritionFacts) || other.nutritionFacts == nutritionFacts)&&(identical(other.foodMetadata, foodMetadata) || other.foodMetadata == foodMetadata)&&(identical(other.specs, specs) || other.specs == specs)&&const DeepCollectionEquality().equals(other._bundledProductIds, _bundledProductIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,nameF,priceCents,compareAtPriceCents,description,descriptionF,const DeepCollectionEquality().hash(_imageUrls),videoUrl,sellerId,sellerAddress,categoryId,stockQuantity,rating,lifecycleStatus,weightKg,lengthCm,widthCm,heightCm,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(_deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,digitalType,slug,const DeepCollectionEquality().hash(_digitalBuilds),deviceLimit,taxCode,const DeepCollectionEquality().hash(_keywords),costCents,supplierSku,supplierUrl,supplier,inventory,sellerSku,const DeepCollectionEquality().hash(_warehouseIds),shipFromCity,shipFromProvince,shipFromCountry,const DeepCollectionEquality().hash(_shipFromCountries),hasVariants,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_variantOptions),subcategory,nutritionFacts,foodMetadata,specs,const DeepCollectionEquality().hash(_bundledProductIds)]);

@override
String toString() {
  return 'ProductCreate(name: $name, nameF: $nameF, priceCents: $priceCents, compareAtPriceCents: $compareAtPriceCents, description: $description, descriptionF: $descriptionF, imageUrls: $imageUrls, videoUrl: $videoUrl, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, lifecycleStatus: $lifecycleStatus, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, digitalType: $digitalType, slug: $slug, digitalBuilds: $digitalBuilds, deviceLimit: $deviceLimit, taxCode: $taxCode, keywords: $keywords, costCents: $costCents, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, sellerSku: $sellerSku, warehouseIds: $warehouseIds, shipFromCity: $shipFromCity, shipFromProvince: $shipFromProvince, shipFromCountry: $shipFromCountry, shipFromCountries: $shipFromCountries, hasVariants: $hasVariants, variants: $variants, variantOptions: $variantOptions, subcategory: $subcategory, nutritionFacts: $nutritionFacts, foodMetadata: $foodMetadata, specs: $specs, bundledProductIds: $bundledProductIds)';
}


}

/// @nodoc
abstract mixin class _$ProductCreateCopyWith<$Res> implements $ProductCreateCopyWith<$Res> {
  factory _$ProductCreateCopyWith(_ProductCreate value, $Res Function(_ProductCreate) _then) = __$ProductCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String? nameF, int priceCents, int? compareAtPriceCents, String description, String? descriptionF, List<String> imageUrls, String? videoUrl, String sellerId, Address? sellerAddress, int categoryId, int stockQuantity, double rating, String lifecycleStatus, double? weightKg, double? lengthCm, double? widthCm, double? heightCm, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, String? digitalType, String? slug, Map<String, String>? digitalBuilds, int? deviceLimit, String? taxCode, List<String> keywords, int? costCents, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String? sellerSku, List<String>? warehouseIds, String? shipFromCity, String? shipFromProvince, String? shipFromCountry, List<String>? shipFromCountries, bool hasVariants, List<ProductVariant> variants, List<VariantOption> variantOptions, String? subcategory, NutritionFacts? nutritionFacts, FoodMetadata? foodMetadata, ProductSpecs? specs, List<String> bundledProductIds
});


@override $AddressCopyWith<$Res>? get sellerAddress;@override $SupplierInfoCopyWith<$Res>? get supplier;@override $InventoryConfigCopyWith<$Res>? get inventory;@override $NutritionFactsCopyWith<$Res>? get nutritionFacts;@override $FoodMetadataCopyWith<$Res>? get foodMetadata;@override $ProductSpecsCopyWith<$Res>? get specs;

}
/// @nodoc
class __$ProductCreateCopyWithImpl<$Res>
    implements _$ProductCreateCopyWith<$Res> {
  __$ProductCreateCopyWithImpl(this._self, this._then);

  final _ProductCreate _self;
  final $Res Function(_ProductCreate) _then;

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? nameF = freezed,Object? priceCents = null,Object? compareAtPriceCents = freezed,Object? description = null,Object? descriptionF = freezed,Object? imageUrls = null,Object? videoUrl = freezed,Object? sellerId = null,Object? sellerAddress = freezed,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? lifecycleStatus = null,Object? weightKg = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? digitalType = freezed,Object? slug = freezed,Object? digitalBuilds = freezed,Object? deviceLimit = freezed,Object? taxCode = freezed,Object? keywords = null,Object? costCents = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? sellerSku = freezed,Object? warehouseIds = freezed,Object? shipFromCity = freezed,Object? shipFromProvince = freezed,Object? shipFromCountry = freezed,Object? shipFromCountries = freezed,Object? hasVariants = null,Object? variants = null,Object? variantOptions = null,Object? subcategory = freezed,Object? nutritionFacts = freezed,Object? foodMetadata = freezed,Object? specs = freezed,Object? bundledProductIds = null,}) {
  return _then(_ProductCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameF: freezed == nameF ? _self.nameF : nameF // ignore: cast_nullable_to_non_nullable
as String?,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,compareAtPriceCents: freezed == compareAtPriceCents ? _self.compareAtPriceCents : compareAtPriceCents // ignore: cast_nullable_to_non_nullable
as int?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,descriptionF: freezed == descriptionF ? _self.descriptionF : descriptionF // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: freezed == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,lifecycleStatus: null == lifecycleStatus ? _self.lifecycleStatus : lifecycleStatus // ignore: cast_nullable_to_non_nullable
as String,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self._deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,digitalBuilds: freezed == digitalBuilds ? _self._digitalBuilds : digitalBuilds // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,sellerSku: freezed == sellerSku ? _self.sellerSku : sellerSku // ignore: cast_nullable_to_non_nullable
as String?,warehouseIds: freezed == warehouseIds ? _self._warehouseIds : warehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>?,shipFromCity: freezed == shipFromCity ? _self.shipFromCity : shipFromCity // ignore: cast_nullable_to_non_nullable
as String?,shipFromProvince: freezed == shipFromProvince ? _self.shipFromProvince : shipFromProvince // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountry: freezed == shipFromCountry ? _self.shipFromCountry : shipFromCountry // ignore: cast_nullable_to_non_nullable
as String?,shipFromCountries: freezed == shipFromCountries ? _self._shipFromCountries : shipFromCountries // ignore: cast_nullable_to_non_nullable
as List<String>?,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,variantOptions: null == variantOptions ? _self._variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,subcategory: freezed == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String?,nutritionFacts: freezed == nutritionFacts ? _self.nutritionFacts : nutritionFacts // ignore: cast_nullable_to_non_nullable
as NutritionFacts?,foodMetadata: freezed == foodMetadata ? _self.foodMetadata : foodMetadata // ignore: cast_nullable_to_non_nullable
as FoodMetadata?,specs: freezed == specs ? _self.specs : specs // ignore: cast_nullable_to_non_nullable
as ProductSpecs?,bundledProductIds: null == bundledProductIds ? _self._bundledProductIds : bundledProductIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get sellerAddress {
    if (_self.sellerAddress == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.sellerAddress!, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NutritionFactsCopyWith<$Res>? get nutritionFacts {
    if (_self.nutritionFacts == null) {
    return null;
  }

  return $NutritionFactsCopyWith<$Res>(_self.nutritionFacts!, (value) {
    return _then(_self.copyWith(nutritionFacts: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodMetadataCopyWith<$Res>? get foodMetadata {
    if (_self.foodMetadata == null) {
    return null;
  }

  return $FoodMetadataCopyWith<$Res>(_self.foodMetadata!, (value) {
    return _then(_self.copyWith(foodMetadata: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductSpecsCopyWith<$Res>? get specs {
    if (_self.specs == null) {
    return null;
  }

  return $ProductSpecsCopyWith<$Res>(_self.specs!, (value) {
    return _then(_self.copyWith(specs: value));
  });
}
}


/// @nodoc
mixin _$VariantOption {

 String get name; List<String> get values;
/// Create a copy of VariantOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantOptionCopyWith<VariantOption> get copyWith => _$VariantOptionCopyWithImpl<VariantOption>(this as VariantOption, _$identity);

  /// Serializes this VariantOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantOption&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.values, values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(values));

@override
String toString() {
  return 'VariantOption(name: $name, values: $values)';
}


}

/// @nodoc
abstract mixin class $VariantOptionCopyWith<$Res>  {
  factory $VariantOptionCopyWith(VariantOption value, $Res Function(VariantOption) _then) = _$VariantOptionCopyWithImpl;
@useResult
$Res call({
 String name, List<String> values
});




}
/// @nodoc
class _$VariantOptionCopyWithImpl<$Res>
    implements $VariantOptionCopyWith<$Res> {
  _$VariantOptionCopyWithImpl(this._self, this._then);

  final VariantOption _self;
  final $Res Function(VariantOption) _then;

/// Create a copy of VariantOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? values = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [VariantOption].
extension VariantOptionPatterns on VariantOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VariantOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VariantOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VariantOption value)  $default,){
final _that = this;
switch (_that) {
case _VariantOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VariantOption value)?  $default,){
final _that = this;
switch (_that) {
case _VariantOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<String> values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VariantOption() when $default != null:
return $default(_that.name,_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<String> values)  $default,) {final _that = this;
switch (_that) {
case _VariantOption():
return $default(_that.name,_that.values);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<String> values)?  $default,) {final _that = this;
switch (_that) {
case _VariantOption() when $default != null:
return $default(_that.name,_that.values);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VariantOption implements VariantOption {
  const _VariantOption({required this.name, required final  List<String> values}): _values = values;
  factory _VariantOption.fromJson(Map<String, dynamic> json) => _$VariantOptionFromJson(json);

@override final  String name;
 final  List<String> _values;
@override List<String> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of VariantOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VariantOptionCopyWith<_VariantOption> get copyWith => __$VariantOptionCopyWithImpl<_VariantOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VariantOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VariantOption&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._values, _values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'VariantOption(name: $name, values: $values)';
}


}

/// @nodoc
abstract mixin class _$VariantOptionCopyWith<$Res> implements $VariantOptionCopyWith<$Res> {
  factory _$VariantOptionCopyWith(_VariantOption value, $Res Function(_VariantOption) _then) = __$VariantOptionCopyWithImpl;
@override @useResult
$Res call({
 String name, List<String> values
});




}
/// @nodoc
class __$VariantOptionCopyWithImpl<$Res>
    implements _$VariantOptionCopyWith<$Res> {
  __$VariantOptionCopyWithImpl(this._self, this._then);

  final _VariantOption _self;
  final $Res Function(_VariantOption) _then;

/// Create a copy of VariantOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? values = null,}) {
  return _then(_VariantOption(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProductVariant {

 String get variantId; Map<String, String> get optionValues; int? get priceCents; int get stockQuantity; String? get sku; bool get isActive;
/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<ProductVariant> get copyWith => _$ProductVariantCopyWithImpl<ProductVariant>(this as ProductVariant, _$identity);

  /// Serializes this ProductVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductVariant&&(identical(other.variantId, variantId) || other.variantId == variantId)&&const DeepCollectionEquality().equals(other.optionValues, optionValues)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,variantId,const DeepCollectionEquality().hash(optionValues),priceCents,stockQuantity,sku,isActive);

@override
String toString() {
  return 'ProductVariant(variantId: $variantId, optionValues: $optionValues, priceCents: $priceCents, stockQuantity: $stockQuantity, sku: $sku, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $ProductVariantCopyWith<$Res>  {
  factory $ProductVariantCopyWith(ProductVariant value, $Res Function(ProductVariant) _then) = _$ProductVariantCopyWithImpl;
@useResult
$Res call({
 String variantId, Map<String, String> optionValues, int? priceCents, int stockQuantity, String? sku, bool isActive
});




}
/// @nodoc
class _$ProductVariantCopyWithImpl<$Res>
    implements $ProductVariantCopyWith<$Res> {
  _$ProductVariantCopyWithImpl(this._self, this._then);

  final ProductVariant _self;
  final $Res Function(ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? variantId = null,Object? optionValues = null,Object? priceCents = freezed,Object? stockQuantity = null,Object? sku = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,optionValues: null == optionValues ? _self.optionValues : optionValues // ignore: cast_nullable_to_non_nullable
as Map<String, String>,priceCents: freezed == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int?,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductVariant].
extension ProductVariantPatterns on ProductVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductVariant value)  $default,){
final _that = this;
switch (_that) {
case _ProductVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductVariant value)?  $default,){
final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String variantId,  Map<String, String> optionValues,  int? priceCents,  int stockQuantity,  String? sku,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.variantId,_that.optionValues,_that.priceCents,_that.stockQuantity,_that.sku,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String variantId,  Map<String, String> optionValues,  int? priceCents,  int stockQuantity,  String? sku,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _ProductVariant():
return $default(_that.variantId,_that.optionValues,_that.priceCents,_that.stockQuantity,_that.sku,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String variantId,  Map<String, String> optionValues,  int? priceCents,  int stockQuantity,  String? sku,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.variantId,_that.optionValues,_that.priceCents,_that.stockQuantity,_that.sku,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductVariant implements ProductVariant {
  const _ProductVariant({this.variantId = '', required final  Map<String, String> optionValues, this.priceCents, required this.stockQuantity, this.sku, this.isActive = true}): _optionValues = optionValues;
  factory _ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

@override@JsonKey() final  String variantId;
 final  Map<String, String> _optionValues;
@override Map<String, String> get optionValues {
  if (_optionValues is EqualUnmodifiableMapView) return _optionValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_optionValues);
}

@override final  int? priceCents;
@override final  int stockQuantity;
@override final  String? sku;
@override@JsonKey() final  bool isActive;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductVariantCopyWith<_ProductVariant> get copyWith => __$ProductVariantCopyWithImpl<_ProductVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductVariant&&(identical(other.variantId, variantId) || other.variantId == variantId)&&const DeepCollectionEquality().equals(other._optionValues, _optionValues)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,variantId,const DeepCollectionEquality().hash(_optionValues),priceCents,stockQuantity,sku,isActive);

@override
String toString() {
  return 'ProductVariant(variantId: $variantId, optionValues: $optionValues, priceCents: $priceCents, stockQuantity: $stockQuantity, sku: $sku, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ProductVariantCopyWith<$Res> implements $ProductVariantCopyWith<$Res> {
  factory _$ProductVariantCopyWith(_ProductVariant value, $Res Function(_ProductVariant) _then) = __$ProductVariantCopyWithImpl;
@override @useResult
$Res call({
 String variantId, Map<String, String> optionValues, int? priceCents, int stockQuantity, String? sku, bool isActive
});




}
/// @nodoc
class __$ProductVariantCopyWithImpl<$Res>
    implements _$ProductVariantCopyWith<$Res> {
  __$ProductVariantCopyWithImpl(this._self, this._then);

  final _ProductVariant _self;
  final $Res Function(_ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? variantId = null,Object? optionValues = null,Object? priceCents = freezed,Object? stockQuantity = null,Object? sku = freezed,Object? isActive = null,}) {
  return _then(_ProductVariant(
variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as String,optionValues: null == optionValues ? _self._optionValues : optionValues // ignore: cast_nullable_to_non_nullable
as Map<String, String>,priceCents: freezed == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int?,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProductQuestion {

 String get questionId; String get productId; String get sellerId; String get askerId; String get question; String? get answer; DateTime? get answeredAt; String? get answeredBy; bool get isAnswered; int get upvotes; DateTime get createdAt;
/// Create a copy of ProductQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductQuestionCopyWith<ProductQuestion> get copyWith => _$ProductQuestionCopyWithImpl<ProductQuestion>(this as ProductQuestion, _$identity);

  /// Serializes this ProductQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductQuestion&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.askerId, askerId) || other.askerId == askerId)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.answeredBy, answeredBy) || other.answeredBy == answeredBy)&&(identical(other.isAnswered, isAnswered) || other.isAnswered == isAnswered)&&(identical(other.upvotes, upvotes) || other.upvotes == upvotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,productId,sellerId,askerId,question,answer,answeredAt,answeredBy,isAnswered,upvotes,createdAt);

@override
String toString() {
  return 'ProductQuestion(questionId: $questionId, productId: $productId, sellerId: $sellerId, askerId: $askerId, question: $question, answer: $answer, answeredAt: $answeredAt, answeredBy: $answeredBy, isAnswered: $isAnswered, upvotes: $upvotes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ProductQuestionCopyWith<$Res>  {
  factory $ProductQuestionCopyWith(ProductQuestion value, $Res Function(ProductQuestion) _then) = _$ProductQuestionCopyWithImpl;
@useResult
$Res call({
 String questionId, String productId, String sellerId, String askerId, String question, String? answer, DateTime? answeredAt, String? answeredBy, bool isAnswered, int upvotes, DateTime createdAt
});




}
/// @nodoc
class _$ProductQuestionCopyWithImpl<$Res>
    implements $ProductQuestionCopyWith<$Res> {
  _$ProductQuestionCopyWithImpl(this._self, this._then);

  final ProductQuestion _self;
  final $Res Function(ProductQuestion) _then;

/// Create a copy of ProductQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? productId = null,Object? sellerId = null,Object? askerId = null,Object? question = null,Object? answer = freezed,Object? answeredAt = freezed,Object? answeredBy = freezed,Object? isAnswered = null,Object? upvotes = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,askerId: null == askerId ? _self.askerId : askerId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredBy: freezed == answeredBy ? _self.answeredBy : answeredBy // ignore: cast_nullable_to_non_nullable
as String?,isAnswered: null == isAnswered ? _self.isAnswered : isAnswered // ignore: cast_nullable_to_non_nullable
as bool,upvotes: null == upvotes ? _self.upvotes : upvotes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductQuestion].
extension ProductQuestionPatterns on ProductQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductQuestion value)  $default,){
final _that = this;
switch (_that) {
case _ProductQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _ProductQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  String productId,  String sellerId,  String askerId,  String question,  String? answer,  DateTime? answeredAt,  String? answeredBy,  bool isAnswered,  int upvotes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductQuestion() when $default != null:
return $default(_that.questionId,_that.productId,_that.sellerId,_that.askerId,_that.question,_that.answer,_that.answeredAt,_that.answeredBy,_that.isAnswered,_that.upvotes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  String productId,  String sellerId,  String askerId,  String question,  String? answer,  DateTime? answeredAt,  String? answeredBy,  bool isAnswered,  int upvotes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ProductQuestion():
return $default(_that.questionId,_that.productId,_that.sellerId,_that.askerId,_that.question,_that.answer,_that.answeredAt,_that.answeredBy,_that.isAnswered,_that.upvotes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  String productId,  String sellerId,  String askerId,  String question,  String? answer,  DateTime? answeredAt,  String? answeredBy,  bool isAnswered,  int upvotes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ProductQuestion() when $default != null:
return $default(_that.questionId,_that.productId,_that.sellerId,_that.askerId,_that.question,_that.answer,_that.answeredAt,_that.answeredBy,_that.isAnswered,_that.upvotes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductQuestion implements ProductQuestion {
  const _ProductQuestion({required this.questionId, required this.productId, required this.sellerId, required this.askerId, required this.question, this.answer, this.answeredAt, this.answeredBy, this.isAnswered = false, this.upvotes = 0, required this.createdAt});
  factory _ProductQuestion.fromJson(Map<String, dynamic> json) => _$ProductQuestionFromJson(json);

@override final  String questionId;
@override final  String productId;
@override final  String sellerId;
@override final  String askerId;
@override final  String question;
@override final  String? answer;
@override final  DateTime? answeredAt;
@override final  String? answeredBy;
@override@JsonKey() final  bool isAnswered;
@override@JsonKey() final  int upvotes;
@override final  DateTime createdAt;

/// Create a copy of ProductQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductQuestionCopyWith<_ProductQuestion> get copyWith => __$ProductQuestionCopyWithImpl<_ProductQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductQuestion&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.askerId, askerId) || other.askerId == askerId)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.answeredBy, answeredBy) || other.answeredBy == answeredBy)&&(identical(other.isAnswered, isAnswered) || other.isAnswered == isAnswered)&&(identical(other.upvotes, upvotes) || other.upvotes == upvotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,productId,sellerId,askerId,question,answer,answeredAt,answeredBy,isAnswered,upvotes,createdAt);

@override
String toString() {
  return 'ProductQuestion(questionId: $questionId, productId: $productId, sellerId: $sellerId, askerId: $askerId, question: $question, answer: $answer, answeredAt: $answeredAt, answeredBy: $answeredBy, isAnswered: $isAnswered, upvotes: $upvotes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProductQuestionCopyWith<$Res> implements $ProductQuestionCopyWith<$Res> {
  factory _$ProductQuestionCopyWith(_ProductQuestion value, $Res Function(_ProductQuestion) _then) = __$ProductQuestionCopyWithImpl;
@override @useResult
$Res call({
 String questionId, String productId, String sellerId, String askerId, String question, String? answer, DateTime? answeredAt, String? answeredBy, bool isAnswered, int upvotes, DateTime createdAt
});




}
/// @nodoc
class __$ProductQuestionCopyWithImpl<$Res>
    implements _$ProductQuestionCopyWith<$Res> {
  __$ProductQuestionCopyWithImpl(this._self, this._then);

  final _ProductQuestion _self;
  final $Res Function(_ProductQuestion) _then;

/// Create a copy of ProductQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? productId = null,Object? sellerId = null,Object? askerId = null,Object? question = null,Object? answer = freezed,Object? answeredAt = freezed,Object? answeredBy = freezed,Object? isAnswered = null,Object? upvotes = null,Object? createdAt = null,}) {
  return _then(_ProductQuestion(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,askerId: null == askerId ? _self.askerId : askerId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredBy: freezed == answeredBy ? _self.answeredBy : answeredBy // ignore: cast_nullable_to_non_nullable
as String?,isAnswered: null == isAnswered ? _self.isAnswered : isAnswered // ignore: cast_nullable_to_non_nullable
as bool,upvotes: null == upvotes ? _self.upvotes : upvotes // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SellerDeliveryOption {

/// Delivery type: 'standard', 'express', 'same_day', etc.
 String get type;/// Human-readable description
 String get description;/// Shipping cost in dollars
 int get costCents;/// Estimated delivery days
 int get estimatedDays;/// Optional quantity-based discounts for this delivery option
 List<ShippingQuantityDiscount> get quantityDiscounts;/// Maximum items before shipping cost increases (0 = no limit)
 int get maxItemsPerShipment;/// Additional cost per item after maxItemsPerShipment (0 = free per-item)
 int get additionalItemCostCents;/// Whether this option is available for international orders
 bool get availableNationwide;
/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerDeliveryOptionCopyWith<SellerDeliveryOption> get copyWith => _$SellerDeliveryOptionCopyWithImpl<SellerDeliveryOption>(this as SellerDeliveryOption, _$identity);

  /// Serializes this SellerDeliveryOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerDeliveryOption&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.estimatedDays, estimatedDays) || other.estimatedDays == estimatedDays)&&const DeepCollectionEquality().equals(other.quantityDiscounts, quantityDiscounts)&&(identical(other.maxItemsPerShipment, maxItemsPerShipment) || other.maxItemsPerShipment == maxItemsPerShipment)&&(identical(other.additionalItemCostCents, additionalItemCostCents) || other.additionalItemCostCents == additionalItemCostCents)&&(identical(other.availableNationwide, availableNationwide) || other.availableNationwide == availableNationwide));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,costCents,estimatedDays,const DeepCollectionEquality().hash(quantityDiscounts),maxItemsPerShipment,additionalItemCostCents,availableNationwide);

@override
String toString() {
  return 'SellerDeliveryOption(type: $type, description: $description, costCents: $costCents, estimatedDays: $estimatedDays, quantityDiscounts: $quantityDiscounts, maxItemsPerShipment: $maxItemsPerShipment, additionalItemCostCents: $additionalItemCostCents, availableNationwide: $availableNationwide)';
}


}

/// @nodoc
abstract mixin class $SellerDeliveryOptionCopyWith<$Res>  {
  factory $SellerDeliveryOptionCopyWith(SellerDeliveryOption value, $Res Function(SellerDeliveryOption) _then) = _$SellerDeliveryOptionCopyWithImpl;
@useResult
$Res call({
 String type, String description, int costCents, int estimatedDays, List<ShippingQuantityDiscount> quantityDiscounts, int maxItemsPerShipment, int additionalItemCostCents, bool availableNationwide
});




}
/// @nodoc
class _$SellerDeliveryOptionCopyWithImpl<$Res>
    implements $SellerDeliveryOptionCopyWith<$Res> {
  _$SellerDeliveryOptionCopyWithImpl(this._self, this._then);

  final SellerDeliveryOption _self;
  final $Res Function(SellerDeliveryOption) _then;

/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? description = null,Object? costCents = null,Object? estimatedDays = null,Object? quantityDiscounts = null,Object? maxItemsPerShipment = null,Object? additionalItemCostCents = null,Object? availableNationwide = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,costCents: null == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int,estimatedDays: null == estimatedDays ? _self.estimatedDays : estimatedDays // ignore: cast_nullable_to_non_nullable
as int,quantityDiscounts: null == quantityDiscounts ? _self.quantityDiscounts : quantityDiscounts // ignore: cast_nullable_to_non_nullable
as List<ShippingQuantityDiscount>,maxItemsPerShipment: null == maxItemsPerShipment ? _self.maxItemsPerShipment : maxItemsPerShipment // ignore: cast_nullable_to_non_nullable
as int,additionalItemCostCents: null == additionalItemCostCents ? _self.additionalItemCostCents : additionalItemCostCents // ignore: cast_nullable_to_non_nullable
as int,availableNationwide: null == availableNationwide ? _self.availableNationwide : availableNationwide // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerDeliveryOption].
extension SellerDeliveryOptionPatterns on SellerDeliveryOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerDeliveryOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerDeliveryOption value)  $default,){
final _that = this;
switch (_that) {
case _SellerDeliveryOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerDeliveryOption value)?  $default,){
final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String description,  int costCents,  int estimatedDays,  List<ShippingQuantityDiscount> quantityDiscounts,  int maxItemsPerShipment,  int additionalItemCostCents,  bool availableNationwide)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
return $default(_that.type,_that.description,_that.costCents,_that.estimatedDays,_that.quantityDiscounts,_that.maxItemsPerShipment,_that.additionalItemCostCents,_that.availableNationwide);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String description,  int costCents,  int estimatedDays,  List<ShippingQuantityDiscount> quantityDiscounts,  int maxItemsPerShipment,  int additionalItemCostCents,  bool availableNationwide)  $default,) {final _that = this;
switch (_that) {
case _SellerDeliveryOption():
return $default(_that.type,_that.description,_that.costCents,_that.estimatedDays,_that.quantityDiscounts,_that.maxItemsPerShipment,_that.additionalItemCostCents,_that.availableNationwide);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String description,  int costCents,  int estimatedDays,  List<ShippingQuantityDiscount> quantityDiscounts,  int maxItemsPerShipment,  int additionalItemCostCents,  bool availableNationwide)?  $default,) {final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
return $default(_that.type,_that.description,_that.costCents,_that.estimatedDays,_that.quantityDiscounts,_that.maxItemsPerShipment,_that.additionalItemCostCents,_that.availableNationwide);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SellerDeliveryOption implements SellerDeliveryOption {
  const _SellerDeliveryOption({this.type = DeliveryTypeValues.standard, this.description = '', this.costCents = 0, this.estimatedDays = 3, final  List<ShippingQuantityDiscount> quantityDiscounts = const [], this.maxItemsPerShipment = 0, this.additionalItemCostCents = 0, this.availableNationwide = true}): _quantityDiscounts = quantityDiscounts;
  factory _SellerDeliveryOption.fromJson(Map<String, dynamic> json) => _$SellerDeliveryOptionFromJson(json);

/// Delivery type: 'standard', 'express', 'same_day', etc.
@override@JsonKey() final  String type;
/// Human-readable description
@override@JsonKey() final  String description;
/// Shipping cost in dollars
@override@JsonKey() final  int costCents;
/// Estimated delivery days
@override@JsonKey() final  int estimatedDays;
/// Optional quantity-based discounts for this delivery option
 final  List<ShippingQuantityDiscount> _quantityDiscounts;
/// Optional quantity-based discounts for this delivery option
@override@JsonKey() List<ShippingQuantityDiscount> get quantityDiscounts {
  if (_quantityDiscounts is EqualUnmodifiableListView) return _quantityDiscounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quantityDiscounts);
}

/// Maximum items before shipping cost increases (0 = no limit)
@override@JsonKey() final  int maxItemsPerShipment;
/// Additional cost per item after maxItemsPerShipment (0 = free per-item)
@override@JsonKey() final  int additionalItemCostCents;
/// Whether this option is available for international orders
@override@JsonKey() final  bool availableNationwide;

/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerDeliveryOptionCopyWith<_SellerDeliveryOption> get copyWith => __$SellerDeliveryOptionCopyWithImpl<_SellerDeliveryOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SellerDeliveryOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerDeliveryOption&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.estimatedDays, estimatedDays) || other.estimatedDays == estimatedDays)&&const DeepCollectionEquality().equals(other._quantityDiscounts, _quantityDiscounts)&&(identical(other.maxItemsPerShipment, maxItemsPerShipment) || other.maxItemsPerShipment == maxItemsPerShipment)&&(identical(other.additionalItemCostCents, additionalItemCostCents) || other.additionalItemCostCents == additionalItemCostCents)&&(identical(other.availableNationwide, availableNationwide) || other.availableNationwide == availableNationwide));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,costCents,estimatedDays,const DeepCollectionEquality().hash(_quantityDiscounts),maxItemsPerShipment,additionalItemCostCents,availableNationwide);

@override
String toString() {
  return 'SellerDeliveryOption(type: $type, description: $description, costCents: $costCents, estimatedDays: $estimatedDays, quantityDiscounts: $quantityDiscounts, maxItemsPerShipment: $maxItemsPerShipment, additionalItemCostCents: $additionalItemCostCents, availableNationwide: $availableNationwide)';
}


}

/// @nodoc
abstract mixin class _$SellerDeliveryOptionCopyWith<$Res> implements $SellerDeliveryOptionCopyWith<$Res> {
  factory _$SellerDeliveryOptionCopyWith(_SellerDeliveryOption value, $Res Function(_SellerDeliveryOption) _then) = __$SellerDeliveryOptionCopyWithImpl;
@override @useResult
$Res call({
 String type, String description, int costCents, int estimatedDays, List<ShippingQuantityDiscount> quantityDiscounts, int maxItemsPerShipment, int additionalItemCostCents, bool availableNationwide
});




}
/// @nodoc
class __$SellerDeliveryOptionCopyWithImpl<$Res>
    implements _$SellerDeliveryOptionCopyWith<$Res> {
  __$SellerDeliveryOptionCopyWithImpl(this._self, this._then);

  final _SellerDeliveryOption _self;
  final $Res Function(_SellerDeliveryOption) _then;

/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = null,Object? costCents = null,Object? estimatedDays = null,Object? quantityDiscounts = null,Object? maxItemsPerShipment = null,Object? additionalItemCostCents = null,Object? availableNationwide = null,}) {
  return _then(_SellerDeliveryOption(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,costCents: null == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int,estimatedDays: null == estimatedDays ? _self.estimatedDays : estimatedDays // ignore: cast_nullable_to_non_nullable
as int,quantityDiscounts: null == quantityDiscounts ? _self._quantityDiscounts : quantityDiscounts // ignore: cast_nullable_to_non_nullable
as List<ShippingQuantityDiscount>,maxItemsPerShipment: null == maxItemsPerShipment ? _self.maxItemsPerShipment : maxItemsPerShipment // ignore: cast_nullable_to_non_nullable
as int,additionalItemCostCents: null == additionalItemCostCents ? _self.additionalItemCostCents : additionalItemCostCents // ignore: cast_nullable_to_non_nullable
as int,availableNationwide: null == availableNationwide ? _self.availableNationwide : availableNationwide // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SellerWarehouse {

 String get warehouseId;/// Display name, e.g. 'Toronto Warehouse' or 'Home Office'
 String get label;/// Location type: 'warehouse' | 'personal'
 String get type;/// Physical address of this location
 Address get address;/// Whether this is the seller's default shipping origin
 bool get isDefault; DateTime? get createdAt;
/// Create a copy of SellerWarehouse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerWarehouseCopyWith<SellerWarehouse> get copyWith => _$SellerWarehouseCopyWithImpl<SellerWarehouse>(this as SellerWarehouse, _$identity);

  /// Serializes this SellerWarehouse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerWarehouse&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.address, address) || other.address == address)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,warehouseId,label,type,address,isDefault,createdAt);

@override
String toString() {
  return 'SellerWarehouse(warehouseId: $warehouseId, label: $label, type: $type, address: $address, isDefault: $isDefault, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SellerWarehouseCopyWith<$Res>  {
  factory $SellerWarehouseCopyWith(SellerWarehouse value, $Res Function(SellerWarehouse) _then) = _$SellerWarehouseCopyWithImpl;
@useResult
$Res call({
 String warehouseId, String label, String type, Address address, bool isDefault, DateTime? createdAt
});


$AddressCopyWith<$Res> get address;

}
/// @nodoc
class _$SellerWarehouseCopyWithImpl<$Res>
    implements $SellerWarehouseCopyWith<$Res> {
  _$SellerWarehouseCopyWithImpl(this._self, this._then);

  final SellerWarehouse _self;
  final $Res Function(SellerWarehouse) _then;

/// Create a copy of SellerWarehouse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? warehouseId = null,Object? label = null,Object? type = null,Object? address = null,Object? isDefault = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of SellerWarehouse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res> get address {
  
  return $AddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds pattern-matching-related methods to [SellerWarehouse].
extension SellerWarehousePatterns on SellerWarehouse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerWarehouse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerWarehouse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerWarehouse value)  $default,){
final _that = this;
switch (_that) {
case _SellerWarehouse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerWarehouse value)?  $default,){
final _that = this;
switch (_that) {
case _SellerWarehouse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String warehouseId,  String label,  String type,  Address address,  bool isDefault,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerWarehouse() when $default != null:
return $default(_that.warehouseId,_that.label,_that.type,_that.address,_that.isDefault,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String warehouseId,  String label,  String type,  Address address,  bool isDefault,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SellerWarehouse():
return $default(_that.warehouseId,_that.label,_that.type,_that.address,_that.isDefault,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String warehouseId,  String label,  String type,  Address address,  bool isDefault,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SellerWarehouse() when $default != null:
return $default(_that.warehouseId,_that.label,_that.type,_that.address,_that.isDefault,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SellerWarehouse implements SellerWarehouse {
  const _SellerWarehouse({required this.warehouseId, required this.label, this.type = 'warehouse', required this.address, this.isDefault = false, this.createdAt});
  factory _SellerWarehouse.fromJson(Map<String, dynamic> json) => _$SellerWarehouseFromJson(json);

@override final  String warehouseId;
/// Display name, e.g. 'Toronto Warehouse' or 'Home Office'
@override final  String label;
/// Location type: 'warehouse' | 'personal'
@override@JsonKey() final  String type;
/// Physical address of this location
@override final  Address address;
/// Whether this is the seller's default shipping origin
@override@JsonKey() final  bool isDefault;
@override final  DateTime? createdAt;

/// Create a copy of SellerWarehouse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerWarehouseCopyWith<_SellerWarehouse> get copyWith => __$SellerWarehouseCopyWithImpl<_SellerWarehouse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SellerWarehouseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerWarehouse&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.address, address) || other.address == address)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,warehouseId,label,type,address,isDefault,createdAt);

@override
String toString() {
  return 'SellerWarehouse(warehouseId: $warehouseId, label: $label, type: $type, address: $address, isDefault: $isDefault, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SellerWarehouseCopyWith<$Res> implements $SellerWarehouseCopyWith<$Res> {
  factory _$SellerWarehouseCopyWith(_SellerWarehouse value, $Res Function(_SellerWarehouse) _then) = __$SellerWarehouseCopyWithImpl;
@override @useResult
$Res call({
 String warehouseId, String label, String type, Address address, bool isDefault, DateTime? createdAt
});


@override $AddressCopyWith<$Res> get address;

}
/// @nodoc
class __$SellerWarehouseCopyWithImpl<$Res>
    implements _$SellerWarehouseCopyWith<$Res> {
  __$SellerWarehouseCopyWithImpl(this._self, this._then);

  final _SellerWarehouse _self;
  final $Res Function(_SellerWarehouse) _then;

/// Create a copy of SellerWarehouse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? warehouseId = null,Object? label = null,Object? type = null,Object? address = null,Object? isDefault = null,Object? createdAt = freezed,}) {
  return _then(_SellerWarehouse(
warehouseId: null == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of SellerWarehouse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res> get address {
  
  return $AddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// @nodoc
mixin _$ShippingQuantityDiscount {

/// Minimum quantity to qualify for this discount
 int get minQuantity;/// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
 String get discountType;/// Discount value (interpretation depends on discountType)
 double get discountValue;/// Optional label for display (e.g., "Bulk Shipping Discount")
 String? get label;
/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShippingQuantityDiscountCopyWith<ShippingQuantityDiscount> get copyWith => _$ShippingQuantityDiscountCopyWithImpl<ShippingQuantityDiscount>(this as ShippingQuantityDiscount, _$identity);

  /// Serializes this ShippingQuantityDiscount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShippingQuantityDiscount&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,discountType,discountValue,label);

@override
String toString() {
  return 'ShippingQuantityDiscount(minQuantity: $minQuantity, discountType: $discountType, discountValue: $discountValue, label: $label)';
}


}

/// @nodoc
abstract mixin class $ShippingQuantityDiscountCopyWith<$Res>  {
  factory $ShippingQuantityDiscountCopyWith(ShippingQuantityDiscount value, $Res Function(ShippingQuantityDiscount) _then) = _$ShippingQuantityDiscountCopyWithImpl;
@useResult
$Res call({
 int minQuantity, String discountType, double discountValue, String? label
});




}
/// @nodoc
class _$ShippingQuantityDiscountCopyWithImpl<$Res>
    implements $ShippingQuantityDiscountCopyWith<$Res> {
  _$ShippingQuantityDiscountCopyWithImpl(this._self, this._then);

  final ShippingQuantityDiscount _self;
  final $Res Function(ShippingQuantityDiscount) _then;

/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minQuantity = null,Object? discountType = null,Object? discountValue = null,Object? label = freezed,}) {
  return _then(_self.copyWith(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as String,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShippingQuantityDiscount].
extension ShippingQuantityDiscountPatterns on ShippingQuantityDiscount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShippingQuantityDiscount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShippingQuantityDiscount value)  $default,){
final _that = this;
switch (_that) {
case _ShippingQuantityDiscount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShippingQuantityDiscount value)?  $default,){
final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minQuantity,  String discountType,  double discountValue,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
return $default(_that.minQuantity,_that.discountType,_that.discountValue,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minQuantity,  String discountType,  double discountValue,  String? label)  $default,) {final _that = this;
switch (_that) {
case _ShippingQuantityDiscount():
return $default(_that.minQuantity,_that.discountType,_that.discountValue,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minQuantity,  String discountType,  double discountValue,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
return $default(_that.minQuantity,_that.discountType,_that.discountValue,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShippingQuantityDiscount implements ShippingQuantityDiscount {
  const _ShippingQuantityDiscount({required this.minQuantity, this.discountType = DiscountTypeValues.percent, required this.discountValue, this.label});
  factory _ShippingQuantityDiscount.fromJson(Map<String, dynamic> json) => _$ShippingQuantityDiscountFromJson(json);

/// Minimum quantity to qualify for this discount
@override final  int minQuantity;
/// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
@override@JsonKey() final  String discountType;
/// Discount value (interpretation depends on discountType)
@override final  double discountValue;
/// Optional label for display (e.g., "Bulk Shipping Discount")
@override final  String? label;

/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShippingQuantityDiscountCopyWith<_ShippingQuantityDiscount> get copyWith => __$ShippingQuantityDiscountCopyWithImpl<_ShippingQuantityDiscount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShippingQuantityDiscountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShippingQuantityDiscount&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,discountType,discountValue,label);

@override
String toString() {
  return 'ShippingQuantityDiscount(minQuantity: $minQuantity, discountType: $discountType, discountValue: $discountValue, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ShippingQuantityDiscountCopyWith<$Res> implements $ShippingQuantityDiscountCopyWith<$Res> {
  factory _$ShippingQuantityDiscountCopyWith(_ShippingQuantityDiscount value, $Res Function(_ShippingQuantityDiscount) _then) = __$ShippingQuantityDiscountCopyWithImpl;
@override @useResult
$Res call({
 int minQuantity, String discountType, double discountValue, String? label
});




}
/// @nodoc
class __$ShippingQuantityDiscountCopyWithImpl<$Res>
    implements _$ShippingQuantityDiscountCopyWith<$Res> {
  __$ShippingQuantityDiscountCopyWithImpl(this._self, this._then);

  final _ShippingQuantityDiscount _self;
  final $Res Function(_ShippingQuantityDiscount) _then;

/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minQuantity = null,Object? discountType = null,Object? discountValue = null,Object? label = freezed,}) {
  return _then(_ShippingQuantityDiscount(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as String,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SupplierInfo {

/// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
 String get type;/// Supplier's SKU/Product ID
 String? get supplierSku;/// Direct URL to supplier product page
 String? get supplierUrl;/// Cost price from supplier
 int? get costCents;/// Currency of supplier cost price (supplier's currency, NOT selling currency).
/// Selling price is always CAD. This tracks the supplier's original currency.
 String get currency;/// Estimated shipping days range (e.g., '7-15')
 String? get shippingDays;/// Whether supplier provides tracking
 bool get hasTracking;/// Internal notes about this supplier/product
 String? get notes;
/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<SupplierInfo> get copyWith => _$SupplierInfoCopyWithImpl<SupplierInfo>(this as SupplierInfo, _$identity);

  /// Serializes this SupplierInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupplierInfo&&(identical(other.type, type) || other.type == type)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.shippingDays, shippingDays) || other.shippingDays == shippingDays)&&(identical(other.hasTracking, hasTracking) || other.hasTracking == hasTracking)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,supplierSku,supplierUrl,costCents,currency,shippingDays,hasTracking,notes);

@override
String toString() {
  return 'SupplierInfo(type: $type, supplierSku: $supplierSku, supplierUrl: $supplierUrl, costCents: $costCents, currency: $currency, shippingDays: $shippingDays, hasTracking: $hasTracking, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SupplierInfoCopyWith<$Res>  {
  factory $SupplierInfoCopyWith(SupplierInfo value, $Res Function(SupplierInfo) _then) = _$SupplierInfoCopyWithImpl;
@useResult
$Res call({
 String type, String? supplierSku, String? supplierUrl, int? costCents, String currency, String? shippingDays, bool hasTracking, String? notes
});




}
/// @nodoc
class _$SupplierInfoCopyWithImpl<$Res>
    implements $SupplierInfoCopyWith<$Res> {
  _$SupplierInfoCopyWithImpl(this._self, this._then);

  final SupplierInfo _self;
  final $Res Function(SupplierInfo) _then;

/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? costCents = freezed,Object? currency = null,Object? shippingDays = freezed,Object? hasTracking = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,shippingDays: freezed == shippingDays ? _self.shippingDays : shippingDays // ignore: cast_nullable_to_non_nullable
as String?,hasTracking: null == hasTracking ? _self.hasTracking : hasTracking // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupplierInfo].
extension SupplierInfoPatterns on SupplierInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupplierInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupplierInfo value)  $default,){
final _that = this;
switch (_that) {
case _SupplierInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupplierInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String? supplierSku,  String? supplierUrl,  int? costCents,  String currency,  String? shippingDays,  bool hasTracking,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
return $default(_that.type,_that.supplierSku,_that.supplierUrl,_that.costCents,_that.currency,_that.shippingDays,_that.hasTracking,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String? supplierSku,  String? supplierUrl,  int? costCents,  String currency,  String? shippingDays,  bool hasTracking,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SupplierInfo():
return $default(_that.type,_that.supplierSku,_that.supplierUrl,_that.costCents,_that.currency,_that.shippingDays,_that.hasTracking,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String? supplierSku,  String? supplierUrl,  int? costCents,  String currency,  String? shippingDays,  bool hasTracking,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
return $default(_that.type,_that.supplierSku,_that.supplierUrl,_that.costCents,_that.currency,_that.shippingDays,_that.hasTracking,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupplierInfo implements SupplierInfo {
  const _SupplierInfo({required this.type, this.supplierSku, this.supplierUrl, this.costCents, this.currency = 'USD', this.shippingDays, this.hasTracking = false, this.notes});
  factory _SupplierInfo.fromJson(Map<String, dynamic> json) => _$SupplierInfoFromJson(json);

/// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
@override final  String type;
/// Supplier's SKU/Product ID
@override final  String? supplierSku;
/// Direct URL to supplier product page
@override final  String? supplierUrl;
/// Cost price from supplier
@override final  int? costCents;
/// Currency of supplier cost price (supplier's currency, NOT selling currency).
/// Selling price is always CAD. This tracks the supplier's original currency.
@override@JsonKey() final  String currency;
/// Estimated shipping days range (e.g., '7-15')
@override final  String? shippingDays;
/// Whether supplier provides tracking
@override@JsonKey() final  bool hasTracking;
/// Internal notes about this supplier/product
@override final  String? notes;

/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupplierInfoCopyWith<_SupplierInfo> get copyWith => __$SupplierInfoCopyWithImpl<_SupplierInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupplierInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupplierInfo&&(identical(other.type, type) || other.type == type)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.costCents, costCents) || other.costCents == costCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.shippingDays, shippingDays) || other.shippingDays == shippingDays)&&(identical(other.hasTracking, hasTracking) || other.hasTracking == hasTracking)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,supplierSku,supplierUrl,costCents,currency,shippingDays,hasTracking,notes);

@override
String toString() {
  return 'SupplierInfo(type: $type, supplierSku: $supplierSku, supplierUrl: $supplierUrl, costCents: $costCents, currency: $currency, shippingDays: $shippingDays, hasTracking: $hasTracking, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SupplierInfoCopyWith<$Res> implements $SupplierInfoCopyWith<$Res> {
  factory _$SupplierInfoCopyWith(_SupplierInfo value, $Res Function(_SupplierInfo) _then) = __$SupplierInfoCopyWithImpl;
@override @useResult
$Res call({
 String type, String? supplierSku, String? supplierUrl, int? costCents, String currency, String? shippingDays, bool hasTracking, String? notes
});




}
/// @nodoc
class __$SupplierInfoCopyWithImpl<$Res>
    implements _$SupplierInfoCopyWith<$Res> {
  __$SupplierInfoCopyWithImpl(this._self, this._then);

  final _SupplierInfo _self;
  final $Res Function(_SupplierInfo) _then;

/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? costCents = freezed,Object? currency = null,Object? shippingDays = freezed,Object? hasTracking = null,Object? notes = freezed,}) {
  return _then(_SupplierInfo(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,costCents: freezed == costCents ? _self.costCents : costCents // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,shippingDays: freezed == shippingDays ? _self.shippingDays : shippingDays // ignore: cast_nullable_to_non_nullable
as String?,hasTracking: null == hasTracking ? _self.hasTracking : hasTracking // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
