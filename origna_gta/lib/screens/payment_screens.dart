import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Gate that waits for order to be confirmed after Stripe payment
class OrderSuccessGate extends ConsumerWidget {
  final String sessionId;

  const OrderSuccessGate({super.key, required this.sessionId});

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
      error: (error, _) => ErrorScreen(message: 'Error loading order: $error'),
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

/// Screen shown when user cancels payment
class PaymentCanceledScreen extends StatelessWidget {
  const PaymentCanceledScreen({super.key});

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
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
