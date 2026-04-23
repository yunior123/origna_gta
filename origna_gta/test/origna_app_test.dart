import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/services/orignabase_notification_service.dart';
import 'package:origna_gta/services/push_transport.dart';
import 'package:origna_gta/services/session_timeout_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_asset_loader.dart';
@GenerateNiceMocks([
  MockSpec<PushMessagingClient>(),
  MockSpec<ProductRepository>(),
])
import 'origna_app_test.mocks.dart';

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

    // Reset the singleton service and its keys
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
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
        path: 'assets/translations',
        assetLoader: MockAssetLoader(),
        startLocale: const Locale('en'),
        child: const OrignaApp(),
      ),
    );
  }

  group('OrignaApp Tests', () {
    testWidgets('renders and navigates correctly', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(seconds: 2));
      });

      expect(find.byType(OrignaApp), findsOneWidget);

      final nav = OrignaBaseNotificationService.navigatorKey.currentState;
      expect(nav, isNotNull, reason: 'Navigator state should not be null');

      Future<void> pumpRobust() async {
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
      }

      // 1. Login
      nav!.pushNamed(AppRoutes.login);
      await pumpRobust();
      expect(find.byType(LoginScreen), findsOneWidget);
      nav.pop();
      await pumpRobust();

      // 2. Privacy Policy
      nav.pushNamed(AppRoutes.privacyPolicy);
      await pumpRobust();
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      nav.pop();
      await pumpRobust();

      // 3. Cart
      nav.pushNamed(AppRoutes.cart);
      await pumpRobust();
      expect(find.textContaining('sign in'), findsWidgets);
      nav.pop();
      await pumpRobust();

      // 4. Product Slug
      nav.pushNamed(AppRoutes.productBySlugPath('test-product-slug'));
      await pumpRobust();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });
  });
}
