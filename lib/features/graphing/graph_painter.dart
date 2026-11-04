import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/utils/formatters.dart';
import 'graph_controller.dart';

/// Paints an adaptive grid, axes, curves and an optional cursor crosshair.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.controller,
    required this.angleMode,
    required this.gridColor,
    required this.axisColor,
    required this.labelColor,
    required this.cursor,
    required this.crosshairColor,
  });

  final GraphController controller;
  final AngleMode angleMode;
  final Color gridColor;
  final Color axisColor;
  final Color labelColor;
  final Color crosshairColor;
  final Offset? cursor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintGrid(canvas, size);
    _paintCurves(canvas, size);
    _paintCursor(canvas, size);
    canvas.restore();
  }

  double _toScreenX(double x, Size size) =>
      size.width / 2 + (x - controller.centerX) * controller.scale;

  double _toScreenY(double y, Size size) =>
      size.height / 2 - (y - controller.centerY) * controller.scale;

  double _toGraphX(double px, Size size) =>
      controller.centerX + (px - size.width / 2) / controller.scale;

  double _toGraphY(double py, Size size) =>
      controller.centerY - (py - size.height / 2) / controller.scale;

  void _paintGrid(Canvas canvas, Size size) {
    final step = niceStep(78 / controller.scale);
    final minor = step / 5;

    final minorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    final left = _toGraphX(0, size);
    final right = _toGraphX(size.width, size);
    final bottom = _toGraphY(size.height, size);
    final top = _toGraphY(0, size);

    // Minor grid.
    final minorStartX = (left / minor).floor() * minor;
    for (var x = minorStartX; x <= right; x += minor) {
      final px = _toScreenX(x, size);
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), minorPaint);
    }
    final minorStartY = (bottom / minor).floor() * minor;
    for (var y = minorStartY; y <= top; y += minor) {
      final py = _toScreenY(y, size);
      canvas.drawLine(Offset(0, py), Offset(size.width, py), minorPaint);
    }

    // Major grid.
    final startX = (left / step).floor() * step;
    for (var x = startX; x <= right; x += step) {
      if (x.abs() < step / 1000) continue;
      final px = _toScreenX(x, size);
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), majorPaint);
    }
    final startY = (bottom / step).floor() * step;
    for (var y = startY; y <= top; y += step) {
      if (y.abs() < step / 1000) continue;
      final py = _toScreenY(y, size);
      canvas.drawLine(Offset(0, py), Offset(size.width, py), majorPaint);
    }

    final axisPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    final originY = _toScreenY(0, size);
    final originX = _toScreenX(0, size);
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

    _paintLabels(canvas, size, step, startX, startY, left, right, bottom, top);
  }

  void _paintLabels(
    Canvas canvas,
    Size size,
    double step,
    double startX,
    double startY,
    double left,
    double right,
    double bottom,
    double top,
  ) {
    final originY = _toScreenY(0, size);
    final originX = _toScreenX(0, size);
    final labelY = originY.clamp(4.0, size.height - 18);
    final labelX = originX.clamp(28.0, size.width - 8);

    for (var x = startX; x <= right; x += step) {
      if (x.abs() < step / 1000) continue;
      final px = _toScreenX(x, size);
      if (px < 18 || px > size.width - 18) continue;
      _text(
        canvas,
        formatNumber(x, precision: 4),
        Offset(px + 3, labelY + 3),
        alignCenter: false,
      );
    }
    for (var y = startY; y <= top; y += step) {
      if (y.abs() < step / 1000) continue;
      final py = _toScreenY(y, size);
      if (py < 14 || py > size.height - 6) continue;
      _text(
        canvas,
        formatNumber(y, precision: 4),
        Offset(labelX + 4, py + 2),
        alignCenter: false,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset, {
    required bool alignCenter,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: labelColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignCenter ? offset.dx - painter.width / 2 : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  void _paintCurves(Canvas canvas, Size size) {
    for (final expression in controller.expressions) {
      if (!expression.visible) continue;
      final body = expression.body;
      if (body.isEmpty) continue;
      try {
        if (expression.kind == GraphExpressionKind.implicit) {
          final (leftSource, rightSource) = expression.implicitSides;
          if (leftSource.isEmpty || rightSource.isEmpty) continue;
          final left = MathEngine.parse(leftSource);
          final right = MathEngine.parse(rightSource);
          _paintImplicit(canvas, size, left, right, expression.color);
        } else {
          final parsed = MathEngine.parse(body);
          if (expression.kind == GraphExpressionKind.cartesian) {
            _paintCartesian(canvas, size, parsed, expression.color);
          } else {
            _paintPolar(canvas, size, parsed, expression.color);
          }
        }
      } on MathException {
        continue;
      }
    }
  }

  void _paintCartesian(Canvas canvas, Size size, Expr expr, Color color) {
    final path = Path();
    var started = false;
    double? previousY;
    final context = EvalContext(variables: const {}, angleMode: angleMode);
    final xContext = _MutableContext(context);

    for (var px = 0.0; px <= size.width; px += 1.25) {
      final x = _toGraphX(px, size);
      double y;
      try {
        y = expr.eval(xContext.withVariable('x', x));
      } on MathException {
        y = double.nan;
      }
      final finite = y.isFinite;
      final sy = finite ? _toScreenY(y, size) : double.nan;
      final visible = finite && sy > -size.height * 3 && sy < size.height * 4;
      if (!visible) {
        started = false;
        previousY = null;
        continue;
      }
      if (!started) {
        path.moveTo(px, sy);
        started = true;
      } else {
        final jump =
            previousY != null && (sy - previousY).abs() > size.height * 1.6;
        if (jump) {
          path.moveTo(px, sy);
        } else {
          path.lineTo(px, sy);
        }
      }
      previousY = sy;
    }

    _stroke(canvas, path, color);
  }

  void _paintPolar(Canvas canvas, Size size, Expr expr, Color color) {
    final path = Path();
    var started = false;
    const samples = 1400;
    const maxTheta = math.pi * 6;
    final context = EvalContext(angleMode: angleMode);
    final polarContext = _MutableContext(context);

    for (var i = 0; i <= samples; i++) {
      final theta = maxTheta * i / samples;
      double radius;
      try {
        radius = expr.eval(
          polarContext.withVariables({'theta': theta, 't': theta}),
        );
      } on MathException {
        radius = double.nan;
      }
      if (!radius.isFinite) {
        started = false;
        continue;
      }
      final x = radius * math.cos(theta);
      final y = radius * math.sin(theta);
      final px = _toScreenX(x, size);
      final py = _toScreenY(y, size);
      if (px < -size.width * 4 ||
          px > size.width * 5 ||
          py < -size.height * 4 ||
          py > size.height * 5) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(px, py);
        started = true;
      } else {
        path.lineTo(px, py);
      }
    }

    _stroke(canvas, path, color);
  }

  /// Marching-squares contour extraction for implicit equations.
  void _paintImplicit(
    Canvas canvas,
    Size size,
    Expr left,
    Expr right,
    Color color,
  ) {
    const cell = 5.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    final values = List<List<double>>.generate(
      rows + 1,
      (_) => List<double>.filled(cols + 1, double.nan),
    );

    for (var j = 0; j <= rows; j++) {
      final y = _toGraphY(j * cell, size);
      for (var i = 0; i <= cols; i++) {
        final x = _toGraphX(i * cell, size);
        try {
          final l = left.eval(
            EvalContext(variables: {'x': x, 'y': y}, angleMode: angleMode),
          );
          final r = right.eval(
            EvalContext(variables: {'x': x, 'y': y}, angleMode: angleMode),
          );
          values[j][i] = l - r;
        } on MathException {
          values[j][i] = double.nan;
        }
      }
    }

    final path = Path();
    Offset screen(int i, int j) => Offset(i * cell, j * cell);
    Offset? crossing(int i1, int j1, int i2, int j2) {
      final v1 = values[j1][i1];
      final v2 = values[j2][i2];
      if (!v1.isFinite || !v2.isFinite) return null;
      final delta = v1 - v2;
      if (delta.abs() < 1e-12) return null;
      final t = v1 / delta;
      final a = screen(i1, j1);
      final b = screen(i2, j2);
      return a + (b - a) * t;
    }

    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final v00 = values[j][i];
        final v10 = values[j][i + 1];
        final v11 = values[j + 1][i + 1];
        final v01 = values[j + 1][i];
        if (!v00.isFinite || !v10.isFinite || !v11.isFinite || !v01.isFinite) {
          continue;
        }
        final points = <Offset>[];
        if ((v00 >= 0) != (v10 >= 0)) {
          final p = crossing(i, j, i + 1, j);
          if (p != null) points.add(p);
        }
        if ((v10 >= 0) != (v11 >= 0)) {
          final p = crossing(i + 1, j, i + 1, j + 1);
          if (p != null) points.add(p);
        }
        if ((v11 >= 0) != (v01 >= 0)) {
          final p = crossing(i + 1, j + 1, i, j + 1);
          if (p != null) points.add(p);
        }
        if ((v01 >= 0) != (v00 >= 0)) {
          final p = crossing(i, j + 1, i, j);
          if (p != null) points.add(p);
        }
        if (points.length == 2) {
          path.moveTo(points[0].dx, points[0].dy);
          path.lineTo(points[1].dx, points[1].dy);
        } else if (points.length == 4) {
          path.moveTo(points[0].dx, points[0].dy);
          path.lineTo(points[1].dx, points[1].dy);
          path.moveTo(points[2].dx, points[2].dy);
          path.lineTo(points[3].dx, points[3].dy);
        }
      }
    }

    _stroke(canvas, path, color);
  }

  void _stroke(Canvas canvas, Path path, Color color) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.18);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  void _paintCursor(Canvas canvas, Size size) {
    final point = cursor;
    if (point == null) return;
    if (point.dx < 0 ||
        point.dy < 0 ||
        point.dx > size.width ||
        point.dy > size.height) {
      return;
    }
    final paint = Paint()
      ..color = crosshairColor.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(point.dx, 0), Offset(point.dx, size.height), paint);
    canvas.drawLine(Offset(0, point.dy), Offset(size.width, point.dy), paint);

    final x = _toGraphX(point.dx, size);
    for (final expression in controller.expressions) {
      if (!expression.visible ||
          expression.kind != GraphExpressionKind.cartesian ||
          expression.body.isEmpty) {
        continue;
      }
      try {
        final value = MathEngine.evaluate(
          expression.body,
          variables: {'x': x},
          angleMode: angleMode,
        );
        if (!value.isFinite) continue;
        final py = _toScreenY(value, size);
        if (py < -20 || py > size.height + 20) continue;
        canvas.drawCircle(
          Offset(point.dx, py),
          4.5,
          Paint()..color = expression.color,
        );
        canvas.drawCircle(
          Offset(point.dx, py),
          2,
          Paint()..color = Colors.white,
        );
      } on MathException {
        continue;
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.controller.centerX != controller.centerX ||
        oldDelegate.controller.centerY != controller.centerY ||
        oldDelegate.controller.scale != controller.scale ||
        oldDelegate.controller.expressions != controller.expressions ||
        oldDelegate.cursor != cursor ||
        oldDelegate.angleMode != angleMode;
  }
}

/// Tiny adapter so we can reuse an [EvalContext] with extra variables without
/// allocating maps at every sample point.
class _MutableContext {
  _MutableContext(this._base);

  final EvalContext _base;
  String? _xName;
  double? _xValue;
  Map<String, double>? _extra;

  EvalContext withVariable(String name, double value) {
    _xName = name;
    _xValue = value;
    return EvalContext(variables: _variables(), angleMode: _base.angleMode);
  }

  EvalContext withVariables(Map<String, double> extra) {
    _extra = extra;
    return EvalContext(variables: extra, angleMode: _base.angleMode);
  }

  Map<String, double> _variables() {
    if (_extra != null) return _extra!;
    if (_xName != null && _xValue != null) return {_xName!: _xValue!};
    return const {};
  }
}
