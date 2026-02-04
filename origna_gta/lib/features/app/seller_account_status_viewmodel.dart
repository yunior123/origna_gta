import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';

/// Main provider - reads ONLY from Firestore (cached data), NO backend call
/// Use [refreshSellerStatusProvider] to manually sync with Stripe
final sellerAccountStatusProvider = FutureProvider.autoDispose<SellerAccountStatus>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Please log in to continue');
  }

  // Read from Firestore only - no backend call to avoid excessive API calls
  debugPrint('📊 Reading seller status from Firestore cache for ${user.uid}');
  return ref.read(userRepositoryProvider).getSellerAccountStatus(user.uid);
});

/// Manual refresh provider - calls backend to sync Stripe status with Firestore
/// Use this ONLY when user explicitly requests a status check (e.g., "Check Status" button)
final refreshSellerStatusProvider = FutureProvider.family.autoDispose<SellerAccountStatus, void>((ref, _) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Please log in to continue');
  }

  debugPrint('🔄 Manually syncing seller status from Stripe backend...');
  
  try {
    final functions = ref.read(firebaseFunctionsProvider);
    final callable = functions.httpsCallable('get_connect_account_status');
    final result = await callable.call();
    final data = result.data as Map<String, dynamic>;
    
    final chargesEnabled = data['chargesEnabled'] == true;
    final payoutsEnabled = data['payoutsEnabled'] == true;
    final detailsSubmitted = data['detailsSubmitted'] == true;
    final requirementsDue = (data['requirementsCurrentlyDue'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    
    debugPrint('📊 Stripe Status - charges: $chargesEnabled, payouts: $payoutsEnabled, detailsSubmitted: $detailsSubmitted, requirements: $requirementsDue');
    
    // Invalidate main provider so it refetches from Firestore (now updated by backend)
    ref.invalidate(sellerAccountStatusProvider);
    
    return SellerAccountStatus(
      isSeller: true,
      chargesEnabled: chargesEnabled && payoutsEnabled,
      detailsSubmitted: detailsSubmitted,
      hasPendingRequirements: requirementsDue.isNotEmpty,
      pendingRequirements: requirementsDue,
    );
  } catch (e) {
    debugPrint('❌ Error syncing status from backend: $e');
    rethrow;
  }
});
