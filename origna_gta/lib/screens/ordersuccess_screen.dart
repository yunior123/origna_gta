// OrderSuccessScreen
import 'package:flutter/material.dart';
import 'package:origna_gta/screens/orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

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
                decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 100, color: Colors.green[600]),
              ),
              const SizedBox(height: 32),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Order ID: $orderId', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  child: const Text('Continue Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const OrdersScreen()), (route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF6B35))),
                  child: const Text(
                    'View My Orders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
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