import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/screens/productaddvideo_screen.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';
import 'package:origna_gta/screens/subscription_cancel_screen.dart';
import 'package:origna_gta/screens/subscription_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>(), MockSpec<OrderRepository>()])
import 'remaining_screens_batch8_test.mocks.dart';

void main() {
  late AppAuthUser mockUser;
  late MockProductRepository mockProductRepo;
  late MockOrderRepository mockOrderRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
    );
    mockProductRepo = MockProductRepository();
    mockOrderRepo = MockOrderRepository();
  });

  Future<void> pumpResilient(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        ],
        child: widget,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    } catch (_) {}
  }

  group('Remaining Screens Batch 8 Smoke Tests', () {
    testWidgets('renders ProductAddImages', (tester) async {
      await pumpResilient(tester, const ProductAddImages(imageModels: []));
      expect(find.byType(ProductAddImages), findsOneWidget);
    });

    testWidgets('renders ProductAddVideo', (tester) async {
      await pumpResilient(tester, const ProductAddVideo());
      expect(find.byType(ProductAddVideo), findsOneWidget);
    });

    testWidgets('renders ShippingApprovalScreen', (tester) async {
      await pumpResilient(tester, const ShippingApprovalScreen());
      expect(find.byType(ShippingApprovalScreen), findsOneWidget);
    });

    testWidgets('renders SubscriptionCancelScreen', (tester) async {
      await pumpResilient(tester, const SubscriptionCancelScreen());
      expect(find.byType(SubscriptionCancelScreen), findsOneWidget);
    });

    testWidgets('renders SubscriptionScreen', (tester) async {
      await pumpResilient(tester, const SubscriptionScreen());
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });
  });
}
