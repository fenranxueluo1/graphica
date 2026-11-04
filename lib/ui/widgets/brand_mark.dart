import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Rounded-square brand mark with a plotted curve and glowing gradient.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.brand, palette.brandAlt],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: palette.brand.withValues(alpha: 0.40),
            blurRadius: size * 0.5,
            spreadRadius: -size * 0.1,
            offset: Offset(0, size * 0.18),
          ),
        ],
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.22, h * 0.76),
      Offset(w * 0.80, h * 0.76),
      axisPaint,
    );
    canvas.drawLine(
      Offset(w * 0.22, h * 0.76),
      Offset(w * 0.22, h * 0.20),
      axisPaint,
    );

    final curve = Path();
    final amplitude = h * 0.19;
    for (var i = 0; i <= 48; i++) {
      final t = i / 48;
      final x = w * (0.26 + 0.52 * t);
      final y = h * 0.52 - amplitude * _sin(t * 3.14159 * 2);
      if (i == 0) {
        curve.moveTo(x, y);
      } else {
        curve.lineTo(x, y);
      }
    }

    canvas.drawPath(
      curve,
      Paint()
        ..color = Colors.white
        ..strokeWidth = w * 0.075
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  double _sin(double value) {
    // Small polynomial sine is enough for the decorative mark.
    var x = value % (2 * 3.141592653589793);
    if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
