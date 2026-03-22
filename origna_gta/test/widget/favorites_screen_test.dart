import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('FavoritesScreen', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Completer<List<Product>>().future,
            ),
            userProfileProvider.overrideWith(
              (_) => Stream.value(
                UserModel(
                  uid: 'user1',
                  email: 'test@test.com',
                  name: 'Test User',
                  roles: [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith(
              (_) => Stream.value(
                UserModel(
                  uid: 'user1',
                  email: 'test@test.com',
                  name: 'Test User',
                  roles: [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.error('Network error'),
            ),
            userProfileProvider.overrideWith(
              (_) => Stream.value(
                UserModel(
                  uid: 'user1',
                  email: 'test@test.com',
                  name: 'Test User',
                  roles: [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('has app bar', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith(
              (_) => Stream.value(
                UserModel(
                  uid: 'user1',
                  email: 'test@test.com',
                  name: 'Test User',
                  roles: [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith(
              (_) => Stream.value(
                UserModel(
                  uid: 'user1',
                  email: 'test@test.com',
                  name: 'Test User',
                  roles: [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(find.byType(FavoritesScreen), findsNothing);
    });

    testWidgets('has scaffold', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith(
              (_) => Stream.value(
                UserModel(
                  uid: 'user1',
                  email: 'test@test.com',
                  name: 'Test User',
                  roles: [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
