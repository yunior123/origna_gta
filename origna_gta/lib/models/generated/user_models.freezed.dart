// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 String get uid; String get email; String get name; List<UserRole> get roles; Address? get address; DateTime get createdAt;// Stripe information
 String? get customerId; String? get lastCheckoutSession; String? get lastOrderId; DateTime? get lastCheckoutTimestamp;// Seller information (Stripe Connect)
 String? get stripeAccountId; bool get payoutsEnabled; bool get chargesEnabled; bool get onboardingCompleted;// Account status
 bool get suspended; DateTime? get suspendedAt; DateTime? get updatedAt;// === AUDIT FIX: 13 missing fields synced from Python/Firestore ===
// Payment provider
 String? get paymentProvider;// Airwallex (alternative payment provider)
 String? get airwallexAccountId; String? get airwallexCustomerId; String? get airwallexStatus;// Suspension details
 DateTime? get unsuspendedAt; String? get suspendedBy; String? get suspensionReason;// Seller verification & commission
 double? get commissionRate; bool get verified; String? get verificationStatus; String? get platform; String? get businessName; int? get payoutHoldDays;// Tax exemption for businesses
 Map<String, dynamic>? get taxExemption;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.lastCheckoutSession, lastCheckoutSession) || other.lastCheckoutSession == lastCheckoutSession)&&(identical(other.lastOrderId, lastOrderId) || other.lastOrderId == lastOrderId)&&(identical(other.lastCheckoutTimestamp, lastCheckoutTimestamp) || other.lastCheckoutTimestamp == lastCheckoutTimestamp)&&(identical(other.stripeAccountId, stripeAccountId) || other.stripeAccountId == stripeAccountId)&&(identical(other.payoutsEnabled, payoutsEnabled) || other.payoutsEnabled == payoutsEnabled)&&(identical(other.chargesEnabled, chargesEnabled) || other.chargesEnabled == chargesEnabled)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.suspended, suspended) || other.suspended == suspended)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider)&&(identical(other.airwallexAccountId, airwallexAccountId) || other.airwallexAccountId == airwallexAccountId)&&(identical(other.airwallexCustomerId, airwallexCustomerId) || other.airwallexCustomerId == airwallexCustomerId)&&(identical(other.airwallexStatus, airwallexStatus) || other.airwallexStatus == airwallexStatus)&&(identical(other.unsuspendedAt, unsuspendedAt) || other.unsuspendedAt == unsuspendedAt)&&(identical(other.suspendedBy, suspendedBy) || other.suspendedBy == suspendedBy)&&(identical(other.suspensionReason, suspensionReason) || other.suspensionReason == suspensionReason)&&(identical(other.commissionRate, commissionRate) || other.commissionRate == commissionRate)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.payoutHoldDays, payoutHoldDays) || other.payoutHoldDays == payoutHoldDays)&&const DeepCollectionEquality().equals(other.taxExemption, taxExemption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,email,name,const DeepCollectionEquality().hash(roles),address,createdAt,customerId,lastCheckoutSession,lastOrderId,lastCheckoutTimestamp,stripeAccountId,payoutsEnabled,chargesEnabled,onboardingCompleted,suspended,suspendedAt,updatedAt,paymentProvider,airwallexAccountId,airwallexCustomerId,airwallexStatus,unsuspendedAt,suspendedBy,suspensionReason,commissionRate,verified,verificationStatus,platform,businessName,payoutHoldDays,const DeepCollectionEquality().hash(taxExemption)]);

@override
String toString() {
  return 'User(uid: $uid, email: $email, name: $name, roles: $roles, address: $address, createdAt: $createdAt, customerId: $customerId, lastCheckoutSession: $lastCheckoutSession, lastOrderId: $lastOrderId, lastCheckoutTimestamp: $lastCheckoutTimestamp, stripeAccountId: $stripeAccountId, payoutsEnabled: $payoutsEnabled, chargesEnabled: $chargesEnabled, onboardingCompleted: $onboardingCompleted, suspended: $suspended, suspendedAt: $suspendedAt, updatedAt: $updatedAt, paymentProvider: $paymentProvider, airwallexAccountId: $airwallexAccountId, airwallexCustomerId: $airwallexCustomerId, airwallexStatus: $airwallexStatus, unsuspendedAt: $unsuspendedAt, suspendedBy: $suspendedBy, suspensionReason: $suspensionReason, commissionRate: $commissionRate, verified: $verified, verificationStatus: $verificationStatus, platform: $platform, businessName: $businessName, payoutHoldDays: $payoutHoldDays, taxExemption: $taxExemption)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String uid, String email, String name, List<UserRole> roles, Address? address, DateTime createdAt, String? customerId, String? lastCheckoutSession, String? lastOrderId, DateTime? lastCheckoutTimestamp, String? stripeAccountId, bool payoutsEnabled, bool chargesEnabled, bool onboardingCompleted, bool suspended, DateTime? suspendedAt, DateTime? updatedAt, String? paymentProvider, String? airwallexAccountId, String? airwallexCustomerId, String? airwallexStatus, DateTime? unsuspendedAt, String? suspendedBy, String? suspensionReason, double? commissionRate, bool verified, String? verificationStatus, String? platform, String? businessName, int? payoutHoldDays, Map<String, dynamic>? taxExemption
});


