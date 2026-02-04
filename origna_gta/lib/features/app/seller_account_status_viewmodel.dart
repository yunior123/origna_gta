import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';

final sellerAccountStatusProvider = FutureProvider.autoDispose<SellerAccountStatus>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Please log in to continue');
  }

  // First, call backend to sync latest status from Stripe
  try {
    final functions = ref.read(firebaseFunctionsProvider);
    final callable = functions.httpsCallable('get_connect_account_status');
    final result = await callable.call();
    final data = result.data as Map<String, dynamic>;
    
    // Return status directly from backend response
    // Both chargesEnabled AND payoutsEnabled must be true to be complete
    return SellerAccountStatus(
      isSeller: true, // If we got here, user has a Stripe account
      chargesEnabled: data['chargesEnabled'] == true && data['payoutsEnabled'] == true,
    );
  } catch (e) {
    debugPrint('Error fetching status from backend: $e');
    // Fallback to reading from Firestore if backend call fails
    return ref.read(userRepositoryProvider).getSellerAccountStatus(user.uid);
  }
});
