import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository(this._firestore);

  @override
  Future<SellerAccountStatus> getSellerAccountStatus(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    final roles = List<String>.from(data?['roles'] ?? const []);
    final isSeller = roles.contains(UserRoles.seller) || roles.contains(UserRoles.admin);
    final chargesEnabled = data?['chargesEnabled'] == true;
    final payoutsEnabled = data?['payoutsEnabled'] == true;
    final onboardingCompleted = data?['onboardingCompleted'] == true;
    return SellerAccountStatus(
      isSeller: isSeller, 
      chargesEnabled: chargesEnabled && payoutsEnabled,
      detailsSubmitted: onboardingCompleted,
    );
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateAddress(String userId, Address address) async {
    await _firestore.collection('users').doc(userId).update({'address': address.toMap()});
  }
}

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
  
  /// User has submitted all info and documents, waiting for Stripe review
  bool get isPendingVerification => isSeller && detailsSubmitted && !chargesEnabled && !hasPendingRequirements;
  
  /// User has started but there are still requirements to complete
  bool get isIncomplete => isSeller && (!detailsSubmitted || hasPendingRequirements);
  
  /// Check if identity documents are required
  bool get needsIdentityDocuments => pendingRequirements.any((r) => 
    r.contains('verification') || 
    r.contains('document') || 
    r.contains('individual.id_number') ||
    r.contains('individual.verification'));
  
  /// Get a human-readable description of what's missing
  String get pendingRequirementsDescription {
    if (pendingRequirements.isEmpty) return '';
    
    final descriptions = <String>[];
    for (final req in pendingRequirements) {
      if (req.contains('verification.document')) {
        descriptions.add('Identity document (ID, passport, or driver\'s license)');
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
  Future<SellerAccountStatus> getSellerAccountStatus(String userId);
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateAddress(String userId, Address address);
}