$AddressCopyWith<$Res>? get address;

}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = null,Object? name = null,Object? roles = null,Object? address = freezed,Object? createdAt = null,Object? customerId = freezed,Object? lastCheckoutSession = freezed,Object? lastOrderId = freezed,Object? lastCheckoutTimestamp = freezed,Object? stripeAccountId = freezed,Object? payoutsEnabled = null,Object? chargesEnabled = null,Object? onboardingCompleted = null,Object? suspended = null,Object? suspendedAt = freezed,Object? updatedAt = freezed,Object? paymentProvider = freezed,Object? airwallexAccountId = freezed,Object? airwallexCustomerId = freezed,Object? airwallexStatus = freezed,Object? unsuspendedAt = freezed,Object? suspendedBy = freezed,Object? suspensionReason = freezed,Object? commissionRate = freezed,Object? verified = null,Object? verificationStatus = freezed,Object? platform = freezed,Object? businessName = freezed,Object? payoutHoldDays = freezed,Object? taxExemption = freezed,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,lastCheckoutSession: freezed == lastCheckoutSession ? _self.lastCheckoutSession : lastCheckoutSession // ignore: cast_nullable_to_non_nullable
as String?,lastOrderId: freezed == lastOrderId ? _self.lastOrderId : lastOrderId // ignore: cast_nullable_to_non_nullable
as String?,lastCheckoutTimestamp: freezed == lastCheckoutTimestamp ? _self.lastCheckoutTimestamp : lastCheckoutTimestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,stripeAccountId: freezed == stripeAccountId ? _self.stripeAccountId : stripeAccountId // ignore: cast_nullable_to_non_nullable
as String?,payoutsEnabled: null == payoutsEnabled ? _self.payoutsEnabled : payoutsEnabled // ignore: cast_nullable_to_non_nullable
as bool,chargesEnabled: null == chargesEnabled ? _self.chargesEnabled : chargesEnabled // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,suspended: null == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentProvider: freezed == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String?,airwallexAccountId: freezed == airwallexAccountId ? _self.airwallexAccountId : airwallexAccountId // ignore: cast_nullable_to_non_nullable
as String?,airwallexCustomerId: freezed == airwallexCustomerId ? _self.airwallexCustomerId : airwallexCustomerId // ignore: cast_nullable_to_non_nullable
as String?,airwallexStatus: freezed == airwallexStatus ? _self.airwallexStatus : airwallexStatus // ignore: cast_nullable_to_non_nullable
as String?,unsuspendedAt: freezed == unsuspendedAt ? _self.unsuspendedAt : unsuspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedBy: freezed == suspendedBy ? _self.suspendedBy : suspendedBy // ignore: cast_nullable_to_non_nullable
as String?,suspensionReason: freezed == suspensionReason ? _self.suspensionReason : suspensionReason // ignore: cast_nullable_to_non_nullable
as String?,commissionRate: freezed == commissionRate ? _self.commissionRate : commissionRate // ignore: cast_nullable_to_non_nullable
as double?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,verificationStatus: freezed == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,businessName: freezed == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String?,payoutHoldDays: freezed == payoutHoldDays ? _self.payoutHoldDays : payoutHoldDays // ignore: cast_nullable_to_non_nullable
as int?,taxExemption: freezed == taxExemption ? _self.taxExemption : taxExemption // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String email,  String name,  List<UserRole> roles,  Address? address,  DateTime createdAt,  String? customerId,  String? lastCheckoutSession,  String? lastOrderId,  DateTime? lastCheckoutTimestamp,  String? stripeAccountId,  bool payoutsEnabled,  bool chargesEnabled,  bool onboardingCompleted,  bool suspended,  DateTime? suspendedAt,  DateTime? updatedAt,  String? paymentProvider,  String? airwallexAccountId,  String? airwallexCustomerId,  String? airwallexStatus,  DateTime? unsuspendedAt,  String? suspendedBy,  String? suspensionReason,  double? commissionRate,  bool verified,  String? verificationStatus,  String? platform,  String? businessName,  int? payoutHoldDays,  Map<String, dynamic>? taxExemption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.uid,_that.email,_that.name,_that.roles,_that.address,_that.createdAt,_that.customerId,_that.lastCheckoutSession,_that.lastOrderId,_that.lastCheckoutTimestamp,_that.stripeAccountId,_that.payoutsEnabled,_that.chargesEnabled,_that.onboardingCompleted,_that.suspended,_that.suspendedAt,_that.updatedAt,_that.paymentProvider,_that.airwallexAccountId,_that.airwallexCustomerId,_that.airwallexStatus,_that.unsuspendedAt,_that.suspendedBy,_that.suspensionReason,_that.commissionRate,_that.verified,_that.verificationStatus,_that.platform,_that.businessName,_that.payoutHoldDays,_that.taxExemption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String email,  String name,  List<UserRole> roles,  Address? address,  DateTime createdAt,  String? customerId,  String? lastCheckoutSession,  String? lastOrderId,  DateTime? lastCheckoutTimestamp,  String? stripeAccountId,  bool payoutsEnabled,  bool chargesEnabled,  bool onboardingCompleted,  bool suspended,  DateTime? suspendedAt,  DateTime? updatedAt,  String? paymentProvider,  String? airwallexAccountId,  String? airwallexCustomerId,  String? airwallexStatus,  DateTime? unsuspendedAt,  String? suspendedBy,  String? suspensionReason,  double? commissionRate,  bool verified,  String? verificationStatus,  String? platform,  String? businessName,  int? payoutHoldDays,  Map<String, dynamic>? taxExemption)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.uid,_that.email,_that.name,_that.roles,_that.address,_that.createdAt,_that.customerId,_that.lastCheckoutSession,_that.lastOrderId,_that.lastCheckoutTimestamp,_that.stripeAccountId,_that.payoutsEnabled,_that.chargesEnabled,_that.onboardingCompleted,_that.suspended,_that.suspendedAt,_that.updatedAt,_that.paymentProvider,_that.airwallexAccountId,_that.airwallexCustomerId,_that.airwallexStatus,_that.unsuspendedAt,_that.suspendedBy,_that.suspensionReason,_that.commissionRate,_that.verified,_that.verificationStatus,_that.platform,_that.businessName,_that.payoutHoldDays,_that.taxExemption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String email,  String name,  List<UserRole> roles,  Address? address,  DateTime createdAt,  String? customerId,  String? lastCheckoutSession,  String? lastOrderId,  DateTime? lastCheckoutTimestamp,  String? stripeAccountId,  bool payoutsEnabled,  bool chargesEnabled,  bool onboardingCompleted,  bool suspended,  DateTime? suspendedAt,  DateTime? updatedAt,  String? paymentProvider,  String? airwallexAccountId,  String? airwallexCustomerId,  String? airwallexStatus,  DateTime? unsuspendedAt,  String? suspendedBy,  String? suspensionReason,  double? commissionRate,  bool verified,  String? verificationStatus,  String? platform,  String? businessName,  int? payoutHoldDays,  Map<String, dynamic>? taxExemption)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.uid,_that.email,_that.name,_that.roles,_that.address,_that.createdAt,_that.customerId,_that.lastCheckoutSession,_that.lastOrderId,_that.lastCheckoutTimestamp,_that.stripeAccountId,_that.payoutsEnabled,_that.chargesEnabled,_that.onboardingCompleted,_that.suspended,_that.suspendedAt,_that.updatedAt,_that.paymentProvider,_that.airwallexAccountId,_that.airwallexCustomerId,_that.airwallexStatus,_that.unsuspendedAt,_that.suspendedBy,_that.suspensionReason,_that.commissionRate,_that.verified,_that.verificationStatus,_that.platform,_that.businessName,_that.payoutHoldDays,_that.taxExemption);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User extends User {
  const _User({required this.uid, required this.email, required this.name, required final  List<UserRole> roles, this.address, required this.createdAt, this.customerId, this.lastCheckoutSession, this.lastOrderId, this.lastCheckoutTimestamp, this.stripeAccountId, this.payoutsEnabled = false, this.chargesEnabled = false, this.onboardingCompleted = false, this.suspended = false, this.suspendedAt, this.updatedAt, this.paymentProvider, this.airwallexAccountId, this.airwallexCustomerId, this.airwallexStatus, this.unsuspendedAt, this.suspendedBy, this.suspensionReason, this.commissionRate, this.verified = false, this.verificationStatus, this.platform, this.businessName, this.payoutHoldDays, final  Map<String, dynamic>? taxExemption}): _roles = roles,_taxExemption = taxExemption,super._();
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  String uid;
@override final  String email;
@override final  String name;
 final  List<UserRole> _roles;
