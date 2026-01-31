import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

final adminOrdersProvider = StreamProvider.autoDispose.family<List<OrderModel>, String>((ref, status) {
  return ref.watch(adminRepositoryProvider).watchOrders(status: status);
});

final adminProductsProvider = StreamProvider.autoDispose.family<List<ProductModel>, String?>((ref, sellerId) {
  return ref.watch(adminRepositoryProvider).watchProducts(sellerId: sellerId);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirebaseAdminRepository(ref.watch(firestoreProvider));
});

final adminSellersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchSellers();
});

final adminUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchUsers();
});
