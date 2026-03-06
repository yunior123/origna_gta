import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/home_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/models/models.dart' as models;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<User>(), MockSpec<ProductRepository>()])
import 'home_screen_test.mocks.dart';

void main() {
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;
  late MockProductRepository mockProductRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUser = MockUser();
    fakeFirestore = FakeFirebaseFirestore();
    mockProductRepo = MockProductRepository();
    when(mockUser.uid).thenReturn('test_user_123');
  });

  group('HomeScreen Smoke Test', () {
    testWidgets('renders home screen correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Stub fetchProducts to avoid FakeUsedError
      when(mockProductRepo.fetchProducts(
        searchQuery: anyNamed('searchQuery'),
        categoryId: anyNamed('categoryId'),
        subcategory: anyNamed('subcategory'),
        lastDocument: anyNamed('lastDocument'),
        pageSize: anyNamed('pageSize'),
        sortOption: anyNamed('sortOption'),
        minPriceCents: anyNamed('minPriceCents'),
        maxPriceCents: anyNamed('maxPriceCents'),
      )).thenAnswer((_) async => ProductQueryResult(products: [], lastDocument: null, hasMore: false));

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userProfileProvider.overrideWith((ref) => Stream.value(models.UserModel(
              uid: 'test_user_123',
              name: 'Test',
              email: 'test@example.com',
              roles: ['buyer'],
              createdAt: DateTime.now(),
            ))),
            firestoreProvider.overrideWithValue(fakeFirestore),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
          ],
          child: const HomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
