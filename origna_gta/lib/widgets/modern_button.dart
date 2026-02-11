import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/design_tokens.dart';
import 'modern_loading_indicator.dart';

/// Modern 2100 Button with gradient and smooth interactions
class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;
  final double width;
  final double height;
  final bool fullWidth;
  final Color? backgroundColor;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isOutlined = false,
    this.icon,
    this.width = double.infinity,
    this.height = 52,
    this.fullWidth = true,
    this.backgroundColor,
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
      label: widget.label,
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
                // Prevent double tap execution as InkWell handles the tap too
                // widget.onPressed?.call();
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
                    ? Colors.transparent
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
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              child: Center(
                child: widget.isLoading
                    ? ModernLoadingIndicator(
                        size: 20,
                        color: widget.isPrimary && !widget.isOutlined
                            ? Colors.white
                            : DesignTokens.primary,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.isPrimary && !widget.isOutlined
                                  ? Colors.white
                                  : DesignTokens.primary,
                              size: 18,
                            ),
                            const SizedBox(width: DesignTokens.spacing8),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: widget.isPrimary && !widget.isOutlined
                                  ? Colors.white
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
