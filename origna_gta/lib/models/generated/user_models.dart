// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';

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

// ============================================================================
// USER MODEL
// ============================================================================

@freezed
class User with _$User {
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
  }) = _User;

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse roles
    final rolesData = data['roles'] as List<dynamic>? ?? ['buyer'];
    final roles = rolesData.map((r) => UserRole.values.firstWhere((e) => e.name == r.toString(), orElse: () => UserRole.buyer)).toList();

    return User(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      roles: roles,
      address: data['address'] != null ? Address.fromJson(data['address'] as Map<String, dynamic>) : null,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      customerId: data['customerId'],
      lastCheckoutSession: data['lastCheckoutSession'],
      lastOrderId: data['lastOrderId'],
      lastCheckoutTimestamp: _parseDateTime(data['lastCheckoutTimestamp']),
      stripeAccountId: data['stripeAccountId'],
      payoutsEnabled: data['payoutsEnabled'] ?? false,
      chargesEnabled: data['chargesEnabled'] ?? false,
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      suspended: data['suspended'] ?? false,
      suspendedAt: _parseDateTime(data['suspendedAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      // === AUDIT FIX: Parse 13 missing fields ===
      paymentProvider: data['paymentProvider'] as String?,
      airwallexAccountId: data['airwallexAccountId'] as String?,
      airwallexCustomerId: data['airwallexCustomerId'] as String?,
      airwallexStatus: data['airwallexStatus'] as String?,
      unsuspendedAt: _parseDateTime(data['unsuspendedAt']),
      suspendedBy: data['suspendedBy'] as String?,
      suspensionReason: data['suspensionReason'] as String?,
      commissionRate: data['commissionRate'] != null ? (data['commissionRate'] as num).toDouble() : null,
      verified: data['verified'] ?? false,
      verificationStatus: data['verificationStatus'] as String?,
      platform: data['platform'] as String?,
      businessName: data['businessName'] as String?,
      payoutHoldDays: data['payoutHoldDays'] != null ? (data['payoutHoldDays'] as num).toInt() : null,
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
class UserCreate with _$UserCreate {
  const factory UserCreate({required String email, required String name, @Default([UserRole.buyer]) List<UserRole> roles, Address? address}) = _UserCreate;

  factory UserCreate.fromJson(Map<String, dynamic> json) => _$UserCreateFromJson(json);
}
