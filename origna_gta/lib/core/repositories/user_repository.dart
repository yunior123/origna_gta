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
    return SellerAccountStatus(isSeller: isSeller, chargesEnabled: chargesEnabled);
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

  const SellerAccountStatus({required this.isSeller, required this.chargesEnabled});

  bool get isComplete => isSeller && chargesEnabled;
}

abstract class UserRepository {
  Future<SellerAccountStatus> getSellerAccountStatus(String userId);
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateAddress(String userId, Address address);
}
