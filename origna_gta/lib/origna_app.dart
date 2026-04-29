import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:origna_gta/core/lifecycle_provider.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/theme_provider.dart';
// Deferred imports for code splitting — reduces initial JS bundle on Flutter Web
import 'package:origna_gta/features/admin/admin_panel_screen.dart'
    deferred as admin_panel;
import 'package:origna_gta/features/admin/tabs/admin_sellers_tab.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/screens/addproduct_screen.dart'
    deferred as add_product;
import 'package:origna_gta/screens/addressmanagement_screen.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/screens/cart_screen.dart';
import 'package:origna_gta/screens/chat_conversations_screen.dart';
import 'package:origna_gta/screens/chat_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart' deferred as checkout;
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/screens/editproduct_screen.dart'
    deferred as edit_product;
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/mfa_challenge_screen.dart';
import 'package:origna_gta/screens/mfa_setup_screen.dart';
import 'package:origna_gta/screens/security_settings_screen.dart';
import 'package:origna_gta/screens/notifications_screen.dart';
import 'package:origna_gta/features/support/support_screen.dart'
    deferred as support_chat;
import 'package:origna_gta/screens/order_detail_screen.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/screens/return_request_screen.dart';
import 'package:origna_gta/screens/payment_screens.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart'
    deferred as privacy;
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/screens/reset_password_screen.dart';
import 'package:origna_gta/screens/seller/bulk_upload_screen.dart'
    deferred as seller_bulk_upload;
import 'package:origna_gta/screens/seller/seller_analytics_screen.dart'
    deferred as seller_analytics;
import 'package:origna_gta/screens/seller/seller_warehouses_screen.dart'
    deferred as seller_warehouses;
import 'package:origna_gta/screens/seller_integration_screen.dart'
    deferred as seller_integration;
import 'package:origna_gta/screens/seller_orders_screen.dart'
    deferred as seller_orders;
import 'package:origna_gta/screens/seller_products_screen.dart'
    deferred as seller_products;
import 'package:origna_gta/screens/seller_registration_screen.dart'
    deferred as seller_reg;
import 'package:origna_gta/screens/seller_setup_screen.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart'
    deferred as shipping_approval;
import 'package:origna_gta/screens/subscription_cancel_screen.dart';
import 'package:origna_gta/screens/subscription_screen.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';
import 'package:origna_gta/screens/terms_of_service_screen.dart'
    deferred as terms;
import 'package:origna_gta/services/orignabase_notification_service.dart';
import 'package:origna_gta/services/session_timeout_service.dart';
import 'package:origna_gta/services/web_auth_redirect_stub.dart'
    if (dart.library.js_interop) 'package:origna_gta/services/web_auth_redirect_web.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/deferred_widget.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/app_update_service.dart';
import 'package:origna_gta/widgets/update_required_dialog.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/cookie_consent_banner.dart';

final _validResetPasswordOobCode = RegExp(r'^[A-Za-z0-9\-_]{10,512}$');

Map<String, String> extractWebOAuthCallbackParams(Uri uri) {
  if (uri.fragment.isNotEmpty) {
    return Uri.splitQueryString(uri.fragment);
  }

  final query = uri.queryParameters;
  if (query.containsKey(DeepLinkParams.obAccessToken) ||
      query.containsKey(DeepLinkParams.obRefreshToken)) {
    return query.map((key, value) => MapEntry(key, value));
  }

  return const <String, String>{};
}

String cleanedWebOAuthCallbackUrl(Uri uri) {
  final filteredQuery = Map<String, String>.from(uri.queryParameters)
    ..remove(DeepLinkParams.obAccessToken)
    ..remove(DeepLinkParams.obRefreshToken)
    ..remove('ob_provider')
    ..remove('ob_error')
    ..remove('ob_error_description');

  final hasDefaultPort =
      (uri.scheme == 'https' && uri.port == 443) ||
      (uri.scheme == 'http' && uri.port == 80);

  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort && !hasDefaultPort ? uri.port : null,
    path: uri.path,
    queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
  ).toString();
}

