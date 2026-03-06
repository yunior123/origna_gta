import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import '../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
import 'product_details_screen_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockDocumentSnapshot mockSnapshot;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    SharedPreferences.setMockInitialValues({});
    initTestMocks();
    
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
  });

  final testProduct = Product(
    productId: 'p1',
    name: 'Honey',
    price: 10.0,
    imageUrls: ['https://example.com/img.jpg'],
    description: 'Sweet honey',
    sellerId: 's1',
    stockQuantity: 10,
    categoryId: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isDigital: false,
    rating: 4.5,
    ratingCount: 10,
  );

  Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return TestWrapper(
      overrides: overrides,
      child: child,
    );
  }

  group('ProductDetailScreen Widget Tests', () {
    testWidgets('renders product data with discount', (tester) async {
      tester.view.physicalSize = const Size(3000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final discountProduct = testProduct.copyWith(compareAtPrice: 15.0);
      
      await tester.pumpWidget(createTestApp(
        overrides: [
          productByIdProvider('p1').overrideWith((ref) => discountProduct),
          userProfileProvider.overrideWith((ref) => const Stream.empty()),
          subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
          qaListProvider('p1').overrideWith((ref) => const Stream.empty()),
          firestoreProvider.overrideWithValue(mockFirestore),
        ],
        child: const ProductDetailScreen(productId: 'p1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('\$15.00', skipOffstage: false), findsWidgets);
    });

    testWidgets('renders digital product info', (tester) async {
      tester.view.physicalSize = const Size(3000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final digitalProduct = testProduct.copyWith(isDigital: true, digitalType: DigitalTypeValues.software);
      
      await tester.pumpWidget(createTestApp(
        overrides: [
          productByIdProvider('p1').overrideWith((ref) => digitalProduct),
          userProfileProvider.overrideWith((ref) => const Stream.empty()),
          subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
          qaListProvider('p1').overrideWith((ref) => const Stream.empty()),
          firestoreProvider.overrideWithValue(mockFirestore),
        ],
        child: const ProductDetailScreen(productId: 'p1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('product.desktop_software'.tr(), skipOffstage: false), findsWidgets);
    });
  });
}
