import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/authwrapper_screen.dart';
import 'package:origna_gta/ordersuccess_screen.dart';

class OrignaApp extends StatelessWidget {
  const OrignaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrignaGta',
      debugShowCheckedModeBanner: false,
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
      home: const AuthWrapper(),
    );
  }
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
          .where('paymentStatus', isEqualTo: 'paid')
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