@override List<UserRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  Address? address;
@override final  DateTime createdAt;
// Stripe information
@override final  String? customerId;
@override final  String? lastCheckoutSession;
@override final  String? lastOrderId;
@override final  DateTime? lastCheckoutTimestamp;
// Seller information (Stripe Connect)
@override final  String? stripeAccountId;
@override@JsonKey() final  bool payoutsEnabled;
@override@JsonKey() final  bool chargesEnabled;
@override@JsonKey() final  bool onboardingCompleted;
// Account status
@override@JsonKey() final  bool suspended;
@override final  DateTime? suspendedAt;
@override final  DateTime? updatedAt;
// === AUDIT FIX: 13 missing fields synced from Python/Firestore ===
// Payment provider
@override final  String? paymentProvider;
// Airwallex (alternative payment provider)
@override final  String? airwallexAccountId;
@override final  String? airwallexCustomerId;
@override final  String? airwallexStatus;
// Suspension details
@override final  DateTime? unsuspendedAt;
@override final  String? suspendedBy;
@override final  String? suspensionReason;
// Seller verification & commission
@override final  double? commissionRate;
@override@JsonKey() final  bool verified;
@override final  String? verificationStatus;
@override final  String? platform;
@override final  String? businessName;
@override final  int? payoutHoldDays;
// Tax exemption for businesses
 final  Map<String, dynamic>? _taxExemption;
