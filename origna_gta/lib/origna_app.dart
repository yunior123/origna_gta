import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
// Deferred imports for code splitting — reduces initial JS bundle on Flutter Web
import 'package:origna_gta/features/admin/admin_panel_screen.dart' deferred as admin_panel;
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/models.dart' show Address;
import 'package:origna_gta/screens/addproduct_screen.dart' deferred as add_product;
import 'package:origna_gta/screens/addressmanagement_screen.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/screens/cart_screen.dart';
import 'package:origna_gta/screens/chat_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart' deferred as checkout;
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/screens/editproduct_screen.dart' deferred as edit_product;
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/screens/payment_screens.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart' deferred as privacy;
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/screens/seller/seller_warehouses_screen.dart' deferred as seller_warehouses;
import 'package:origna_gta/screens/seller_integration_screen.dart' deferred as seller_integration;
import 'package:origna_gta/screens/seller_orders_screen.dart' deferred as seller_orders;
import 'package:origna_gta/screens/seller_products_screen.dart' deferred as seller_products;
import 'package:origna_gta/screens/seller_registration_screen.dart' deferred as seller_reg;
import 'package:origna_gta/screens/seller_setup_screen.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart' deferred as shipping_approval;
import 'package:origna_gta/screens/subscription_cancel_screen.dart';
import 'package:origna_gta/screens/subscription_screen.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';
import 'package:origna_gta/screens/terms_of_service_screen.dart' deferred as terms;
import 'package:origna_gta/services/notification_service.dart';
import 'package:origna_gta/services/session_timeout_service.dart';
import 'package:origna_gta/utils/animations.dart';
import 'package:origna_gta/utils/deferred_widget.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Handle initial route from URL (critical for web redirects from Stripe)
List<Route<dynamic>> _onGenerateInitialRoutes(String initialRoute) {
  if (kDebugMode) {
    debugPrint('🔗 Initial route: $initialRoute');
  }
  final uri = Uri.tryParse(initialRoute);
  if (kDebugMode && uri != null) {
    debugPrint('🔗 Parsed path: ${uri.path}');
  }

  // Handle product by slug deep link (/p/{slug})
  if (uri != null && uri.path.startsWith('${AppRoutes.productBySlug}/')) {
    final slug = uri.path.substring('${AppRoutes.productBySlug}/'.length);
    if (slug.isNotEmpty) {
      return [
        SlidePageRoute(page: const AuthWrapper()),
        SlidePageRoute(
          settings: RouteSettings(name: initialRoute),
          page: _ProductBySlugScreen(slug: slug),
        ),
      ];
    }
  }

  // Handle payment success redirect from Stripe
  if (uri != null && uri.path == AppRoutes.paymentSuccess) {
    final sessionId = uri.queryParameters['session_id'];
    if (sessionId != null && sessionId.isNotEmpty) {
      return [
        SlidePageRoute(page: const AuthWrapper()),
        SlidePageRoute(
          page: AuthRequiredGate(child: OrderSuccessGate(sessionId: sessionId)),
        ),
      ];
    }
    return [
      SlidePageRoute(page: const AuthWrapper()),
      SlidePageRoute(page: ErrorScreen(message: 'errors.invalid_payment_link'.tr())),
    ];
  }

  // Handle privacy policy route
  if (uri != null && uri.path == AppRoutes.privacyPolicy) {
    return [
      SlidePageRoute(page: const AuthWrapper()),
      SlidePageRoute(
        page: DeferredWidget(loader: privacy.loadLibrary, builder: () => privacy.PrivacyPolicyScreen()),
      ),
    ];
  }
  if (uri != null && uri.path == AppRoutes.termsOfService) {
    return [
      SlidePageRoute(page: const AuthWrapper()),
      SlidePageRoute(
        page: DeferredWidget(loader: terms.loadLibrary, builder: () => terms.TermsOfServiceScreen()),
      ),
    ];
  }

  // Handle payment cancellation redirect
  if (uri != null && uri.path == AppRoutes.paymentCancel) {
    return [SlidePageRoute(page: const AuthWrapper()), SlidePageRoute(page: const AuthRequiredGate(child: PaymentCanceledScreen()))];
  }

  // Handle seller registration return from Stripe Connect
  if (uri != null && uri.path == AppRoutes.sellerReturn) {
    return [
      SlidePageRoute(page: const AuthWrapper()),
      SlidePageRoute(page: const AuthRequiredGate(child: SellerSetupCompleteScreen())),
    ];
  }

  // Handle seller registration refresh (user needs to retry)
  if (uri != null && uri.path == AppRoutes.sellerRefresh) {
    return [
      SlidePageRoute(page: const AuthWrapper()),
      SlidePageRoute(page: const AuthRequiredGate(child: SellerSetupRefreshScreen())),
    ];
  }

  // Default: show AuthWrapper (home)
  return [SlidePageRoute(page: const AuthWrapper())];
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');

  if (uri == null) return null;

  // Handle home route - used when navigating back from deep links
  if (uri.path == AppRoutes.home || uri.path.isEmpty) {
    return SlidePageRoute(
      settings: const RouteSettings(name: '/'),
      page: const AuthWrapper(),
    );
  }

  // Handle privacy policy route
  if (uri.path == AppRoutes.privacyPolicy) {
    return SlidePageRoute(
      page: DeferredWidget(loader: privacy.loadLibrary, builder: () => privacy.PrivacyPolicyScreen()),
    );
  }
  if (uri.path == AppRoutes.termsOfService) {
    return SlidePageRoute(
      page: DeferredWidget(loader: terms.loadLibrary, builder: () => terms.TermsOfServiceScreen()),
    );
  }

  // Handle payment success deep link
  if (uri.path == AppRoutes.paymentSuccess) {
    final sessionId = uri.queryParameters['session_id'];

    if (sessionId == null || sessionId.isEmpty) {
      return SlidePageRoute(page: ErrorScreen(message: 'errors.invalid_payment_link'.tr()));
    }

    return SlidePageRoute(
      page: AuthRequiredGate(child: OrderSuccessGate(sessionId: sessionId)),
    );
  }

  // Handle payment cancellation deep link
  if (uri.path == AppRoutes.paymentCancel) {
    return SlidePageRoute(page: const AuthRequiredGate(child: PaymentCanceledScreen()));
  }

  // Handle seller registration return
  if (uri.path == AppRoutes.sellerReturn) {
    return SlidePageRoute(page: const AuthRequiredGate(child: SellerSetupCompleteScreen()));
  }

  // Handle seller registration refresh
  if (uri.path == AppRoutes.sellerRefresh) {
    return SlidePageRoute(page: const AuthRequiredGate(child: SellerSetupRefreshScreen()));
  }

  // /p/{slug} — shareable product deep link
  if (uri.path.startsWith('${AppRoutes.productBySlug}/')) {
    final slug = uri.path.substring('${AppRoutes.productBySlug}/'.length);
    if (slug.isNotEmpty) {
      return SlidePageRoute(
        settings: settings,
        page: _ProductBySlugScreen(slug: slug),
      );
    }
  }

  // Login screen
  if (uri.path == AppRoutes.login) {
    return SlidePageRoute(settings: settings, page: const LoginScreen());
  }

  // Cart screen
  if (uri.path == AppRoutes.cart) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: CartScreen()),
    );
  }

  // Profile screen
  if (uri.path == AppRoutes.profile) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: ProfileScreen()),
    );
  }

  // Orders screen
  if (uri.path == AppRoutes.orders) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: OrdersScreen()),
    );
  }

  // Add Product screen
  if (uri.path == AppRoutes.addProduct) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: add_product.loadLibrary, builder: () => add_product.AddProductScreen()),
      ),
    );
  }

  // Edit Product screen
  if (uri.path == AppRoutes.editProduct) {
    final args = settings.arguments as EditProductArgs?;
    if (args == null) {
      return SlidePageRoute(
        settings: const RouteSettings(name: '/'),
        page: const AuthWrapper(),
      );
    }
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(
          loader: edit_product.loadLibrary,
          builder: () => edit_product.EditProductScreen(product: args.product),
        ),
      ),
    );
  }

  // Product Details screen
  if (uri.path == AppRoutes.productDetails) {
    final args = settings.arguments as ProductDetailsArgs?;
    if (args == null) {
      return SlidePageRoute(
        settings: const RouteSettings(name: '/'),
        page: const AuthWrapper(),
      );
    }
    return SlidePageRoute(
      settings: settings,
      page: ProductDetailScreen(productId: args.productId, product: args.product),
    );
  }

  // Address Management screen
  if (uri.path == AppRoutes.addressManagement) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: AddressManagementScreen()),
    );
  }

  // Add/Edit Address screen
  if (uri.path == AppRoutes.addEditAddress) {
    final address = settings.arguments as Address?;
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(child: AddEditAddressScreen(address: address)),
    );
  }

  // Checkout screen
  if (uri.path == AppRoutes.checkout) {
    final args = settings.arguments as CheckoutArgs?;
    if (args == null) {
      return SlidePageRoute(
        settings: const RouteSettings(name: '/'),
        page: const AuthWrapper(),
      );
    }
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(
          loader: checkout.loadLibrary,
          builder: () => checkout.CheckoutScreen(items: args.items, total: args.total),
        ),
      ),
    );
  }

  // Order Success screen (internal post-payment navigation)
  if (uri.path == AppRoutes.orderSuccess) {
    final orderId = settings.arguments as String?;
    if (orderId == null) {
      return SlidePageRoute(
        settings: const RouteSettings(name: '/'),
        page: const AuthWrapper(),
      );
    }
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(child: OrderSuccessScreen(orderId: orderId)),
    );
  }

  // Shipping Approval screen
  if (uri.path == AppRoutes.shippingApproval) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: shipping_approval.loadLibrary, builder: () => shipping_approval.ShippingApprovalScreen()),
      ),
    );
  }

  // Seller Registration screen
  if (uri.path == AppRoutes.sellerRegistration) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: seller_reg.loadLibrary, builder: () => seller_reg.SellerRegistrationScreen()),
      ),
    );
  }

  // Seller Orders screen
  if (uri.path == AppRoutes.sellerOrders) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: seller_orders.loadLibrary, builder: () => seller_orders.SellerOrdersScreen()),
      ),
    );
  }

  // Seller Products screen
  if (uri.path == AppRoutes.sellerProducts) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: seller_products.loadLibrary, builder: () => seller_products.SellerProductsScreen()),
      ),
    );
  }

  // Seller Warehouses screen
  if (uri.path == AppRoutes.sellerWarehouses) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: seller_warehouses.loadLibrary, builder: () => seller_warehouses.SellerWarehousesScreen()),
      ),
    );
  }

  // Seller Integration Guide
  if (uri.path == AppRoutes.sellerIntegration) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: DeferredWidget(loader: seller_integration.loadLibrary, builder: () => seller_integration.SellerIntegrationScreen()),
      ),
    );
  }

  // Admin Panel screen — requires admin role verification
  if (uri.path == AppRoutes.adminPanel) {
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: AdminRequiredGate(
          child: DeferredWidget(loader: admin_panel.loadLibrary, builder: () => admin_panel.AdminPanelScreen()),
        ),
      ),
    );
  }

  // Favorites screen
  if (uri.path == AppRoutes.favorites) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: FavoritesScreen()),
    );
  }

  // Subscription screen
  if (uri.path == AppRoutes.subscription) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: SubscriptionScreen()),
    );
  }

  // Subscription success (redirect from Stripe)
  if (uri.path == AppRoutes.subscriptionSuccess) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: SubscriptionSuccessScreen()),
    );
  }

  // Subscription cancel (redirect from Stripe)
  if (uri.path == AppRoutes.subscriptionCancel) {
    return SlidePageRoute(
      settings: settings,
      page: const AuthRequiredGate(child: SubscriptionCancelScreen()),
    );
  }

  // Chat screen
  if (uri.path == AppRoutes.chat) {
    final args = settings.arguments as ChatArgs?;
    // Support deep-link via URL query params: /chat?productId=X&productTitle=Y
    final resolvedArgs = args ??
        (uri.queryParameters.containsKey('productId')
            ? ChatArgs(
                productId: uri.queryParameters['productId']!,
                productTitle: uri.queryParameters['productTitle'] ?? '',
              )
            : null);
    if (resolvedArgs == null) {
      return SlidePageRoute(
        settings: const RouteSettings(name: '/'),
        page: const AuthWrapper(),
      );
    }
    return SlidePageRoute(
      settings: settings,
      page: AuthRequiredGate(
        child: ChatScreen(productId: resolvedArgs.productId, productTitle: resolvedArgs.productTitle),
      ),
    );
  }

  // Default fallback: redirect unknown routes to home
  if (kDebugMode) {
    debugPrint('⚠️ Unknown route: ${uri.path} — redirecting to home');
  }
  return SlidePageRoute(
    settings: const RouteSettings(name: '/'),
    page: const AuthWrapper(),
  );
}

