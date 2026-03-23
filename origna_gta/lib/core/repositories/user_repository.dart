import 'package:origna_gta/utils/utils.dart';

/// Documentation for SellerAccountStatus
class SellerAccountStatus {
  final bool isSeller;
  final bool chargesEnabled;
  final bool detailsSubmitted;
  final bool hasPendingRequirements;
  final List<String> pendingRequirements;

  const SellerAccountStatus({
    required this.isSeller,
    required this.chargesEnabled,
    this.detailsSubmitted = false,
    this.hasPendingRequirements = false,
    this.pendingRequirements = const [],
  });

  /// Account is fully verified and can sell products
  bool get isComplete => isSeller && chargesEnabled;

  /// User has started but there are still requirements to complete
  bool get isIncomplete =>
      isSeller && (!detailsSubmitted || hasPendingRequirements);

  /// User has submitted all info and documents, waiting for Stripe review
  bool get isPendingVerification =>
      isSeller &&
      detailsSubmitted &&
      !chargesEnabled &&
      !hasPendingRequirements;

  /// Check if identity documents are required
  bool get needsIdentityDocuments => pendingRequirements.any(
    (r) =>
        r.contains('verification') ||
        r.contains('document') ||
        r.contains('individual.id_number') ||
        r.contains('individual.verification'),
  );

  /// Get a human-readable description of what's missing
  String get pendingRequirementsDescription {
    if (pendingRequirements.isEmpty) return '';

    final descriptions = <String>[];
    for (final req in pendingRequirements) {
      if (req.contains('verification.document')) {
        descriptions.add(
          'Identity document (ID, passport, or driver\'s license)',
        );
      } else if (req.contains('individual.id_number')) {
        descriptions.add('Social Insurance Number (SIN)');
      } else if (req.contains('external_account')) {
        descriptions.add('Bank account for payouts');
      } else if (req.contains('business_profile')) {
        descriptions.add('Business information');
      } else if (req.contains('tos_acceptance')) {
        descriptions.add('Terms of Service acceptance');
      } else if (!descriptions.contains(req)) {
        // Add other requirements as-is but formatted
        descriptions.add(req.replaceAll('.', ' ').replaceAll('_', ' '));
      }
    }
    return descriptions.toSet().join('\n• ');
  }
}

abstract class UserRepository {
  Future<String> addBuyerAddress(Address address);
  Future<void> deleteBuyerAddress(String addressId);
  Future<SellerAccountStatus> getSellerAccountStatus(String userId);
  Future<UserModel?> getUserProfile(String userId);
  Future<void> recordTermsAcceptance();
  Future<void> setDefaultBuyerAddress(String addressId);
  Future<void> updateBuyerAddress(String addressId, Address address);
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? notifyNewProducts,
    bool? notifyTrending,
  });
  Future<void> updatePreferredLanguage(String userId, String lang);
  // Address Book
  Stream<List<Address>> watchAddresses(
    String userId, {
    int limit = 50,
    int offset = 0,
  });
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId);
}
