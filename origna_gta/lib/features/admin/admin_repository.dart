// coverage:ignore-file
import 'package:origna_gta/utils/utils.dart';

abstract class AdminRepository {
  Future<void> approveProduct(String productId);
  Future<void> deleteProduct(String productId);
  Future<void> deleteReview(String reviewId);
  Future<void> disableAdminMfa(String code);
  Future<Map<String, dynamic>> enableAdminMfa();
  Future<UserModel?> fetchUserById(String userId);
  Future<Map<String, dynamic>> getPaymentProviders();
  Future<void> flagReview(String reviewId, {required bool flagged});
  Future<void> refundOrder(String orderId, {String reason = 'Admin refund'});
  Future<void> rejectProduct(String productId, String reason);
  Future<void> setUserSuspended(String userId, bool suspended);
  Future<void> updatePaymentProvider(String provider, bool enabled, {String? reason});
  Future<void> updateProductStock(String productId, int quantity);
  Future<void> updateUserRoles(String userId, {List<String> add, List<String> remove, String? reason});
  Future<Map<String, dynamic>> verifyAdminMfa(String code);
  Stream<List<OrderModel>> watchOrders({String? status, int limit});
  Stream<List<ProductModel>> watchProducts({int limit, String? sellerId});
  Stream<List<ProductModel>> watchPendingReviewProducts({int limit});
  Stream<List<Map<String, dynamic>>> watchReviews({bool flaggedOnly, bool hasPhotosOnly, int limit});
  Stream<List<UserModel>> watchSellers({int limit});
  Stream<List<UserModel>> watchUsers({int limit});
}