class OrignaApp extends ConsumerStatefulWidget {
  const OrignaApp({super.key});

  @override
  ConsumerState<OrignaApp> createState() => _OrignaAppState();
}

class _OrignaAppState extends ConsumerState<OrignaApp> {
  final _sessionTimeout = SessionTimeoutService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, _) {
        _sessionTimeout.recordActivity();
        return KeyEventResult.ignored; // Let key events propagate normally
      },
      child: Listener(
        onPointerDown: (_) => _sessionTimeout.recordActivity(),
        onPointerMove: (_) => _sessionTimeout.recordActivity(),
        onPointerSignal: (_) => _sessionTimeout.recordActivity(), // mouse wheel / trackpad scroll
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: NotificationService.scaffoldMessengerKey,
        // === i18n: easy_localization (Quebec Bill 96 / Loi 96 compliance) ===
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          // Fix Sentry issue: !identical(kind, PointerDeviceKind.trackpad)
          // Explicitly supports all pointer kinds for modern Flutter Web
          scrollbars: true,
          physics: const BouncingScrollPhysics(),
        ),
        onGenerateTitle: (ctx) => 'app.title'.tr(),
        debugShowCheckedModeBanner: !kReleaseMode && !envConfig.isProduction,
        // Handle initial URL from web (e.g., Stripe redirect to /payment-success)
        onGenerateInitialRoutes: _onGenerateInitialRoutes,
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: (_) => SlidePageRoute(
          settings: const RouteSettings(name: '/'),
          page: const AuthWrapper(),
        ),
        theme: ThemeData(
          useMaterial3: true,
          // Centralized Theme using DesignTokens
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: DesignTokens.primary,
              foregroundColor: DesignTokens.textOnPrimary,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: DesignTokens.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DesignTokens.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DesignTokens.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: DesignTokens.surface,
            surfaceTintColor: DesignTokens.surface,
          ),
          dividerTheme: DividerThemeData(color: DesignTokens.outlineVariant, thickness: 1, space: 1),
        ),
      ),
    ), // Listener
    ); // Focus
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    _sessionTimeout.stopMonitoring();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize Push Notifications
    if (!kIsWeb) {
      NotificationService.instance.initialize(ref);
    }

    // Listen for incoming deep links (Universal Links / URL schemes on iOS)
    if (!kIsWeb) {
      final appLinks = AppLinks();

      // Handle initial link if app was closed
      appLinks.getInitialLink().then((uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }).catchError((e) {
        debugPrint('⚠️ getInitialLink failed: $e');
      });

      _deepLinkSubscription = appLinks.uriLinkStream.listen((Uri uri) {
        if (kDebugMode) {
          debugPrint('🔗 Incoming deep link: $uri');
        }
        _handleDeepLink(uri);
      });
    }

    // Listen to auth state changes — store subscription for cleanup
    _authSubscription = ref.read(firebaseAuthProvider).authStateChanges().listen((user) async {
      if (user != null && mounted) {
        _sessionTimeout.startMonitoring(_navigatorKey);

        // Ensure Firestore document exists for verified users
        try {
          await ref.read(authRepositoryProvider).ensureUserDocumentExists();
          if (!mounted) return;
        } catch (e) {
          debugPrint('Could not ensure user document: $e');
        }
      } else {
        _sessionTimeout.stopMonitoring();
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      final segs = uri.pathSegments;
      // /p/{slug} — product share link
      if (segs.length >= 2 && segs[0] == 'p') {
        navigator.pushNamed('/p/${segs[1]}');
        return;
      }
      // Route the deep link through the existing route handler
      final path = uri.path.isNotEmpty ? uri.path : '/';
      final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
      navigator.pushNamed('$path$query');
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
                      Icon(Icons.search_off_rounded, size: 64, color: DesignTokens.textSecondary),
                      const SizedBox(height: 16),
                      Text('product.not_found'.tr(), style: TextStyle(fontSize: 18, color: DesignTokens.textSecondary)),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
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
            return ProductDetailScreen(productId: product.productId, product: product.toJson());
          },
          loading: () => const Scaffold(body: Center(child: ModernLoadingIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error loading product: $error')),
          ),
        );
  }
}
