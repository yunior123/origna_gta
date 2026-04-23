/// Centralized route constants and navigation helpers for the app.
/// Web/runtime navigation should prefer GoRouter; tests can still fall back
/// to Navigator when no router is mounted.
///
/// NEVER pass raw `Map<String, dynamic>` as route arguments.
/// Use the typed classes below — they are compile-time safe.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:origna_gta/models/generated/models.dart' show Product;
import 'package:origna_gta/models/models.dart' show CartItemDetailModel;

/// Centralized route path constants. Never hardcode route strings in screens.
class AppRoutes {
  static const String home = '/';

  static const String productSlugParam = 'slug';
  static const String productIdParam = 'productId';
  static const String sellerIdParam = 'sellerId';
  static const String sellerProductsSegment = 'products';

  static const String login = '/login';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/detail';
  static const String addProduct = '/add-product';
  static const String editProduct = '/edit-product';
  static const String productDetails = '/product-details';
  static const String addressManagement = '/addresses';
  static const String addEditAddress = '/address/edit';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String shippingApproval = '/shipping-approval';
  static const String sellerRegistration = '/seller/register';
  // BOOT-L2: sellerSetup route removed — screen not implemented
  static const String sellerOrders = '/seller/orders';
  static const String sellerProducts = '/seller/products';
  static const String sellerBulkUpload = '/seller/bulk-upload';
  static const String sellerWarehouses = '/seller/warehouses';
  static const String sellerIntegration = '/seller/integration';
  static const String sellerAnalytics = '/seller/analytics';
  static const String favorites = '/favorites';
  static const String adminPanel = '/admin';
  static const String adminSellerProducts = '/admin/sellers';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String paymentSuccess = '/payment-success';
  static const String paymentCancel = '/payment-cancel';
  static const String sellerReturn = '/seller/return';
  static const String sellerRefresh = '/seller/refresh';
  static const String productBySlug = '/p';
  static const String productById = '/product';
  static const String subscription = '/subscription';
  static const String subscriptionSuccess = '/subscription/success';
  static const String subscriptionCancel = '/subscription/cancel';
  static const String chat = '/chat';
  static const String chatInbox = '/chat/inbox';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String mfaSetup = '/mfa/setup';
  static const String mfaChallenge = '/mfa/challenge';
  static const String securitySettings = '/security-settings';
  static const String returnRequest = '/orders/return-request';

  static String get productBySlugPattern => '$productBySlug/:$productSlugParam';
  static String get productByIdPattern => '$productById/:$productIdParam';
  static String get adminSellerProductsPattern =>
      '$adminSellerProducts/:$sellerIdParam/$sellerProductsSegment';

  static String productByIdPath(String productId) => '$productById/$productId';
  static String productBySlugPath(String slug) => '$productBySlug/$slug';
  static String adminSellerProductsPath(String sellerId, {String? sellerName}) {
    return Uri(
      path: '$adminSellerProducts/$sellerId/$sellerProductsSegment',
      queryParameters: sellerName == null || sellerName.isEmpty
          ? null
          : <String, String>{'name': sellerName},
    ).toString();
  }
  AppRoutes._(); // Prevent instantiation
}

Future<T?> appPushNamed<T extends Object?>(
  BuildContext context,
  String route, {
  Object? arguments,
}) {
  final targetContext = _resolveNavigationContext(context);
  final resolvedRoute = _normalizeRoute(route);
  final router = GoRouter.maybeOf(targetContext);
  if (router != null) {
    if (kIsWeb) {
      targetContext.go(resolvedRoute, extra: arguments);
      return Future<T?>.value(null);
    }
    return targetContext.push<T>(resolvedRoute, extra: arguments);
  }
  return Navigator.of(
    targetContext,
    rootNavigator: true,
  ).pushNamed<T>(resolvedRoute, arguments: arguments);
}

Future<T?> appPushReplacementNamed<T extends Object?, TO extends Object?>(
  BuildContext context,
  String route, {
  TO? result,
  Object? arguments,
}) async {
  final targetContext = _resolveNavigationContext(context);
  final resolvedRoute = _normalizeRoute(route);
  final router = GoRouter.maybeOf(targetContext);
  if (router != null) {
    targetContext.pushReplacement(resolvedRoute, extra: arguments);
    return null;
  }
  return Navigator.of(
    targetContext,
    rootNavigator: true,
  ).pushReplacementNamed<T, TO>(
    resolvedRoute,
    arguments: arguments,
    result: result,
  );
}

