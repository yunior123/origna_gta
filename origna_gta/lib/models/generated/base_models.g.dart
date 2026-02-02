// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddressImpl _$$AddressImplFromJson(Map<String, dynamic> json) =>
    _$AddressImpl(
      street: json['street'] as String,
      apartment: json['apartment'] as String? ?? '',
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String? ?? 'Canada',
      phoneNumber: json['phoneNumber'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      label: json['label'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$AddressImplToJson(_$AddressImpl instance) =>
    <String, dynamic>{
      'street': instance.street,
      'apartment': instance.apartment,
      'city': instance.city,
      'state': instance.state,
      'postalCode': instance.postalCode,
      'country': instance.country,
      'phoneNumber': instance.phoneNumber,
      'isDefault': instance.isDefault,
      'label': instance.label,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_$AddressDetailsImpl _$$AddressDetailsImplFromJson(Map<String, dynamic> json) =>
    _$AddressDetailsImpl(
      street: json['street'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      postalCode: json['postalCode'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$AddressDetailsImplToJson(
  _$AddressDetailsImpl instance,
) => <String, dynamic>{
  'street': instance.street,
  'city': instance.city,
  'province': instance.province,
  'postalCode': instance.postalCode,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