String resolvedWebOAuthCallbackRoute(Uri uri) {
  final cleanedUri = Uri.parse(cleanedWebOAuthCallbackUrl(uri));
  if (cleanedUri.path == AppRoutes.login) {
    final redirect = cleanedUri.queryParameters['redirect'];
    if (redirect != null && redirect.isNotEmpty) {
      final redirectUri = Uri.parse(redirect);
      return Uri(
        path: redirectUri.path.isEmpty ? AppRoutes.home : redirectUri.path,
        queryParameters: redirectUri.queryParameters.isEmpty
            ? null
            : redirectUri.queryParameters,
      ).toString();
    }
    return AppRoutes.home;
  }

  return Uri(
    path: cleanedUri.path.isEmpty ? AppRoutes.home : cleanedUri.path,
    queryParameters: cleanedUri.queryParameters.isEmpty
        ? null
        : cleanedUri.queryParameters,
  ).toString();
}

GoRoute _appRoute({
  required String path,
  required Widget Function(GoRouterState state) builder,
  bool animated = true,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        _buildRouterPage(state, builder(state), animated: animated),
  );
}

Widget _buildHomeScreen(GoRouterState state) {
  final oobCode = state.uri.queryParameters[DeepLinkParams.oobCode];
  if (state.uri.queryParameters[DeepLinkParams.mode] ==
          DeepLinkParams.modeResetPassword &&
      oobCode != null &&
      _validResetPasswordOobCode.hasMatch(oobCode)) {
    return ResetPasswordScreen(oobCode: oobCode);
  }
  return const AuthWrapper();
}

Widget _buildFeatureFlaggedSellerScreen(Widget child) {
  if (!FeatureFlags.kSellerOnboardingEnabled) {
    return const AuthWrapper();
  }
  return AuthRequiredGate(child: child);
}

