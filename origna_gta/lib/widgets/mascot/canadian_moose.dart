import 'dart:math' as math;
import 'package:flutter/material.dart';

class MooseController extends ChangeNotifier {
  Offset _lookTarget = Offset.zero;
  bool _isJumping = false;
  double _excitementLevel = 0.0;

  Offset get lookTarget => _lookTarget;
  bool get isJumping => _isJumping;
  double get excitementLevel => _excitementLevel;

  void lookAt(Offset target) {
    final dx = target.dx.clamp(-1.0, 1.0);
    final dy = target.dy.clamp(-1.0, 1.0);
    _lookTarget = Offset(dx, dy);
    notifyListeners();
  }

  Future<void> jump() async {
    if (_isJumping) return;
    _isJumping = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _isJumping = false;
    notifyListeners();
  }

  void setExcitement(double level) {
    _excitementLevel = level.clamp(0.0, 1.0);
    notifyListeners();
  }
}

class CanadianMoose extends StatefulWidget {
  final MooseController controller;
  final double size;

  const CanadianMoose({
    super.key,
    required this.controller,
    this.size = 250,
  });

  @override
  State<CanadianMoose> createState() => _CanadianMooseState();
}

class _CanadianMooseState extends State<CanadianMoose> with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _jumpController;
  late AnimationController _blinkController;
  late AnimationController _earWiggleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _jumpController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _startBlinkLoop();
    _earWiggleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    widget.controller.addListener(_handleCommand);
  }

  void _handleCommand() {
    if (widget.controller.isJumping && !_jumpController.isAnimating) {
      _jumpController.forward(from: 0).then((_) => _jumpController.reverse());
    }
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 3000 + math.Random().nextInt(2000)));
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
    _earWiggleController.dispose();
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
        _earWiggleController,
        widget.controller
      ]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: MoosePainter(
            idleValue: _idleController.value,
            jumpValue: _jumpController.value,
            blinkValue: _blinkController.value,
            earWiggle: _earWiggleController.value,
            lookTarget: widget.controller.lookTarget,
            excitement: widget.controller.excitementLevel,
          ),
        );
      },
    );
  }
}

class MoosePainter extends CustomPainter {
  final double idleValue;
  final double jumpValue;
  final double blinkValue;
  final double earWiggle;
  final Offset lookTarget;
  final double excitement;

  MoosePainter({
    required this.idleValue,
    required this.jumpValue,
    required this.blinkValue,
    required this.earWiggle,
    required this.lookTarget,
    required this.excitement,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);
    final hoverY = math.sin(idleValue * math.pi * 2) * 4.0;
    final jumpY = -math.sin(jumpValue * math.pi) * (size.height * 0.25);
    final antlerLag = math.sin(jumpValue * math.pi * 2) * 10.0;
    canvas.save();
    canvas.translate(center.dx, center.dy + hoverY + jumpY);
    final lookAngleX = lookTarget.dx * 0.1;
    final lookAngleY = lookTarget.dy * 0.1;
    canvas.rotate(lookAngleX);
    _drawShadow(canvas, size, jumpValue);
    _drawBody(canvas, size);
    _drawScarf(canvas, size, hoverY);
    _drawHead(canvas, size, lookAngleY, antlerLag);
    canvas.restore();
  }

