import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/products/add_product_viewmodel.dart';
import 'package:origna_gta/features/products/add_product_state.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/models/generated/models.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'add_product_viewmodel_test.mocks.dart';

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  group('AddProductViewModel', () {
    test('validation fails on empty name', () async {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      await viewModel.addProduct(
        name: '',
        description: 'A valid description',
        price: 10.0,
        stock: 10,
        categoryId: 1,
        street: '123 Test St',
        apartment: '',
        city: 'Toronto',
        postalCode: 'M1M 1M1',
        deliveryOptions: [],
      );

      final state = container.read(addProductViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('name'));
    });

    test('validation fails on short description', () async {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      await viewModel.addProduct(
        name: 'Valid Name',
        description: 'Short',
        price: 10.0,
        stock: 10,
        categoryId: 1,
        street: '123 Test St',
        apartment: '',
        city: 'Toronto',
        postalCode: 'M1M 1M1',
        deliveryOptions: [],
      );

      final state = container.read(addProductViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('description'));
    });

    test('validation fails on negative price', () async {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      await viewModel.addProduct(
        name: 'Valid Name',
        description: 'A valid description that is long enough',
        price: -1.0,
        stock: 10,
        categoryId: 1,
        street: '123 Test St',
        apartment: '',
        city: 'Toronto',
        postalCode: 'M1M 1M1',
        deliveryOptions: [],
      );

      final state = container.read(addProductViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('price'));
    });

    test('validation fails on negative stock', () async {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      await viewModel.addProduct(
        name: 'Valid Name',
        description: 'A valid description that is long enough',
        price: 10.0,
        stock: -5,
        categoryId: 1,
        street: '123 Test St',
        apartment: '',
        city: 'Toronto',
        postalCode: 'M1M 1M1',
        deliveryOptions: [],
      );

      final state = container.read(addProductViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('stock'));
    });

    test('validation fails on invalid category', () async {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      await viewModel.addProduct(
        name: 'Valid Name',
        description: 'A valid description that is long enough',
        price: 10.0,
        stock: 10,
        categoryId: 0,
        street: '123 Test St',
        apartment: '',
        city: 'Toronto',
        postalCode: 'M1M 1M1',
        deliveryOptions: [],
      );

      final state = container.read(addProductViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('category'));
    });

    test('toggle options updates state correctly', () {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      
      viewModel.toggleDigital(true);
      expect(container.read(addProductViewModelProvider).isDigital, isTrue);

      viewModel.togglePerishable(true);
      expect(container.read(addProductViewModelProvider).isPerishable, isTrue);

      viewModel.toggleAgeRestricted(true);
      expect(container.read(addProductViewModelProvider).isAgeRestricted, isTrue);
      
      viewModel.setCondition('like_new');
      expect(container.read(addProductViewModelProvider).condition, 'like_new');
    });

    test('update address updates state via selectAddress', () {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      
      viewModel.selectAddress({
        'geometry': {
          'coordinates': [-79.0, 43.0]
        }
      });
      
      final state = container.read(addProductViewModelProvider);
      expect(state.latitude, 43.0);
      expect(state.longitude, -79.0);
      expect(state.addressVerified, isTrue);
    });

    test('delivery options toggles update state', () {
      final viewModel = container.read(addProductViewModelProvider.notifier);
      
      viewModel.setStandardEnabled(true);
      expect(container.read(addProductViewModelProvider).standardEnabled, isTrue);

      viewModel.setExpressEnabled(true);
      expect(container.read(addProductViewModelProvider).expressEnabled, isTrue);

      viewModel.setSameDayEnabled(true);
      expect(container.read(addProductViewModelProvider).sameDayEnabled, isTrue);
      
      viewModel.setLocalDeliveryOnly(true);
      expect(container.read(addProductViewModelProvider).isLocalDeliveryOnly, isTrue);
    });
  });
}