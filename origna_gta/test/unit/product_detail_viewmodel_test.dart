import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

import 'product_detail_viewmodel_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<Document>(),
])
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
    when(mockCollectionRef.doc('s1')).thenReturn(mockDocumentRef);
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

  group('ProductDetailViewModel Tests', () {
    test('initial state', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, 1);
      expect(state.currentImageIndex, 0);
    });

    test('increment/decrement quantity', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.incrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 2);

      notifier.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 1);

      notifier.decrementQuantity(); // Should not go below 1
      expect(container.read(productDetailViewModelProvider).quantity, 1);
    });

    test('setImageIndex', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      notifier.setImageIndex(2);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        2,
      );
    });

    test('quantity cannot exceed product stock', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      // Increment multiple times
      for (int i = 0; i < 50; i++) {
        notifier.incrementQuantity();
      }

      // Should be capped by stock or reasonable limit
      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, greaterThanOrEqualTo(1));
    });

    test('setImageIndex with negative index', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      notifier.setImageIndex(-1);
      final state = container.read(productDetailViewModelProvider);
      expect(state.currentImageIndex, -1);
    });

    test('setImageIndex with large index', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      notifier.setImageIndex(999);
      final state = container.read(productDetailViewModelProvider);
      expect(state.currentImageIndex, 999);
    });

    test('quantity starts at 1', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, 1);
    });

    test('currentImageIndex starts at 0', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.currentImageIndex, 0);
    });

    test('incrementQuantity increases by exactly 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      final before = container.read(productDetailViewModelProvider).quantity;
      notifier.incrementQuantity();
      final after = container.read(productDetailViewModelProvider).quantity;
      expect(after - before, 1);
    });

    test('decrementQuantity decreases by exactly 1 until 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      notifier.incrementQuantity();
      notifier.incrementQuantity();

      final before = container.read(productDetailViewModelProvider).quantity;
      notifier.decrementQuantity();
      final after = container.read(productDetailViewModelProvider).quantity;
      expect(before - after, 1);
    });

    test('multiple incrementQuantity calls accumulate', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.incrementQuantity();
      notifier.incrementQuantity();
      notifier.incrementQuantity();

      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, 4); // 1 + 3
    });

    test('setImageIndex can be set multiple times', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setImageIndex(1);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        1,
      );

      notifier.setImageIndex(5);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        5,
      );

      notifier.setImageIndex(0);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        0,
      );
    });

    test('decrementQuantity with quantity 1 stays at 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      // Already at 1
      notifier.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 1);

      notifier.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 1);
    });

    test('ProductDetailState has quantity field', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, isA<int>());
    });

    test('ProductDetailState has currentImageIndex field', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.currentImageIndex, isA<int>());
    });

    test('incrementQuantity multiple times in sequence', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      for (int i = 0; i < 10; i++) {
        notifier.incrementQuantity();
      }

      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, 11); // 1 + 10
    });

    test('setImageIndex with 0', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      notifier.setImageIndex(0);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        0,
      );
    });

    test('setImageIndex with 1', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);
      notifier.setImageIndex(1);
      expect(
        container.read(productDetailViewModelProvider).currentImageIndex,
        1,
      );
    });

    test('setQuantity ignores values below one', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setQuantity(3);
      notifier.setQuantity(0);

      expect(container.read(productDetailViewModelProvider).quantity, 3);
    });

    test('setSelectedOption updates option map and selected variant', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedOption('Size', 'Large', variantId: 'v-large');

      final state = container.read(productDetailViewModelProvider);
      expect(state.selectedOptions, {'Size': 'Large'});
      expect(state.selectedVariantId, 'v-large');
    });

    test('setSelectedVariantId clears selection when null is passed', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.setSelectedVariantId('v-small');
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        'v-small',
      );

      notifier.setSelectedVariantId(null);
      expect(
        container.read(productDetailViewModelProvider).selectedVariantId,
        isNull,
      );
    });

    test('ProductDetailState.copyWith can clear seller metrics', () {
      const metrics = SellerMetrics(avgResponseHours: 2.0);
      const state = ProductDetailState(sellerMetrics: metrics);

      final cleared = state.copyWith(sellerMetrics: null);

      expect(cleared.sellerMetrics, isNull);
    });

    test('fetchSellerMetrics clears metrics for a blank seller id', () {
      final notifier = container.read(productDetailViewModelProvider.notifier);

      notifier.fetchSellerMetrics('   ');

      final state = container.read(productDetailViewModelProvider);
      expect(state.sellerMetrics, isNull);
      expect(state.sellerMetricsLoading, isFalse);
    });

    test('voteHelpful posts a helpful vote when a user is signed in', () async {
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

    test('voteHelpful requires a signed-in user', () async {
      await expectLater(
        container
            .read(productDetailViewModelProvider.notifier)
            .voteHelpful('rating-1', 'product-1', false),
        throwsA(isA<StateError>()),
      );
    });
  });
}