  void _drawShadow(Canvas canvas, Size size, double jumpHeight) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.2 * (1 - jumpHeight));
    final shadowSize = (size.width * 0.5) * (1 - (jumpHeight * 0.3));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, size.height * 0.35 - (-math.sin(jumpValue * math.pi) * (size.height * 0.25))),
        width: shadowSize,
        height: shadowSize * 0.3
      ),
      shadowPaint,
    );
  }

  void _drawBody(Canvas canvas, Size size) {
    final furColor = const Color(0xFF5D4037);
    final bodyPaint = Paint()..color = furColor;
    final bodyRect = Rect.fromCenter(center: const Offset(0, 50), width: size.width * 0.45, height: size.height * 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(40)), bodyPaint);
    final bellyPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 60), width: size.width * 0.25, height: size.height * 0.2), bellyPaint);
  }

  void _drawScarf(Canvas canvas, Size size, double wind) {
    canvas.save();
    final scarfPaint = Paint()..color = const Color(0xFFD32F2F);
    final scarfRect = Rect.fromCenter(center: const Offset(0, 10), width: size.width * 0.38, height: 30);
    canvas.drawRRect(RRect.fromRectAndRadius(scarfRect, const Radius.circular(10)), scarfPaint);
    final stripePaint = Paint()..color = Colors.black.withValues(alpha: 0.3)..strokeWidth = 3;
    canvas.drawLine(Offset(-40, 5), Offset(40, 5), stripePaint);
    canvas.drawLine(Offset(-40, 15), Offset(40, 15), stripePaint);
    for(double i = -30; i <= 30; i+= 15) {
       canvas.drawLine(Offset(i, 0), Offset(i, 25), stripePaint);
    }
    canvas.translate(45, 15);
    canvas.rotate(-0.2 + (math.sin(wind) * 0.1));
    final tailPath = Path()
      ..moveTo(0, 0)
      ..lineTo(25, 50)
      ..lineTo(-10, 50)
      ..lineTo(-15, 0)
      ..close();
    canvas.drawPath(tailPath, scarfPaint);
    canvas.drawLine(const Offset(5, 10), const Offset(5, 40), stripePaint);
    canvas.drawLine(const Offset(-5, 45), const Offset(20, 45), stripePaint);
    canvas.restore();
  }

  void _drawHead(Canvas canvas, Size size, double lookY, double antlerLag) {
    canvas.save();
    canvas.translate(0, lookY * 20);
    _drawAntlers(canvas, size, antlerLag);
    final headColor = const Color(0xFF6D4C41);
    final snoutColor = const Color(0xFF8D6E63);
    final headRect = Rect.fromCenter(center: const Offset(0, -60), width: size.width * 0.4, height: size.height * 0.35);
    _drawEars(canvas, headRect);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(50)), Paint()..color = headColor);
    final snoutRect = Rect.fromCenter(center: const Offset(0, -35), width: size.width * 0.42, height: size.height * 0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(snoutRect, const Radius.circular(40)), Paint()..color = snoutColor);
    _drawEyes(canvas);
    _drawNostrils(canvas);
    canvas.restore();
  }

  void _drawAntlers(Canvas canvas, Size size, double lag) {
    final antlerPaint = Paint()..color = const Color(0xFFEFEBE9);
    canvas.save();
    canvas.translate(-60, -100);
    canvas.rotate(-0.2 + (lag * 0.01));
    _drawSingleAntler(canvas, antlerPaint, true);
    canvas.restore();
    canvas.save();
    canvas.translate(60, -100);
    canvas.rotate(0.2 - (lag * 0.01));
    _drawSingleAntler(canvas, antlerPaint, false);
    canvas.restore();
  }

  void _drawSingleAntler(Canvas canvas, Paint paint, bool isLeft) {
    final scale = isLeft ? 1.0 : -1.0;
    canvas.scale(scale, 1.0);
    final palmPath = Path();
    palmPath.addOval(Rect.fromLTWH(0, 0, 80, 50));
    palmPath.addOval(Rect.fromLTWH(10, -20, 20, 40));
    palmPath.addOval(Rect.fromLTWH(35, -25, 20, 50));
    palmPath.addOval(Rect.fromLTWH(60, -15, 20, 40));
    canvas.drawPath(palmPath, paint);
  }

  void _drawEars(Canvas canvas, Rect headRect) {
    final earPaint = Paint()..color = const Color(0xFF5D4037);
    final wiggle = math.sin(earWiggle * math.pi * 2) * 0.1;
    canvas.save();
    canvas.translate(headRect.left + 10, headRect.top + 40);
    canvas.rotate(-0.5 + wiggle);
    canvas.drawOval(const Rect.fromLTWH(-30, -15, 40, 30), earPaint);
    canvas.restore();
    canvas.save();
    canvas.translate(headRect.right - 10, headRect.top + 40);
    canvas.rotate(0.5 - wiggle);
    canvas.drawOval(const Rect.fromLTWH(-10, -15, 40, 30), earPaint);
    canvas.restore();
  }

  void _drawEyes(Canvas canvas) {
    final eyeWhite = Paint()..color = Colors.white;
    final pupil = Paint()..color = Colors.black;
    final leftEyePos = Offset(-35 + (lookTarget.dx * 8), -80 + (lookTarget.dy * 5));
    final rightEyePos = Offset(35 + (lookTarget.dx * 8), -80 + (lookTarget.dy * 5));
    if (blinkValue > 0.1) {
      final blinkPaint = Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: leftEyePos, width: 25, height: 10), 0, 3.14, false, blinkPaint);
      canvas.drawArc(Rect.fromCenter(center: rightEyePos, width: 25, height: 10), 0, 3.14, false, blinkPaint);
    } else {
      canvas.drawCircle(leftEyePos, 14, eyeWhite);
      canvas.drawCircle(rightEyePos, 14, eyeWhite);
      canvas.drawCircle(leftEyePos, 6, pupil);
      canvas.drawCircle(rightEyePos, 6, pupil);
      canvas.drawCircle(leftEyePos - const Offset(3,3), 3, Paint()..color = Colors.white);
      canvas.drawCircle(rightEyePos - const Offset(3,3), 3, Paint()..color = Colors.white);
    }
  }

  void _drawNostrils(Canvas canvas) {
    final nostrilColor = const Color(0xFF3E2723);
    final paint = Paint()..color = nostrilColor;
    final flare = excitement * 5.0;
    canvas.drawOval(Rect.fromCenter(center: const Offset(-20, -35), width: 12 + flare, height: 8 + flare), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(20, -35), width: 12 + flare, height: 8 + flare), paint);
    final mouthPath = Path();
    mouthPath.moveTo(-10, -20);
    mouthPath.quadraticBezierTo(0, -10 + (excitement * 5), 10, -20);
    canvas.drawPath(mouthPath, Paint()..color = nostrilColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant MoosePainter oldDelegate) => true;
}
