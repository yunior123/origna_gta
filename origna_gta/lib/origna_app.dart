import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/app/seller_account_status_viewmodel.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';
import 'package:origna_gta/services/session_timeout_service.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Handle initial route from URL (critical for web redirects from Stripe)
List<Route<dynamic>> _onGenerateInitialRoutes(String initialRoute) {
  if (kDebugMode) {
    print('🔗 Initial route: $initialRoute');
  }
  final uri = Uri.tryParse(initialRoute);
  if (kDebugMode && uri != null) {
    print('🔗 Parsed path: ${uri.path}');
  }

  // Handle payment success redirect from Stripe
  if (uri != null && uri.path == '/payment-success') {
    final sessionId = uri.queryParameters['session_id'];
    if (sessionId != null && sessionId.isNotEmpty) {
      return [
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        MaterialPageRoute(
          builder: (_) => _AuthRequiredGate(child: _OrderSuccessGate(sessionId: sessionId)),
        ),
      ];
    }
    return [MaterialPageRoute(builder: (_) => const AuthWrapper()), MaterialPageRoute(builder: (_) => const _ErrorScreen(message: 'Invalid payment link'))];
  }

  // Handle payment cancellation redirect
  if (uri != null && uri.path == '/payment-cancel') {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _AuthRequiredGate(child: _PaymentCanceledScreen())),
    ];
  }

  // Handle seller registration return from Stripe Connect
  if (uri != null && uri.path == '/seller/return') {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _AuthRequiredGate(child: _SellerSetupCompleteScreen())),
    ];
  }

  // Handle seller registration refresh (user needs to retry)
  if (uri != null && uri.path == '/seller/refresh') {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _AuthRequiredGate(child: _SellerSetupRefreshScreen())),
    ];
  }

  // Default: show AuthWrapper (home)
  return [MaterialPageRoute(builder: (_) => const AuthWrapper())];
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');

  if (uri == null) return null;

  // Handle payment success deep link
  if (uri.path == '/payment-success') {
    final sessionId = uri.queryParameters['session_id'];

    if (sessionId == null || sessionId.isEmpty) {
      return MaterialPageRoute(builder: (_) => const _ErrorScreen(message: 'Invalid payment link'));
    }

    return MaterialPageRoute(
      builder: (_) => _AuthRequiredGate(child: _OrderSuccessGate(sessionId: sessionId)),
    );
  }

  // Handle payment cancellation deep link
  if (uri.path == '/payment-cancel') {
    return MaterialPageRoute(builder: (_) => const _AuthRequiredGate(child: _PaymentCanceledScreen()));
  }

  // Handle seller registration return
  if (uri.path == '/seller/return') {
    return MaterialPageRoute(builder: (_) => const _AuthRequiredGate(child: _SellerSetupCompleteScreen()));
  }

  // Handle seller registration refresh
  if (uri.path == '/seller/refresh') {
    return MaterialPageRoute(builder: (_) => const _AuthRequiredGate(child: _SellerSetupRefreshScreen()));
  }

  return null;
}

class OrignaApp extends ConsumerStatefulWidget {
  const OrignaApp({super.key});

  @override
  ConsumerState<OrignaApp> createState() => _OrignaAppState();
}

class _AuthRequiredGate extends ConsumerWidget {
  final Widget child;

  const _AuthRequiredGate({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _ErrorScreen(message: 'Authentication error: $error'),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sign In Required')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: DesignTokens.primary),
                    const SizedBox(height: 16),
                    const Text('Please sign in to continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Go Home')),
                  ],
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: DesignTokens.error),
              const SizedBox(height: 24),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Go Home')),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSuccessGate extends ConsumerWidget {
  final String sessionId;

  const _OrderSuccessGate({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(paidOrderBySessionProvider(sessionId));

    return orderAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Confirming your payment...')],
          ),
        ),
      ),
      error: (error, _) => _ErrorScreen(message: 'Error loading order: $error'),
      data: (order) {
        if (order == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your payment...'),
                  SizedBox(height: 8),
                  Text('This may take a few moments', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return OrderSuccessScreen(orderId: order.orderId);
      },
    );
  }
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
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          // Fix Sentry issue: !identical(kind, PointerDeviceKind.trackpad)
          // Explicitly supports all pointer kinds for modern Flutter Web
          scrollbars: true,
          physics: const BouncingScrollPhysics(),
        ),
        title: 'OrignaGta',
        debugShowCheckedModeBanner: false,
        // Handle initial URL from web (e.g., Stripe redirect to /payment-success)
        onGenerateInitialRoutes: _onGenerateInitialRoutes,
        onGenerateRoute: _onGenerateRoute,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1, space: 1),
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
    ref.read(firebaseAuthProvider).authStateChanges().listen((user) {
      if (user != null && mounted) {
        _sessionTimeout.startMonitoring(context);
      } else {
        _sessionTimeout.stopMonitoring();
      }
    });
  }
}

