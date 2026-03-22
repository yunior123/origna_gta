import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import '../test_utils.dart';


void main() {
  setUpAll(() {
    initTestMocks();
  });
  late AppAuthUser mockUser;

  setUp(() {
    mockUser = const AppAuthUser(uid: 'test_user_123', email: 'test@example.com');
  });

  group('EditProductScreen Smoke Test', () {
    testWidgets('renders edit product screen correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_123',
        name: 'Existing Product',
        description: 'Existing description.',
        price: 4999 / 100.0,
        sellerId: 'test_user_123',
        categoryId: 1,
        imageUrls: [],
        stockQuantity: 5,
        createdAt: DateTime.now(),
        isDigital: false,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
          ],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Existing Product'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
