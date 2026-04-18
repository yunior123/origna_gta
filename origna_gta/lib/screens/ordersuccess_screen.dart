// OrderSuccessScreen
import 'package:origna_gta/utils/preview_helpers.dart';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/models/generated/models.dart' show PaymentStatus;
import 'package:origna_gta/services/analytics_service.dart'
    show analyticsServiceProvider;
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/mascot/shop_mascot.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/widget_previews.dart';

/// Post-payment success screen that polls for the confirmed order via Stripe session ID.
class OrderSuccessScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double valueCad;
  final int itemCount;

  /// Max estimated ship days across all order items (null = don't show window)
  final int? estimatedShipDays;

  /// True when all items are local-delivery-only (show hours, not days)
  final bool isLocalDelivery;

  /// Preview/test safety switch for analytics + Sentry side effects.
  final bool enableSideEffects;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.valueCad = 0,
    this.itemCount = 0,
    this.estimatedShipDays,
    this.isLocalDelivery = false,
    this.enableSideEffects = true,
  });

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

// ── Confetti celebration ────────────────────────────────────────────────────

class _ConfettiAnimation extends StatefulWidget {
  const _ConfettiAnimation();

  @override
  State<_ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<_ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(35, (i) => _Particle.random(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(count: 3);
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y =
          ((t * p.speedFactor + p.yOffset) % 1.0) * (size.height + 20) - 10;
      final x = p.xFrac * size.width;
      final paint = Paint()..color = p.color.withValues(alpha: 0.82);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * p.speedFactor * math.pi * 6);
      // Alternating rectangles and diamonds for variety
      if (p.size > 9) {
        final path = Path()
          ..moveTo(0, -p.size * 0.5)
          ..lineTo(p.size * 0.4, 0)
          ..lineTo(0, p.size * 0.5)
          ..lineTo(-p.size * 0.4, 0)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => t != old.t;
}

// ── Delivery window card ────────────────────────────────────────────────────

class _DeliveryWindowCard extends StatelessWidget {
  final int estimatedShipDays;
  final bool isLocalDelivery;

  const _DeliveryWindowCard({
    required this.estimatedShipDays,
    this.isLocalDelivery = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String windowLabel;

    if (isLocalDelivery) {
      // Local / same-day: show in hours (2–4h window)
      windowLabel = 'orders.delivery_window_hours'.tr();
    } else {
      final now = DateTime.now();
      // Processing time: +1 day
      final earliest = now.add(Duration(days: estimatedShipDays + 1));
      final latest = now.add(Duration(days: estimatedShipDays + 3));
      final fmt = DateFormat('MMM d');
      windowLabel = '${fmt.format(earliest)} – ${fmt.format(latest)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.success.withValues(alpha: 0.08)
            : DesignTokens.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 20,
            color: DesignTokens.success,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'orders.estimated_delivery'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                windowLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  late final MascotController _mascotController;

  Future<void> _logPurchaseIfPaymentConfirmed() async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final order = await orderRepo.fetchOrderById(widget.orderId);
      if (order == null) return;
      final status = order.paymentStatus;
      if (status == PaymentStatus.captured || status == PaymentStatus.paid) {
        ref
            .read(analyticsServiceProvider)
            .logPurchase(
              orderId: widget.orderId,
              valueCad: widget.valueCad,
              itemCount: widget.itemCount,
            );
      } else {
        AppLogger.d(
          'Skipping analytics: payment status is $status',
          tag: 'order_success',
        );
      }
    } catch (e) {
      AppLogger.w(
        'Failed to verify payment status for analytics',
        tag: 'order_success',
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Confetti celebration particles
              const Positioned.fill(child: _ConfettiAnimation()),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacing24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Celebrating mascot
                        FadeSlideIn(
                          child: ShopMascot(
                            controller: _mascotController,
                            size: 90,
                            showSpeechBubble: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 50),
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
                                  color: DesignTokens.success.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 80,
                              color: DesignTokens.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: ShaderMask(
                            shaderCallback: (bounds) => DesignTokens
                                .primaryGradient
                                .createShader(bounds),
                            child: Text(
                              'orders.order_placed'.tr(),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: DesignTokens.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DesignTokens.white.withValues(alpha: 0.06)
                                  : DesignTokens.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radius12,
                              ),
                            ),
                            child: Text(
                              'orders.order_id_label'.tr(
                                namedArgs: {'id': widget.orderId},
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: DesignTokens.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
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
                        // ── AUDIT FIX [HIGH]: Show purchase summary (value + items) ──
                        // Previously valueCad and itemCount were passed to this screen
                        // but never rendered — a major gap in the success experience.
                        if (widget.valueCad > 0 || widget.itemCount > 0) ...[
                          const SizedBox(height: 20),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 230),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    DesignTokens.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    DesignTokens.secondary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius16,
                                ),
                                border: Border.all(
                                  color: DesignTokens.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.itemCount > 0) ...[
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 18,
                                      color: DesignTokens.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'orders.items_ordered'.tr(
                                        namedArgs: {
                                          'count': '${widget.itemCount}',
                                        },
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: DesignTokens.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (widget.itemCount > 0 &&
                                      widget.valueCad > 0) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Container(
                                        width: 1,
                                        height: 18,
                                        color: DesignTokens.outline,
                                      ),
                                    ),
                                  ],
                                  if (widget.valueCad > 0)
                                    ShaderMask(
                                      shaderCallback: (bounds) => DesignTokens
                                          .primaryGradient
                                          .createShader(bounds),
                                      child: Text(
                                        '\$${widget.valueCad.toStringAsFixed(2)} CAD',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: DesignTokens.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // Delivery window from Stitch UX
                        if (widget.estimatedShipDays != null ||
                            widget.isLocalDelivery) ...[
                          const SizedBox(height: 16),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 250),
                            child: _DeliveryWindowCard(
                              estimatedShipDays: widget.estimatedShipDays ?? 0,
                              isLocalDelivery: widget.isLocalDelivery,
                            ),
                          ),
                        ],
                        const SizedBox(height: 48),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: Semantics(
                            button: true,
                            label: 'btn-continue-shopping',
                            child: ModernButton(
                              label: 'orders.continue_shopping'.tr(),
                              icon: Icons.shopping_bag_outlined,
                              onPressed: () =>
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.home,
                                    (route) => false,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 360),
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
                                  (route) =>
                                      route.settings.name == AppRoutes.home,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ), // Center
            ], // Stack children
          ), // Stack
        ), // SafeArea
      ),
    );
  }

  @override
  void dispose() {
    _mascotController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mascotController = MascotController();
    // Trigger celebration after first frame so animation controllers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mascotController.setExcitement(1.0);
        _mascotController.jump();
      }
    });
    if (!widget.enableSideEffects) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'order_success',
        data: {'itemCount': widget.itemCount},
        timestamp: DateTime.now(),
      ),
    );
    // Only log analytics purchase event after confirming payment was captured/paid
    _logPurchaseIfPaymentConfirmed();
  }
}