class _PaymentCanceledScreen extends StatelessWidget {
  const _PaymentCanceledScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Canceled')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, size: 100, color: DesignTokens.error),
              const SizedBox(height: 24),
              const Text('Payment Canceled', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'Your payment was canceled. Your cart items are still saved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
                  child: const Text('Back to Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown when seller returns from Stripe Connect onboarding
class _SellerSetupCompleteScreen extends ConsumerStatefulWidget {
  const _SellerSetupCompleteScreen();

  @override
  ConsumerState<_SellerSetupCompleteScreen> createState() => _SellerSetupCompleteScreenState();
}

class _SellerSetupCompleteScreenState extends ConsumerState<_SellerSetupCompleteScreen> {
  bool _isRefreshing = false;
  String? _statusMessage;
  DateTime? _lastCheckTime;
  static const _minCheckInterval = Duration(seconds: 10); // Rate limit: 10 seconds between checks

  Future<void> _checkStatusAgain() async {
    // Rate limiting - prevent spam clicking
    if (_lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < _minCheckInterval) {
        final remaining = _minCheckInterval - elapsed;
        setState(() {
          _statusMessage = '⏳ Please wait ${remaining.inSeconds} seconds before checking again.';
        });
        return;
      }
    }
    
    _lastCheckTime = DateTime.now();
    
    setState(() {
      _isRefreshing = true;
      _statusMessage = null;
    });
    
    try {
      // Invalidate and refetch - this calls the backend which updates Firestore
      ref.invalidate(sellerAccountStatusProvider);
      // Wait for the provider to complete
      final status = await ref.read(sellerAccountStatusProvider.future);
      
      // Also invalidate userProfileProvider so HomeScreen gets fresh data
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          if (status.isComplete) {
            // Account is fully verified - charges enabled
            _statusMessage = '✅ Verification complete! You can now add products.';
          } else {
            // Still waiting for Stripe verification
            _statusMessage = '⏳ Verification still in progress. Stripe is reviewing your documents.';
          }
        });
        
        // Clear message after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _statusMessage = null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _statusMessage = '❌ Could not check status. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(sellerAccountStatusProvider);

    if (_isRefreshing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Checking status...')],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: statusAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Verifying your seller account...')],
              ),
            ),
            error: (error, _) => _buildError(context, error.toString()),
            data: (status) => status.isComplete ? _buildSuccess(context) : _buildPending(context),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 80, color: DesignTokens.error),
        const SizedBox(height: 24),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _checkStatusAgain,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Go Home')),
      ],
    );
  }

  Future<void> _goToHome() async {
    // Show loading indicator
    setState(() => _isRefreshing = true);
    
    try {
      // Call backend to sync Stripe status with Firestore
      // This ensures chargesEnabled, payoutsEnabled, onboardingCompleted are updated
      ref.invalidate(sellerAccountStatusProvider);
      await ref.read(sellerAccountStatusProvider.future);
    } catch (e) {
      // Ignore errors - we'll still navigate home
      debugPrint('Error syncing status before going home: $e');
    }
    
    // Refresh user profile to get updated seller status from Firestore
    ref.invalidate(userProfileProvider);
    
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildPending(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.hourglass_empty, size: 100, color: Colors.orange),
        ),
        const SizedBox(height: 32),
        const Text(
          'Identity Verification Pending',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Stripe is reviewing your identity documents. This usually takes a few minutes but can take up to 2 business days.\n\nYou will be able to add products once your verification is complete.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
            child: const Text('Go to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _checkStatusAgain,
          child: const Text('Check Verification Status'),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusMessage!.startsWith('✅') 
                  ? DesignTokens.success.withValues(alpha: 0.1)
                  : _statusMessage!.startsWith('❌')
                      ? DesignTokens.error.withValues(alpha: 0.1)
                      : DesignTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _statusMessage!.startsWith('✅')
                    ? DesignTokens.success
                    : _statusMessage!.startsWith('❌')
                        ? DesignTokens.error
                        : DesignTokens.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.check_circle, size: 100, color: DesignTokens.success),
        ),
        const SizedBox(height: 32),
        const Text(
          'Seller Account Ready!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your account is set up and you can now start selling products.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
            child: const Text('Start Selling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

/// Screen shown when seller needs to refresh/retry Stripe Connect onboarding
class _SellerSetupRefreshScreen extends StatelessWidget {
  const _SellerSetupRefreshScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: DesignTokens.info.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.refresh, size: 100, color: DesignTokens.info),
              ),
              const SizedBox(height: 32),
              const Text(
                'Continue Your Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your seller account setup needs to be completed. Please continue to finish setting up your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerRegistrationScreen()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
                  child: const Text('Continue Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }
}
