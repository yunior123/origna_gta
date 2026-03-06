import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
import 'product_detail_viewmodel_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockDocumentSnapshot mockSnapshot;
  late ProviderContainer container;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    
    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
    
    container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(mockFirestore),
        firebaseFunctionsProvider.overrideWithValue(mockFunctions),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProductDetailViewModel Unit Tests', () {
    test('initial state is correct', () {
      final state = container.read(productDetailViewModelProvider);
      expect(state.quantity, 1);
      expect(state.currentImageIndex, 0);
      expect(state.sellerMetrics, isNull);
    });

    test('setQuantity updates state', () {
      final viewModel = container.read(productDetailViewModelProvider.notifier);
      viewModel.setQuantity(5);
      expect(container.read(productDetailViewModelProvider).quantity, 5);
      
      viewModel.setQuantity(0); // Should be ignored
      expect(container.read(productDetailViewModelProvider).quantity, 5);
    });

    test('increment/decrement updates quantity', () {
      final viewModel = container.read(productDetailViewModelProvider.notifier);
      viewModel.incrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 2);
      
      viewModel.decrementQuantity();
      expect(container.read(productDetailViewModelProvider).quantity, 1);
      
      viewModel.decrementQuantity(); // Should not go below 1
      expect(container.read(productDetailViewModelProvider).quantity, 1);
    });

    test('setImageIndex updates state', () {
      final viewModel = container.read(productDetailViewModelProvider.notifier);
      viewModel.setImageIndex(2);
      expect(container.read(productDetailViewModelProvider).currentImageIndex, 2);
    });

    test('voteHelpful calls backend', () async {
      final viewModel = container.read(productDetailViewModelProvider.notifier);
      await viewModel.voteHelpful('r1', 'p1', true);
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.voteReviewHelpful)).called(1);
      verify(mockCallable.call(argThat(containsPair('helpful', true)))).called(1);
    });

    test('fetchSellerMetrics updates state from Firestore', () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({
        Fields.avgResponseTimeHours: 2.5,
        Fields.avgShipDays: 1.5,
        Fields.positiveRatePct: 98.0,
        Fields.totalReviews: 150,
      });
      
      final viewModel = container.read(productDetailViewModelProvider.notifier);
      await viewModel.fetchSellerMetrics('seller_123');
      
      final state = container.read(productDetailViewModelProvider);
      expect(state.sellerMetricsLoading, isFalse);
      expect(state.sellerMetrics!.avgResponseHours, 2.5);
      expect(state.sellerMetrics!.totalReviews, 150);
      
      verify(mockFirestore.collection(Collections.sellerMetrics)).called(1);
      verify(mockCollection.doc('seller_123')).called(1);
    });

    test('fetchSellerMetrics handles non-existent document', () async {
      when(mockSnapshot.exists).thenReturn(false);
      
      final viewModel = container.read(productDetailViewModelProvider.notifier);
      await viewModel.fetchSellerMetrics('seller_123');
      
      final state = container.read(productDetailViewModelProvider);
      expect(state.sellerMetrics, isNotNull);
      expect(state.sellerMetrics!.totalReviews, isNull);
    });
  });
}