class _Particle {
  final double xFrac;
  final double yOffset;
  final double speedFactor;
  final Color color;
  final double size;
  final double rotation;

  const _Particle({
    required this.xFrac,
    required this.yOffset,
    required this.speedFactor,
    required this.color,
    required this.size,
    required this.rotation,
  });

  factory _Particle.random(math.Random rng) {
    const colors = [
      DesignTokens.goldPrimary,
      DesignTokens.tertiary,
      DesignTokens.accent,
      DesignTokens.digital,
      DesignTokens.success,
      DesignTokens.confettiOrange,
      DesignTokens.confettiPink,
      DesignTokens.confettiCyan,
    ];
    return _Particle(
      xFrac: rng.nextDouble(),
      yOffset: rng.nextDouble(),
      speedFactor: 0.4 + rng.nextDouble() * 0.6,
      color: colors[rng.nextInt(colors.length)],
      size: 5.0 + rng.nextDouble() * 7.0,
      rotation: rng.nextDouble() * math.pi * 2,
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

Widget _orderSuccessContent() => previewScope(
  child: Scaffold(
    body: Center(
      child: OrderSuccessScreen(
        orderId: 'preview-id',
        valueCad: 126.40,
        itemCount: 3,
        estimatedShipDays: 2,
        enableSideEffects: false,
      ),
    ),
  ),
);

@Preview(
  name: 'Order Success — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrderSuccessScreenMobile() =>
    previewMobile(child: _orderSuccessContent());

@Preview(
  name: 'Order Success — Tablet',
  group: 'Order Screens',
  size: Size(768, 1024),
)
Widget previewOrderSuccessScreenTablet() =>
    previewTablet(child: _orderSuccessContent());

@Preview(
  name: 'Order Success — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrderSuccessScreenDesktop() =>
    previewDesktop(child: _orderSuccessContent());

@Preview(
  name: 'Order Success — Web',
  group: 'Order Screens',
  size: Size(1440, 900),
)
Widget previewOrderSuccessScreenWeb() =>
    previewWeb(child: _orderSuccessContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(
  name: 'Order Success Light — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrderSuccessScreenLightMobile() =>
    previewMobile(theme: previewLightTheme, child: _orderSuccessContent());

@Preview(
  name: 'Order Success Light — Tablet',
  group: 'Order Screens',
  size: Size(768, 1024),
)
Widget previewOrderSuccessScreenLightTablet() =>
    previewTablet(theme: previewLightTheme, child: _orderSuccessContent());

@Preview(
  name: 'Order Success Light — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrderSuccessScreenLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _orderSuccessContent());

@Preview(
  name: 'Order Success Light — Web',
  group: 'Order Screens',
  size: Size(1440, 900),
)
Widget previewOrderSuccessScreenLightWeb() =>
    previewWeb(theme: previewLightTheme, child: _orderSuccessContent());
