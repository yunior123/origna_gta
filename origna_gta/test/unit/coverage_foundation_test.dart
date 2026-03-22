import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_cart_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_location_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_order_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_product_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_user_repository.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/core/errors/error_codes.dart';
import 'package:origna_gta/core/compat/timestamp.dart';
import 'package:origna_gta/models/generated/models.dart' hide Address;
import 'package:origna_gta/models/models.dart' as models;
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/services/push_transport.dart';
import 'package:origna_gta/services/turnstile_service.dart';
import 'package:origna_gta/services/turnstile_service_stub.dart';
import 'package:origna_gta/services/web_auth_redirect_stub.dart';
import 'package:orignabase/orignabase.dart';

import 'mfa_viewmodel_test.mocks.dart' as mfa_mocks;

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({this.addresses = const []});

  final List<models.Address> addresses;

  @override
  Future<String> addBuyerAddress(models.Address address) async => 'addr-1';

  @override
  Future<void> deleteBuyerAddress(String addressId) async {}

  @override
  Future<SellerAccountStatus> getSellerAccountStatus(String userId) async =>
      const SellerAccountStatus(isSeller: false, chargesEnabled: false);

  @override
  Future<models.UserModel?> getUserProfile(String userId) async => null;

  @override
  Future<void> recordTermsAcceptance() async {}

  @override
  Future<void> setDefaultBuyerAddress(String addressId) async {}

  @override
  Future<void> updateBuyerAddress(
    String addressId,
    models.Address address,
  ) async {}

  @override
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? notifyNewProducts,
    bool? notifyTrending,
  }) async {}

  @override
  Future<void> updatePreferredLanguage(String userId, String lang) async {}

  @override
  Stream<List<models.Address>> watchAddresses(String userId) =>
      Stream.value(addresses);

  @override
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId) =>
      Stream.value(
        const SellerAccountStatus(isSeller: false, chargesEnabled: false),
      );
}

