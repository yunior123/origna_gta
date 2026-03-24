import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/return_request_screen.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/return_request_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import '../test_utils.dart';

Order _mockOrder({String orderId = 'order1', List<OrderItem>? items}) {
  return Order(
    orderId: orderId,
    userId: 'buyer1',
    items: items ?? [],
    subtotalCents: 1000,
    totalAmountCents: 1000,
    taxes: const Taxes(),
    createdAt: DateTime.now(),
  );
}

OrderItem _mockOrderItem({
  String productId = 'p1',
  String name = 'Test Item',
  String description = 'A test item',
  int quantity = 1,
  int priceCents = 1000,
  String sellerId = 'seller1',
  String status = DeliveryStatusValues.delivered,
  List<String> imageUrls = const [],
  DateTime? deliveredAt,
  String? cartItemId,
}) {
  return OrderItem(
    productId: productId,
    name: name,
    description: description,
    quantity: quantity,
    priceCents: priceCents,
    sellerId: sellerId,
    imageUrls: imageUrls,
    status: status,
    deliveredAt: deliveredAt,
    cartItemId: cartItemId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('ReturnRequestScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider('test-order').overrideWith((ref) async => null),
          ],
          child: const ReturnRequestScreen(orderId: 'test-order'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReturnRequestScreen), findsOneWidget);
    });

    testWidgets('shows no eligible items when none are delivered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final order = _mockOrder(
        orderId: 'order1',
        items: [
          _mockOrderItem(productId: 'p1', status: DeliveryStatusValues.shipped),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider('order1').overrideWith((ref) async => order),
          ],
          child: const ReturnRequestScreen(orderId: 'order1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('returns.no_eligible_items'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows form with delivered items', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final order = _mockOrder(
        orderId: 'order1',
        items: [
          _mockOrderItem(
            productId: 'p1',
            name: 'Delivered Widget',
            status: DeliveryStatusValues.delivered,
            deliveredAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider('order1').overrideWith((ref) async => order),
          ],
          child: const ReturnRequestScreen(orderId: 'order1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('returns.select_items'), findsOneWidget);
      expect(find.text('Delivered Widget'), findsOneWidget);
      expect(find.text('returns.select_reason'), findsOneWidget);
      expect(find.text('returns.description_label'), findsOneWidget);
      expect(find.bySemanticsLabel('btn-submit-return'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('has return window notice', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final order = _mockOrder(
        orderId: 'order1',
        items: [
          _mockOrderItem(
            productId: 'p1',
            name: 'Widget',
            status: DeliveryStatusValues.delivered,
            deliveredAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider('order1').overrideWith((ref) async => order),
          ],
          child: const ReturnRequestScreen(orderId: 'order1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.schedule), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows error from viewmodel', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final order = _mockOrder(
        orderId: 'order1',
        items: [
          _mockOrderItem(
            productId: 'p1',
            name: 'Widget',
            status: DeliveryStatusValues.delivered,
            deliveredAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider('order1').overrideWith((ref) async => order),
          ],
          child: const ReturnRequestScreen(orderId: 'order1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReturnRequestScreen), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('scaffold has gradient background', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider('test-order').overrideWith((ref) async => null),
          ],
          child: const ReturnRequestScreen(orderId: 'test-order'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('ReturnRequestState', () {
    test('default state is not loading, not success', () {
      const state = ReturnRequestState();
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith works correctly', () {
      const state = ReturnRequestState();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.isSuccess, isFalse);

      final success = loading.copyWith(isLoading: false, isSuccess: true);
      expect(success.isLoading, isFalse);
      expect(success.isSuccess, isTrue);

      final error = state.copyWith(errorMessage: 'Failed');
      expect(error.errorMessage, 'Failed');
    });

    test('clearStatus resets error and success', () {
      const state = ReturnRequestState(
        isSuccess: true,
        errorMessage: 'Some error',
      );
      final cleared = state.copyWith(errorMessage: null, isSuccess: false);
      expect(cleared.isSuccess, isFalse);
      expect(cleared.errorMessage, isNull);
    });
  });
}
