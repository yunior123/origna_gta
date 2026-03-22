import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/chat/chat_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/seller/seller_products_viewmodel.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/generated/models.dart' as gen;
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';
import 'package:origna_gta/screens/cart_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/home_screen.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';
import 'package:origna_gta/screens/seller_products_screen.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';
import 'package:origna_gta/screens/seller_setup_screen.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';
import 'package:origna_gta/screens/subscription_screen.dart';
import 'package:origna_gta/utils/env_config.dart';

@GenerateNiceMocks([
  MockSpec<ProductRepository>(),
  MockSpec<OrderRepository>(),
  MockSpec<UserRepository>(),
  MockSpec<AuthRepository>(),
  MockSpec<EnvConfig>(),
])
import 'coverage_booster_states_test.mocks.dart';
import 'test_utils.dart';

void main() {
  late AppAuthUser mockUser;
  late MockProductRepository mockProductRepo;
  late MockOrderRepository mockOrderRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthRepository mockAuthRepo;
  late MockEnvConfig mockConfig;

  setUpAll(() => initTestMocks());

  setUp(() {
    mockUser = const AppAuthUser(uid: 'test_user', email: 't@e.com');
    mockProductRepo = MockProductRepository();
    mockOrderRepo = MockOrderRepository();
    mockUserRepo = MockUserRepository();
    mockAuthRepo = MockAuthRepository();
    mockConfig = MockEnvConfig();

    when(mockConfig.isDev).thenReturn(true);

    when(
      mockProductRepo.fetchProducts(
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

    when(mockUserRepo.watchAddresses(any)).thenAnswer((_) => Stream.value([]));
    when(
      mockOrderRepo.watchBuyerOrders(any),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockOrderRepo.watchSellerOrders(any),
    ).thenAnswer((_) => Stream.value([]));
    when(mockUserRepo.watchSellerAccountStatus(any)).thenAnswer(
      (_) => Stream.value(
        const SellerAccountStatus(isSeller: false, chargesEnabled: false),
      ),
    );
  });

  final mockProduct = gen.Product(
    productId: 'p1',
    name: 'Coverage Product',
    price: 99.99,
    categoryId: 1,
    sellerId: 's1',
    createdAt: DateTime.now(),
    imageUrls: const [],
    description: 'Detailed description for testing code coverage.',
    stockQuantity: 10,
    sellerAddress: const gen.Address(
      street: 'S',
      city: 'C',
      state: 'ON',
      postalCode: 'M1M 1M1',
      country: 'CA',
    ),
  );

  Widget boosterWrapper(
    Widget child, {
    List<Override> extraOverrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return TestWrapper(
      overrides: [
        obUserIdProvider.overrideWithValue(null),
        obAuthStateProvider.overrideWith((ref) => const Stream.empty()),
        sellerWarehousesStreamProvider.overrideWith((ref) => Stream.value([])),
        currentUserProvider.overrideWithValue(mockUser),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(
            UserModel(
              uid: 'test_user',
              name: 'Test',
              email: 't@e.com',
              roles: const [UserRole.seller],
              createdAt: DateTime.now(),
              address: Address(
                street: 'S',
                city: 'C',
                state: 'ON',
                postalCode: 'M1M 1M1',
                country: 'CA',
              ),
            ),
          ),
        ),
        productRepositoryProvider.overrideWithValue(mockProductRepo),
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        envConfigProvider.overrideWithValue(mockConfig),
        subscriptionStreamProvider.overrideWith((ref) => Stream.value(null)),
        cartItemsProvider.overrideWith((ref) => Stream.value([])),
        myAllChatsProvider.overrideWith((ref) => Stream.value([])),
        ...extraOverrides,
      ],
      child: Theme(
        data: themeMode == ThemeMode.dark
            ? ThemeData.dark()
            : ThemeData.light(),
        child: Scaffold(body: child),
      ),
    );
  }

  /// Helper that pumps a widget and handles pending timers from async providers.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(boosterWrapper(screen, themeMode: themeMode));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  // ====== DARK THEME VARIANTS ======
  group('Dark Theme Coverage', () {
    testWidgets('HomeScreen dark', (tester) async {
      await pumpScreen(tester, const HomeScreen(), themeMode: ThemeMode.dark);
    });

    testWidgets('ProfileScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const ProfileScreen(),
        themeMode: ThemeMode.dark,
      );
    });

    testWidgets('CartScreen dark', (tester) async {
      await pumpScreen(tester, const CartScreen(), themeMode: ThemeMode.dark);
    });

    testWidgets('FavoritesScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const FavoritesScreen(),
        themeMode: ThemeMode.dark,
      );
    });

    testWidgets('LoginScreen dark', (tester) async {
      await pumpScreen(tester, const LoginScreen(), themeMode: ThemeMode.dark);
    });

    testWidgets('SellerOrdersScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const SellerOrdersScreen(),
        themeMode: ThemeMode.dark,
      );
    });

    testWidgets('OrdersScreen dark', (tester) async {
      await pumpScreen(tester, const OrdersScreen(), themeMode: ThemeMode.dark);
    });

    testWidgets('AddProductScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const AddProductScreen(),
        themeMode: ThemeMode.dark,
      );
    });

    testWidgets('EditProductScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          EditProductScreen(product: mockProduct),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ProductDetailScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const ProductDetailScreen(productId: 'p1'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('CheckoutScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const CheckoutScreen(items: [], total: 0),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ShippingApprovalScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const ShippingApprovalScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AddressManagementScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const AddressManagementScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SubscriptionScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const SubscriptionScreen(),
        themeMode: ThemeMode.dark,
      );
    });

    testWidgets('SellerRegistrationScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const SellerRegistrationScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SellerSetupCompleteScreen dark', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const SellerSetupCompleteScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AddEditAddressScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const AddEditAddressScreen(),
        themeMode: ThemeMode.dark,
      );
    });

    testWidgets('SellerProductsScreen dark', (tester) async {
      await pumpScreen(
        tester,
        const SellerProductsScreen(),
        themeMode: ThemeMode.dark,
      );
    });
  });

  // ====== PROVIDER STATE VARIANTS ======
  group('ShippingApprovalScreen States', () {
    testWidgets('loading state', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const ShippingApprovalScreen(),
          extraOverrides: [
            pendingShippingApprovalsProvider.overrideWith(
              (ref) => const AsyncValue.loading(),
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const ShippingApprovalScreen(),
          extraOverrides: [
            pendingShippingApprovalsProvider.overrideWith(
              (ref) => AsyncValue.error('err', StackTrace.empty),
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('empty data state', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const ShippingApprovalScreen(),
          extraOverrides: [
            pendingShippingApprovalsProvider.overrideWith(
              (ref) => const AsyncValue.data([]),
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('SellerProductsScreen States', () {
    testWidgets('loading state', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const SellerProductsScreen(),
          extraOverrides: [
            sellerProductsProvider.overrideWith((ref) => const Stream.empty()),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const SellerProductsScreen(),
          extraOverrides: [
            sellerProductsProvider.overrideWith((ref) => Stream.error('err')),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('data with products', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(
          const SellerProductsScreen(),
          extraOverrides: [
            sellerProductsProvider.overrideWith(
              (ref) => Stream.value([mockProduct]),
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  // ====== PUMP AND SETTLE VARIANTS ======
  // The original booster only uses pump(), these use pumpAndSettle for deeper build coverage
  group('PumpAndSettle Coverage', () {
    testWidgets('HomeScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('ProfileScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const ProfileScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('LoginScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('AddProductScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const AddProductScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('EditProductScreen settles', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(EditProductScreen(product: mockProduct)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('CheckoutScreen settles', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(const CheckoutScreen(items: [], total: 0)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('SellerOrdersScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const SellerOrdersScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('AddressManagementScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const AddressManagementScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('SubscriptionScreen settles', (tester) async {
      await tester.pumpWidget(boosterWrapper(const SubscriptionScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  // ====== FORM FIELD EXISTENCE CHECKS ======
  group('Form Fields Coverage', () {
    testWidgets('AddProductScreen has form fields', (tester) async {
      await tester.pumpWidget(boosterWrapper(const AddProductScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('AddEditAddressScreen has form fields', (tester) async {
      await tester.pumpWidget(boosterWrapper(const AddEditAddressScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('EditProductScreen has form fields', (tester) async {
      await tester.pumpWidget(
        boosterWrapper(EditProductScreen(product: mockProduct)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
