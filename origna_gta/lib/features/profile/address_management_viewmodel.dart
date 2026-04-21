import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';

/// Riverpod provider for [AddressManagementViewModel].
///
/// Auto-disposed — fresh state per address book session.
final addressManagementViewModelProvider =
    StateNotifierProvider.autoDispose<
      AddressManagementViewModel,
      AsyncValue<void>
    >((ref) {
      return AddressManagementViewModel(ref);
    });

/// Manages the address book: delete and set default address.
///
/// Uses [AsyncValue<void>] as state — loading/error/data pattern for
/// mutation feedback. The address list itself is read from [userAddressesProvider],
/// not managed here.
///
/// See also:
/// - [AddressViewModel] for single-address form logic
class AddressManagementViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  AddressManagementViewModel(this.ref) : super(const AsyncValue.data(null));

  /// Deletes an address by [addressId] from the buyer's address book.
  ///
  /// Sets state to loading during the operation, data on success, or error on failure.
  Future<void> deleteAddress(String addressId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(userRepositoryProvider).deleteBuyerAddress(addressId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sets the address identified by [addressId] as the buyer's default.
  ///
  /// Sets state to loading during the operation, data on success, or error on failure.
  Future<void> setDefaultAddress(String addressId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(userRepositoryProvider).setDefaultBuyerAddress(addressId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
