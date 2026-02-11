// OrderSuccessScreen
import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/modern_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

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
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
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
                            colors: [
                              DesignTokens.success.withValues(alpha: 0.15),
                              DesignTokens.success.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.success.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(Icons.check_circle_rounded, size: 80, color: DesignTokens.success),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: ShaderMask(
                        shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                        child: const Text(
                          'Order Placed Successfully!',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : DesignTokens.surfaceVariant,
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
                        child: Text(
                          'Order ID: $orderId',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Thank you for your purchase!\nYou will receive a confirmation email shortly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 250),
                      child: ModernButton(
                        label: 'Continue Shopping',
                        icon: Icons.shopping_bag_outlined,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: ModernButton(
                        label: 'View My Orders',
                        icon: Icons.receipt_long_outlined,
                        isPrimary: false,
                        isOutlined: true,
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.orders,
                            (route) => route.isFirst,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}