import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:origna_gta/utils/design_tokens.dart';
import 'modern_loading_indicator.dart';
import 'package:flutter/widget_previews.dart';

/// Modern 2100 Button with gradient and smooth interactions
class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;
  final String? imageIcon;
  final double width;
  final double height;
  final bool fullWidth;
  final Color? backgroundColor;
  final String? semanticsLabel;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isOutlined = false,
    this.icon,
    this.imageIcon,
    this.width = double.infinity,
    this.height = 52,
    this.fullWidth = true,
    this.backgroundColor,
    this.semanticsLabel,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  Widget build(BuildContext context) {
    // Theme detection for future dark mode support
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.semanticsLabel ?? widget.label,
      container: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: isDisabled
            ? null
            : (_) {
                if (widget.isPrimary && !widget.isOutlined) {
                  HapticFeedback.lightImpact();
                }
                _scaleController.forward();
              },
        onTapUp: isDisabled
            ? null
            : (_) {
                _scaleController.reverse();
                // GestureDetector's onTapUp fires before InkWell's onTap; calling
                // widget.onPressed here would double-fire. Tap is handled by InkWell.
              },
        onTapCancel: isDisabled ? null : () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.fullWidth ? double.infinity : widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.isPrimary && !widget.isOutlined && !isDisabled
                  ? DesignTokens.primaryGradient
                  : null,
              color:
                  widget.backgroundColor ??
                  (widget.isOutlined
                      ? DesignTokens.transparent
                      : (!widget.isPrimary
                            ? DesignTokens.surface
                            : (isDisabled ? DesignTokens.textDisabled : null))),
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: widget.isOutlined
                  ? Border.all(color: DesignTokens.primary, width: 1.5)
                  : null,
              boxShadow: !widget.isOutlined && widget.isPrimary && !isDisabled
                  ? DesignTokens.shadowMd
                  : null,
            ),
            child: Material(
              color: DesignTokens.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                child: Center(
                  child: widget.isLoading
                      ? ModernLoadingIndicator(
                          size: 20,
                          color: widget.isPrimary && !widget.isOutlined
                              ? DesignTokens.white
                              : DesignTokens.primary,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacing12,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.imageIcon != null) ...[
                                  Image.asset(
                                    widget.imageIcon!,
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: DesignTokens.spacing8),
                                ] else if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color:
                                        widget.isPrimary && !widget.isOutlined
                                        ? DesignTokens.white
                                        : DesignTokens.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: DesignTokens.spacing8),
                                ],
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color:
                                        widget.isPrimary && !widget.isOutlined
                                        ? DesignTokens.white
                                        : DesignTokens.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

// ─── Primary Button ──────────────────────────────────────────────────────────

@Preview(name: 'Primary — dark', group: 'Buttons')
Widget previewPrimaryButtonDark() => previewWrapper(
  child: ModernButton(label: 'Checkout', onPressed: () {}),
);

@Preview(
  name: 'Primary — light',
  group: 'Buttons',
  brightness: Brightness.light,
)
Widget previewPrimaryButtonLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: ModernButton(label: 'Checkout', onPressed: () {}),
);

// ─── Loading State ────────────────────────────────────────────────────────────

@Preview(name: 'Loading', group: 'Buttons')
Widget previewButtonLoading() => previewWrapper(
  child: ModernButton(label: 'Processing…', isLoading: true, onPressed: () {}),
);

// ─── Disabled State ───────────────────────────────────────────────────────────

@Preview(name: 'Disabled', group: 'Buttons')
Widget previewButtonDisabled() => previewWrapper(
  child: const ModernButton(
    label: 'Unavailable',
    onPressed: null, // null = disabled
  ),
);

// ─── Outlined Button ──────────────────────────────────────────────────────────

@Preview(name: 'Outlined', group: 'Buttons')
Widget previewButtonOutlined() => previewWrapper(
  child: ModernButton(
    label: 'Cancel Order',
    isOutlined: true,
    onPressed: () {},
  ),
);

// ─── With Icon ────────────────────────────────────────────────────────────────

@Preview(name: 'With Icon', group: 'Buttons')
Widget previewButtonWithIcon() => previewWrapper(
  child: ModernButton(
    label: 'Add to Cart',
    icon: Icons.shopping_cart_outlined,
    onPressed: () {},
  ),
);

// ─── Secondary (non-primary) ─────────────────────────────────────────────────

@Preview(name: 'Secondary', group: 'Buttons')
Widget previewButtonSecondary() => previewWrapper(
  child: ModernButton(
    label: 'View Details',
    isPrimary: false,
    onPressed: () {},
  ),
);

// ─── All States ───────────────────────────────────────────────────────────────

@Preview(name: 'All States', group: 'Buttons')
Widget previewButtonAllStates() => previewGrid(
  children: [
    ModernButton(label: 'Primary', onPressed: () {}),
    ModernButton(
      label: 'With Icon',
      icon: Icons.shopping_bag_outlined,
      onPressed: () {},
    ),
    ModernButton(label: 'Outlined', isOutlined: true, onPressed: () {}),
    ModernButton(label: 'Secondary', isPrimary: false, onPressed: () {}),
    ModernButton(label: 'Loading…', isLoading: true, onPressed: () {}),
    const ModernButton(label: 'Disabled', onPressed: null),
  ],
);

// ═══ Widget Previews ═══

@Preview(name: 'Modern Button — States', group: 'ModernButton')
Widget previewButtonStates() => previewGrid(
  children: [
    ModernButton(
      label: 'With Icon',
      icon: Icons.shopping_basket_rounded,
      onPressed: () {},
    ),
    ModernButton(label: 'Loading State', isLoading: true, onPressed: () {}),
    ModernButton(label: 'Custom Height', height: 60, onPressed: () {}),
    ModernButton(
      label: 'Fixed Width',
      fullWidth: false,
      width: 200,
      onPressed: () {},
    ),
  ],
);

@Preview(name: 'Modern Button — Types', group: 'ModernButton')
Widget previewButtonTypes() => previewGrid(
  children: [
    ModernButton(label: 'Primary Button', onPressed: () {}),
    ModernButton(label: 'Secondary Button', isPrimary: false, onPressed: () {}),
    ModernButton(label: 'Outlined Button', isOutlined: true, onPressed: () {}),
    const ModernButton(label: 'Disabled Button', onPressed: null),
  ],
);

@Preview(name: 'Modern Button Light — States', group: 'ModernButton')
Widget previewButtonStatesLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    ModernButton(
      label: 'With Icon',
      icon: Icons.shopping_basket_rounded,
      onPressed: () {},
    ),
    ModernButton(label: 'Loading State', isLoading: true, onPressed: () {}),
    ModernButton(label: 'Custom Height', height: 60, onPressed: () {}),
    ModernButton(
      label: 'Fixed Width',
      fullWidth: false,
      width: 200,
      onPressed: () {},
    ),
  ],
);

@Preview(name: 'Modern Button Light — Types', group: 'ModernButton')
Widget previewButtonTypesLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    ModernButton(label: 'Primary Button', onPressed: () {}),
    ModernButton(label: 'Secondary Button', isPrimary: false, onPressed: () {}),
    ModernButton(label: 'Outlined Button', isOutlined: true, onPressed: () {}),
    const ModernButton(label: 'Disabled Button', onPressed: null),
  ],
);
