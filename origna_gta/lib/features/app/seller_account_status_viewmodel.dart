import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';

final sellerAccountStatusProvider = FutureProvider.autoDispose<SellerAccountStatus>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Please log in to continue');
  }

  return ref.watch(userRepositoryProvider).getSellerAccountStatus(user.uid);
});