// Tax exemption for businesses
@override Map<String, dynamic>? get taxExemption {
  final value = _taxExemption;
  if (value == null) return null;
  if (_taxExemption is EqualUnmodifiableMapView) return _taxExemption;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.address, address) || other.address == address)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.lastCheckoutSession, lastCheckoutSession) || other.lastCheckoutSession == lastCheckoutSession)&&(identical(other.lastOrderId, lastOrderId) || other.lastOrderId == lastOrderId)&&(identical(other.lastCheckoutTimestamp, lastCheckoutTimestamp) || other.lastCheckoutTimestamp == lastCheckoutTimestamp)&&(identical(other.stripeAccountId, stripeAccountId) || other.stripeAccountId == stripeAccountId)&&(identical(other.payoutsEnabled, payoutsEnabled) || other.payoutsEnabled == payoutsEnabled)&&(identical(other.chargesEnabled, chargesEnabled) || other.chargesEnabled == chargesEnabled)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.suspended, suspended) || other.suspended == suspended)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider)&&(identical(other.airwallexAccountId, airwallexAccountId) || other.airwallexAccountId == airwallexAccountId)&&(identical(other.airwallexCustomerId, airwallexCustomerId) || other.airwallexCustomerId == airwallexCustomerId)&&(identical(other.airwallexStatus, airwallexStatus) || other.airwallexStatus == airwallexStatus)&&(identical(other.unsuspendedAt, unsuspendedAt) || other.unsuspendedAt == unsuspendedAt)&&(identical(other.suspendedBy, suspendedBy) || other.suspendedBy == suspendedBy)&&(identical(other.suspensionReason, suspensionReason) || other.suspensionReason == suspensionReason)&&(identical(other.commissionRate, commissionRate) || other.commissionRate == commissionRate)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.payoutHoldDays, payoutHoldDays) || other.payoutHoldDays == payoutHoldDays)&&const DeepCollectionEquality().equals(other._taxExemption, _taxExemption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,email,name,const DeepCollectionEquality().hash(_roles),address,createdAt,customerId,lastCheckoutSession,lastOrderId,lastCheckoutTimestamp,stripeAccountId,payoutsEnabled,chargesEnabled,onboardingCompleted,suspended,suspendedAt,updatedAt,paymentProvider,airwallexAccountId,airwallexCustomerId,airwallexStatus,unsuspendedAt,suspendedBy,suspensionReason,commissionRate,verified,verificationStatus,platform,businessName,payoutHoldDays,const DeepCollectionEquality().hash(_taxExemption)]);

