import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/admin/admin_panel_screen.dart';
import 'package:origna_gta/models/models.dart' show Address;
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/screens/cart_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/screens/payment_screens.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';
import 'package:origna_gta/screens/seller_setup_screen.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';
import 'package:origna_gta/screens/terms_of_service_screen.dart';
import 'package:origna_gta/services/session_timeout_service.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Handle initial route from URL (critical for web redirects from Stripe)
List<Route<dynamic>> _onGenerateInitialRoutes(String initialRoute) {
  if (kDebugMode) {
    print('🔗 Initial route: $initialRoute');
  }
  final uri = Uri.tryParse(initialRoute);
  if (kDebugMode && uri != null) {
    debugPrint('🔗 Parsed path: ${uri.path}');
  }

  // Handle payment success redirect from Stripe
  if (uri != null && uri.path == AppRoutes.paymentSuccess) {
    final sessionId = uri.queryParameters['session_id'];
    if (sessionId != null && sessionId.isNotEmpty) {
      return [
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        MaterialPageRoute(
          builder: (_) =>
              AuthRequiredGate(child: OrderSuccessGate(sessionId: sessionId)),
        ),
      ];
    }
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(
        builder: (_) => const ErrorScreen(message: 'Invalid payment link'),
      ),
    ];
  }

  // Handle privacy policy route
  if (uri != null && uri.path == AppRoutes.privacyPolicy) {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    ];
  }
  if (uri != null && uri.path == AppRoutes.termsOfService) {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    ];
  }

  // Handle payment cancellation redirect
  if (uri != null && uri.path == AppRoutes.paymentCancel) {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(
        builder: (_) => const AuthRequiredGate(child: PaymentCanceledScreen()),
      ),
    ];
  }

  // Handle seller registration return from Stripe Connect
  if (uri != null && uri.path == AppRoutes.sellerReturn) {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(
        builder: (_) =>
            const AuthRequiredGate(child: SellerSetupCompleteScreen()),
      ),
    ];
  }

  // Handle seller registration refresh (user needs to retry)
  if (uri != null && uri.path == AppRoutes.sellerRefresh) {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(
        builder: (_) =>
            const AuthRequiredGate(child: SellerSetupRefreshScreen()),
      ),
    ];
  }

  // Default: show AuthWrapper (home)
  return [MaterialPageRoute(builder: (_) => const AuthWrapper())];
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');

  if (uri == null) return null;

  // Handle home route - used when navigating back from deep links
  if (uri.path == AppRoutes.home || uri.path.isEmpty) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/'),
      builder: (_) => const AuthWrapper(),
    );
  }

  // Handle privacy policy route
  if (uri.path == AppRoutes.privacyPolicy) {
    return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
  }
  if (uri.path == AppRoutes.termsOfService) {
    return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());
  }

  // Handle payment success deep link
  if (uri.path == AppRoutes.paymentSuccess) {
    final sessionId = uri.queryParameters['session_id'];

    if (sessionId == null || sessionId.isEmpty) {
      return MaterialPageRoute(
        builder: (_) => const ErrorScreen(message: 'Invalid payment link'),
      );
    }

    return MaterialPageRoute(
      builder: (_) =>
          AuthRequiredGate(child: OrderSuccessGate(sessionId: sessionId)),
    );
  }

  // Handle payment cancellation deep link
  if (uri.path == AppRoutes.paymentCancel) {
    return MaterialPageRoute(
      builder: (_) => const AuthRequiredGate(child: PaymentCanceledScreen()),
    );
  }

  // Handle seller registration return
  if (uri.path == AppRoutes.sellerReturn) {
    return MaterialPageRoute(
      builder: (_) =>
          const AuthRequiredGate(child: SellerSetupCompleteScreen()),
    );
  }

  // Handle seller registration refresh
  if (uri.path == AppRoutes.sellerRefresh) {
    return MaterialPageRoute(
      builder: (_) => const AuthRequiredGate(child: SellerSetupRefreshScreen()),
    );
  }

  // Login screen
  if (uri.path == AppRoutes.login) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const LoginScreen(),
    );
  }

  // Cart screen
  if (uri.path == AppRoutes.cart) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: CartScreen()),
    );
  }

  // Profile screen
  if (uri.path == AppRoutes.profile) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: ProfileScreen()),
    );
  }

  // Orders screen
  if (uri.path == AppRoutes.orders) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: OrdersScreen()),
    );
  }

  // Add Product screen
  if (uri.path == AppRoutes.addProduct) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: AddProductScreen()),
    );
  }

  // Edit Product screen
  if (uri.path == AppRoutes.editProduct) {
    final args = settings.arguments as EditProductArgs?;
    if (args == null) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const AuthWrapper(),
      );
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthRequiredGate(child: EditProductScreen(product: args.product)),
    );
  }

  // Product Details screen
  if (uri.path == AppRoutes.productDetails) {
    final args = settings.arguments as ProductDetailsArgs?;
    if (args == null) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const AuthWrapper(),
      );
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => ProductDetailScreen(
        productId: args.productId,
        product: args.product,
      ),
    );
  }

  // Address Management screen
  if (uri.path == AppRoutes.addressManagement) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: AddressManagementScreen()),
    );
  }

  // Add/Edit Address screen
  if (uri.path == AppRoutes.addEditAddress) {
    final address = settings.arguments as Address?;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthRequiredGate(child: AddEditAddressScreen(address: address)),
    );
  }

  // Checkout screen
  if (uri.path == AppRoutes.checkout) {
    final args = settings.arguments as CheckoutArgs?;
    if (args == null) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const AuthWrapper(),
      );
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthRequiredGate(
        child: CheckoutScreen(
          items: args.items,
          total: args.total,
        ),
      ),
    );
  }

  // Order Success screen (internal post-payment navigation)
  if (uri.path == AppRoutes.orderSuccess) {
    final orderId = settings.arguments as String?;
    if (orderId == null) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const AuthWrapper(),
      );
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthRequiredGate(child: OrderSuccessScreen(orderId: orderId)),
    );
  }

  // Shipping Approval screen
  if (uri.path == AppRoutes.shippingApproval) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: ShippingApprovalScreen()),
    );
  }

  // Seller Registration screen
  if (uri.path == AppRoutes.sellerRegistration) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: SellerRegistrationScreen()),
    );
  }

  // Seller Orders screen
  if (uri.path == AppRoutes.sellerOrders) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: SellerOrdersScreen()),
    );
  }

  // Admin Panel screen
  if (uri.path == AppRoutes.adminPanel) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: AdminPanelScreen()),
    );
  }

  // Favorites screen
  if (uri.path == AppRoutes.favorites) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthRequiredGate(child: FavoritesScreen()),
    );
  }

  // Default fallback: redirect unknown routes to home
  if (kDebugMode) {
    debugPrint('⚠️ Unknown route: ${uri.path} — redirecting to home');
  }
  return MaterialPageRoute(
    settings: const RouteSettings(name: '/'),
    builder: (_) => const AuthWrapper(),
  );
}

