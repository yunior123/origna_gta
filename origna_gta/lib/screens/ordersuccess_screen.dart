// OrderSuccessScreen
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/services/analytics_service.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final double valueCad;
  final int itemCount;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.valueCad = 0,
    this.itemCount = 0,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'order_success',
      data: {'orderId': widget.orderId},
      timestamp: DateTime.now(),
    ));
    AnalyticsService.logPurchase(
      orderId: widget.orderId,
      valueCad: widget.valueCad,
      itemCount: widget.itemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
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
                        child: Text(
                          'orders.order_placed'.tr(),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
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
                          'orders.order_id_label'.tr(namedArgs: {'id': widget.orderId}),
                          style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'orders.thank_you'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: DesignTokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 250),
                      child: Semantics(
                        button: true,
                        label: 'btn-continue-shopping',
                        child: ModernButton(
                          label: 'orders.continue_shopping'.tr(),
                          icon: Icons.shopping_bag_outlined,
                          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: Semantics(
                        button: true,
                        label: 'btn-view-my-orders',
                        child: ModernButton(
                          label: 'orders.view_my_orders'.tr(),
                          icon: Icons.receipt_long_outlined,
                          isPrimary: false,
                          isOutlined: true,
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.orders,
                              (route) => route.settings.name == AppRoutes.home,
                            );
                          },
                        ),
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