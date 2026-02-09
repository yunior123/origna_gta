// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get uid => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<UserRole> get roles => throw _privateConstructorUsedError;
  Address? get address => throw _privateConstructorUsedError;
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Stripe information
  String? get customerId => throw _privateConstructorUsedError;
  String? get lastCheckoutSession => throw _privateConstructorUsedError;
  String? get lastOrderId => throw _privateConstructorUsedError;
  DateTime? get lastCheckoutTimestamp =>
      throw _privateConstructorUsedError; // Seller information (Stripe Connect)
  String? get stripeAccountId => throw _privateConstructorUsedError;
  bool get payoutsEnabled => throw _privateConstructorUsedError;
  bool get chargesEnabled => throw _privateConstructorUsedError;
  bool get onboardingCompleted =>
      throw _privateConstructorUsedError; // Account status
  bool get suspended => throw _privateConstructorUsedError;
  DateTime? get suspendedAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // === AUDIT FIX: 13 missing fields synced from Python/Firestore ===
  // Payment provider
  String? get paymentProvider =>
      throw _privateConstructorUsedError; // Airwallex (alternative payment provider)
  String? get airwallexAccountId => throw _privateConstructorUsedError;
  String? get airwallexCustomerId => throw _privateConstructorUsedError;
  String? get airwallexStatus =>
      throw _privateConstructorUsedError; // Suspension details
  DateTime? get unsuspendedAt => throw _privateConstructorUsedError;
  String? get suspendedBy => throw _privateConstructorUsedError;
  String? get suspensionReason =>
      throw _privateConstructorUsedError; // Seller verification & commission
  double? get commissionRate => throw _privateConstructorUsedError;
  bool get verified => throw _privateConstructorUsedError;
  String? get verificationStatus => throw _privateConstructorUsedError;
  String? get platform => throw _privateConstructorUsedError;
  String? get businessName => throw _privateConstructorUsedError;
  int? get payoutHoldDays =>
      throw _privateConstructorUsedError; // Tax exemption for businesses
  Map<String, dynamic>? get taxExemption => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call({
    String uid,
    String email,
    String name,
    List<UserRole> roles,
    Address? address,
    DateTime createdAt,
    String? customerId,
    String? lastCheckoutSession,
    String? lastOrderId,
    DateTime? lastCheckoutTimestamp,
    String? stripeAccountId,
    bool payoutsEnabled,
    bool chargesEnabled,
    bool onboardingCompleted,
    bool suspended,
    DateTime? suspendedAt,
    DateTime? updatedAt,
    String? paymentProvider,
    String? airwallexAccountId,
    String? airwallexCustomerId,
    String? airwallexStatus,
    DateTime? unsuspendedAt,
    String? suspendedBy,
    String? suspensionReason,
    double? commissionRate,
    bool verified,
    String? verificationStatus,
    String? platform,
    String? businessName,
    int? payoutHoldDays,
    Map<String, dynamic>? taxExemption,
  });

  $AddressCopyWith<$Res>? get address;
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? name = null,
    Object? roles = null,
    Object? address = freezed,
    Object? createdAt = null,
    Object? customerId = freezed,
    Object? lastCheckoutSession = freezed,
    Object? lastOrderId = freezed,
    Object? lastCheckoutTimestamp = freezed,
    Object? stripeAccountId = freezed,
    Object? payoutsEnabled = null,
    Object? chargesEnabled = null,
    Object? onboardingCompleted = null,
    Object? suspended = null,
    Object? suspendedAt = freezed,
    Object? updatedAt = freezed,
    Object? paymentProvider = freezed,
    Object? airwallexAccountId = freezed,
    Object? airwallexCustomerId = freezed,
    Object? airwallexStatus = freezed,
    Object? unsuspendedAt = freezed,
    Object? suspendedBy = freezed,
    Object? suspensionReason = freezed,
    Object? commissionRate = freezed,
    Object? verified = null,
    Object? verificationStatus = freezed,
    Object? platform = freezed,
    Object? businessName = freezed,
    Object? payoutHoldDays = freezed,
    Object? taxExemption = freezed,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<UserRole>,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as Address?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            customerId: freezed == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastCheckoutSession: freezed == lastCheckoutSession
                ? _value.lastCheckoutSession
                : lastCheckoutSession // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastOrderId: freezed == lastOrderId
                ? _value.lastOrderId
                : lastOrderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastCheckoutTimestamp: freezed == lastCheckoutTimestamp
                ? _value.lastCheckoutTimestamp
                : lastCheckoutTimestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            stripeAccountId: freezed == stripeAccountId
                ? _value.stripeAccountId
                : stripeAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            payoutsEnabled: null == payoutsEnabled
                ? _value.payoutsEnabled
                : payoutsEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            chargesEnabled: null == chargesEnabled
                ? _value.chargesEnabled
                : chargesEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            onboardingCompleted: null == onboardingCompleted
                ? _value.onboardingCompleted
                : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            suspended: null == suspended
                ? _value.suspended
                : suspended // ignore: cast_nullable_to_non_nullable
                      as bool,
            suspendedAt: freezed == suspendedAt
                ? _value.suspendedAt
                : suspendedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            paymentProvider: freezed == paymentProvider
                ? _value.paymentProvider
                : paymentProvider // ignore: cast_nullable_to_non_nullable
                      as String?,
            airwallexAccountId: freezed == airwallexAccountId
                ? _value.airwallexAccountId
                : airwallexAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            airwallexCustomerId: freezed == airwallexCustomerId
                ? _value.airwallexCustomerId
                : airwallexCustomerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            airwallexStatus: freezed == airwallexStatus
                ? _value.airwallexStatus
                : airwallexStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            unsuspendedAt: freezed == unsuspendedAt
                ? _value.unsuspendedAt
                : unsuspendedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            suspendedBy: freezed == suspendedBy
                ? _value.suspendedBy
                : suspendedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            suspensionReason: freezed == suspensionReason
                ? _value.suspensionReason
                : suspensionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            commissionRate: freezed == commissionRate
                ? _value.commissionRate
                : commissionRate // ignore: cast_nullable_to_non_nullable
                      as double?,
            verified: null == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                      as bool,
            verificationStatus: freezed == verificationStatus
                ? _value.verificationStatus
                : verificationStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            platform: freezed == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as String?,
            businessName: freezed == businessName
                ? _value.businessName
                : businessName // ignore: cast_nullable_to_non_nullable
                      as String?,
            payoutHoldDays: freezed == payoutHoldDays
                ? _value.payoutHoldDays
                : payoutHoldDays // ignore: cast_nullable_to_non_nullable
                      as int?,
            taxExemption: freezed == taxExemption
                ? _value.taxExemption
                : taxExemption // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res>? get address {
    if (_value.address == null) {
      return null;
    }

    return $AddressCopyWith<$Res>(_value.address!, (value) {
      return _then(_value.copyWith(address: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String email,
    String name,
    List<UserRole> roles,
    Address? address,
    DateTime createdAt,
    String? customerId,
    String? lastCheckoutSession,
    String? lastOrderId,
    DateTime? lastCheckoutTimestamp,
    String? stripeAccountId,
    bool payoutsEnabled,
    bool chargesEnabled,
    bool onboardingCompleted,
    bool suspended,
    DateTime? suspendedAt,
    DateTime? updatedAt,
    String? paymentProvider,
    String? airwallexAccountId,
    String? airwallexCustomerId,
    String? airwallexStatus,
    DateTime? unsuspendedAt,
    String? suspendedBy,
    String? suspensionReason,
    double? commissionRate,
    bool verified,
    String? verificationStatus,
    String? platform,
    String? businessName,
    int? payoutHoldDays,
    Map<String, dynamic>? taxExemption,
  });

  @override
  $AddressCopyWith<$Res>? get address;
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? name = null,
    Object? roles = null,
    Object? address = freezed,
    Object? createdAt = null,
    Object? customerId = freezed,
    Object? lastCheckoutSession = freezed,
    Object? lastOrderId = freezed,
    Object? lastCheckoutTimestamp = freezed,
    Object? stripeAccountId = freezed,
    Object? payoutsEnabled = null,
    Object? chargesEnabled = null,
    Object? onboardingCompleted = null,
    Object? suspended = null,
    Object? suspendedAt = freezed,
    Object? updatedAt = freezed,
    Object? paymentProvider = freezed,
    Object? airwallexAccountId = freezed,
    Object? airwallexCustomerId = freezed,
    Object? airwallexStatus = freezed,
    Object? unsuspendedAt = freezed,
    Object? suspendedBy = freezed,
    Object? suspensionReason = freezed,
    Object? commissionRate = freezed,
    Object? verified = null,
    Object? verificationStatus = freezed,
    Object? platform = freezed,
    Object? businessName = freezed,
    Object? payoutHoldDays = freezed,
    Object? taxExemption = freezed,
  }) {
    return _then(
      _$UserImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<UserRole>,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as Address?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        customerId: freezed == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastCheckoutSession: freezed == lastCheckoutSession
            ? _value.lastCheckoutSession
            : lastCheckoutSession // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastOrderId: freezed == lastOrderId
            ? _value.lastOrderId
            : lastOrderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastCheckoutTimestamp: freezed == lastCheckoutTimestamp
            ? _value.lastCheckoutTimestamp
            : lastCheckoutTimestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        stripeAccountId: freezed == stripeAccountId
            ? _value.stripeAccountId
            : stripeAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        payoutsEnabled: null == payoutsEnabled
            ? _value.payoutsEnabled
            : payoutsEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        chargesEnabled: null == chargesEnabled
            ? _value.chargesEnabled
            : chargesEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        onboardingCompleted: null == onboardingCompleted
            ? _value.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        suspended: null == suspended
            ? _value.suspended
            : suspended // ignore: cast_nullable_to_non_nullable
                  as bool,
        suspendedAt: freezed == suspendedAt
            ? _value.suspendedAt
            : suspendedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        paymentProvider: freezed == paymentProvider
            ? _value.paymentProvider
            : paymentProvider // ignore: cast_nullable_to_non_nullable
                  as String?,
        airwallexAccountId: freezed == airwallexAccountId
            ? _value.airwallexAccountId
            : airwallexAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        airwallexCustomerId: freezed == airwallexCustomerId
            ? _value.airwallexCustomerId
            : airwallexCustomerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        airwallexStatus: freezed == airwallexStatus
            ? _value.airwallexStatus
            : airwallexStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        unsuspendedAt: freezed == unsuspendedAt
            ? _value.unsuspendedAt
            : unsuspendedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        suspendedBy: freezed == suspendedBy
            ? _value.suspendedBy
            : suspendedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        suspensionReason: freezed == suspensionReason
            ? _value.suspensionReason
            : suspensionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        commissionRate: freezed == commissionRate
            ? _value.commissionRate
            : commissionRate // ignore: cast_nullable_to_non_nullable
                  as double?,
        verified: null == verified
            ? _value.verified
            : verified // ignore: cast_nullable_to_non_nullable
                  as bool,
        verificationStatus: freezed == verificationStatus
            ? _value.verificationStatus
            : verificationStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        platform: freezed == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String?,
        businessName: freezed == businessName
            ? _value.businessName
            : businessName // ignore: cast_nullable_to_non_nullable
                  as String?,
        payoutHoldDays: freezed == payoutHoldDays
            ? _value.payoutHoldDays
            : payoutHoldDays // ignore: cast_nullable_to_non_nullable
                  as int?,
        taxExemption: freezed == taxExemption
            ? _value._taxExemption
            : taxExemption // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl extends _User {
  const _$UserImpl({
    required this.uid,
    required this.email,
    required this.name,
    required final List<UserRole> roles,
    this.address,
    required this.createdAt,
    this.customerId,
    this.lastCheckoutSession,
    this.lastOrderId,
    this.lastCheckoutTimestamp,
    this.stripeAccountId,
    this.payoutsEnabled = false,
    this.chargesEnabled = false,
    this.onboardingCompleted = false,
    this.suspended = false,
    this.suspendedAt,
    this.updatedAt,
    this.paymentProvider,
    this.airwallexAccountId,
    this.airwallexCustomerId,
    this.airwallexStatus,
    this.unsuspendedAt,
    this.suspendedBy,
    this.suspensionReason,
    this.commissionRate,
    this.verified = false,
    this.verificationStatus,
    this.platform,
    this.businessName,
    this.payoutHoldDays,
    final Map<String, dynamic>? taxExemption,
  }) : _roles = roles,
       _taxExemption = taxExemption,
       super._();

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String uid;
  @override
  final String email;
  @override
  final String name;
  final List<UserRole> _roles;
  @override
  List<UserRole> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  final Address? address;
  @override
  final DateTime createdAt;
  // Stripe information
  @override
  final String? customerId;
  @override
  final String? lastCheckoutSession;
  @override
  final String? lastOrderId;
  @override
  final DateTime? lastCheckoutTimestamp;
  // Seller information (Stripe Connect)
  @override
  final String? stripeAccountId;
  @override
  @JsonKey()
  final bool payoutsEnabled;
  @override
  @JsonKey()
  final bool chargesEnabled;
  @override
  @JsonKey()
  final bool onboardingCompleted;
  // Account status
  @override
  @JsonKey()
  final bool suspended;
  @override
  final DateTime? suspendedAt;
  @override
  final DateTime? updatedAt;
  // === AUDIT FIX: 13 missing fields synced from Python/Firestore ===
  // Payment provider
  @override
  final String? paymentProvider;
  // Airwallex (alternative payment provider)
  @override
  final String? airwallexAccountId;
  @override
  final String? airwallexCustomerId;
  @override
  final String? airwallexStatus;
  // Suspension details
  @override
  final DateTime? unsuspendedAt;
  @override
  final String? suspendedBy;
  @override
  final String? suspensionReason;
  // Seller verification & commission
  @override
  final double? commissionRate;
  @override
  @JsonKey()
  final bool verified;
  @override
  final String? verificationStatus;
  @override
  final String? platform;
  @override
  final String? businessName;
  @override
  final int? payoutHoldDays;
  // Tax exemption for businesses
  final Map<String, dynamic>? _taxExemption;
  // Tax exemption for businesses
  @override
  Map<String, dynamic>? get taxExemption {
    final value = _taxExemption;
    if (value == null) return null;
    if (_taxExemption is EqualUnmodifiableMapView) return _taxExemption;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, name: $name, roles: $roles, address: $address, createdAt: $createdAt, customerId: $customerId, lastCheckoutSession: $lastCheckoutSession, lastOrderId: $lastOrderId, lastCheckoutTimestamp: $lastCheckoutTimestamp, stripeAccountId: $stripeAccountId, payoutsEnabled: $payoutsEnabled, chargesEnabled: $chargesEnabled, onboardingCompleted: $onboardingCompleted, suspended: $suspended, suspendedAt: $suspendedAt, updatedAt: $updatedAt, paymentProvider: $paymentProvider, airwallexAccountId: $airwallexAccountId, airwallexCustomerId: $airwallexCustomerId, airwallexStatus: $airwallexStatus, unsuspendedAt: $unsuspendedAt, suspendedBy: $suspendedBy, suspensionReason: $suspensionReason, commissionRate: $commissionRate, verified: $verified, verificationStatus: $verificationStatus, platform: $platform, businessName: $businessName, payoutHoldDays: $payoutHoldDays, taxExemption: $taxExemption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.lastCheckoutSession, lastCheckoutSession) ||
                other.lastCheckoutSession == lastCheckoutSession) &&
            (identical(other.lastOrderId, lastOrderId) ||
                other.lastOrderId == lastOrderId) &&
            (identical(other.lastCheckoutTimestamp, lastCheckoutTimestamp) ||
                other.lastCheckoutTimestamp == lastCheckoutTimestamp) &&
            (identical(other.stripeAccountId, stripeAccountId) ||
                other.stripeAccountId == stripeAccountId) &&
            (identical(other.payoutsEnabled, payoutsEnabled) ||
                other.payoutsEnabled == payoutsEnabled) &&
            (identical(other.chargesEnabled, chargesEnabled) ||
                other.chargesEnabled == chargesEnabled) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.suspended, suspended) ||
                other.suspended == suspended) &&
            (identical(other.suspendedAt, suspendedAt) ||
                other.suspendedAt == suspendedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.paymentProvider, paymentProvider) ||
                other.paymentProvider == paymentProvider) &&
            (identical(other.airwallexAccountId, airwallexAccountId) ||
                other.airwallexAccountId == airwallexAccountId) &&
            (identical(other.airwallexCustomerId, airwallexCustomerId) ||
                other.airwallexCustomerId == airwallexCustomerId) &&
            (identical(other.airwallexStatus, airwallexStatus) ||
                other.airwallexStatus == airwallexStatus) &&
            (identical(other.unsuspendedAt, unsuspendedAt) ||
                other.unsuspendedAt == unsuspendedAt) &&
            (identical(other.suspendedBy, suspendedBy) ||
                other.suspendedBy == suspendedBy) &&
            (identical(other.suspensionReason, suspensionReason) ||
                other.suspensionReason == suspensionReason) &&
            (identical(other.commissionRate, commissionRate) ||
                other.commissionRate == commissionRate) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.verificationStatus, verificationStatus) ||
                other.verificationStatus == verificationStatus) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.payoutHoldDays, payoutHoldDays) ||
                other.payoutHoldDays == payoutHoldDays) &&
            const DeepCollectionEquality().equals(
              other._taxExemption,
              _taxExemption,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    uid,
    email,
    name,
    const DeepCollectionEquality().hash(_roles),
    address,
    createdAt,
    customerId,
    lastCheckoutSession,
    lastOrderId,
    lastCheckoutTimestamp,
    stripeAccountId,
    payoutsEnabled,
    chargesEnabled,
    onboardingCompleted,
    suspended,
    suspendedAt,
    updatedAt,
    paymentProvider,
    airwallexAccountId,
    airwallexCustomerId,
    airwallexStatus,
    unsuspendedAt,
    suspendedBy,
    suspensionReason,
    commissionRate,
    verified,
    verificationStatus,
    platform,
    businessName,
    payoutHoldDays,
    const DeepCollectionEquality().hash(_taxExemption),
  ]);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User extends User {
  const factory _User({
    required final String uid,
    required final String email,
    required final String name,
    required final List<UserRole> roles,
    final Address? address,
    required final DateTime createdAt,
    final String? customerId,
    final String? lastCheckoutSession,
    final String? lastOrderId,
    final DateTime? lastCheckoutTimestamp,
    final String? stripeAccountId,
    final bool payoutsEnabled,
    final bool chargesEnabled,
    final bool onboardingCompleted,
    final bool suspended,
    final DateTime? suspendedAt,
    final DateTime? updatedAt,
    final String? paymentProvider,
    final String? airwallexAccountId,
    final String? airwallexCustomerId,
    final String? airwallexStatus,
    final DateTime? unsuspendedAt,
    final String? suspendedBy,
    final String? suspensionReason,
    final double? commissionRate,
    final bool verified,
    final String? verificationStatus,
    final String? platform,
    final String? businessName,
    final int? payoutHoldDays,
    final Map<String, dynamic>? taxExemption,
  }) = _$UserImpl;
  const _User._() : super._();

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get uid;
  @override
  String get email;
  @override
  String get name;
  @override
  List<UserRole> get roles;
  @override
  Address? get address;
  @override
  DateTime get createdAt; // Stripe information
  @override
  String? get customerId;
  @override
  String? get lastCheckoutSession;
  @override
  String? get lastOrderId;
  @override
  DateTime? get lastCheckoutTimestamp; // Seller information (Stripe Connect)
  @override
  String? get stripeAccountId;
  @override
  bool get payoutsEnabled;
  @override
  bool get chargesEnabled;
  @override
  bool get onboardingCompleted; // Account status
  @override
  bool get suspended;
  @override
  DateTime? get suspendedAt;
  @override
  DateTime? get updatedAt; // === AUDIT FIX: 13 missing fields synced from Python/Firestore ===
  // Payment provider
  @override
  String? get paymentProvider; // Airwallex (alternative payment provider)
  @override
  String? get airwallexAccountId;
  @override
  String? get airwallexCustomerId;
  @override
  String? get airwallexStatus; // Suspension details
  @override
  DateTime? get unsuspendedAt;
  @override
  String? get suspendedBy;
  @override
  String? get suspensionReason; // Seller verification & commission
  @override
  double? get commissionRate;
  @override
  bool get verified;
  @override
  String? get verificationStatus;
  @override
  String? get platform;
  @override
  String? get businessName;
  @override
  int? get payoutHoldDays; // Tax exemption for businesses
  @override
  Map<String, dynamic>? get taxExemption;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserCreate _$UserCreateFromJson(Map<String, dynamic> json) {
  return _UserCreate.fromJson(json);
}

/// @nodoc
mixin _$UserCreate {
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<UserRole> get roles => throw _privateConstructorUsedError;
  Address? get address => throw _privateConstructorUsedError;

  /// Serializes this UserCreate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCreateCopyWith<UserCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCreateCopyWith<$Res> {
  factory $UserCreateCopyWith(
    UserCreate value,
    $Res Function(UserCreate) then,
  ) = _$UserCreateCopyWithImpl<$Res, UserCreate>;
  @useResult
  $Res call({
    String email,
    String name,
    List<UserRole> roles,
    Address? address,
  });

  $AddressCopyWith<$Res>? get address;
}

/// @nodoc
class _$UserCreateCopyWithImpl<$Res, $Val extends UserCreate>
    implements $UserCreateCopyWith<$Res> {
  _$UserCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? name = null,
    Object? roles = null,
    Object? address = freezed,
  }) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<UserRole>,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as Address?,
          )
          as $Val,
    );
  }

  /// Create a copy of UserCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res>? get address {
    if (_value.address == null) {
      return null;
    }

    return $AddressCopyWith<$Res>(_value.address!, (value) {
      return _then(_value.copyWith(address: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserCreateImplCopyWith<$Res>
    implements $UserCreateCopyWith<$Res> {
  factory _$$UserCreateImplCopyWith(
    _$UserCreateImpl value,
    $Res Function(_$UserCreateImpl) then,
  ) = __$$UserCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String email,
    String name,
    List<UserRole> roles,
    Address? address,
  });

  @override
  $AddressCopyWith<$Res>? get address;
}

/// @nodoc
class __$$UserCreateImplCopyWithImpl<$Res>
    extends _$UserCreateCopyWithImpl<$Res, _$UserCreateImpl>
    implements _$$UserCreateImplCopyWith<$Res> {
  __$$UserCreateImplCopyWithImpl(
    _$UserCreateImpl _value,
    $Res Function(_$UserCreateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? name = null,
    Object? roles = null,
    Object? address = freezed,
  }) {
    return _then(
      _$UserCreateImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<UserRole>,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as Address?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserCreateImpl implements _UserCreate {
  const _$UserCreateImpl({
    required this.email,
    required this.name,
    final List<UserRole> roles = const [UserRole.buyer],
    this.address,
  }) : _roles = roles;

  factory _$UserCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserCreateImplFromJson(json);

  @override
  final String email;
  @override
  final String name;
  final List<UserRole> _roles;
  @override
  @JsonKey()
  List<UserRole> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  final Address? address;

  @override
  String toString() {
    return 'UserCreate(email: $email, name: $name, roles: $roles, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCreateImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            (identical(other.address, address) || other.address == address));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    email,
    name,
    const DeepCollectionEquality().hash(_roles),
    address,
  );

  /// Create a copy of UserCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCreateImplCopyWith<_$UserCreateImpl> get copyWith =>
      __$$UserCreateImplCopyWithImpl<_$UserCreateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserCreateImplToJson(this);
  }
}

abstract class _UserCreate implements UserCreate {
  const factory _UserCreate({
    required final String email,
    required final String name,
    final List<UserRole> roles,
    final Address? address,
  }) = _$UserCreateImpl;

  factory _UserCreate.fromJson(Map<String, dynamic> json) =
      _$UserCreateImpl.fromJson;

  @override
  String get email;
  @override
  String get name;
  @override
  List<UserRole> get roles;
  @override
  Address? get address;

  /// Create a copy of UserCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCreateImplCopyWith<_$UserCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