class OrignaApp extends ConsumerStatefulWidget {
  const OrignaApp({super.key});

  @override
  ConsumerState<OrignaApp> createState() => _OrignaAppState();
}

class _OrignaAppState extends ConsumerState<OrignaApp> {
  final _sessionTimeout = SessionTimeoutService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _sessionTimeout.recordActivity(context),
      onPanDown: (_) => _sessionTimeout.recordActivity(context),
      child: MaterialApp(
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
        title: 'Origna GTA',
        debugShowCheckedModeBanner: false,
        // Handle initial URL from web (e.g., Stripe redirect to /payment-success)
        onGenerateInitialRoutes: _onGenerateInitialRoutes,
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: (_) => MaterialPageRoute(
          settings: const RouteSettings(name: '/'),
          builder: (_) => const AuthWrapper(),
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
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1a1a2e),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: DesignTokens.primary,
                width: 2,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey[200],
            thickness: 1,
            space: 1,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimeout.stopMonitoring();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    ref.read(firebaseAuthProvider).authStateChanges().listen((user) async {
      if (user != null && mounted) {
        _sessionTimeout.startMonitoring(context);

        // ✅ Ensure Firestore document exists for verified users
        await ref.read(authRepositoryProvider).ensureUserDocumentExists();
      } else {
        _sessionTimeout.stopMonitoring();
      }
    });
  }
}
