import 'dart:math' as math;
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 1. THE CONTROLLER - "The Remote Control"
// -----------------------------------------------------------------------------
class MascotController extends ChangeNotifier {
  Offset _lookTarget = Offset.zero;
  bool _isJumping = false;
  double _excitementLevel = 0.0;

  Offset get lookTarget => _lookTarget;
  bool get isJumping => _isJumping;
  double get excitementLevel => _excitementLevel;

  /// Make the mascot look at a specific normalized coordinate (-1.0 to 1.0)
  void lookAt(Offset target) {
    _lookTarget = target;
    notifyListeners();
  }

  /// Trigger a jump animation
  Future<void> jump() async {
    if (_isJumping) return;
    _isJumping = true;
    notifyListeners();
    // The widget listens to this bool, triggers animation, then resets it.
    await Future.delayed(const Duration(milliseconds: 600)); 
    _isJumping = false;
    notifyListeners();
  }

  /// Set excitement (0.0 to 1.0) - e.g., when adding to cart
  void setExcitement(double level) {
    _excitementLevel = level.clamp(0.0, 1.0);
    notifyListeners();
  }
}

// -----------------------------------------------------------------------------
// 2. THE WIDGET - "The Stage"
// -----------------------------------------------------------------------------
class ShopMascot extends StatefulWidget {
  final MascotController controller;
  final double size;

  const ShopMascot({
    super.key, 
    required this.controller, 
    this.size = 200,
  });

  @override
  State<ShopMascot> createState() => _ShopMascotState();
}

