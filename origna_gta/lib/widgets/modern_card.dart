import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:origna_gta/utils/design_tokens.dart';
import 'package:flutter/widget_previews.dart';

/// Modern 2100 Card with glassmorphism and hover effects
class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool enableHoverScale;
  final double? width;
  final double? height;
  final String? semanticLabel;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(DesignTokens.spacing16),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(DesignTokens.radius16),
    ),
    this.enableHoverScale = true,
    this.width,
    this.height,
    this.semanticLabel,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _elevationAnimation,
          builder: (context, child) {
            final card = GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color:
                      widget.backgroundColor ??
                      (isDark
                          ? DesignTokens.darkSurfaceVariant.withValues(
                              alpha: 0.6,
                            )
                          : DesignTokens.surface),
                  borderRadius: widget.borderRadius,
                  border: Border.all(
                    color: DesignTokens.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: Padding(padding: widget.padding, child: widget.child),
                ),
              ),
            );
            if (widget.semanticLabel != null) {
              return Semantics(label: widget.semanticLabel, child: card);
            }
            // WCAG 4.1.2: Interactive cards must have a semantic role
            if (widget.onTap != null) {
              return Semantics(button: true, child: card);
            }
            return card;
          },
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
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 8, end: 16).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.easeOutCubic),
    );
  }

  void _onHover(bool isHovering) {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux) {
      return;
    }
    if (widget.enableHoverScale && widget.onTap != null) {
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

@Preview(name: 'Basic card — dark', group: 'Cards')
Widget previewCardBasic() => previewWrapper(
  child: ModernCard(
    onTap: () {},
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_outlined,
                color: DesignTokens.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toronto Vintage',
                    style: TextStyle(
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '4.8 ★  ·  142 sales',
                    style: TextStyle(
                      color: DesignTokens.white.withValues(alpha: 0.54),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: DesignTokens.white.withValues(alpha: 0.54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: DesignTokens.white.withValues(alpha: 0.12)),
        const SizedBox(height: 12),
        Text(
          'Vintage clothing from the 80s and 90s. Authenticated and curated.',
          style: TextStyle(
            color: DesignTokens.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    ),
  ),
);

@Preview(name: 'Info card — stats', group: 'Cards')
Widget previewCardStats() => previewWrapper(
  child: ModernCard(
    child: Column(
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        _statRow('Subtotal', '\$89.99'),
        _statRow('Platform Fee (2.5%)', '\$2.25'),
        _statRow('Estimated Tax', '\$11.70'),
        _statRow('Shipping', '\$12.00'),
        Divider(color: DesignTokens.white.withValues(alpha: 0.12), height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Total',
              style: TextStyle(
                color: DesignTokens.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              '\$115.94',
              style: TextStyle(
                color: DesignTokens.primary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);

Widget _statRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: DesignTokens.white.withValues(alpha: 0.54),
          fontSize: 14,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: DesignTokens.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
);

@Preview(name: 'Alert card — warning', group: 'Cards')
Widget previewCardWarning() => previewWrapper(
  child: ModernCard(
    backgroundColor: DesignTokens.warning.withValues(alpha: 0.15),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DesignTokens.warning.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: DesignTokens.warning,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stock running low',
                style: TextStyle(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Only 2 items left in stock.',
                style: TextStyle(
                  color: DesignTokens.white.withValues(alpha: 0.54),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

@Preview(name: 'Success card', group: 'Cards')
Widget previewCardSuccess() => previewWrapper(
  child: ModernCard(
    backgroundColor: DesignTokens.success.withValues(alpha: 0.12),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DesignTokens.success.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: DesignTokens.success,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Placed!',
                style: TextStyle(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                'Your order #ORD-2025-8472 is confirmed.',
                style: TextStyle(
                  color: DesignTokens.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

@Preview(name: 'Empty state card', group: 'Cards')
Widget previewCardEmpty() => previewWrapper(
  child: ModernCard(
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: DesignTokens.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: DesignTokens.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No orders yet',
          style: TextStyle(
            color: DesignTokens.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Browse the marketplace and\nplace your first order.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.white.withValues(alpha: 0.54),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    ),
  ),
);

@Preview(name: 'Light mode', group: 'Cards', brightness: Brightness.light)
Widget previewCardLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: ModernCard(
    backgroundColor: DesignTokens.white,
    onTap: () {},
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Title',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        SizedBox(height: 4),
        Text(
          'By Toronto Vintage  ·  4.8 ★',
          style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
        ),
        SizedBox(height: 12),
        Text(
          '\$89.99 CAD',
          style: TextStyle(
            color: DesignTokens.primary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ],
    ),
  ),
);

// ═══ Widget Previews ═══

@Preview(name: 'Modern Card — Complex Content', group: 'ModernCard')
Widget previewCardComplex() => previewGrid(
  children: [
    ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: DesignTokens.warning),
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                'Premium Offer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          const Text('Get exclusive access to Canadian heritage products.'),
        ],
      ),
    ),
  ],
);

@Preview(name: 'Modern Card — Variants', group: 'ModernCard')
Widget previewCardVariants() => previewGrid(
  children: [
    const ModernCard(child: Text('Basic Card Content')),
    ModernCard(onTap: () {}, child: const Text('Interactive Card (Hover Me)')),
    ModernCard(
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
      child: const Text('Custom Background Color'),
    ),
    ModernCard(
      borderRadius: BorderRadius.circular(DesignTokens.radius8),
      padding: const EdgeInsets.all(DesignTokens.spacing8),
      child: const Text('Small Radius & Padding'),
    ),
  ],
);

@Preview(name: 'Modern Card Light — Complex Content', group: 'ModernCard')
Widget previewCardComplexLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: DesignTokens.warning),
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                'Premium Offer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          const Text('Get exclusive access to Canadian heritage products.'),
        ],
      ),
    ),
  ],
);

@Preview(name: 'Modern Card Light — Variants', group: 'ModernCard')
Widget previewCardVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    const ModernCard(child: Text('Basic Card Content')),
    ModernCard(onTap: () {}, child: const Text('Interactive Card (Hover Me)')),
    ModernCard(
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
      child: const Text('Custom Background Color'),
    ),
    ModernCard(
      borderRadius: BorderRadius.circular(DesignTokens.radius8),
      padding: const EdgeInsets.all(DesignTokens.spacing8),
      child: const Text('Small Radius & Padding'),
    ),
  ],
);
