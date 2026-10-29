import 'package:flutter/material.dart';

class WebRevenLogo extends StatelessWidget {
  final double size;

  const WebRevenLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D9488), // Teal
            Color(0xFF0284C7), // Sky Blue
            Color(0xFF4F46E5), // Indigo
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.68, size * 0.68),
          painter: _RavenWingsPainter(),
        ),
      ),
    );
  }
}

class _RavenWingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Geometric Cyber-Raven Head & Beak Path
    final headPath = Path();
    // Beak tip
    headPath.moveTo(w * 0.92, h * 0.50);
    // Lower jaw
    headPath.lineTo(w * 0.58, h * 0.68);
    // Neck/chin
    headPath.lineTo(w * 0.45, h * 0.88);
    // Chest base
    headPath.lineTo(w * 0.25, h * 0.82);
    // Wing arc up
    headPath.lineTo(w * 0.08, h * 0.38);
    headPath.lineTo(w * 0.28, h * 0.42);
    headPath.lineTo(w * 0.20, h * 0.16);
    headPath.lineTo(w * 0.48, h * 0.28);
    // Forehead
    headPath.lineTo(w * 0.65, h * 0.25);
    // Beak bridge down to tip
    headPath.lineTo(w * 0.92, h * 0.50);
    headPath.close();

    canvas.drawPath(headPath, glowPaint);

    // 2. Glowing Eye Node (representing web intelligence)
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.58, h * 0.42), w * 0.07, eyePaint);

    final eyeCenter = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.59, h * 0.41), w * 0.035, eyeCenter);

    // 3. Web radar sweeping signal line
    final arcPath = Path();
    arcPath.moveTo(w * 0.72, h * 0.16);
    arcPath.quadraticBezierTo(w * 0.95, h * 0.24, w * 0.98, h * 0.44);
    canvas.drawPath(arcPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
