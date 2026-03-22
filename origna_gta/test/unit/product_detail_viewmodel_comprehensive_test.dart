import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<Document>(),
])
import 'product_detail_viewmodel_comprehensive_test.mocks.dart';

void main() {
  late MockOrignaBase mockOrignaBase;
  late MockCollectionRef mockCollectionRef;
  late MockDocumentRef mockDocumentRef;
  late MockDocument mockDocument;
  late ProviderContainer container;

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    mockCollectionRef = MockCollectionRef();
    mockDocumentRef = MockDocumentRef();
    mockDocument = MockDocument();

    when(
      mockOrignaBase.collection(Collections.sellerMetrics),
    ).thenReturn(mockCollectionRef);
    when(mockCollectionRef.doc(any)).thenReturn(mockDocumentRef);
    when(mockDocumentRef.get()).thenAnswer((_) async => mockDocument);
    when(mockDocument.exists).thenReturn(true);
    when(mockDocument.data).thenReturn({
      Fields.avgResponseTimeHours: 2.5,
      Fields.avgShipDays: 1.0,
      Fields.positiveRatePct: 98.0,
      Fields.totalReviews: 50,
    });

    container = ProviderContainer(
      overrides: [orignabaseProvider.overrideWithValue(mockOrignaBase)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProductDetailViewModel Initial State Tests', () {
    test('initial state has quantity 1', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, 1);
    });

    test('initial state has currentImageIndex 0', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.currentImageIndex, 0);
    });

    test('initial state has empty selectedOptions', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.selectedOptions, isEmpty);
    });

    test('initial state has null selectedVariantId', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.selectedVariantId, isNull);
    });

    test('initial state has null sellerMetrics', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.sellerMetrics, isNull);
    });

    test('initial state has sellerMetricsLoading false', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.sellerMetricsLoading, isFalse);
    });
  });

  group('ProductDetailViewModel State Transitions Tests', () {
    test('setQuantity transitions state correctly', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(5);
      expect(container.read(productDetailViewModelProvider).quantity, 5);

      notifier.setQuantity(10);
      expect(container.read(productDetailViewModelProvider).quantity, 10);
    });

    test('setQuantity ignores values below 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(5);
      notifier.setQuantity(0);
      expect(container.read(productDetailViewModelProvider).quantity, 5);

      notifier.setQuantity(-1);
      expect(container.read(productDetailViewModelProvider).quantity, 5);
    });

    test('incrementQuantity increases by 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(1);
      notifier.incrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 2);

      notifier.incrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 3);
    });

    test('decrementQuantity decreases by 1 but not below 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(3);
      notifier.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 2);

      notifier.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 1);

      notifier.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 1);
    });

    test('setImageIndex transitions correctly', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setImageIndex(2);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        2,
      );

      notifier.setImageIndex(0);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        0,
      );

      notifier.setImageIndex(10);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        10,
      );
    });

    test('setSelectedOption updates options map', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedOption('Size', 'Large', variantId: 'v-large');
      expect(container.read(productDetailViewModelProvider).selectedOptions, {
        'Size': 'Large',
      });
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'v-large',
      );

      notifier.setSelectedOption('Color', 'Red', variantId: 'v-red');
      expect(container.read(productDetailViewModelProvider).selectedOptions, {
        'Size': 'Large',
        'Color': 'Red',
      });
    });

    test('setSelectedVariantId updates variant ID', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedVariantId('variant_123');
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'variant_123',
      );

      notifier.setSelectedVariantId('variant_456');
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'variant_456',
      );
    });

    test('setSelectedVariantId preserves existing value when null passed', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedVariantId('variant_123');
      notifier.setSelectedVariantId(null);
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'variant_123',
      );
    });
  });

  group('ProductDetailViewModel Public Methods Tests', () {
    test('fetchSellerMetrics clears metrics for empty seller ID', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.fetchSellerMetrics('');
      expect(
        container.read(productDetailViewModelProvider).sellerMetrics,
        isNull,
      );
      expect(
        container.read(productDetailViewModelProvider).sellerMetricsLoading,
        isFalse,
      );
    });

    test('fetchSellerMetrics clears metrics for whitespace seller ID', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.fetchSellerMetrics('   ');
      expect(
        container.read(productDetailViewModelProvider).sellerMetrics,
        isNull,
      );
    });

    test('voteHelpful requires signed-in user', () async {
      await expectLater(
        container
            .read(productDetailViewModelProvider.notifier)
            .voteHelpful('rating-1', 'product-1', true),
        throwsA(isA<StateError>()),
      );
    });

    test('voteHelpful posts vote when user signed in', () async {
      final voteContainer = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(mockOrignaBase),
          obUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(voteContainer.dispose);

      when(
        mockOrignaBase.request(
          'POST',
          ApiEndpoints.productsReviewVote,
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await voteContainer
          .read(productDetailViewModelProvider.notifier)
          .voteHelpful('rating-1', 'product-1', true);

      verify(
        mockOrignaBase.request(
          'POST',
          ApiEndpoints.productsReviewVote,
          body: {Fields.reviewId: 'rating-1', 'vote': 'helpful'},
        ),
      ).called(1);
    });
  });

  group('ProductDetailViewModel Error Handling Tests', () {
    test('voteHelpful propagates network errors', () async {
      final voteContainer = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(mockOrignaBase),
          obUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(voteContainer.dispose);

      when(
        mockOrignaBase.request(
          'POST',
          ApiEndpoints.productsReviewVote,
          body: anyNamed('body'),
        ),
      ).thenThrow(Exception('Network error'));

      await expectLater(
        voteContainer
            .read(productDetailViewModelProvider.notifier)
            .voteHelpful('rating-1', 'product-1', true),
        throwsException,
      );
    });
  });

  group('ProductDetailViewModel Edge Cases Tests', () {
    test('setQuantity handles large values', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(1000000);
      expect(container.read(productDetailViewModelProvider).quantity, 1000000);
    });

    test('setQuantity handles value of 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(5);
      notifier.setQuantity(1);
      expect(container.read(productDetailViewModelProvider).quantity, 1);
    });

    test('incrementQuantity can be called multiple times rapidly', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      for (var i = 0; i < 100; i++) {
        notifier.incrementQuantity();
      }
      expect(container.read(productDetailViewModelProvider).quantity, 101);
    });

    test('decrementQuantity called repeatedly stays at 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      for (var i = 0; i < 100; i++) {
        notifier.decrementQuantity();
      }
      expect(container.read(productDetailViewModelProvider).quantity, 1);
    });

    test('setImageIndex accepts negative values', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setImageIndex(-1);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        -1,
      );
    });

    test('setSelectedOption overwrites existing option', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedOption('Size', 'Small', variantId: 'v-small');
      notifier.setSelectedOption('Size', 'Large', variantId: 'v-large');

      expect(
        container.read(productDetailViewModelProvider).selectedOptions['Size'],
        'Large',
      );
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'v-large',
      );
    });

    test('setSelectedOption without variantId updates options only', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedVariantId('existing-variant');
      notifier.setSelectedOption('Color', 'Blue');

      expect(
        container.read(productDetailViewModelProvider).selectedOptions['Color'],
        'Blue',
      );
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'existing-variant',
      );
    });
  });

  group('SellerMetrics Tests', () {
    test('SellerMetrics can be created with all fields', () {
      const metrics = SellerMetrics(
        avgResponseHours: 2.5,
        avgShipDays: 1.0,
        positiveRatePct: 98.0,
        totalReviews: 50,
      );

      expect(metrics.avgResponseHours, 2.5);
      expect(metrics.avgShipDays, 1.0);
      expect(metrics.positiveRatePct, 98.0);
      expect(metrics.totalReviews, 50);
    });

    test('SellerMetrics can be created with null fields', () {
      const metrics = SellerMetrics();

      expect(metrics.avgResponseHours, isNull);
      expect(metrics.avgShipDays, isNull);
      expect(metrics.positiveRatePct, isNull);
      expect(metrics.totalReviews, isNull);
    });
  });

  group('ProductDetailState copyWith Tests', () {
    test('copyWith preserves values when not specified', () {
      final state = ProductDetailState(
        quantity: 5,
        currentImageIndex: 2,
        selectedOptions: {'Size': 'Large'},
        selectedVariantId: 'v1',
      );

      final copied = state.copyWith();

      expect(copied.quantity, 5);
      expect(copied.currentImageIndex, 2);
      expect(copied.selectedOptions, {'Size': 'Large'});
      expect(copied.selectedVariantId, 'v1');
    });

    test('copyWith clears sellerMetrics when clearSellerMetrics is true', () {
      const metrics = SellerMetrics(avgResponseHours: 2.0);
      final state = ProductDetailState(sellerMetrics: metrics);

      final copied = state.copyWith(clearSellerMetrics: true);

      expect(copied.sellerMetrics, isNull);
    });

    test('copyWith updates individual fields', () {
      final state = ProductDetailState();

      final copied = state.copyWith(
        quantity: 10,
        currentImageIndex: 3,
        selectedOptions: {'Color': 'Red'},
        selectedVariantId: 'v2',
      );

      expect(copied.quantity, 10);
      expect(copied.currentImageIndex, 3);
      expect(copied.selectedOptions, {'Color': 'Red'});
      expect(copied.selectedVariantId, 'v2');
    });
  });
}
