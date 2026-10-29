import 'package:flutter/material.dart';

class WebRevenLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const WebRevenLogo({
    super.key,
    this.size = 36,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0D),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.75),
          width: size > 40 ? 1.5 : 1.0,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.35),
                  blurRadius: size * 0.3,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/webreven_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // High-tech cyber raven vector fallback matching client reference
            return CustomPaint(
              size: Size(size, size),
              painter: _CyberRavenPainter(),
            );
          },
        ),
      ),
    );
  }
}

class _CyberRavenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark background
    final bgPaint = Paint()..color = const Color(0xFF090D0B);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final greenGlow = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    final fillGreen = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;

    // 1. Radar Ring / Targeting Circle
    final center = Offset(w * 0.5, h * 0.5);
    canvas.drawCircle(center, w * 0.42, greenGlow);

    // 2. Raven Head silhouette
    final headPath = Path();
    headPath.moveTo(w * 0.5, h * 0.15); // Crown
    headPath.lineTo(w * 0.72, h * 0.38); // Right temple
    headPath.lineTo(w * 0.65, h * 0.62); // Right jaw
    headPath.lineTo(w * 0.5, h * 0.78); // Beak tip
    headPath.lineTo(w * 0.35, h * 0.62); // Left jaw
    headPath.lineTo(w * 0.28, h * 0.38); // Left temple
    headPath.close();

    final ravenPaint = Paint()..color = const Color(0xFF161F1A);
    canvas.drawPath(headPath, ravenPaint);

    final edgePaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawPath(headPath, edgePaint);

    // 3. Piercing 3 Eyes (Two main eyes + mystical third forehead eye)
    // Third eye (forehead)
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.065, fillGreen);
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.03, Paint()..color = Colors.black);

    // Left eye
    canvas.drawCircle(Offset(w * 0.40, h * 0.46), w * 0.05, fillGreen);
    canvas.drawCircle(Offset(w * 0.40, h * 0.46), w * 0.025, Paint()..color = Colors.black);

    // Right eye
    canvas.drawCircle(Offset(w * 0.60, h * 0.46), w * 0.05, fillGreen);
    canvas.drawCircle(Offset(w * 0.60, h * 0.46), w * 0.025, Paint()..color = Colors.black);

    // 4. Cyber Beak Highlight
    final beakPath = Path();
    beakPath.moveTo(w * 0.45, h * 0.54);
    beakPath.lineTo(w * 0.55, h * 0.54);
    beakPath.lineTo(w * 0.5, h * 0.76);
    beakPath.close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFF23352B));

    // 5. Neon Green Mail Envelope
    final envRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.82), width: w * 0.42, height: h * 0.24);
    final envRRect = RRect.fromRectAndRadius(envRect, const Radius.circular(3));
    final envBorder = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;
    canvas.drawRRect(envRRect, envBorder);

    final flapPath = Path();
    flapPath.moveTo(envRect.left, envRect.top);
    flapPath.lineTo(envRect.center.dx, envRect.center.dy + h * 0.03);
    flapPath.lineTo(envRect.right, envRect.top);
    canvas.drawPath(flapPath, envBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
