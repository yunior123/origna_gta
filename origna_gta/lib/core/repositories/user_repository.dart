import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class UserRepository {
  Future<void> updateAddress(String userId, Address address);
  Future<UserModel?> getUserProfile(String userId);
  Future<SellerAccountStatus> getSellerAccountStatus(String userId);
}

class SellerAccountStatus {
  final bool isSeller;
  final bool chargesEnabled;

  const SellerAccountStatus({required this.isSeller, required this.chargesEnabled});

  bool get isComplete => isSeller && chargesEnabled;
}

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository(this._firestore);

  @override
  Future<void> updateAddress(String userId, Address address) async {
    await _firestore.collection('users').doc(userId).update({'address': address.toMap()});
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  @override
  Future<SellerAccountStatus> getSellerAccountStatus(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    final isSeller = data?['isSeller'] == true;
    final chargesEnabled = data?['stripeChargesEnabled'] == true;
    return SellerAccountStatus(isSeller: isSeller, chargesEnabled: chargesEnabled);
  }
}