void main() {
  group('Foundation coverage targets', () {
    test('ErrorCodes.describe resolves known and unknown codes', () {
      expect(
        ErrorCodes.describe(ErrorCodes.authEmailInUse),
        contains('already registered'),
      );
      expect(
        ErrorCodes.describe('ORIGNA-UNKNOWN-404'),
        'Unexpected error. Please try again.',
      );
    });

    test('Timestamp supports conversion, equality, parsing, and truncation', () {
      final date = DateTime.utc(2026, 3, 19, 12, 34, 56, 789, 123);
      final timestamp = Timestamp.fromDate(date);
      final sameTimestamp = Timestamp.fromDate(date);
      final laterTimestamp = Timestamp.fromDate(
        date.add(const Duration(seconds: 1)),
      );

      expect(timestamp.toDate(), date);
      expect(timestamp.millisecondsSinceEpoch, date.millisecondsSinceEpoch);
      expect(timestamp.seconds, date.millisecondsSinceEpoch ~/ 1000);
      expect(timestamp.compareTo(sameTimestamp), 0);
      expect(timestamp.compareTo(laterTimestamp), lessThan(0));
      expect(timestamp, sameTimestamp);
      expect(timestamp.hashCode, sameTimestamp.hashCode);
      expect(timestamp.toString(), contains('Timestamp('));
      expect(Timestamp.now().toDate(), isA<DateTime>());

      expect(
        truncateNanoseconds('2026-03-12T11:56:03.185238962+00:00'),
        '2026-03-12T11:56:03.185238+00:00',
      );
      expect(
        truncateNanoseconds('2026-03-12T11:56:03.185238+00:00'),
        '2026-03-12T11:56:03.185238+00:00',
      );
      expect(parseTimestamp(null), isNull);
      expect(parseTimestamp(date), date);
      expect(
        parseTimestamp('2026-03-12T11:56:03.185238962+00:00'),
        DateTime.parse('2026-03-12T11:56:03.185238+00:00'),
      );
      expect(
        parseTimestamp(date.millisecondsSinceEpoch),
        DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch),
      );
      expect(parseTimestamp(const Object()), isNull);
    });

    test('push transport no-op client returns denied defaults', () async {
      const client = NoopPushMessagingClient();
      const notification = AppRemoteNotification(title: 'Hello', body: 'Body');
      const message = AppRemoteMessage(
        messageId: 'm1',
        data: {'kind': 'support'},
        notification: notification,
      );

      expect(notification.title, 'Hello');
      expect(notification.body, 'Body');
      expect(message.messageId, 'm1');
      expect(message.data['kind'], 'support');
      expect(message.notification, notification);

      expect(await client.getToken(), isNull);
      expect(await client.getInitialMessage(), isNull);
      expect(
        (await client.requestPermission()).authorizationStatus,
        AppNotificationAuthorizationStatus.denied,
      );
      expect(await client.onTokenRefresh.isEmpty, isTrue);
    });

    test('stubbed web integration helpers are safe no-ops', () async {
      expect(await getTurnstileTokenFromJs(), isNull);
      expect(await TurnstileService.getToken(), isNull);
      expect(resetTurnstileWidget, returnsNormally);
      expect(TurnstileService.reset, returnsNormally);
      expect(
        () => clearWebAuthCallbackFragment('https://orignagta.ca/#access'),
        returnsNormally,
      );
    });

    test('route argument types preserve payloads', () {
      final product = Product(
        productId: 'p1',
        name: 'Honey',
        price: 1000 / 100.0,
        imageUrls: const ['images/33.png'],
        description: 'Sweet honey',
        sellerId: 'seller-1',
        stockQuantity: 3,
        categoryId: 1,
        createdAt: DateTime.utc(2026, 3, 19),
      );
      final cartItem = models.CartItemDetailModel(
        productId: 'p1',
        name: 'Honey',
        description: 'Sweet honey',
        price: 1000 / 100.0,
        imageUrls: const ['images/33.png'],
        quantity: 2,
        createdAt: DateTime.utc(2026, 3, 19),
        sellerAddress: models.Address(
          street: '1 Main',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1M1M1',
          country: 'CA',
        ),
        sellerId: 'seller-1',
        sellerName: 'Seller',
      );

      const chatArgs = ChatArgs(productId: 'p1', productTitle: 'Honey');
      final checkoutArgs = CheckoutArgs(items: [cartItem], total: 20);
      final editArgs = EditProductArgs(product: product);
      const orderDetailArgs = OrderDetailArgs(orderId: 'o1');
      const returnArgs = ReturnRequestArgs(orderId: 'o1');
      const productDetailsArgs = ProductDetailsArgs(
        productId: 'p1',
        product: {'name': 'Honey'},
      );
      const slugArgs = ProductSlugArgs(slug: 'honey');

      expect(chatArgs.productTitle, 'Honey');
      expect(checkoutArgs.items.single.productId, 'p1');
      expect(checkoutArgs.total, 20);
      expect(editArgs.product.productId, 'p1');
      expect(orderDetailArgs.orderId, 'o1');
      expect(returnArgs.orderId, 'o1');
      expect(productDetailsArgs.product!['name'], 'Honey');
      expect(slugArgs.slug, 'honey');

      expect(AppRoutes.home, '/');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.cart, '/cart');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.orders, '/orders');
      expect(AppRoutes.orderDetail, '/orders/detail');
      expect(AppRoutes.addProduct, '/add-product');
      expect(AppRoutes.editProduct, '/edit-product');
      expect(AppRoutes.productDetails, '/product-details');
      expect(AppRoutes.addressManagement, '/addresses');
      expect(AppRoutes.addEditAddress, '/address/edit');
      expect(AppRoutes.checkout, '/checkout');
      expect(AppRoutes.orderSuccess, '/order-success');
      expect(AppRoutes.shippingApproval, '/shipping-approval');
      expect(AppRoutes.sellerRegistration, '/seller/register');
      expect(AppRoutes.sellerOrders, '/seller/orders');
      expect(AppRoutes.sellerProducts, '/seller/products');
      expect(AppRoutes.sellerBulkUpload, '/seller/bulk-upload');
      expect(AppRoutes.sellerWarehouses, '/seller/warehouses');
      expect(AppRoutes.sellerIntegration, '/seller/integration');
      expect(AppRoutes.sellerAnalytics, '/seller/analytics');
      expect(AppRoutes.favorites, '/favorites');
      expect(AppRoutes.adminPanel, '/admin');
      expect(AppRoutes.privacyPolicy, '/privacy-policy');
      expect(AppRoutes.termsOfService, '/terms-of-service');
      expect(AppRoutes.paymentSuccess, '/payment-success');
      expect(AppRoutes.paymentCancel, '/payment-cancel');
      expect(AppRoutes.sellerReturn, '/seller/return');
      expect(AppRoutes.sellerRefresh, '/seller/refresh');
      expect(AppRoutes.productBySlug, '/p');
      expect(AppRoutes.productById, '/product');
      expect(AppRoutes.subscription, '/subscription');
      expect(AppRoutes.subscriptionSuccess, '/subscription/success');
      expect(AppRoutes.subscriptionCancel, '/subscription/cancel');
      expect(AppRoutes.chat, '/chat');
      expect(AppRoutes.chatInbox, '/chat/inbox');
      expect(AppRoutes.notifications, '/notifications');
      expect(AppRoutes.support, '/support');
      expect(AppRoutes.mfaSetup, '/mfa/setup');
      expect(AppRoutes.mfaChallenge, '/mfa/challenge');
      expect(AppRoutes.securitySettings, '/security-settings');
      expect(AppRoutes.returnRequest, '/orders/return-request');
    });

    test('provider model helpers parse and copy correctly', () async {
      const availability = PublicAuthProviderAvailability(
        enabled: true,
        clientIdConfigured: false,
        clientSecretConfigured: true,
      );
      const providerInfo = AppAuthProviderInfo('google.com');
      const authState = AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
        email: 'user@example.com',
        emailVerified: true,
      );
      final authUser = AppAuthUser.fromAuthState(authState).copyWith(
        providerData: const [providerInfo],
      );
      final parsedAvailability = PublicAuthProviderAvailability.fromJson({
        'enabled': true,
        'client_id_configured': true,
        'client_secret_configured': false,
      });
      final emptyAvailability = PublicAuthProviderAvailability.fromJson(null);

      expect(availability.enabled, isTrue);
      expect(providerInfo.providerId, 'google.com');
      expect(authUser.uid, 'user-1');
      expect(authUser.emailVerified, isTrue);
      expect(authUser.providerData.single.providerId, 'google.com');
      expect(parsedAvailability.clientIdConfigured, isTrue);
      expect(parsedAvailability.clientSecretConfigured, isFalse);
      expect(emptyAvailability.enabled, isFalse);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(authUser)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      expect(container.read(currentUserProvider)?.uid, 'user-1');
      expect(container.read(userIdProvider), 'user-1');
      expect(
        await container.read(googleAuthAvailabilityProvider.future),
        isA<PublicAuthProviderAvailability>(),
      );
    });

    test('repository providers and authStateProvider emit OrignaBase-backed values', () async {
      final mockOb = mfa_mocks.MockOrignaBase();
      final mockAuth = mfa_mocks.MockOrignaBaseAuth();
      final authController = StreamController<AuthState>();

      when(mockOb.auth).thenReturn(mockAuth);
      when(mockAuth.currentState).thenReturn(
        const AuthState(status: AuthStatus.unauthenticated),
      );
      when(mockAuth.authStateChanges).thenAnswer((_) => authController.stream);

      final container = ProviderContainer(
        overrides: [orignabaseProvider.overrideWithValue(mockOb)],
      );
      addTearDown(() async {
        await authController.close();
        container.dispose();
      });

      expect(container.read(authRepositoryProvider), isA<OrignaBaseAuthRepository>());
      expect(container.read(cartRepositoryProvider), isA<OrignaBaseCartRepository>());
      expect(container.read(orderRepositoryProvider), isA<OrignaBaseOrderRepository>());
      expect(container.read(productRepositoryProvider), isA<OrignaBaseProductRepository>());
      expect(container.read(userRepositoryProvider), isA<OrignaBaseUserRepository>());
      expect(container.read(locationRepositoryProvider), isA<OrignaBaseLocationRepository>());

      expect(await container.read(authStateProvider.future), isNull);

      authController.add(
        const AuthState(
          status: AuthStatus.authenticated,
          userId: 'user-2',
          email: 'user2@example.com',
          emailVerified: true,
        ),
      );

      AppAuthUser? authedUser;
      final listener = container.listen<AsyncValue<AppAuthUser?>>(
        authStateProvider,
        (_, next) {
          authedUser = next.valueOrNull;
        },
        fireImmediately: true,
      );
      addTearDown(listener.close);

      await Future<void>.delayed(Duration.zero);
      expect(authedUser?.email, 'user2@example.com');
    });

    test('userAddressesProvider returns empty list without a signed-in user', () async {
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(await container.read(userAddressesProvider.future), isEmpty);
    });

    test('userAddressesProvider forwards repository addresses for signed-in users', () async {
      final address = models.Address(
        street: '99 Queen St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5H2N2',
        country: 'CA',
      );
      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWith((ref) => 'user-9'),
          userRepositoryProvider.overrideWithValue(
            _FakeUserRepository(addresses: [address]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final addresses = await container.read(userAddressesProvider.future);
      expect(addresses.single.street, '99 Queen St');
    });

    test('schema constants expose expected values', () {
      expect(AddressLabelValues.home, 'Home');
      expect(AdminActionValues.paymentProviderUpdate, contains('payment'));
      expect(ApiKeys.turnstileToken, 'turnstileToken');
      expect(BusinessRules.sessionTimeoutMinutes, 15);
      expect(BusinessRules.taxRates['NS']?['HST'], 14.0);
      expect(CarrierValues.all, contains(CarrierValues.canadaPost));
      expect(CategoryIds.min, 1);
      expect(CategoryIds.max, 21);
    });
  });
}
