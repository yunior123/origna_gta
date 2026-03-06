import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<WriteBatch>(),
])
import 'cart_repository_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockDocumentSnapshot mockSnapshot;
  late FirebaseCartRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    
    repository = FirebaseCartRepository(mockFirestore);
    
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.collection(any)).thenReturn(mockCollection);
    when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
  });

  group('FirebaseCartRepository Unit Tests', () {
    test('removeFromCart deletes document', () async {
      await repository.removeFromCart('user_123', 'cart_456');
      
      verify(mockFirestore.collection(Collections.users)).called(1);
      verify(mockCollection.doc('user_123')).called(1);
      verify(mockDoc.collection(Collections.cart)).called(1);
      verify(mockCollection.doc('cart_456')).called(1);
      verify(mockDoc.delete()).called(1);
    });

    test('updateQuantity updates quantity field', () async {
      await repository.updateQuantity('user_123', 'cart_456', 5);
      verify(mockDoc.update({Fields.quantity: 5})).called(1);
    });

    test('updateQuantity deletes if quantity < 1', () async {
      await repository.updateQuantity('user_123', 'cart_456', 0);
      verify(mockDoc.delete()).called(1);
    });

    test('updateBuyerNote updates field', () async {
      await repository.updateBuyerNote('user_123', 'cart_456', 'New note');
      verify(mockDoc.set({Fields.buyerNote: 'New note'}, any)).called(1);
    });

    test('updateBuyerNote deletes field if note is null', () async {
      await repository.updateBuyerNote('user_123', 'cart_456', null);
      verify(mockDoc.update(any)).called(1);
    });

    test('getProductSellerId returns sellerId if product exists', () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({Fields.sellerId: 'seller_789'});
      
      final id = await repository.getProductSellerId('prod_123');
      expect(id, 'seller_789');
    });

    test('watchCart returns correct stream', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      when(mockCollection.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([]);
      
      final stream = repository.watchCart('user_123');
      final list = await stream.first;
      expect(list, isEmpty);
    });
  });
}
