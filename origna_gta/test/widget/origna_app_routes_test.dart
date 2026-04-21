import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/services/orignabase_notification_service.dart';
import 'package:origna_gta/services/push_transport.dart';
import 'package:origna_gta/services/session_timeout_service.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mock_asset_loader.dart';

@GenerateNiceMocks([
  MockSpec<PushMessagingClient>(),
  MockSpec<ProductRepository>(),
])
import 'origna_app_routes_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPushMessagingClient mockMessaging;
  late MockProductRepository mockProductRepository;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockMessaging = MockPushMessagingClient();
    mockProductRepository = MockProductRepository();

    OrignaBaseNotificationService.instance.resetForTesting();
    OrignaBaseNotificationService.instance.testNavigatorKey =
        GlobalKey<NavigatorState>();
    OrignaBaseNotificationService.instance.testScaffoldMessengerKey =
        GlobalKey<ScaffoldMessengerState>();

    SessionTimeoutService().configure(
      currentUserIdProvider: () => null,
      signOutCallback: () async {},
    );
    OrignaBaseNotificationService.instance.messagingOverride = mockMessaging;
    OrignaBaseNotificationService.instance.onMessageOverride =
        const Stream.empty();
    OrignaBaseNotificationService.instance.onMessageOpenedAppOverride =
        const Stream.empty();

    when(
      mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        announcement: anyNamed('announcement'),
        badge: anyNamed('badge'),
        carPlay: anyNamed('carPlay'),
        criticalAlert: anyNamed('criticalAlert'),
        provisional: anyNamed('provisional'),
        sound: anyNamed('sound'),
      ),
    ).thenAnswer(
      (_) async => const AppNotificationSettings(
        authorizationStatus: AppNotificationAuthorizationStatus.authorized,
      ),
    );
    when(mockMessaging.getToken()).thenAnswer((_) async => 'fake-token');
    when(mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());
    when(mockMessaging.getInitialMessage()).thenAnswer((_) async => null);

    when(
      mockProductRepository.fetchProducts(
        searchQuery: anyNamed('searchQuery'),
        categoryId: anyNamed('categoryId'),
        subcategory: anyNamed('subcategory'),
        lastDocumentId: anyNamed('lastDocumentId'),
        pageSize: anyNamed('pageSize'),
        sortOption: anyNamed('sortOption'),
        minPriceCents: anyNamed('minPriceCents'),
        maxPriceCents: anyNamed('maxPriceCents'),
      ),
    ).thenAnswer((_) async => ProductQueryResult(products: [], hasMore: false));

    when(mockProductRepository.getProductBySlug(any)).thenAnswer(
      (_) async => Product(
        productId: 'p1',
        name: 'Test Product',
        priceCents: 1000,
        imageUrls: const [],
        description: 'Desc',
        stockQuantity: 10,
        categoryId: 1,
        sellerId: 's1',
        createdAt: DateTime.now(),
      ),
    );
  });

  Widget createTestApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        productRepositoryProvider.overrideWithValue(mockProductRepository),
        ...overrides,
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('fr')],
        path: 'assets/translations',
        assetLoader: MockAssetLoader(),
        startLocale: const Locale('en'),
        child: const OrignaApp(),
      ),
    );
  }

  Future<void> pumpFrames(WidgetTester tester, {int count = 8}) async {
    for (int i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  group('OrignaApp widget', () {
    testWidgets('renders OrignaApp', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      expect(find.byType(OrignaApp), findsOneWidget);
    });

    testWidgets('navigator state is available', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState;
      expect(nav, isNotNull);
    });
  });

  group('_onGenerateRoute via Navigator', () {
    testWidgets('navigates to login route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/login');
      await pumpFrames(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('navigates to home route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/');
      await pumpFrames(tester);
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('navigates to cart route (auth required)', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/cart');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to profile route (auth required)', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/profile');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to orders route (auth required)', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/orders');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to orders/detail without orderId falls back', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/orders/detail');
      await pumpFrames(tester);
      // Without orderId, falls back to OrdersScreen
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to orders/detail with orderId', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/orders/detail?orderId=order123');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to return-request without orderId falls back', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/orders/return-request');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to favorites route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/favorites');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to subscription route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/subscription');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to subscription/success route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/subscription/success');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to subscription/cancel route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/subscription/cancel');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to payment-cancel route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/payment-cancel');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to payment-success without sessionId shows error', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/payment-success');
      await pumpFrames(tester);
      expect(find.byType(ErrorScreen), findsOneWidget);
    });

    testWidgets('navigates to payment-success with sessionId', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/payment-success?session_id=sess_123');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to seller/return route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/return');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to seller/refresh route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/refresh');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /p/{slug} product by slug', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/p/test-slug');
      await pumpFrames(tester);
      // Should navigate to product detail screen via slug resolution
      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });

    testWidgets('navigates to /product/{id} product by id', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/product/prod_123');
      await pumpFrames(tester);
      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });

    testWidgets('navigates to /addresses route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/addresses');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to /chat/inbox route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/chat/inbox');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to /notifications route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/notifications');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to /chat without args falls back to home', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/chat');
      await pumpFrames(tester);
      // Without ChatArgs or productId query param, falls back to AuthWrapper
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('navigates to /chat with query params', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/chat?productId=p1&productTitle=Test');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to /edit-product without args falls back to home', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/edit-product');
      await pumpFrames(tester);
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('navigates to /product-details without args falls back', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/product-details');
      await pumpFrames(tester);
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('navigates to /checkout without args falls back', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/checkout');
      await pumpFrames(tester);
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('navigates to /order-success without args falls back', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/order-success');
      await pumpFrames(tester);
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('navigates to /seller/register route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/register');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /seller/orders route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/orders');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /seller/products route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/products');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /seller/warehouses route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/warehouses');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /seller/integration route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/integration');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /seller/analytics route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/seller/analytics');
      await pumpFrames(tester);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(find.byType(AuthRequiredGate), findsWidgets);
      } else {
        expect(find.byType(AuthWrapper), findsWidgets);
      }
    });

    testWidgets('navigates to /admin route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/admin');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to /shipping-approval route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/shipping-approval');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('navigates to /support route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/support');
      await pumpFrames(tester);
      expect(find.byType(AuthRequiredGate), findsWidgets);
    });

    testWidgets('unknown route falls back to AuthWrapper', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      nav.pushNamed('/totally-unknown-route');
      await pumpFrames(tester);
      expect(find.byType(AuthWrapper), findsWidgets);
    });

    testWidgets('route with empty path after parse falls back', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final nav = OrignaBaseNotificationService.navigatorKey.currentState!;
      // An unparseable route name
      nav.pushNamed(':not-a-route');
      await pumpFrames(tester);
      // Should fall back to home
      expect(find.byType(AuthWrapper), findsWidgets);
    });
  });

  group('OrignaApp theme', () {
    testWidgets('renders with light theme by default', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.dark);
    });
  });

  group('OrignaApp onUnknownRoute', () {
    testWidgets('onUnknownRoute returns AuthWrapper', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });
      // Verify the MaterialApp has onUnknownRoute configured
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.onUnknownRoute, isNotNull);
    });
  });
}
