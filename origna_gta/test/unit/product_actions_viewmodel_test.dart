import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/products/product_actions_viewmodel.dart';

class _FakeProductRepo implements ProductRepository {
  Object? nextError;
  int deleteCalls = 0;

  @override
  Future<void> deleteProduct(String productId) async {
    deleteCalls++;
    if (nextError != null) throw nextError!;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeProductRepo fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeProductRepo();
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
  });

  group('ProductActionsViewModel', () {
    test('initial state is clean', () {
      final s = container.read(productActionsViewModelProvider);
      expect(s.isLoading, isFalse);
      expect(s.isSuccess, isFalse);
      expect(s.errorMessage, isNull);
    });

    test('deleteProduct returns true and sets isSuccess on success', () async {
      final result = await container.read(productActionsViewModelProvider.notifier).deleteProduct('prod_1');
      expect(result, isTrue);
      expect(container.read(productActionsViewModelProvider).isSuccess, isTrue);
      expect(fakeRepo.deleteCalls, 1);
    });

    test('deleteProduct returns false and sets errorMessage on failure', () async {
      fakeRepo.nextError = Exception('not found');
      final result = await container.read(productActionsViewModelProvider.notifier).deleteProduct('prod_2');
      expect(result, isFalse);
      expect(container.read(productActionsViewModelProvider).errorMessage, isNotNull);
    });

    test('deleteProduct returns false if already loading', () async {
      final notifier = container.read(productActionsViewModelProvider.notifier);
      notifier.state = notifier.state.copyWith(isLoading: true);
      final result = await notifier.deleteProduct('prod_3');
      expect(result, isFalse);
      expect(fakeRepo.deleteCalls, 0);
    });
  });
}