List<RouteBase> _buildAppRoutes() {
  return [
    _appRoute(path: AppRoutes.home, builder: _buildHomeScreen, animated: false),
    _appRoute(
      path: AppRoutes.privacyPolicy,
      builder: (_) => DeferredWidget(
        loader: privacy.loadLibrary,
        builder: () => privacy.PrivacyPolicyScreen(),
      ),
    ),
    _appRoute(
      path: AppRoutes.termsOfService,
      builder: (_) => DeferredWidget(
        loader: terms.loadLibrary,
        builder: () => terms.TermsOfServiceScreen(),
      ),
    ),
    _appRoute(
      path: AppRoutes.paymentSuccess,
      builder: (state) {
        final sessionId = state.uri.queryParameters[DeepLinkParams.sessionId];
        if (sessionId == null || sessionId.isEmpty) {
          return ErrorScreen(message: 'errors.invalid_payment_link'.tr());
        }
        return AuthRequiredGate(child: OrderSuccessGate(sessionId: sessionId));
      },
    ),
    _appRoute(
      path: AppRoutes.paymentCancel,
      builder: (_) => const AuthRequiredGate(child: PaymentCanceledScreen()),
    ),
    _appRoute(
      path: AppRoutes.sellerReturn,
      builder: (_) =>
          _buildFeatureFlaggedSellerScreen(const SellerSetupCompleteScreen()),
    ),
    _appRoute(
      path: AppRoutes.sellerRefresh,
      builder: (_) =>
          _buildFeatureFlaggedSellerScreen(const SellerSetupRefreshScreen()),
    ),
    _appRoute(
      path: AppRoutes.productBySlugPattern,
      builder: (state) => _ProductBySlugScreen(
        slug: state.pathParameters[AppRoutes.productSlugParam]!,
      ),
    ),
    _appRoute(
      path: AppRoutes.productByIdPattern,
      builder: (state) {
        final args = state.extra as ProductDetailsArgs?;
        return ProductDetailScreen(
          productId: state.pathParameters[AppRoutes.productIdParam]!,
          product: args?.product,
        );
      },
    ),
    _appRoute(path: AppRoutes.login, builder: (_) => const LoginScreen()),
    _appRoute(
      path: AppRoutes.mfaChallenge,
      builder: (state) {
        final args = state.extra as MfaChallengeArgs?;
        if (args == null) return const AuthWrapper();
        return MfaChallengeScreen(challengeToken: args.challengeToken);
      },
    ),
    _appRoute(
      path: AppRoutes.mfaSetup,
      builder: (_) => const AuthRequiredGate(child: MfaSetupScreen()),
    ),
    _appRoute(
      path: AppRoutes.securitySettings,
      builder: (_) => const AuthRequiredGate(child: SecuritySettingsScreen()),
    ),
    _appRoute(
      path: AppRoutes.cart,
      builder: (_) => const AuthRequiredGate(child: CartScreen()),
    ),
    _appRoute(
      path: AppRoutes.profile,
      builder: (_) => const AuthRequiredGate(child: ProfileScreen()),
    ),
    _appRoute(
      path: AppRoutes.orders,
      builder: (_) => const AuthRequiredGate(child: OrdersScreen()),
    ),
    _appRoute(
      path: AppRoutes.orderDetail,
      builder: (state) {
        final args = state.extra as OrderDetailArgs?;
        final orderId =
            args?.orderId ?? state.uri.queryParameters[DeepLinkParams.orderId];
        if (orderId == null || orderId.isEmpty) {
          return const AuthRequiredGate(child: OrdersScreen());
        }
        return AuthRequiredGate(child: OrderDetailScreen(orderId: orderId));
      },
    ),
    _appRoute(
      path: AppRoutes.returnRequest,
      builder: (state) {
        final args = state.extra as ReturnRequestArgs?;
        final orderId =
            args?.orderId ?? state.uri.queryParameters[DeepLinkParams.orderId];
        if (orderId == null || orderId.isEmpty) {
          return const AuthRequiredGate(child: OrdersScreen());
        }
        return AuthRequiredGate(child: ReturnRequestScreen(orderId: orderId));
      },
    ),
    _appRoute(
      path: AppRoutes.addProduct,
      builder: (_) => AuthRequiredGate(
        child: DeferredWidget(
          loader: add_product.loadLibrary,
          builder: () => add_product.AddProductScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.editProduct,
      builder: (state) {
        final args = state.extra as EditProductArgs?;
        if (args == null) return const AuthWrapper();
        return AuthRequiredGate(
          child: DeferredWidget(
            loader: edit_product.loadLibrary,
            builder: () =>
                edit_product.EditProductScreen(product: args.product),
          ),
        );
      },
    ),
    _appRoute(
      path: AppRoutes.productDetails,
      builder: (state) {
        final args = state.extra as ProductDetailsArgs?;
        if (args == null) return const AuthWrapper();
        return ProductDetailScreen(
          productId: args.productId,
          product: args.product,
        );
      },
    ),
    _appRoute(
      path: AppRoutes.addressManagement,
      builder: (_) => const AuthRequiredGate(child: AddressManagementScreen()),
    ),
    _appRoute(
      path: AppRoutes.addEditAddress,
      builder: (state) => AuthRequiredGate(
        child: AddEditAddressScreen(address: state.extra as Address?),
      ),
    ),
    _appRoute(
      path: AppRoutes.checkout,
      builder: (state) {
        final args = state.extra as CheckoutArgs?;
        if (args == null) return const AuthWrapper();
        return AuthRequiredGate(
          child: DeferredWidget(
            loader: checkout.loadLibrary,
            builder: () => checkout.CheckoutScreen(
              items: args.items,
              totalCents: args.totalCents,
            ),
          ),
        );
      },
    ),
    _appRoute(
      path: AppRoutes.orderSuccess,
      builder: (state) {
        final orderId = state.extra as String?;
        if (orderId == null || orderId.isEmpty) return const AuthWrapper();
        return AuthRequiredGate(child: OrderSuccessScreen(orderId: orderId));
      },
    ),
    _appRoute(
      path: AppRoutes.shippingApproval,
      builder: (_) => AuthRequiredGate(
        child: DeferredWidget(
          loader: shipping_approval.loadLibrary,
          builder: () => shipping_approval.ShippingApprovalScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerRegistration,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_reg.loadLibrary,
          builder: () => seller_reg.SellerRegistrationScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerOrders,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_orders.loadLibrary,
          builder: () => seller_orders.SellerOrdersScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerProducts,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_products.loadLibrary,
          builder: () => seller_products.SellerProductsScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerWarehouses,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_warehouses.loadLibrary,
          builder: () => seller_warehouses.SellerWarehousesScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerBulkUpload,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_bulk_upload.loadLibrary,
          builder: () => seller_bulk_upload.BulkUploadScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerIntegration,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_integration.loadLibrary,
          builder: () => seller_integration.SellerIntegrationScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.sellerAnalytics,
      builder: (_) => _buildFeatureFlaggedSellerScreen(
        DeferredWidget(
          loader: seller_analytics.loadLibrary,
          builder: () => seller_analytics.SellerAnalyticsScreen(),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.adminPanel,
      builder: (_) => AuthRequiredGate(
        child: AdminRequiredGate(
          child: DeferredWidget(
            loader: admin_panel.loadLibrary,
            builder: () => admin_panel.AdminPanelScreen(),
          ),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.adminSellerProductsPattern,
      builder: (state) => AuthRequiredGate(
        child: AdminRequiredGate(
          child: AdminSellerProductsScreen(
            sellerId: state.pathParameters[AppRoutes.sellerIdParam]!,
            sellerName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
      ),
    ),
    _appRoute(
      path: AppRoutes.favorites,
      builder: (_) => const AuthRequiredGate(child: FavoritesScreen()),
    ),
    _appRoute(
      path: AppRoutes.subscription,
      builder: (_) => const AuthRequiredGate(child: SubscriptionScreen()),
    ),
    _appRoute(
      path: AppRoutes.subscriptionSuccess,
      builder: (_) =>
          const AuthRequiredGate(child: SubscriptionSuccessScreen()),
    ),
    _appRoute(
      path: AppRoutes.subscriptionCancel,
      builder: (_) => const AuthRequiredGate(child: SubscriptionCancelScreen()),
    ),
    _appRoute(
      path: AppRoutes.chat,
      builder: (state) {
        final args = state.extra as ChatArgs?;
        final resolvedArgs =
            args ??
            (state.uri.queryParameters.containsKey(DeepLinkParams.productId)
                ? ChatArgs(
                    productId:
                        state.uri.queryParameters[DeepLinkParams.productId]!,
                    productTitle:
                        state.uri.queryParameters[DeepLinkParams
                            .productTitle] ??
                        '',
                  )
                : null);
        if (resolvedArgs == null) return const AuthWrapper();
        return AuthRequiredGate(
          child: ChatScreen(
            productId: resolvedArgs.productId,
            productTitle: resolvedArgs.productTitle,
          ),
        );
      },
    ),
    _appRoute(
      path: AppRoutes.chatInbox,
      builder: (_) => const AuthRequiredGate(child: ChatConversationsScreen()),
    ),
    _appRoute(
      path: AppRoutes.notifications,
      builder: (_) => const AuthRequiredGate(child: NotificationsScreen()),
    ),
    _appRoute(
      path: AppRoutes.support,
      builder: (_) => AuthRequiredGate(
        child: DeferredWidget(
          loader: support_chat.loadLibrary,
          builder: () => support_chat.SupportScreen(),
        ),
      ),
    ),
  ];
}

Page<void> _buildRouterPage(
  GoRouterState state,
  Widget child, {
  bool animated = true,
}) {
  if (!animated) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(
        begin: 0,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOut));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

/// Root widget: configures themes, localization, GoRouter, Riverpod, and GlitchTip.
class OrignaApp extends ConsumerStatefulWidget {
  const OrignaApp({super.key});

  @override
  ConsumerState<OrignaApp> createState() => _OrignaAppState();
}

class _OrignaAppState extends ConsumerState<OrignaApp>
    with WidgetsBindingObserver {
  static const _resumeRefreshThreshold = Duration(minutes: 5);
  static const _backgroundStates = {
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  };

  final _sessionTimeout = SessionTimeoutService();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  String? _ensuredUserId; // Guard: only call ensureUserDocument once per user
  DateTime? _pausedAt; // Track when app went to background
  bool _resumeRefreshInFlight = false;
  AppLifecycleState? _lastLifecycleState;
  late final GoRouter _router;
  // FIX-5 (HIGH): Use the shared navigatorKey from OrignaBaseNotificationService so
  // notification tap handlers can push routes headlessly (without BuildContext).
  // The private _navigatorKey is replaced by the static singleton key.
  GlobalKey<NavigatorState> get _navigatorKey =>
      OrignaBaseNotificationService.navigatorKey;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Focus(
      onKeyEvent: (_, _) {
        _sessionTimeout.recordActivity();
        return KeyEventResult.ignored; // Let key events propagate normally
      },
      child: Listener(
        onPointerDown: (_) => _sessionTimeout.recordActivity(),
        onPointerMove: (_) => _sessionTimeout.recordActivity(),
        onPointerSignal: (_) =>
            _sessionTimeout.recordActivity(), // mouse wheel / trackpad scroll
        child: MaterialApp.router(
          scaffoldMessengerKey:
              OrignaBaseNotificationService.scaffoldMessengerKey,
          routerConfig: _router,
          builder: (context, child) => Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Align(
                alignment: Alignment.bottomCenter,
                child: CookieConsentBanner(),
              ),
            ],
          ),
          // === i18n: easy_localization (Quebec Bill 96 / Loi 96 compliance) ===
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            // Avoid Flutter web pointer-kind assertions seen in telemetry.
            // Explicitly supports all pointer kinds for modern Flutter Web
            scrollbars: true,
            // ClampingScrollPhysics prevents overscroll crashes on Flutter Web
            // (BouncingScrollPhysics causes negative pixel values → layout crashes)
            physics: const ClampingScrollPhysics(),
          ),
          onGenerateTitle: (ctx) => 'app.title'.tr(),
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          // ── Light Theme ──────────────────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.primary,
              primary: DesignTokens.primary,
              secondary: DesignTokens.secondary,
              tertiary: DesignTokens.tertiary,
              surface: DesignTokens.surface,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: DesignTokens.surface,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: DesignTokens.surface,
              foregroundColor: DesignTokens.textPrimary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                ),
                backgroundColor: DesignTokens.primary,
                foregroundColor: DesignTokens.textOnPrimary,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: DesignTokens.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                borderSide: const BorderSide(
                  color: DesignTokens.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                borderSide: const BorderSide(
                  color: DesignTokens.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                borderSide: const BorderSide(
                  color: DesignTokens.primary,
                  width: 2,
                ),
              ),
              labelStyle: const TextStyle(color: DesignTokens.textSecondary),
              hintStyle: const TextStyle(color: DesignTokens.textSecondary),
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: DesignTokens.primary,
              selectionHandleColor: DesignTokens.primary,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
              ),
              color: DesignTokens.surface,
              surfaceTintColor: DesignTokens.surface,
            ),
            dividerTheme: const DividerThemeData(
              color: DesignTokens.outlineVariant,
              thickness: 1,
              space: 1,
            ),
          ),
          // ── Dark Theme ───────────────────────────────────────────────────────
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.primary,
              primary: DesignTokens.primary,
              secondary: DesignTokens.secondary,
              tertiary: DesignTokens.tertiary,
              surface: DesignTokens.darkSurface,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: DesignTokens.darkBackground,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: DesignTokens.darkSurface,
              foregroundColor: DesignTokens.textOnDark,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                ),
                backgroundColor: DesignTokens.primary,
                foregroundColor: DesignTokens.textOnPrimary,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: DesignTokens.darkSurfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                borderSide: const BorderSide(color: DesignTokens.darkOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                borderSide: const BorderSide(color: DesignTokens.darkOutline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                borderSide: const BorderSide(
                  color: DesignTokens.primary,
                  width: 2,
                ),
              ),
              labelStyle: const TextStyle(
                color: DesignTokens.textOnDarkSecondary,
              ),
              hintStyle: const TextStyle(
                color: DesignTokens.textOnDarkSecondary,
              ),
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(DesignTokens.radius16),
                ),
              ),
              color: DesignTokens.darkCard,
              surfaceTintColor: DesignTokens.darkCard,
            ),
            dividerTheme: const DividerThemeData(
              color: DesignTokens.darkOutline,
              thickness: 1,
              space: 1,
            ),
          ),
        ),
      ), // Listener
    ); // Focus
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    _sessionTimeout.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    ref.read(appLifecycleProvider.notifier).state = state;
    final previousState = _lastLifecycleState;
    _lastLifecycleState = state;

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed(previousState);
      case AppLifecycleState.paused:
        _onAppBackgrounded();
      case AppLifecycleState.inactive:
      // Transitional state — no action needed
      case AppLifecycleState.detached:
        _onAppDetached();
      case AppLifecycleState.hidden:
        _onAppBackgrounded();
    }
  }

  void _onAppResumed(AppLifecycleState? previousState) {
    _sessionTimeout.recordActivity();

    if (previousState == null || !_backgroundStates.contains(previousState)) {
      return;
    }

    final pausedAt = _pausedAt;
    _pausedAt = null;

    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null || pausedAt == null) return;

    final timeInBackground = DateTime.now().difference(pausedAt);
    if (timeInBackground < _resumeRefreshThreshold || _resumeRefreshInFlight) {
      return;
    }

    _resumeRefreshInFlight = true;
    unawaited(_refreshAfterResume(userId, timeInBackground));
  }

  void _onAppBackgrounded() {
    _pausedAt ??= DateTime.now();
    AppLogger.d('App paused at $_pausedAt', tag: 'lifecycle');
  }

  void _onAppDetached() {
    AppLogger.d('App detached — cleaning up', tag: 'lifecycle');
    _sessionTimeout.stopMonitoring();
  }

  Future<void> _refreshAfterResume(
    String userId,
    Duration timeInBackground,
  ) async {
    try {
      // Skip refresh if device is offline — saves unnecessary network calls
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        AppLogger.d(
          'Skipping resume refresh — device is offline',
          tag: 'lifecycle',
        );
        return;
      }

      AppLogger.d(
        'App resumed after ${timeInBackground.inMinutes}min — validating session and refreshing cart, orders, favorites, and notifications',
        tag: 'lifecycle',
      );

      final isValid = await ref
          .read(authRepositoryProvider)
          .validateCurrentUser();
      if (!mounted || !isValid) return;

      // Re-fetch the highest-signal buyer/seller surfaces after a meaningful
      // background gap so stale badges, counts, and order states self-heal
      // without firing duplicate work on quick foreground hops.
      ref.invalidate(cartItemsProvider);
      ref.invalidate(buyerOrdersProvider);
      if (FeatureFlags.kSellerOnboardingEnabled) {
        ref.invalidate(sellerOrdersProvider);
      }
      ref.invalidate(favoritesProvider);
      ref.invalidate(userNotificationsProvider);
    } catch (e) {
      AppLogger.w('Resume refresh failed: $e', tag: 'lifecycle');
    } finally {
      _resumeRefreshInFlight = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = GoRouter(
      navigatorKey: _navigatorKey,
      routes: _buildAppRoutes(),
      errorPageBuilder: (context, state) =>
          _buildRouterPage(state, const AuthWrapper(), animated: false),
    );

    // Check for required app updates (mobile/tablet only)
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final minVersion = await AppUpdateService.checkForUpdate();
        if (minVersion != null && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => UpdateRequiredDialog(minVersion: minVersion),
          );
        }
      });
    }

    // Initialize Push Notifications after first frame to avoid ProviderScope.containerOf error in initState
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OrignaBaseNotificationService.instance.initialize(ref);
      });
    }

    _sessionTimeout.configure(
      currentUserIdProvider: () => ref.read(currentUserProvider)?.uid,
      signOutCallback: () => ref.read(authRepositoryProvider).signOut(),
    );

    // Listen for incoming deep links (Universal Links / URL schemes on iOS)
    // app_links has no web implementation — skip entirely on web to avoid
    // MissingPluginException from the method channel.
    if (!kIsWeb) {
      try {
        final appLinks = AppLinks();

        appLinks
            .getInitialLink()
            .then((uri) {
              if (uri != null) {
                _handleDeepLink(uri);
              }
            })
            .catchError((e) {
              AppLogger.w('getInitialLink failed: $e', tag: 'deeplink');
            });

        _deepLinkSubscription = appLinks.uriLinkStream.listen((Uri uri) {
          AppLogger.d('Incoming deep link: $uri', tag: 'deeplink');
          _handleDeepLink(uri);
        });
      } catch (e) {
        AppLogger.w(
          'Deep link init skipped (plugin unavailable): $e',
          tag: 'deeplink',
        );
      }
    }

    // Listen to auth state changes — store subscription for cleanup
    _authSubscription = ref.read(orignabaseProvider).auth.authStateChanges.listen((
      state,
    ) async {
      final user = state.isAuthenticated && state.userId != null
          ? AppAuthUser.fromAuthState(state)
          : null;
      if (user != null && mounted) {
        _sessionTimeout.startMonitoring(_navigatorKey);

        // Ensure user profile exists — guarded to run only once per user
        // to prevent infinite loop (ensureUserDoc can trigger auth state change).
        if (_ensuredUserId != user.uid) {
          _ensuredUserId = user.uid;
          try {
            await ref.read(authRepositoryProvider).ensureUserDocumentExists();
            if (!mounted) return;
          } catch (e) {
            _ensuredUserId = null; // Allow retry on failure
            AppLogger.w('Could not ensure user document: $e', tag: 'auth');
          }
        }
      } else {
        _ensuredUserId = null; // Reset on logout
        _sessionTimeout.stopMonitoring();
      }
    });

    _restoreWebOAuthCallbackSession();
  }

  void _restoreWebOAuthCallbackSession() {
    if (!kIsWeb) return;

    final uri = Uri.base;
    final callbackParams = extractWebOAuthCallbackParams(uri);
    final accessToken = callbackParams[DeepLinkParams.obAccessToken];
    if (accessToken == null || accessToken.isEmpty) return;

    ref
        .read(orignabaseProvider)
        .auth
        .restoreSession(
          accessToken: accessToken,
          refreshToken: callbackParams[DeepLinkParams.obRefreshToken],
        );

    final cleanedUrl = cleanedWebOAuthCallbackUrl(uri);
    final cleanedRoute = resolvedWebOAuthCallbackRoute(uri);
    clearWebAuthCallbackFragment(cleanedUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _router.go(cleanedRoute);
    });
  }

  void _handleDeepLink(Uri uri) {
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      final segs = uri.pathSegments;
      // /p/{slug} — product share link
      if (segs.length >= 2 && segs[0] == 'p') {
        _router.push(AppRoutes.productBySlugPath(segs[1]));
        return;
      }
      // Route the deep link through the existing route handler
      final path = uri.path.isNotEmpty ? uri.path : AppRoutes.home;
      final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
      _router.push('$path$query');
    }
  }
}

/// Resolves a slug to a product and renders the product detail screen directly.
/// This preserves the /p/{slug} URL on Web for better SEO and sharing support.
class _ProductBySlugScreen extends ConsumerWidget {
  final String slug;
  const _ProductBySlugScreen({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(productBySlugProvider(slug))
        .when(
          data: (product) {
            if (product == null) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: DesignTokens.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'product.not_found'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => appPushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (_) => false,
                        ),
                        child: Text('product.browse'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ProductDetailScreen(
              productId: product.productId,
              product: product.toJson(),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: ModernLoadingIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(AppError.getMessage(error))),
          ),
        );
  }
}