void appGoNamed(BuildContext context, String route, {Object? arguments}) {
  final targetContext = _resolveNavigationContext(context);
  final resolvedRoute = _normalizeRoute(route);
  final router = GoRouter.maybeOf(targetContext);
  if (router != null) {
    targetContext.go(resolvedRoute, extra: arguments);
    return;
  }
  Navigator.of(
    targetContext,
    rootNavigator: true,
  ).pushNamed(resolvedRoute, arguments: arguments);
}

void appPushNamedAndRemoveUntil(
  BuildContext context,
  String route,
  bool Function(Route<dynamic>) predicate, {
  Object? arguments,
}) {
  final targetContext = _resolveNavigationContext(context);
  final resolvedRoute = _normalizeRoute(route);
  final router = GoRouter.maybeOf(targetContext);
  if (router != null) {
    targetContext.go(resolvedRoute, extra: arguments);
    return;
  }
  Navigator.of(
    targetContext,
    rootNavigator: true,
  ).pushNamedAndRemoveUntil(resolvedRoute, predicate, arguments: arguments);
}

String _normalizeRoute(String route) {
  final trimmed = route.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('/')) {
    return AppRoutes.home;
  }
  return trimmed;
}

bool appPop<T extends Object?>(BuildContext context, [T? result]) {
  final localNavigator = Navigator.maybeOf(context);
  if (localNavigator != null && localNavigator.canPop()) {
    localNavigator.pop(result);
    return true;
  }

  final targetContext = _resolveNavigationContext(context);
  final router = GoRouter.maybeOf(targetContext);
  if (router != null && router.canPop()) {
    targetContext.pop(result);
    return true;
  }

  final rootNavigator = Navigator.maybeOf(targetContext, rootNavigator: true);
  if (rootNavigator != null && rootNavigator.canPop()) {
    rootNavigator.pop(result);
    return true;
  }
  return false;
}

void appPopOrGo(
  BuildContext context,
  String fallbackRoute, {
  Object? arguments,
}) {
  if (appPop(context)) {
    return;
  }

  final targetContext = _resolveNavigationContext(context);
  final resolvedRoute = _normalizeRoute(fallbackRoute);
  final router = GoRouter.maybeOf(targetContext);
  if (router != null) {
    targetContext.go(resolvedRoute, extra: arguments);
    return;
  }
  Navigator.of(targetContext, rootNavigator: true).pushNamedAndRemoveUntil(
    resolvedRoute,
    (route) => false,
    arguments: arguments,
  );
}

BuildContext _resolveNavigationContext(BuildContext context) {
  final rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
  final rootContext = rootNavigator?.context;
  if (rootContext != null && GoRouter.maybeOf(rootContext) != null) {
    return rootContext;
  }
  return context;
}

// ─── Typed route arguments ─────────────────────────────────────────

/// Arguments for [AppRoutes.chat].
class ChatArgs {
  final String productId;
  final String productTitle;
  const ChatArgs({required this.productId, required this.productTitle});
}

/// Arguments for [AppRoutes.checkout].
class CheckoutArgs {
  final List<CartItemDetailModel> items;
  final int totalCents;

  const CheckoutArgs({required this.items, required this.totalCents});
}

/// Arguments for [AppRoutes.editProduct].
/// Wraps [Product] for consistency and future extensibility.
class EditProductArgs {
  final Product product;

  const EditProductArgs({required this.product});
}

/// Arguments for [AppRoutes.orderDetail].
class OrderDetailArgs {
  final String orderId;
  const OrderDetailArgs({required this.orderId});
}

/// Arguments for [AppRoutes.returnRequest].
class ReturnRequestArgs {
  final String orderId;
  const ReturnRequestArgs({required this.orderId});
}

/// Arguments for [AppRoutes.productDetails].
class ProductDetailsArgs {
  final String productId;
  final Map<String, dynamic>? product;

  const ProductDetailsArgs({required this.productId, this.product});
}

/// Arguments for [AppRoutes.mfaChallenge].
class MfaChallengeArgs {
  final String challengeToken;
  const MfaChallengeArgs({required this.challengeToken});
}

/// Arguments for [AppRoutes.productBySlug].
class ProductSlugArgs {
  final String slug;
  const ProductSlugArgs({required this.slug});
}
