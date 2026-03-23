import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';

/// Shared cart badge widget used across the app.
///
/// Two modes:
/// - **Animated** (`animated: true`): scale/pulse hover effects, email
///   verification before navigation. Used in the home hero section.
/// - **Simple** (`animated: false`): plain icon button with count badge.
///   Used in [CustomAppBar].
class CartBadge extends ConsumerStatefulWidget {
  /// When true, adds scale/pulse animations on hover and tap.
  final bool animated;

  /// Icon colour — defaults to [DesignTokens.textOnPrimary].
  final Color iconColor;

  /// Whether to check email verification before navigating to cart.
  final bool requireEmailVerification;

  /// Optional tooltip override. Defaults to a localised "Shopping cart" string.
  final String? tooltip;

  /// Badge positioning offset from the top-right corner.
  final double badgeRight;
  final double badgeTop;

  /// Whether the badge shows a border and glow (home-hero style) or a plain
  /// circle (app-bar style).
  final bool showBadgeBorder;

  const CartBadge({
    super.key,
    this.animated = false,
    this.iconColor = DesignTokens.textOnPrimary,
    this.requireEmailVerification = false,
    this.tooltip,
    this.badgeRight = -2,
    this.badgeTop = -2,
    this.showBadgeBorder = false,
  });

  /// Convenience constructor matching the old home hero section badge.
  const CartBadge.animated({super.key})
    : animated = true,
      iconColor = DesignTokens.textOnPrimary,
      requireEmailVerification = true,
      tooltip = null,
      badgeRight = -2,
      badgeTop = -2,
      showBadgeBorder = true;

  /// Convenience constructor matching the old custom app-bar badge.
  const CartBadge.appBar({super.key})
    : animated = false,
      iconColor = DesignTokens.white,
      requireEmailVerification = false,
      tooltip = null,
      badgeRight = 4,
      badgeTop = 4,
      showBadgeBorder = false;

  @override
  ConsumerState<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends ConsumerState<CartBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack),
      );
      _pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _controller?.forward().then((_) => _controller?.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(currentUserProvider.select((u) => u != null));
    final cartCount = ref.watch(cartItemCountProvider);
    final resolvedTooltip =
        widget.tooltip ??
        (widget.animated ? 'home.shopping_cart'.tr() : 'common.cart'.tr());

    Widget iconButton = Semantics(
      button: true,
      label: 'btn-cart',
      child: IconButton(
        key: const Key('cart_badge_button'),
        tooltip: resolvedTooltip,
        icon: Icon(Icons.shopping_cart_outlined, color: widget.iconColor),
        onPressed: () async {
          _triggerAnimation();
          if (!isLoggedIn) {
            showLoginPrompt(context);
            return;
          }
          if (widget.requireEmailVerification) {
            if (!context.mounted) return;
            final verified = await checkEmailVerifiedOrPrompt(context, ref);
            if (!verified) return;
          }
          if (!context.mounted) return;
          Navigator.pushNamed(context, AppRoutes.cart);
        },
      ),
    );

    // Wrap in scale animation when animated
    if (widget.animated && _scaleAnimation != null) {
      iconButton = AnimatedBuilder(
        animation: _scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation!.value, child: child);
        },
        child: iconButton,
      );
    }

    Widget? badge;
    if (cartCount > 0) {
      badge = Positioned(
        right: widget.badgeRight,
        top: widget.badgeTop,
        child: _buildBadgeCircle(cartCount),
      );

      // Wrap badge in pulse animation when animated
      if (widget.animated && _pulseAnimation != null) {
        badge = Positioned(
          right: widget.badgeRight,
          top: widget.badgeTop,
          child: AnimatedBuilder(
            animation: _pulseAnimation!,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation!.value,
                child: child,
              );
            },
            child: _buildBadgeCircle(cartCount),
          ),
        );
      }
    }

    Widget stack = Stack(
      clipBehavior: Clip.none,
      children: [iconButton, if (badge != null) badge],
    );

    if (widget.animated) {
      stack = MouseRegion(onEnter: (_) => _triggerAnimation(), child: stack);
    }

    return stack;
  }

  Widget _buildBadgeCircle(int cartCount) {
    return Container(
      padding: EdgeInsets.all(widget.showBadgeBorder ? 5 : 4),
      decoration: BoxDecoration(
        color: DesignTokens.textOnPrimary,
        shape: BoxShape.circle,
        border: widget.showBadgeBorder
            ? Border.all(color: DesignTokens.primary, width: 2)
            : null,
        boxShadow: widget.showBadgeBorder
            ? [
                BoxShadow(
                  color: DesignTokens.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      constraints: BoxConstraints(
        minWidth: widget.showBadgeBorder ? 20 : 18,
        minHeight: widget.showBadgeBorder ? 20 : 18,
      ),
      child: Text(
        cartCount > 99 ? '99+' : '$cartCount',
        style: const TextStyle(
          color: DesignTokens.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
