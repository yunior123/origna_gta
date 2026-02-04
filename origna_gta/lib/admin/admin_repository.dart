import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class AdminRepository {
  Future<void> deleteProduct(String productId);
  Future<void> disableAdminMfa();
  Future<Map<String, dynamic>> enableAdminMfa();
  Future<UserModel?> fetchUserById(String userId);
  Future<Map<String, dynamic>> getPaymentProviders();
  Future<void> setUserSuspended(String userId, bool suspended);
  Future<void> updatePaymentProvider(String provider, bool enabled, {String? reason});
  Future<void> updateProductStock(String productId, int quantity);
  Future<void> updateUserRoles(String userId, {List<String> add, List<String> remove, String? reason});
  Future<Map<String, dynamic>> verifyAdminMfa(String code);
  Stream<List<OrderModel>> watchOrders({String? status, int limit});
  Stream<List<ProductModel>> watchProducts({int limit, String? sellerId});
  Stream<List<UserModel>> watchSellers({int limit});
  Stream<List<UserModel>> watchUsers({int limit});
}

class FirebaseAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseAdminRepository(this._firestore, this._functions);

  @override
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'stockQuantity': 0,
      'keywords': [],
    });
  }

  @override
  Future<void> disableAdminMfa() async {
    await _functions.httpsCallable('admin_mfa_disable').call();
  }

  @override
  Future<Map<String, dynamic>> enableAdminMfa() async {
    final result = await _functions.httpsCallable('admin_mfa_enroll').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<UserModel?> fetchUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap({'uid': doc.id, ...doc.data()!});
  }

  @override
  Future<Map<String, dynamic>> getPaymentProviders() async {
    final result = await _functions.httpsCallable('get_payment_providers').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<void> setUserSuspended(String userId, bool suspended) async {
    if (suspended) {
      // EDGE CASE FIX #1: Call backend to handle active orders
      await _functions.httpsCallable('suspend_seller').call({'sellerId': userId, 'reason': 'Suspended by admin'});
    } else {
      // Unsuspend: just update Firestore
      await _firestore.collection('users').doc(userId).update({'suspended': false, 'unsuspendedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Future<void> updatePaymentProvider(String provider, bool enabled, {String? reason}) async {
    await _functions.httpsCallable('update_payment_provider').call({
      'provider': provider,
      'enabled': enabled,
      'reason': reason ?? '',
    });
  }

  @override
  Future<void> updateProductStock(String productId, int quantity) async {
    await _firestore.collection('products').doc(productId).update({'stockQuantity': quantity});
  }

  @override
  Future<void> updateUserRoles(String userId, {List<String> add = const [], List<String> remove = const [], String? reason}) async {
    // SECURITY FIX H-1: Call Cloud Function with server-side validation
    await _functions.httpsCallable('update_user_roles').call({'userId': userId, 'add': add, 'remove': remove, 'reason': reason ?? 'No reason provided'});
  }

  @override
  Future<Map<String, dynamic>> verifyAdminMfa(String code) async {
    final result = await _functions.httpsCallable('admin_mfa_verify').call({'code': code});
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Stream<List<OrderModel>> watchOrders({String? status, int limit = 50}) {
    Query query = _firestore.collection('orders').orderBy('createdAt', descending: true).limit(limit);
    if (status != null && status != 'all') {
      query = query.where('paymentStatus', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return OrderModel.fromMap({'orderId': doc.id, ...data});
      }).toList();
    });
  }

  @override
  Stream<List<ProductModel>> watchProducts({int limit = 100, String? sellerId}) {
    Query query = _firestore.collection('products');
    if (sellerId != null && sellerId.isNotEmpty) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }
    query = query.orderBy('dateCreated', descending: true).limit(limit);
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap({'productId': doc.id, ...data});
      }).toList();
    });
  }

  @override
  Stream<List<UserModel>> watchSellers({int limit = 100}) {
    return _firestore.collection('users').where('roles', arrayContains: UserRoles.seller).orderBy('createdAt', descending: true).limit(limit).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => UserModel.fromMap({'uid': doc.id, ...doc.data()})).toList();
    });
  }

  @override
  Stream<List<UserModel>> watchUsers({int limit = 100}) {
    return _firestore.collection('users').orderBy('createdAt', descending: true).limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap({'uid': doc.id, ...doc.data()})).toList();
    });
  }
}
