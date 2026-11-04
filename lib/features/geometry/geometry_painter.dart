import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'geometry_model.dart';

/// Paints the coordinate grid and the constructed geometry.
class GeometryPainter extends CustomPainter {
  GeometryPainter({
    required this.controller,
    required this.centerX,
    required this.centerY,
    required this.scale,
    required this.gridColor,
    required this.axisColor,
    required this.labelColor,
    required this.pointColor,
    required this.segmentColor,
    required this.circleColor,
    required this.selectionColor,
    this.selectedPointId,
    this.pendingPointId,
    this.previewAnchor,
    this.previewCursor,
    this.previewCircle = false,
  });

  final GeometryController controller;
  final double centerX;
  final double centerY;
  final double scale;
  final Color gridColor;
  final Color axisColor;
  final Color labelColor;
  final Color pointColor;
  final Color segmentColor;
  final Color circleColor;
  final Color selectionColor;
  final String? selectedPointId;
  final String? pendingPointId;
  final Offset? previewAnchor;
  final Offset? previewCursor;
  final bool previewCircle;

  Offset toScreen(Offset graph, Size size) => Offset(
    size.width / 2 + (graph.dx - centerX) * scale,
    size.height / 2 - (graph.dy - centerY) * scale,
  );

  Offset toGraph(Offset screen, Size size) => Offset(
    centerX + (screen.dx - size.width / 2) / scale,
    centerY - (screen.dy - size.height / 2) / scale,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintGrid(canvas, size);

    for (final circle in controller.circles) {
      final center = controller.pointById(circle.center);
      if (center == null) continue;
      final screenCenter = toScreen(center.position, size);
      final radiusPx = circle.radius * scale;
      canvas.drawCircle(
        screenCenter,
        radiusPx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = circleColor,
      );
      canvas.drawCircle(
        screenCenter,
        radiusPx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = circleColor.withValues(alpha: 0.14),
      );
      final labelPos = screenCenter + Offset(0, -radiusPx - 8);
      _label(
        canvas,
        'r = ${formatNumber(circle.radius, precision: 4)}',
        labelPos,
      );
    }

    for (final segment in controller.segments) {
      final a = controller.pointById(segment.a);
      final b = controller.pointById(segment.b);
      if (a == null || b == null) continue;
      final paint = Paint()
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = segmentColor;
      canvas.drawLine(
        toScreen(a.position, size),
        toScreen(b.position, size),
        paint,
      );
      final midpoint =
          (toScreen(a.position, size) + toScreen(b.position, size)) / 2;
      _label(
        canvas,
        formatNumber(controller.segmentLength(segment), precision: 4),
        midpoint + const Offset(0, -14),
      );
    }

    _paintPreview(canvas, size);

    for (final point in controller.points) {
      final screen = toScreen(point.position, size);
      final selected = point.id == selectedPointId;
      final pending = point.id == pendingPointId;
      if (selected || pending) {
        canvas.drawCircle(
          screen,
          16,
          Paint()..color = selectionColor.withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(screen, 6.5, Paint()..color = pointColor);
      canvas.drawCircle(
        screen,
        6.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9),
      );
      _label(
        canvas,
        controller.labelFor(point),
        screen + const Offset(10, -18),
        bold: true,
      );
    }

    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    final step = niceStep(78 / scale);
    final minor = step / 5;
    final minorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    final left = centerX - size.width / 2 / scale;
    final right = centerX + size.width / 2 / scale;
    final bottom = centerY - size.height / 2 / scale;
    final top = centerY + size.height / 2 / scale;

    for (var x = (left / minor).floor() * minor; x <= right; x += minor) {
      final px = size.width / 2 + (x - centerX) * scale;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), minorPaint);
    }
    for (var y = (bottom / minor).floor() * minor; y <= top; y += minor) {
      final py = size.height / 2 - (y - centerY) * scale;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), minorPaint);
    }
    for (var x = (left / step).floor() * step; x <= right; x += step) {
      if (x.abs() < step / 1000) continue;
      final px = size.width / 2 + (x - centerX) * scale;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), majorPaint);
    }
    for (var y = (bottom / step).floor() * step; y <= top; y += step) {
      if (y.abs() < step / 1000) continue;
      final py = size.height / 2 - (y - centerY) * scale;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), majorPaint);
    }

    final axisPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.4;
    final originY = size.height / 2 + centerY * scale;
    final originX = size.width / 2 - centerX * scale;
    if (originY >= 0 && originY <= size.height) {
      canvas.drawLine(
        Offset(0, originY),
        Offset(size.width, originY),
        axisPaint,
      );
    }
    if (originX >= 0 && originX <= size.width) {
      canvas.drawLine(
        Offset(originX, 0),
        Offset(originX, size.height),
        axisPaint,
      );
    }
  }

  /// Dashed preview of the segment or circle currently being constructed.
  void _paintPreview(Canvas canvas, Size size) {
    final anchor = previewAnchor;
    final cursor = previewCursor;
    if (anchor == null || cursor == null) return;
    final anchorScreen = toScreen(anchor, size);
    final cursorScreen = toScreen(cursor, size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = selectionColor.withValues(alpha: 0.65);

    if (previewCircle) {
      final radius = (cursor - anchor).distance * scale;
      if (radius > 1) {
        _dashedCircle(canvas, anchorScreen, radius, paint);
        _dashedLine(canvas, anchorScreen, cursorScreen, paint);
        _label(
          canvas,
          'r = ${formatNumber((cursor - anchor).distance, precision: 4)}',
          (anchorScreen + cursorScreen) / 2 + const Offset(0, -12),
          color: selectionColor,
        );
      }
    } else {
      _dashedLine(canvas, anchorScreen, cursorScreen, paint);
      final length = (cursor - anchor).distance;
      _label(
        canvas,
        formatNumber(length, precision: 4),
        (anchorScreen + cursorScreen) / 2 + const Offset(0, -12),
        color: selectionColor,
      );
    }

    canvas.drawCircle(
      cursorScreen,
      4.5,
      Paint()..color = selectionColor.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      cursorScreen,
      4.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total < 1) return;
    final direction = (b - a) / total;
    const dash = 7.0;
    const gap = 5.0;
    var travelled = 0.0;
    while (travelled < total) {
      final end = math.min(travelled + dash, total);
      canvas.drawLine(a + direction * travelled, a + direction * end, paint);
      travelled += dash + gap;
    }
  }

  void _dashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    if (radius < 2) return;
    final dashAngle = 7 / radius;
    final gapAngle = 5 / radius;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var angle = 0.0;
    while (angle < math.pi * 2) {
      final sweep = math.min(dashAngle, math.pi * 2 - angle);
      canvas.drawArc(rect, angle, sweep, false, paint);
      angle += dashAngle + gapAngle;
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset position, {
    bool bold = false,
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? labelColor,
          fontSize: bold ? 12 : 10.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(position.dx - painter.width / 2, position.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GeometryPainter oldDelegate) => true;
}
