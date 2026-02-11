import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Gate that waits for order to be confirmed after Stripe payment
class OrderSuccessGate extends ConsumerWidget {
  final String sessionId;

  const OrderSuccessGate({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(paidOrderBySessionProvider(sessionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return orderAsync.when(
      loading: () => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF0F2FF), Colors.white],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
                      ),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: ModernLoadingIndicator(size: 40, strokeWidth: 3, color: Colors.white, centered: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Confirming your payment...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[900])),
                  const SizedBox(height: 8),
                  Text('This may take a few moments', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (error, _) => ErrorScreen(message: 'Error loading order: $error'),
      data: (order) {
        if (order == null) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
                    : [const Color(0xFFF0F2FF), Colors.white],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
                          ),
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: ModernLoadingIndicator(size: 40, strokeWidth: 3, color: Colors.white, centered: false),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Processing your payment...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[900])),
                      const SizedBox(height: 8),
                      Text('This may take a few moments', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
              : [const Color(0xFFF0F2FF), Colors.white],
        ),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'Payment Canceled'),
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [DesignTokens.error.withValues(alpha: 0.15), DesignTokens.error.withValues(alpha: 0.08)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: DesignTokens.error.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Icon(Icons.cancel_rounded, size: 72, color: DesignTokens.error),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Payment Canceled',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.grey[900]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      'Your payment was canceled.\nYour cart items are still saved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: ModernButton(
                      label: 'Back to Shopping',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
