part of '../login_screen.dart';

/// Google "G" logo mark rendered with official brand colors.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw the 4-color Google G
    // Blue: top → right (~270° to ~30°)
    paint.color = DesignTokens.googleBlue;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.57,
      2.09,
      true,
      paint,
    );

    // Red: left-top (~150° to ~270°)
    paint.color = DesignTokens.googleRed;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.62,
      1.83,
      true,
      paint,
    );

    // Yellow: bottom-left (~90° to ~150°)
    paint.color = DesignTokens.googleYellow;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.57,
      1.05,
      true,
      paint,
    );

    // Green: right-bottom (~30° to ~90°)
    paint.color = DesignTokens.googleGreen;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.52,
      1.05,
      true,
      paint,
    );

    // White center circle to create the "G" cutout
    paint.color = DesignTokens.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);

    // White horizontal bar for the "G" crossbar
    final barPaint = Paint()
      ..color = DesignTokens.googleBlue
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.18, r, r * 0.36), barPaint);

    // Re-mask outer arc for the crossbar area (only right half shows blue in crossbar)
    paint.color = DesignTokens.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);
    // Redraw the crossbar portion in the cutout
    barPaint.color = DesignTokens.googleBlue;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r * 0.42, r * 0.36),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Google Sign-In button following Google's branding guidelines.
/// Uses a white background with the Google "G" logo mark and correct typography.
class _GoogleSignInButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scale;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      // 'login_google_button' is the stable E2E selector; widget.label is the human-readable text.
      label: 'login_google_button',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _scaleController.forward(),
        onTapUp: isDisabled ? null : (_) => _scaleController.reverse(),
        onTapCancel: isDisabled ? null : () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.googleDarkBg : DesignTokens.white,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: Border.all(
                color: isDark
                    ? DesignTokens.googleDarkBorder
                    : DesignTokens.googleLightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: DesignTokens.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                child: Center(
                  child: widget.isLoading
                      ? const ModernLoadingIndicator(
                          size: 20,
                          color: DesignTokens.googleBlue,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Google G logo mark using official brand colors
                            _GoogleGLogo(),
                            const SizedBox(width: 10),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? DesignTokens.white
                                    : DesignTokens.googleDarkText,
                                letterSpacing: 0.25,
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
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }
}
