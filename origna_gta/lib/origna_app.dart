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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35), brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ✅ PAYMENT SUCCESS
  if (uri.scheme == 'orignagta' && uri.host == 'payment-success') {
    final sessionId = uri.queryParameters['session_id'];

    return MaterialPageRoute(
      builder: (_) => OrderSuccessGate(sessionId: sessionId!),
    );
  }

  // ❌ PAYMENT CANCELED
  if (uri.scheme == 'orignagta' && uri.host == 'payment-cancel') {
    return MaterialPageRoute(
      builder: (_) => const PaymentCanceledScreen(),
    );
  }

  return null;
}
class PaymentCanceledScreen extends StatelessWidget {
  const PaymentCanceledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Payment canceled"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Cart"),
            )
          ],
        ),
      ),
    );
  }
}

class OrderSuccessGate extends StatelessWidget {
  final String sessionId;

  const OrderSuccessGate({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('stripeSessionId', isEqualTo: sessionId)
          .where('paymentStatus', isEqualTo: 'paid')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("Confirming payment…")),
          );
        }

        final order = snapshot.data!.docs.first;

        return OrderSuccessScreen(orderId: order.id);
      },
    );
  }
}