class _ShopMascotState extends State<ShopMascot> with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _jumpController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    // 1. Idle Loop (Breathing/Hovering)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. Jump Animation
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 3. Blinking Loop (Randomized)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _startBlinkLoop();

    // Listen to controller commands
    widget.controller.addListener(_handleCommand);
  }

  void _handleCommand() {
    if (widget.controller.isJumping && !_jumpController.isAnimating) {
      _jumpController.forward(from: 0).then((_) => _jumpController.reverse());
    }
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2000 + math.Random().nextInt(2000)));
      if (!mounted) return;
      await _blinkController.forward();
      await _blinkController.reverse();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _jumpController.dispose();
    _blinkController.dispose();
    widget.controller.removeListener(_handleCommand);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleController, 
        _jumpController, 
        _blinkController, 
        widget.controller
      ]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: MascotPainter(
            idleValue: _idleController.value,
            jumpValue: _jumpController.value,
            blinkValue: _blinkController.value,
            lookTarget: widget.controller.lookTarget,
            excitement: widget.controller.excitementLevel,
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. THE PAINTER - "The Artist"
// -----------------------------------------------------------------------------
class MascotPainter extends CustomPainter {
  final double idleValue; // 0.0 to 1.0 (Sinewave basis)
  final double jumpValue; // 0.0 to 1.0 (Impulse)
  final double blinkValue; // 0.0 to 1.0 (Closed eyes)
  final Offset lookTarget; // x,y from -1 to 1
  final double excitement; // 0.0 to 1.0

  MascotPainter({
    required this.idleValue,
    required this.jumpValue,
    required this.blinkValue,
    required this.lookTarget,
    required this.excitement,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // --- Physics Calculation ---
    // Hover effect: Smooth sine wave
    final hoverOffset = math.sin(idleValue * math.pi * 2) * 8.0;
    
    // Jump effect: Parabolic arc
    final jumpOffset = -math.sin(jumpValue * math.pi) * (size.height * 0.3);
    
    // Squash & Stretch: Stretch Y when jumping up, Squash Y when landing
    final stretch = 1.0 + (jumpValue * 0.1) - (jumpValue > 0.8 ? 0.15 : 0.0);
    final squash = 1.0 - (jumpValue * 0.05) + (jumpValue > 0.8 ? 0.1 : 0.0);

    // Apply Transformations
    canvas.save();
    canvas.translate(center.dx, center.dy + hoverOffset + jumpOffset);
    canvas.scale(squash, stretch); // Apply Squash & Stretch

    _drawShadow(canvas, size, jumpValue);
    _drawBody(canvas, size);
    _drawFace(canvas, size);
    _drawAntenna(canvas, size);
    _drawHands(canvas, size);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas, Size size, double jumpHeight) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15 * (1 - jumpHeight))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Shadow shrinks as he jumps
    final shadowSize = (size.width * 0.6) * (1 - (jumpHeight * 0.4));
    
    // Draw shadow decoupled from the body translation (so it stays on the floor)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, size.height * 0.45 - (jumpOffset_reference_hack(jumpHeight, size))), 
        width: shadowSize, 
        height: shadowSize * 0.25
      ),
      shadowPaint,
    );
  }
  
  // Helper to reverse the translate calculation for shadow specifically
  double jumpOffset_reference_hack(double val, Size size) => 
      -math.sin(val * math.pi) * (size.height * 0.3);

  void _drawBody(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.cyan.shade300, Colors.pink.shade300, excitement)!,
          Color.lerp(Colors.blue.shade600, Colors.purple.shade600, excitement)!,
        ],
      ).createShader(Rect.fromLTWH(-100, -100, 200, 200));

    // A nice "Squircle" shape
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size.width * 0.5, height: size.height * 0.45),
      const Radius.circular(40),
    );
    canvas.drawRRect(rrect, bodyPaint);
    
    // Highlight (Reflective shine)
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-30, -30), width: 30, height: 20), 
      shinePaint
    );
  }

  void _drawFace(Canvas canvas, Size size) {
    // Screen/Face background
    final facePaint = Paint()..color = const Color(0xFF1A1A1A);
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -10), width: size.width * 0.35, height: size.height * 0.25),
      const Radius.circular(20),
    );
    canvas.drawRRect(faceRect, facePaint);

    // Eyes Logic
    final eyeColor = Color.lerp(Colors.cyanAccent, Colors.amberAccent, excitement)!;
    final eyePaint = Paint()..color = eyeColor;
    
    // Eye Movement Clamping (Move pupils based on lookTarget)
    final lookX = lookTarget.dx * 10;
    final lookY = lookTarget.dy * 5;

    // Left Eye
    _drawEye(canvas, Offset(-25 + lookX, -10 + lookY), eyePaint);
    // Right Eye
    _drawEye(canvas, Offset(25 + lookX, -10 + lookY), eyePaint);
  }

  void _drawEye(Canvas canvas, Offset center, Paint paint) {
    if (blinkValue > 0.1) {
      // Blink: Draw a line
      final stroke = Paint()
        ..color = paint.color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center - const Offset(10, 0), center + const Offset(10, 0), stroke);
    } else {
      // Open: Draw circle
      // Add slight scale vibration if excited
      final radius = 8.0 + (excitement * math.sin(DateTime.now().millisecondsSinceEpoch / 50) * 1.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawAntenna(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 4;
    
    // The stick
    canvas.drawLine(const Offset(0, -50), const Offset(0, -70), paint);

    // The glow ball
    final ballPaint = Paint()..color = Color.lerp(Colors.redAccent, Colors.greenAccent, excitement)!;
    
    // Bobble effect for antenna
    final bobble = math.sin(idleValue * math.pi * 4) * 2;
    canvas.drawCircle(Offset(bobble, -75), 6, ballPaint);
    
    // Glow effect
    final glowPaint = Paint()
      ..color = ballPaint.color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(bobble, -75), 12, glowPaint);
  }

  void _drawHands(Canvas canvas, Size size) {
    final handPaint = Paint()..color = Colors.white;
    
    // Hands float independent of body somewhat
    final handY = 20.0 + (math.sin(idleValue * math.pi * 2 + 1) * 5.0); // Phase shifted hover

    // Left Hand
    canvas.drawCircle(Offset(-size.width * 0.3, handY), 12, handPaint);
    // Right Hand
    canvas.drawCircle(Offset(size.width * 0.3, handY), 12, handPaint);
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) => true;
}