@override
String toString() {
  return 'User(uid: $uid, email: $email, name: $name, roles: $roles, address: $address, createdAt: $createdAt, customerId: $customerId, lastCheckoutSession: $lastCheckoutSession, lastOrderId: $lastOrderId, lastCheckoutTimestamp: $lastCheckoutTimestamp, stripeAccountId: $stripeAccountId, payoutsEnabled: $payoutsEnabled, chargesEnabled: $chargesEnabled, onboardingCompleted: $onboardingCompleted, suspended: $suspended, suspendedAt: $suspendedAt, updatedAt: $updatedAt, paymentProvider: $paymentProvider, airwallexAccountId: $airwallexAccountId, airwallexCustomerId: $airwallexCustomerId, airwallexStatus: $airwallexStatus, unsuspendedAt: $unsuspendedAt, suspendedBy: $suspendedBy, suspensionReason: $suspensionReason, commissionRate: $commissionRate, verified: $verified, verificationStatus: $verificationStatus, platform: $platform, businessName: $businessName, payoutHoldDays: $payoutHoldDays, taxExemption: $taxExemption)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String uid, String email, String name, List<UserRole> roles, Address? address, DateTime createdAt, String? customerId, String? lastCheckoutSession, String? lastOrderId, DateTime? lastCheckoutTimestamp, String? stripeAccountId, bool payoutsEnabled, bool chargesEnabled, bool onboardingCompleted, bool suspended, DateTime? suspendedAt, DateTime? updatedAt, String? paymentProvider, String? airwallexAccountId, String? airwallexCustomerId, String? airwallexStatus, DateTime? unsuspendedAt, String? suspendedBy, String? suspensionReason, double? commissionRate, bool verified, String? verificationStatus, String? platform, String? businessName, int? payoutHoldDays, Map<String, dynamic>? taxExemption
});


