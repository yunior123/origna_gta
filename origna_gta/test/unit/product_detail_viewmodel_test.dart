import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<Document>(),
])
import 'product_detail_viewmodel_test.mocks.dart';

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

    when(mockOrignaBase.collection(Collections.sellerMetrics))
        .thenReturn(mockCollectionRef);
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
      overrides: [
        orignabaseProvider.overrideWithValue(mockOrignaBase),
      ],
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
      expect(container.read(productDetailViewModelProvider).currentImageIndex, 2);
    });
  });
}
