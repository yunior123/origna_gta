import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/authwrapper_screen.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/ordersuccess_screen.dart';
import 'package:origna_gta/seller_registration_screen.dart';

class OrignaApp extends StatelessWidget {
  const OrignaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrignaGta',
      debugShowCheckedModeBanner: false,
      // Handle initial URL from web (e.g., Stripe redirect to /payment-success)
      onGenerateInitialRoutes: _onGenerateInitialRoutes,
      onGenerateRoute: _onGenerateRoute,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
          ),
        ),
      ),
    );
  }
}

/// Handle initial route from URL (critical for web redirects from Stripe)
List<Route<dynamic>> _onGenerateInitialRoutes(String initialRoute) {
  final uri = Uri.tryParse(initialRoute);

  // Handle payment success redirect from Stripe
  if (uri != null && uri.path == '/payment-success') {
    final sessionId = uri.queryParameters['session_id'];
    if (sessionId != null && sessionId.isNotEmpty) {
      return [
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        MaterialPageRoute(builder: (_) => _OrderSuccessGate(sessionId: sessionId)),
      ];
    }
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _ErrorScreen(message: 'Invalid payment link')),
    ];
  }

  // Handle payment cancellation redirect
  if (uri != null && uri.path == '/payment-cancel') {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _PaymentCanceledScreen()),
    ];
  }

  // Handle seller registration return from Stripe Connect
  if (uri != null && uri.path == '/seller/return') {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _SellerSetupCompleteScreen()),
    ];
  }

  // Handle seller registration refresh (user needs to retry)
  if (uri != null && uri.path == '/seller/refresh') {
    return [
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      MaterialPageRoute(builder: (_) => const _SellerSetupRefreshScreen()),
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
      return MaterialPageRoute(
        builder: (_) => const _ErrorScreen(message: 'Invalid payment link'),
      );
    }

    return MaterialPageRoute(
      builder: (_) => _OrderSuccessGate(sessionId: sessionId),
    );
  }

  // Handle payment cancellation deep link
  if (uri.path == '/payment-cancel') {
    return MaterialPageRoute(
      builder: (_) => const _PaymentCanceledScreen(),
    );
  }

  // Handle seller registration return
  if (uri.path == '/seller/return') {
    return MaterialPageRoute(
      builder: (_) => const _SellerSetupCompleteScreen(),
    );
  }

  // Handle seller registration refresh
  if (uri.path == '/seller/refresh') {
    return MaterialPageRoute(
      builder: (_) => const _SellerSetupRefreshScreen(),
    );
  }

  return null;
}

class _PaymentCanceledScreen extends StatelessWidget {
  const _PaymentCanceledScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Canceled'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, size: 100, color: Colors.red[400]),
              const SizedBox(height: 24),
              const Text(
                'Payment Canceled',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Back to Shopping',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSuccessGate extends StatelessWidget {
  final String sessionId;

  const _OrderSuccessGate({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('stripeSessionId', isEqualTo: sessionId)
          .where('paymentStatus', isEqualTo: PaymentStatus.paid.value)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Confirming your payment...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _ErrorScreen(message: 'Error loading order: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your payment...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final orderDoc = snapshot.data!.docs.first;
        return OrderSuccessScreen(orderId: orderDoc.id);
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
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown when seller returns from Stripe Connect onboarding
class _SellerSetupCompleteScreen extends StatefulWidget {
  const _SellerSetupCompleteScreen();

  @override
  State<_SellerSetupCompleteScreen> createState() => _SellerSetupCompleteScreenState();
}

class _SellerSetupCompleteScreenState extends State<_SellerSetupCompleteScreen> {
  bool _isChecking = true;
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isChecking = false;
          _error = 'Please log in to continue';
        });
        return;
      }

      // Check user's seller status in Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final isSeller = data?['isSeller'] == true;
      final chargesEnabled = data?['stripeChargesEnabled'] == true;

      setState(() {
        _isChecking = false;
        _isComplete = isSeller && chargesEnabled;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _error = 'Error checking account status';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isChecking
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Verifying your seller account...'),
                    ],
                  ),
                )
              : _error != null
                  ? _buildError()
                  : _isComplete
                      ? _buildSuccess()
                      : _buildPending(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
          child: Icon(Icons.check_circle, size: 100, color: Colors.green[600]),
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
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
            child: const Text('Start Selling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPending() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
          child: Icon(Icons.hourglass_empty, size: 100, color: Colors.orange[600]),
        ),
        const SizedBox(height: 32),
        const Text(
          'Setup In Progress',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your seller account is being verified. This usually takes a few minutes. You can check your status in your profile.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
            child: const Text('Go to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() => _isChecking = true);
            _checkAccountStatus();
          },
          child: const Text('Check Status Again'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
        const SizedBox(height: 24),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Go Home'),
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
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: Icon(Icons.refresh, size: 100, color: Colors.blue[600]),
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SellerRegistrationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  child: const Text('Continue Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}