@override $AddressCopyWith<$Res>? get address;

}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = null,Object? name = null,Object? roles = null,Object? address = freezed,Object? createdAt = null,Object? customerId = freezed,Object? lastCheckoutSession = freezed,Object? lastOrderId = freezed,Object? lastCheckoutTimestamp = freezed,Object? stripeAccountId = freezed,Object? payoutsEnabled = null,Object? chargesEnabled = null,Object? onboardingCompleted = null,Object? suspended = null,Object? suspendedAt = freezed,Object? updatedAt = freezed,Object? paymentProvider = freezed,Object? airwallexAccountId = freezed,Object? airwallexCustomerId = freezed,Object? airwallexStatus = freezed,Object? unsuspendedAt = freezed,Object? suspendedBy = freezed,Object? suspensionReason = freezed,Object? commissionRate = freezed,Object? verified = null,Object? verificationStatus = freezed,Object? platform = freezed,Object? businessName = freezed,Object? payoutHoldDays = freezed,Object? taxExemption = freezed,}) {
  return _then(_User(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,lastCheckoutSession: freezed == lastCheckoutSession ? _self.lastCheckoutSession : lastCheckoutSession // ignore: cast_nullable_to_non_nullable
as String?,lastOrderId: freezed == lastOrderId ? _self.lastOrderId : lastOrderId // ignore: cast_nullable_to_non_nullable
as String?,lastCheckoutTimestamp: freezed == lastCheckoutTimestamp ? _self.lastCheckoutTimestamp : lastCheckoutTimestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,stripeAccountId: freezed == stripeAccountId ? _self.stripeAccountId : stripeAccountId // ignore: cast_nullable_to_non_nullable
as String?,payoutsEnabled: null == payoutsEnabled ? _self.payoutsEnabled : payoutsEnabled // ignore: cast_nullable_to_non_nullable
as bool,chargesEnabled: null == chargesEnabled ? _self.chargesEnabled : chargesEnabled // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,suspended: null == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentProvider: freezed == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String?,airwallexAccountId: freezed == airwallexAccountId ? _self.airwallexAccountId : airwallexAccountId // ignore: cast_nullable_to_non_nullable
as String?,airwallexCustomerId: freezed == airwallexCustomerId ? _self.airwallexCustomerId : airwallexCustomerId // ignore: cast_nullable_to_non_nullable
as String?,airwallexStatus: freezed == airwallexStatus ? _self.airwallexStatus : airwallexStatus // ignore: cast_nullable_to_non_nullable
as String?,unsuspendedAt: freezed == unsuspendedAt ? _self.unsuspendedAt : unsuspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedBy: freezed == suspendedBy ? _self.suspendedBy : suspendedBy // ignore: cast_nullable_to_non_nullable
as String?,suspensionReason: freezed == suspensionReason ? _self.suspensionReason : suspensionReason // ignore: cast_nullable_to_non_nullable
as String?,commissionRate: freezed == commissionRate ? _self.commissionRate : commissionRate // ignore: cast_nullable_to_non_nullable
as double?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,verificationStatus: freezed == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,businessName: freezed == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String?,payoutHoldDays: freezed == payoutHoldDays ? _self.payoutHoldDays : payoutHoldDays // ignore: cast_nullable_to_non_nullable
as int?,taxExemption: freezed == taxExemption ? _self._taxExemption : taxExemption // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// @nodoc
mixin _$UserCreate {

 String get email; String get name; List<UserRole> get roles; Address? get address;
/// Create a copy of UserCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCreateCopyWith<UserCreate> get copyWith => _$UserCreateCopyWithImpl<UserCreate>(this as UserCreate, _$identity);

  /// Serializes this UserCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCreate&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,name,const DeepCollectionEquality().hash(roles),address);

@override
String toString() {
  return 'UserCreate(email: $email, name: $name, roles: $roles, address: $address)';
}


}

/// @nodoc
abstract mixin class $UserCreateCopyWith<$Res>  {
  factory $UserCreateCopyWith(UserCreate value, $Res Function(UserCreate) _then) = _$UserCreateCopyWithImpl;
@useResult
$Res call({
 String email, String name, List<UserRole> roles, Address? address
});


$AddressCopyWith<$Res>? get address;

}
/// @nodoc
class _$UserCreateCopyWithImpl<$Res>
    implements $UserCreateCopyWith<$Res> {
  _$UserCreateCopyWithImpl(this._self, this._then);

  final UserCreate _self;
  final $Res Function(UserCreate) _then;

/// Create a copy of UserCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? name = null,Object? roles = null,Object? address = freezed,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,
  ));
}
/// Create a copy of UserCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserCreate].
extension UserCreatePatterns on UserCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCreate value)  $default,){
final _that = this;
switch (_that) {
case _UserCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCreate value)?  $default,){
final _that = this;
switch (_that) {
case _UserCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String name,  List<UserRole> roles,  Address? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCreate() when $default != null:
return $default(_that.email,_that.name,_that.roles,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String name,  List<UserRole> roles,  Address? address)  $default,) {final _that = this;
switch (_that) {
case _UserCreate():
return $default(_that.email,_that.name,_that.roles,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String name,  List<UserRole> roles,  Address? address)?  $default,) {final _that = this;
switch (_that) {
case _UserCreate() when $default != null:
return $default(_that.email,_that.name,_that.roles,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserCreate implements UserCreate {
  const _UserCreate({required this.email, required this.name, final  List<UserRole> roles = const [UserRole.buyer], this.address}): _roles = roles;
  factory _UserCreate.fromJson(Map<String, dynamic> json) => _$UserCreateFromJson(json);

@override final  String email;
@override final  String name;
 final  List<UserRole> _roles;
@override@JsonKey() List<UserRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  Address? address;

/// Create a copy of UserCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCreateCopyWith<_UserCreate> get copyWith => __$UserCreateCopyWithImpl<_UserCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCreate&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,name,const DeepCollectionEquality().hash(_roles),address);

@override
String toString() {
  return 'UserCreate(email: $email, name: $name, roles: $roles, address: $address)';
}


}

/// @nodoc
abstract mixin class _$UserCreateCopyWith<$Res> implements $UserCreateCopyWith<$Res> {
  factory _$UserCreateCopyWith(_UserCreate value, $Res Function(_UserCreate) _then) = __$UserCreateCopyWithImpl;
@override @useResult
$Res call({
 String email, String name, List<UserRole> roles, Address? address
});


@override $AddressCopyWith<$Res>? get address;

}
/// @nodoc
class __$UserCreateCopyWithImpl<$Res>
    implements _$UserCreateCopyWith<$Res> {
  __$UserCreateCopyWithImpl(this._self, this._then);

  final _UserCreate _self;
  final $Res Function(_UserCreate) _then;

/// Create a copy of UserCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? name = null,Object? roles = null,Object? address = freezed,}) {
  return _then(_UserCreate(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,
  ));
}

/// Create a copy of UserCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}

// dart format on
