// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth
// ignore_for_file: non_abstract_class_inherits_abstract_member

import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';
import '../../core/schema/schema_constants.dart';

part 'user_models.freezed.dart';
part 'user_models.g.dart';

/// Safely parse a dynamic value (String, DateTime, int) to DateTime?
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

/// Safely convert dynamic value to `Map<String, dynamic>`
Map<String, dynamic> _safeMap(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

// ============================================================================
// USER MODEL
// ============================================================================

@freezed
abstract class User with _$User {
  const factory User({
    required String uid,
    required String email,
    required String name,
    required List<UserRole> roles,
    Address? address,
    required DateTime createdAt,
    // Stripe buyer information
    String? customerId,
    String? lastCheckoutSession,
    String? lastOrderId,
    DateTime? lastCheckoutTimestamp,
    // Seller flag (details in seller_profiles/{uid})
    @Default(false) bool isSeller,
    // Account status
    @Default(false) bool suspended,
    DateTime? suspendedAt,
    DateTime? updatedAt,
    // Payment provider
    String? paymentProvider,
    // Suspension details
    DateTime? unsuspendedAt,
    String? suspendedBy,
    String? suspensionReason,
    // Tax exemption for businesses
    Map<String, dynamic>? taxExemption,
    // MFA status (secrets live in user_security — backend only)
    @Default(false) bool mfaEnabled,
    DateTime? mfaEnrolledAt,
    DateTime? lastMfaVerify,
    // === CONSENT & COMPLIANCE (CASL + PIPEDA + Quebec Law 25) ===
    @Default(true) bool emailConsent,
    @Default(false) bool marketingOptIn,
    DateTime? consentTimestamp,
    String? consentMethod,
    DateTime? privacyAcceptedAt,
    DateTime? termsAcceptedAt,
    String? privacyPolicyVersion,
    String? termsVersion,
    @Default('en') String preferredLanguage,
    DateTime? unsubscribedAt,
    @Default(false) bool dataProcessingConsent,
    // === PREMIUM SUBSCRIPTION ===
    @Default(false) bool isPremium,
    DateTime? premiumSince,
    DateTime? premiumExpiresAt,
    String? stripeSubscriptionId,
    @Default(false) bool notifyNewProducts,
    @Default(false) bool notifyTrending,
    @Default(true) bool pushEnabled,
    // === FCM (push notifications) ===
    String? fcmToken,
    DateTime? fcmTokenUpdatedAt,
  }) = _User;

  factory User.fromMap(Map<String, dynamic> data, String docId) {

    // Parse roles
    final rolesData = data[Fields.roles] as List<dynamic>? ?? [UserRoleValues.buyer];
    final roles = rolesData.map((r) => UserRole.values.firstWhere((e) => e.name == r.toString(), orElse: () => UserRole.buyer)).toList();

    return User(
      uid: (data[Fields.uid] as String?) ?? docId,
      email: (data[Fields.email] as String?) ?? '',
      name: (data[Fields.name] as String?) ?? '',
      roles: roles,
      address: data[Fields.address] != null ? Address.fromJson(data[Fields.address] as Map<String, dynamic>) : null,
      createdAt: _parseDateTime(data[Fields.createdAt]) ?? DateTime.now(),
      customerId: data[Fields.customerId] as String?,
      lastCheckoutSession: data[Fields.lastCheckoutSession] as String?,
      lastOrderId: data[Fields.lastOrderId] as String?,
      lastCheckoutTimestamp: _parseDateTime(data[Fields.lastCheckoutTimestamp]),
      isSeller: (data[Fields.roles] as List<dynamic>? ?? []).contains(UserRoleValues.seller),
      suspended: (data[Fields.suspended] as bool?) ?? false,
      suspendedAt: _parseDateTime(data[Fields.suspendedAt]),
      updatedAt: _parseDateTime(data[Fields.updatedAt]),
      paymentProvider: data[Fields.paymentProvider] as String?,
      unsuspendedAt: _parseDateTime(data[Fields.unsuspendedAt]),
      suspendedBy: data[Fields.suspendedBy] as String?,
      suspensionReason: data[Fields.suspensionReason] as String?,
      taxExemption: data[Fields.taxExemption] != null ? _safeMap(data[Fields.taxExemption]) : null,
      // MFA status (secrets live in user_security — backend only)
      mfaEnabled: (data[Fields.mfaEnabled] as bool?) ?? false,
      mfaEnrolledAt: _parseDateTime(data[Fields.mfaEnrolledAt]),
      lastMfaVerify: _parseDateTime(data[Fields.lastMfaVerify]),
      // === CONSENT & COMPLIANCE ===
      emailConsent: (data[Fields.emailConsent] as bool?) ?? true,
      marketingOptIn: (data[Fields.marketingOptIn] as bool?) ?? false,
      consentTimestamp: _parseDateTime(data[Fields.consentTimestamp]),
      consentMethod: data[Fields.consentMethod] as String?,
      privacyAcceptedAt: _parseDateTime(data[Fields.privacyAcceptedAt]),
      termsAcceptedAt: _parseDateTime(data[Fields.termsAcceptedAt]),
      privacyPolicyVersion: data[Fields.privacyPolicyVersion] as String?,
      termsVersion: data[Fields.termsVersion] as String?,
      preferredLanguage: data[Fields.preferredLanguage] as String? ?? LanguageValues.english,
      unsubscribedAt: _parseDateTime(data[Fields.unsubscribedAt]),
      dataProcessingConsent: (data[Fields.dataProcessingConsent] as bool?) ?? false,
      // === PREMIUM SUBSCRIPTION ===
      isPremium: (data[Fields.isPremium] as bool?) ?? false,
      premiumSince: _parseDateTime(data[Fields.premiumSince]),
      premiumExpiresAt: _parseDateTime(data[Fields.premiumExpiresAt]),
      stripeSubscriptionId: data[Fields.stripeSubscriptionId] as String?,
      notifyNewProducts: (data[Fields.notifyNewProducts] as bool?) ?? false,
      notifyTrending: (data[Fields.notifyTrending] as bool?) ?? false,
      pushEnabled: (data[Fields.pushEnabled] as bool?) ?? true,
      fcmToken: data[Fields.fcmToken] as String?,
      fcmTokenUpdatedAt: _parseDateTime(data[Fields.fcmTokenUpdatedAt]),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  const User._();

  /// Check if user can sell products (seller/admin + not suspended). Full check requires seller_profiles doc.
  bool get canSell => (isAdmin || isSeller) && !suspended;

  /// Check if user has admin role
  bool get isAdmin => roles.contains(UserRole.admin);
}

// ============================================================================
// USER CREATE MODEL
// ============================================================================

@freezed
abstract class UserCreate with _$UserCreate {
  const factory UserCreate({required String email, required String name, @Default([UserRole.buyer]) List<UserRole> roles, Address? address}) = _UserCreate;

  factory UserCreate.fromJson(Map<String, dynamic> json) => _$UserCreateFromJson(json);
}
