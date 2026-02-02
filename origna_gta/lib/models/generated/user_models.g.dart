// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  uid: json['uid'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  roles: (json['roles'] as List<dynamic>)
      .map((e) => $enumDecode(_$UserRoleEnumMap, e))
      .toList(),
  address: json['address'] == null
      ? null
      : Address.fromJson(json['address'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  customerId: json['customerId'] as String?,
  lastCheckoutSession: json['lastCheckoutSession'] as String?,
  lastOrderId: json['lastOrderId'] as String?,
  lastCheckoutTimestamp: json['lastCheckoutTimestamp'] == null
      ? null
      : DateTime.parse(json['lastCheckoutTimestamp'] as String),
  stripeAccountId: json['stripeAccountId'] as String?,
  payoutsEnabled: json['payoutsEnabled'] as bool? ?? false,
  chargesEnabled: json['chargesEnabled'] as bool? ?? false,
  onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
  suspended: json['suspended'] as bool? ?? false,
  suspendedAt: json['suspendedAt'] == null
      ? null
      : DateTime.parse(json['suspendedAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$UserImplToJson(
  _$UserImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'name': instance.name,
  'roles': instance.roles.map((e) => _$UserRoleEnumMap[e]!).toList(),
  'address': instance.address,
  'createdAt': instance.createdAt.toIso8601String(),
  'customerId': instance.customerId,
  'lastCheckoutSession': instance.lastCheckoutSession,
  'lastOrderId': instance.lastOrderId,
  'lastCheckoutTimestamp': instance.lastCheckoutTimestamp?.toIso8601String(),
  'stripeAccountId': instance.stripeAccountId,
  'payoutsEnabled': instance.payoutsEnabled,
  'chargesEnabled': instance.chargesEnabled,
  'onboardingCompleted': instance.onboardingCompleted,
  'suspended': instance.suspended,
  'suspendedAt': instance.suspendedAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.seller: 'seller',
  UserRole.buyer: 'buyer',
};

_$UserCreateImpl _$$UserCreateImplFromJson(Map<String, dynamic> json) =>
    _$UserCreateImpl(
      email: json['email'] as String,
      name: json['name'] as String,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$UserRoleEnumMap, e))
              .toList() ??
          const [UserRole.buyer],
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserCreateImplToJson(_$UserCreateImpl instance) =>
    <String, dynamic>{
      'email': instance.email,
      'name': instance.name,
      'roles': instance.roles.map((e) => _$UserRoleEnumMap[e]!).toList(),
      'address': instance.address,
    };
