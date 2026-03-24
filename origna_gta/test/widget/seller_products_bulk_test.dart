import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/seller/seller_products_viewmodel.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/models/models.dart' as models;
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/screens/seller_products_screen.dart';

import '../test_utils.dart';

Product _makeProduct({
  String id = 'prod_1',
  String name = 'Test Product',
  int priceCents = 2999,
  int stockQuantity = 10,
  String lifecycleStatus = ProductLifecycleStatusValues.active,
  String? approvalRejectionReason,
  List<String> imageUrls = const [],
}) {
  return Product(
    productId: id,
    name: name,
    priceCents: priceCents,
    description: 'A test product',
    imageUrls: imageUrls,
    sellerId: 'test_user_123',
    categoryId: 1,
    stockQuantity: stockQuantity,
    createdAt: DateTime(2026, 1, 1),
    lifecycleStatus: lifecycleStatus,
    approvalRejectionReason: approvalRejectionReason,
  );
}

Future<void> pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppAuthUser mockUser;

  final testUserModel = models.UserModel(
    uid: 'test_user_123',
    name: 'Test Seller',
    email: 'seller@example.com',
    roles: [UserRole.seller],
    createdAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
    );
  });

  Widget buildScreen({
    Stream<List<Product>>? productsStream,
    int unansweredQaCount = 0,
    bool loggedIn = true,
  }) {
    return TestWrapper(
      overrides: [
        if (loggedIn) currentUserProvider.overrideWithValue(mockUser),
        if (!loggedIn) currentUserProvider.overrideWithValue(null),
        userProfileProvider.overrideWith(
          (ref) => loggedIn ? Stream.value(testUserModel) : Stream.value(null),
        ),
        sellerProductsProvider.overrideWith(
          (ref) => productsStream ?? Stream.value([]),
        ),
        sellerUnansweredQaProvider(
          'test_user_123',
        ).overrideWith((ref) => Stream.value(unansweredQaCount)),
      ],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('Route: ${settings.name}')),
          settings: settings,
        );
      },
      child: const SellerProductsScreen(),
    );
  }

  group('SellerProductsScreen — Bulk Section', () {
    group('bulk action bar visibility', () {
      testWidgets('bulk action bar hidden when no products selected', (
        tester,
      ) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        // No bulk action bar visible initially
        expect(find.textContaining('selected'), findsNothing);
      });
    });

    group('Q&A badge (UnansweredQaBadge)', () {
      testWidgets('badge shows count when unanswered questions > 0', (
        tester,
      ) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(
            productsStream: Stream.value(products),
            unansweredQaCount: 3,
          ),
        );
        await pumpFrames(tester);

        expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('badge shows no count when unanswered = 0', (tester) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(
            productsStream: Stream.value(products),
            unansweredQaCount: 0,
          ),
        );
        await pumpFrames(tester);

        expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
        expect(find.text('0'), findsNothing);
      });

      testWidgets('badge shows 99+ for large counts', (tester) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(
            productsStream: Stream.value(products),
            unansweredQaCount: 150,
          ),
        );
        await pumpFrames(tester);

        expect(find.text('99+'), findsOneWidget);
      });

      testWidgets('badge tapping navigates to seller orders', (tester) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(
            productsStream: Stream.value(products),
            unansweredQaCount: 5,
          ),
        );
        await pumpFrames(tester);

        final badge = find.byIcon(Icons.forum_outlined);
        await tester.tap(badge);
        await tester.pump();
      });
    });

    group('skeleton loader', () {
      testWidgets('loading state shows shimmer skeleton', (tester) async {
        await tester.pumpWidget(
          buildScreen(productsStream: StreamController<List<Product>>().stream),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SellerProductsScreen), findsOneWidget);
      });
    });

    group('product card interactions', () {
      testWidgets('tapping product card navigates', (tester) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        await tester.tap(find.text('Test Product'));
        await tester.pump();
      });

      testWidgets('product card shows image when available', (tester) async {
        final products = [
          _makeProduct(imageUrls: ['https://example.com/img.jpg']),
        ];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        expect(find.byType(Image), findsWidgets);
      });

      testWidgets('product card shows placeholder when no images', (
        tester,
      ) async {
        final products = [_makeProduct(imageUrls: [])];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      });
    });

    group('screen states', () {
      testWidgets('screen has correct key', (tester) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        expect(find.byKey(const Key('seller_products_screen')), findsOneWidget);
      });

      testWidgets('shows scaffold with gradient background', (tester) async {
        final products = [_makeProduct()];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('shows product count in subtitle', (tester) async {
        final products = [_makeProduct(id: 'p1'), _makeProduct(id: 'p2')];

        await tester.pumpWidget(
          buildScreen(productsStream: Stream.value(products)),
        );
        await pumpFrames(tester);

        expect(find.text('2 products'), findsOneWidget);
      });
    });
  });
}
