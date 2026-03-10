// coverage:ignore-file
// Migrated: delegates to OrignaBase for seller account status.
// Screens continue using sellerAccountStatusProvider, refreshSellerStatusProvider.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart' show userRepositoryProvider;
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Main provider - watches user repository in realtime for seller status updates.
final sellerAccountStatusProvider = StreamProvider.autoDispose<SellerAccountStatus>((ref) {
  final uid = ref.watch(obUserIdProvider);
  if (uid == null) {
    return Stream.error(Exception('Please log in to continue'));
  }

  return ref.read(userRepositoryProvider).watchSellerAccountStatus(uid);
});

/// Manual refresh provider - calls OrignaBase backend to sync Stripe status.
final refreshSellerStatusProvider = FutureProvider.family.autoDispose<SellerAccountStatus, void>((ref, _) async {
  final uid = ref.read(obUserIdProvider);
  if (uid == null) {
    throw Exception('Please log in to continue');
  }

  try {
    final ob = ref.read(orignabaseProvider);
    final result = await ob.request('POST', '/api/connect/status', body: {'userId': uid});
    final data = Map<String, dynamic>.from(result as Map);

    final chargesEnabled = data[Fields.chargesEnabled] == true;
    final payoutsEnabled = data[Fields.payoutsEnabled] == true;
    final detailsSubmitted = data[ApiKeys.detailsSubmitted] == true;
    final requirementsDue = data[ApiKeys.requirementsCurrentlyDue] is List
        ? (data[ApiKeys.requirementsCurrentlyDue] as List<dynamic>).map((e) => e.toString()).toList()
        : <String>[];

    if (kDebugMode) {
      debugPrint('Stripe Status - charges: $chargesEnabled, payouts: $payoutsEnabled');
    }

    return SellerAccountStatus(
      isSeller: true,
      chargesEnabled: chargesEnabled && payoutsEnabled,
      detailsSubmitted: detailsSubmitted,
      hasPendingRequirements: requirementsDue.isNotEmpty,
      pendingRequirements: requirementsDue,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error syncing status from backend: $e');
    }
    rethrow;
  }
});
