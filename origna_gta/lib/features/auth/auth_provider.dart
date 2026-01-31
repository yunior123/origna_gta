import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// USER PROFILE PROVIDER
// ============================================================================

/// Stream of current user's profile data from repository
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(null);

  final repository = ref.watch(authRepositoryProvider);
  return repository.watchProfile(userId);
});
