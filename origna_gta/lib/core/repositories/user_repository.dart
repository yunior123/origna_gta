import 'package:origna_gta/utils/utils.dart';

/// Stripe Connect seller account verification status.
///
/// Combines Stripe account state with OrignaBase seller profile to determine
/// whether a user can list and sell products on the marketplace.
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

/// Contract for user profile and address management.
///
/// Implementations: [OrignaBaseUserRepository] (production).
///
/// Manages user profiles, address book (multi-address with default selection),
/// notification preferences, language settings, and seller account status.
abstract class UserRepository {
  /// Adds an address to the user's address book. Returns the new address ID.
  /// If [Address.isDefault] is true, clears the default flag on other addresses.
  Future<String> addBuyerAddress(Address address);

  /// Deletes an address from the user's address book by ID.
  Future<void> deleteBuyerAddress(String addressId);

  /// Fetches the seller's Stripe Connect account status (one-time read).
  Future<SellerAccountStatus> getSellerAccountStatus(String userId);

  /// Fetches the user profile from the `users` collection. Returns null if not found.
  Future<UserModel?> getUserProfile(String userId);

  /// Records the user's acceptance of the current Terms of Service version.
  /// Updates `termsAcceptedAt` and `termsVersion` on the user document.
  Future<void> recordTermsAcceptance();

  /// Sets [addressId] as the default address, clearing the flag on all others.
  Future<void> setDefaultBuyerAddress(String addressId);

  /// Updates an existing address in the user's address book.
  Future<void> updateBuyerAddress(String addressId, Address address);

  /// Updates notification preferences (new products, trending alerts).
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? notifyNewProducts,
    bool? notifyTrending,
  });

  /// Updates the user's preferred language ('en' or 'fr').
  Future<void> updatePreferredLanguage(String userId, String lang);

  /// Real-time stream of the user's address book, sorted by creation date.
  Stream<List<Address>> watchAddresses(
    String userId, {
    int limit = 50,
    int offset = 0,
  });

  /// Polls the seller account status every 5 seconds. Combines OrignaBase
  /// seller profile with Stripe Connect status.
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId);
}
