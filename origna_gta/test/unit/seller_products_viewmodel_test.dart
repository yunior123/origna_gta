import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/seller/seller_products_viewmodel.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>()])
import 'seller_products_viewmodel_test.mocks.dart';

void main() {
  late MockOrignaBase mockOrignaBase;
  late ProviderContainer container;

  setUp(() {
    mockOrignaBase = MockOrignaBase();

    container = ProviderContainer(
      overrides: [orignabaseProvider.overrideWithValue(mockOrignaBase)],
    );
  });

  group('SellerProductsViewModel Tests', () {
    test('initial state is empty', () {
      final state = container.read(sellerProductsViewModelProvider);
      expect(state.selectedIds, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('toggleSelection adds and removes ids', () {
      final notifier = container.read(sellerProductsViewModelProvider.notifier);

      notifier.toggleSelection('p1');
      expect(container.read(sellerProductsViewModelProvider).selectedIds, {
        'p1',
      });

      notifier.toggleSelection('p2');
      expect(container.read(sellerProductsViewModelProvider).selectedIds, {
        'p1',
        'p2',
      });

      notifier.toggleSelection('p1');
      expect(container.read(sellerProductsViewModelProvider).selectedIds, {
        'p2',
      });
    });

    test('bulkAction calls OrignaBase and clears selection', () async {
      final notifier = container.read(sellerProductsViewModelProvider.notifier);
      notifier.toggleSelection('p1');

      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {'updated': 1, 'skipped': 0});

      await notifier.bulkAction('archive');

      final state = container.read(sellerProductsViewModelProvider);
      expect(state.selectedIds, isEmpty);
      expect(state.successMessage, contains('bulk_products_updated'));
    });
  });
}
