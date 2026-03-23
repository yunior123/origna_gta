# Flutter Test Patterns — origna_gta

## Unit Test: ViewModel

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:origna_gta/viewmodels/cart_viewmodel.dart';
import 'package:origna_gta/services/cart_service.dart';

class MockCartService extends Mock implements CartService {}

void main() {
  late MockCartService mockCartService;
  late CartViewModel viewModel;

  setUp(() {
    mockCartService = MockCartService();
    viewModel = CartViewModel(cartService: mockCartService);
  });

  group('CartViewModel', () {
    test('should calculate subtotal in cents', () {
      // Arrange
      final items = [
        CartItem(productId: 'p1', unitPriceCents: 2500, quantity: 2),
        CartItem(productId: 'p2', unitPriceCents: 1000, quantity: 1),
      ];
      when(() => mockCartService.getItems()).thenReturn(items);

      // Act
      final subtotal = viewModel.subtotalCents;

      // Assert
      expect(subtotal, equals(6000)); // $60.00 in cents
    });

    test('should apply free shipping above threshold', () {
      // Arrange
      when(() => mockCartService.subtotalCents).thenReturn(7500); // $75.00

      // Act
      final shipping = viewModel.shippingCostCents;

      // Assert
      expect(shipping, equals(0));
    });

    test('should handle empty cart', () {
      // Arrange
      when(() => mockCartService.getItems()).thenReturn([]);

      // Act
      final subtotal = viewModel.subtotalCents;

      // Assert
      expect(subtotal, equals(0));
    });
  });
}
```

## Widget Test: Screen Smoke Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/providers/cart_provider.dart';

class MockCartNotifier extends Mock implements CartNotifier {}

void main() {
  group('CheckoutScreen', () {
    testWidgets('should build without errors', (tester) async {
      // Arrange
      final mockNotifier = MockCartNotifier();
      when(() => mockNotifier.state).thenReturn(
        const AsyncData(CartState.empty()),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets('should show loading state', (tester) async {
      // Arrange
      final mockNotifier = MockCartNotifier();
      when(() => mockNotifier.state).thenReturn(const AsyncLoading());

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state', (tester) async {
      // Arrange
      final mockNotifier = MockCartNotifier();
      when(() => mockNotifier.state).thenReturn(
        AsyncError(AppError('Failed to load'), StackTrace.current),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to load'), findsOneWidget);
    });
  });
}
```

## Money Assertion Patterns

```dart
// Always integer cents
expect(order.totalAmountCents, equals(8625)); // $86.25
expect(order.taxAmountCents, equals(1125));   // $11.25
expect(order.shippingCostCents, equals(0));   // free shipping

// Display formatting (only at UI layer)
expect(formatCents(8625), equals('\$86.25'));

// Platform fee calculation
final fee = (subtotalCents * platformFeeRate).round();
expect(fee, isA<int>());
```

## Async State Testing

```dart
test('should transition through loading states', () async {
  // Arrange
  when(() => mockService.fetchOrders())
      .thenAnswer((_) async => [testOrder]);

  // Act & Assert — initial state
  expect(viewModel.state, isA<AsyncLoading>());

  // Act — trigger fetch
  await viewModel.fetchOrders();

  // Assert — loaded state
  expect(viewModel.state, isA<AsyncData>());
  expect(viewModel.state.value, hasLength(1));
});
```

## Order State Transition Tests

```dart
group('Order state transitions', () {
  test('pending -> confirmed is valid', () {
    expect(
      order.canTransitionTo(OrderStatus.confirmed),
      isTrue,
    );
  });

  test('pending -> delivered is invalid (no skipping)', () {
    expect(
      order.canTransitionTo(OrderStatus.delivered),
      isFalse,
    );
  });

  test('delivered is terminal', () {
    final delivered = order.copyWith(status: OrderStatus.delivered);
    expect(delivered.isTerminal, isTrue);
  });
});
```
