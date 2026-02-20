// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth
// ignore_for_file: non_abstract_class_inherits_abstract_member

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';
import '../../core/schema/schema_constants.dart';

part 'user_models.freezed.dart';
part 'user_models.g.dart';

/// Safely parse a dynamic value (Timestamp, String, DateTime) to DateTime?
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
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
    // Stripe information
    String? customerId,
    String? lastCheckoutSession,
    String? lastOrderId,
    DateTime? lastCheckoutTimestamp,
    // Seller information (Stripe Connect)
    String? stripeAccountId,
    @Default(false) bool payoutsEnabled,
    @Default(false) bool chargesEnabled,
    @Default(false) bool onboardingCompleted,
    // Account status
    @Default(false) bool suspended,
    DateTime? suspendedAt,
    DateTime? updatedAt,
    // === AUDIT FIX: 13 missing fields synced from Python/Firestore ===
    // Payment provider
    String? paymentProvider,
    // Airwallex (alternative payment provider)
    String? airwallexAccountId,
    String? airwallexCustomerId,
    String? airwallexStatus,
    // Suspension details
    DateTime? unsuspendedAt,
    String? suspendedBy,
    String? suspensionReason,
    // Seller verification & commission
    double? commissionRate,
    @Default(false) bool verified,
    String? verificationStatus,
    String? platform,
    String? businessName,
    int? payoutHoldDays,
    // Tax exemption for businesses
    Map<String, dynamic>? taxExemption,
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
  }) = _User;

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse roles
    final rolesData = data[Fields.roles] as List<dynamic>? ?? ['buyer'];
    final roles = rolesData.map((r) => UserRole.values.firstWhere((e) => e.name == r.toString(), orElse: () => UserRole.buyer)).toList();

    return User(
      uid: data[Fields.uid] ?? doc.id,
      email: data[Fields.email] ?? '',
      name: data[Fields.name] ?? '',
      roles: roles,
      address: data[Fields.address] != null ? Address.fromJson(data[Fields.address] as Map<String, dynamic>) : null,
      createdAt: _parseDateTime(data[Fields.createdAt]) ?? DateTime.now(),
      customerId: data[Fields.customerId],
      lastCheckoutSession: data[Fields.lastCheckoutSession],
      lastOrderId: data[Fields.lastOrderId],
      lastCheckoutTimestamp: _parseDateTime(data[Fields.lastCheckoutTimestamp]),
      stripeAccountId: data[Fields.stripeAccountId],
      payoutsEnabled: data[Fields.payoutsEnabled] ?? false,
      chargesEnabled: data[Fields.chargesEnabled] ?? false,
      onboardingCompleted: data[Fields.onboardingCompleted] ?? false,
      suspended: data[Fields.suspended] ?? false,
      suspendedAt: _parseDateTime(data[Fields.suspendedAt]),
      updatedAt: _parseDateTime(data[Fields.updatedAt]),
      // === AUDIT FIX: Parse 13 missing fields ===
      paymentProvider: data[Fields.paymentProvider] as String?,
      airwallexAccountId: data[Fields.airwallexAccountId] as String?,
      airwallexCustomerId: data[Fields.airwallexCustomerId] as String?,
      airwallexStatus: data[Fields.airwallexStatus] as String?,
      unsuspendedAt: _parseDateTime(data[Fields.unsuspendedAt]),
      suspendedBy: data[Fields.suspendedBy] as String?,
      suspensionReason: data[Fields.suspensionReason] as String?,
      commissionRate: data[Fields.commissionRate] != null ? (data[Fields.commissionRate] as num).toDouble() : null,
      verified: data[Fields.verified] ?? false,
      verificationStatus: data[Fields.verificationStatus] as String?,
      platform: data[Fields.platform] as String?,
      businessName: data[Fields.businessName] as String?,
      payoutHoldDays: data[Fields.payoutHoldDays] != null ? (data[Fields.payoutHoldDays] as num).toInt() : null,
      taxExemption: data[Fields.taxExemption] != null ? _safeMap(data[Fields.taxExemption]) : null,
      // === CONSENT & COMPLIANCE ===
      emailConsent: data[Fields.emailConsent] ?? true,
      marketingOptIn: data[Fields.marketingOptIn] ?? false,
      consentTimestamp: _parseDateTime(data[Fields.consentTimestamp]),
      consentMethod: data[Fields.consentMethod] as String?,
      privacyAcceptedAt: _parseDateTime(data[Fields.privacyAcceptedAt]),
      termsAcceptedAt: _parseDateTime(data[Fields.termsAcceptedAt]),
      privacyPolicyVersion: data[Fields.privacyPolicyVersion] as String?,
      termsVersion: data[Fields.termsVersion] as String?,
      preferredLanguage: data[Fields.preferredLanguage] as String? ?? 'en',
      unsubscribedAt: _parseDateTime(data[Fields.unsubscribedAt]),
      dataProcessingConsent: data[Fields.dataProcessingConsent] ?? false,
      // === PREMIUM SUBSCRIPTION ===
      isPremium: data[Fields.isPremium] ?? false,
      premiumSince: _parseDateTime(data[Fields.premiumSince]),
      premiumExpiresAt: _parseDateTime(data[Fields.premiumExpiresAt]),
      stripeSubscriptionId: data[Fields.stripeSubscriptionId] as String?,
      notifyNewProducts: data[Fields.notifyNewProducts] ?? false,
      notifyTrending: data[Fields.notifyTrending] ?? false,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  const User._();

  /// Check if user can sell products (seller/admin + onboarding + payouts/charges enabled)
  bool get canSell => (isAdmin || isSeller) && onboardingCompleted && chargesEnabled && payoutsEnabled && !suspended;

  /// Check if user has admin role
  bool get isAdmin => roles.contains(UserRole.admin);

  /// Check if user has seller role
  bool get isSeller => roles.contains(UserRole.seller);
}

// ============================================================================
// USER CREATE MODEL
// ============================================================================

@freezed
abstract class UserCreate with _$UserCreate {
  const factory UserCreate({required String email, required String name, @Default([UserRole.buyer]) List<UserRole> roles, Address? address}) = _UserCreate;

  factory UserCreate.fromJson(Map<String, dynamic> json) => _$UserCreateFromJson(json);
}
