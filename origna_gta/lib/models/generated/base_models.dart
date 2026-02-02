// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth

import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_models.freezed.dart';
part 'base_models.g.dart';

// ============================================================================
// ADDRESS MODELS
// ============================================================================

@freezed
class Address with _$Address {
  const factory Address({
    required String street,
    @Default('') String apartment,
    required String city,
    required String state,
    required String postalCode,
    @Default('Canada') String country,
    String? phoneNumber,
    @Default(false) bool isDefault,
    String? label,
    double? latitude,
    double? longitude,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);

  const Address._();

  /// Get formatted address with line breaks
  String get formattedAddress {
    final lines = [street, if (apartment.isNotEmpty) apartment, '$city, $state $postalCode', country];
    return lines.join('\n');
  }

  /// Get single-line address
  String get fullAddress {
    final parts = [street, if (apartment.isNotEmpty) apartment, city, state, postalCode, country];
    return parts.join(', ');
  }
}

@freezed
class AddressDetails with _$AddressDetails {
  const factory AddressDetails({
    required String street,
    required String city,
    required String province,
    required String postalCode,
    required double latitude,
    required double longitude,
  }) = _AddressDetails;

  factory AddressDetails.fromJson(Map<String, dynamic> json) => _$AddressDetailsFromJson(json);
}

enum DeliveryStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('shipped')
  shipped,
  @JsonValue('delivered')
  delivered,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('returned')
  returned,
}

// ============================================================================
// ENUMERATIONS
// ============================================================================

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('shipped')
  shipped,
  @JsonValue('delivered')
  delivered,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
}

enum PaymentStatus {
  @JsonValue('awaiting_payment')
  awaitingPayment,
  @JsonValue('payment_received')
  paymentReceived,
  @JsonValue('payment_failed')
  paymentFailed,
  @JsonValue('refunded')
  refunded,
  @JsonValue('partially_refunded')
  partiallyRefunded,
}

enum ShippingApprovalStatus {
  @JsonValue('not_required')
  notRequired,
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('seller')
  seller,
  @JsonValue('buyer')
  buyer,
}
