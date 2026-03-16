import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/profile/address_management_viewmodel.dart';

class _FakeUserRepo implements UserRepository {
  Object? nextError;
  int deleteCalls = 0;
  int setDefaultCalls = 0;

  @override
  Future<void> deleteBuyerAddress(String addressId) async {
    deleteCalls++;
    if (nextError != null) throw nextError!;
  }

  @override
  Future<void> setDefaultBuyerAddress(String addressId) async {
    setDefaultCalls++;
    if (nextError != null) throw nextError!;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeUserRepo fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeUserRepo();
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
  });

  group('AddressManagementViewModel', () {
    test('initial state is AsyncData(null)', () {
      final state = container.read(addressManagementViewModelProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('deleteAddress succeeds', () async {
      await container.read(addressManagementViewModelProvider.notifier).deleteAddress('addr_1');
      expect(container.read(addressManagementViewModelProvider), isA<AsyncData<void>>());
      expect(fakeRepo.deleteCalls, 1);
    });

    test('deleteAddress sets AsyncError on failure', () async {
      fakeRepo.nextError = Exception('network error');
      await container.read(addressManagementViewModelProvider.notifier).deleteAddress('addr_1');
      expect(container.read(addressManagementViewModelProvider), isA<AsyncError<void>>());
    });

    test('setDefaultAddress succeeds', () async {
      await container.read(addressManagementViewModelProvider.notifier).setDefaultAddress('addr_1');
      expect(container.read(addressManagementViewModelProvider), isA<AsyncData<void>>());
      expect(fakeRepo.setDefaultCalls, 1);
    });

    test('setDefaultAddress sets AsyncError on failure', () async {
      fakeRepo.nextError = Exception('server error');
      await container.read(addressManagementViewModelProvider.notifier).setDefaultAddress('addr_2');
      expect(container.read(addressManagementViewModelProvider), isA<AsyncError<void>>());
    });
  });
}
