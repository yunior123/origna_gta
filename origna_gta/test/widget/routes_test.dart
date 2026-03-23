import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/routes.dart';

void main() {
  group('AppRoutes', () {
    test('home route is correct', () {
      expect(AppRoutes.home, '/');
    });

    test('login route is correct', () {
      expect(AppRoutes.login, '/login');
    });

    test('cart route is correct', () {
      expect(AppRoutes.cart, '/cart');
    });

    test('profile route is correct', () {
      expect(AppRoutes.profile, '/profile');
    });

    test('orders route is correct', () {
      expect(AppRoutes.orders, '/orders');
    });

    test('orderDetail route is correct', () {
      expect(AppRoutes.orderDetail, '/orders/detail');
    });

    test('addProduct route is correct', () {
      expect(AppRoutes.addProduct, '/add-product');
    });

    test('editProduct route is correct', () {
      expect(AppRoutes.editProduct, '/edit-product');
    });

    test('productDetails route is correct', () {
      expect(AppRoutes.productDetails, '/product-details');
    });

    test('addressManagement route is correct', () {
      expect(AppRoutes.addressManagement, '/addresses');
    });

    test('addEditAddress route is correct', () {
      expect(AppRoutes.addEditAddress, '/address/edit');
    });

    test('checkout route is correct', () {
      expect(AppRoutes.checkout, '/checkout');
    });

    test('orderSuccess route is correct', () {
      expect(AppRoutes.orderSuccess, '/order-success');
    });

    test('shippingApproval route is correct', () {
      expect(AppRoutes.shippingApproval, '/shipping-approval');
    });

    test('sellerRegistration route is correct', () {
      expect(AppRoutes.sellerRegistration, '/seller/register');
    });

    test('sellerOrders route is correct', () {
      expect(AppRoutes.sellerOrders, '/seller/orders');
    });

    test('sellerProducts route is correct', () {
      expect(AppRoutes.sellerProducts, '/seller/products');
    });

    test('sellerBulkUpload route is correct', () {
      expect(AppRoutes.sellerBulkUpload, '/seller/bulk-upload');
    });

    test('sellerWarehouses route is correct', () {
      expect(AppRoutes.sellerWarehouses, '/seller/warehouses');
    });

    test('sellerIntegration route is correct', () {
      expect(AppRoutes.sellerIntegration, '/seller/integration');
    });

    test('sellerAnalytics route is correct', () {
      expect(AppRoutes.sellerAnalytics, '/seller/analytics');
    });

    test('favorites route is correct', () {
      expect(AppRoutes.favorites, '/favorites');
    });

    test('adminPanel route is correct', () {
      expect(AppRoutes.adminPanel, '/admin');
    });

    test('privacyPolicy route is correct', () {
      expect(AppRoutes.privacyPolicy, '/privacy-policy');
    });

    test('termsOfService route is correct', () {
      expect(AppRoutes.termsOfService, '/terms-of-service');
    });

    test('paymentSuccess route is correct', () {
      expect(AppRoutes.paymentSuccess, '/payment-success');
    });

    test('paymentCancel route is correct', () {
      expect(AppRoutes.paymentCancel, '/payment-cancel');
    });

    test('sellerReturn route is correct', () {
      expect(AppRoutes.sellerReturn, '/seller/return');
    });

    test('sellerRefresh route is correct', () {
      expect(AppRoutes.sellerRefresh, '/seller/refresh');
    });

    test('productBySlug route is correct', () {
      expect(AppRoutes.productBySlug, '/p');
    });

    test('productById route is correct', () {
      expect(AppRoutes.productById, '/product');
    });

    test('subscription route is correct', () {
      expect(AppRoutes.subscription, '/subscription');
    });

    test('subscriptionSuccess route is correct', () {
      expect(AppRoutes.subscriptionSuccess, '/subscription/success');
    });

    test('subscriptionCancel route is correct', () {
      expect(AppRoutes.subscriptionCancel, '/subscription/cancel');
    });

    test('chat route is correct', () {
      expect(AppRoutes.chat, '/chat');
    });

    test('chatInbox route is correct', () {
      expect(AppRoutes.chatInbox, '/chat/inbox');
    });

    test('notifications route is correct', () {
      expect(AppRoutes.notifications, '/notifications');
    });

    test('support route is correct', () {
      expect(AppRoutes.support, '/support');
    });

    test('mfaSetup route is correct', () {
      expect(AppRoutes.mfaSetup, '/mfa/setup');
    });

    test('mfaChallenge route is correct', () {
      expect(AppRoutes.mfaChallenge, '/mfa/challenge');
    });

    test('securitySettings route is correct', () {
      expect(AppRoutes.securitySettings, '/security-settings');
    });

    test('returnRequest route is correct', () {
      expect(AppRoutes.returnRequest, '/orders/return-request');
    });

    test('all routes are unique', () {
      final routes = <String>[
        AppRoutes.home,
        AppRoutes.login,
        AppRoutes.cart,
        AppRoutes.profile,
        AppRoutes.orders,
        AppRoutes.orderDetail,
        AppRoutes.addProduct,
        AppRoutes.editProduct,
        AppRoutes.productDetails,
        AppRoutes.addressManagement,
        AppRoutes.addEditAddress,
        AppRoutes.checkout,
        AppRoutes.orderSuccess,
        AppRoutes.shippingApproval,
        AppRoutes.sellerRegistration,
        AppRoutes.sellerOrders,
        AppRoutes.sellerProducts,
        AppRoutes.sellerBulkUpload,
        AppRoutes.sellerWarehouses,
        AppRoutes.sellerIntegration,
        AppRoutes.sellerAnalytics,
        AppRoutes.favorites,
        AppRoutes.adminPanel,
        AppRoutes.privacyPolicy,
        AppRoutes.termsOfService,
        AppRoutes.paymentSuccess,
        AppRoutes.paymentCancel,
        AppRoutes.sellerReturn,
        AppRoutes.sellerRefresh,
        AppRoutes.productBySlug,
        AppRoutes.productById,
        AppRoutes.subscription,
        AppRoutes.subscriptionSuccess,
        AppRoutes.subscriptionCancel,
        AppRoutes.chat,
        AppRoutes.chatInbox,
        AppRoutes.notifications,
        AppRoutes.support,
        AppRoutes.mfaSetup,
        AppRoutes.mfaChallenge,
        AppRoutes.securitySettings,
        AppRoutes.returnRequest,
      ];
      final uniqueRoutes = routes.toSet();
      expect(
        routes.length,
        uniqueRoutes.length,
        reason: 'All routes should be unique',
      );
    });

    test('all routes start with /', () {
      final routes = <String>[
        AppRoutes.home,
        AppRoutes.login,
        AppRoutes.cart,
        AppRoutes.profile,
        AppRoutes.orders,
        AppRoutes.orderDetail,
        AppRoutes.addProduct,
        AppRoutes.editProduct,
        AppRoutes.productDetails,
        AppRoutes.addressManagement,
        AppRoutes.addEditAddress,
        AppRoutes.checkout,
        AppRoutes.orderSuccess,
        AppRoutes.shippingApproval,
        AppRoutes.sellerRegistration,
        AppRoutes.sellerOrders,
        AppRoutes.sellerProducts,
        AppRoutes.sellerBulkUpload,
        AppRoutes.sellerWarehouses,
        AppRoutes.sellerIntegration,
        AppRoutes.sellerAnalytics,
        AppRoutes.favorites,
        AppRoutes.adminPanel,
        AppRoutes.privacyPolicy,
        AppRoutes.termsOfService,
        AppRoutes.paymentSuccess,
        AppRoutes.paymentCancel,
        AppRoutes.sellerReturn,
        AppRoutes.sellerRefresh,
        AppRoutes.productBySlug,
        AppRoutes.productById,
        AppRoutes.subscription,
        AppRoutes.subscriptionSuccess,
        AppRoutes.subscriptionCancel,
        AppRoutes.chat,
        AppRoutes.chatInbox,
        AppRoutes.notifications,
        AppRoutes.support,
        AppRoutes.mfaSetup,
        AppRoutes.mfaChallenge,
        AppRoutes.securitySettings,
        AppRoutes.returnRequest,
      ];
      for (final route in routes) {
        expect(
          route.startsWith('/'),
          isTrue,
          reason: 'Route $route should start with /',
        );
      }
    });
  });

  group('ChatArgs', () {
    test('creates with required parameters', () {
      const args = ChatArgs(productId: 'p1', productTitle: 'Test Product');
      expect(args.productId, 'p1');
      expect(args.productTitle, 'Test Product');
    });

    test('const constructor works', () {
      const args = ChatArgs(productId: 'p1', productTitle: 'Test');
      expect(args.productId, 'p1');
    });
  });

  group('CheckoutArgs', () {
    test('creates with required parameters', () {
      const args = CheckoutArgs(items: [], total: 100.0);
      expect(args.items, isEmpty);
      expect(args.total, 100.0);
    });

    test('const constructor works', () {
      const args = CheckoutArgs(items: [], total: 0.0);
      expect(args.items, isEmpty);
    });
  });

  group('OrderDetailArgs', () {
    test('creates with required orderId', () {
      const args = OrderDetailArgs(orderId: 'order123');
      expect(args.orderId, 'order123');
    });

    test('const constructor works', () {
      const args = OrderDetailArgs(orderId: 'order123');
      expect(args.orderId, 'order123');
    });
  });

  group('ReturnRequestArgs', () {
    test('creates with required orderId', () {
      const args = ReturnRequestArgs(orderId: 'order123');
      expect(args.orderId, 'order123');
    });

    test('const constructor works', () {
      const args = ReturnRequestArgs(orderId: 'order123');
      expect(args.orderId, 'order123');
    });
  });

  group('ProductDetailsArgs', () {
    test('creates with required productId', () {
      const args = ProductDetailsArgs(productId: 'p1');
      expect(args.productId, 'p1');
      expect(args.product, isNull);
    });

    test('creates with optional product map', () {
      const args = ProductDetailsArgs(
        productId: 'p1',
        product: {'name': 'Test'},
      );
      expect(args.productId, 'p1');
      expect(args.product, isNotNull);
      expect(args.product!['name'], 'Test');
    });

    test('const constructor works', () {
      const args = ProductDetailsArgs(productId: 'p1');
      expect(args.productId, 'p1');
    });
  });

  group('ProductSlugArgs', () {
    test('creates with required slug', () {
      const args = ProductSlugArgs(slug: 'test-product');
      expect(args.slug, 'test-product');
    });

    test('const constructor works', () {
      const args = ProductSlugArgs(slug: 'test-product');
      expect(args.slug, 'test-product');
    });
  });
}
