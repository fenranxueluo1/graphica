import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/utils/formatters.dart';

/// One surface layer: an expression of x and y plus its colour.
class SurfaceLayer {
  const SurfaceLayer({required this.expression, required this.color});

  final String expression;
  final Color color;
}

/// Paints one or more z = f(x, y) surfaces with a perspective camera.
///
/// With no valid layers it still paints the empty coordinate frame: bounding
/// box, z = 0 grid plane and labelled axes.
class Surface3DPainter extends CustomPainter {
  Surface3DPainter({
    required this.layers,
    required this.angleMode,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.resolution,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.wireframe,
    required this.axisColor,
    required this.labelColor,
  });

  final List<SurfaceLayer> layers;
  final AngleMode angleMode;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final int resolution;
  final double yaw;
  final double pitch;
  final double zoom;
  final bool wireframe;
  final Color axisColor;
  final Color labelColor;

  static const _cameraDistance = 3.2;

  @override
  void paint(Canvas canvas, Size size) {
    if (xMax <= xMin || yMax <= yMin) return;

    final count = resolution + 1;
    final xs = List<double>.generate(
      count,
      (i) => xMin + (xMax - xMin) * i / resolution,
    );
    final ys = List<double>.generate(
      count,
      (i) => yMin + (yMax - yMin) * i / resolution,
    );

    final surfaces = <_SurfaceData>[];
    var zMin = double.infinity;
    var zMax = double.negativeInfinity;

    for (final layer in layers) {
      final source = layer.expression.trim();
      if (source.isEmpty) continue;
      Expr expr;
      try {
        expr = MathEngine.parse(source);
      } on MathException {
        continue;
      }
      final zValues = List<List<double>>.generate(
        count,
        (_) => List<double>.filled(count, double.nan),
      );
      var found = false;
      for (var j = 0; j < count; j++) {
        for (var i = 0; i < count; i++) {
          double z;
          try {
            z = expr.eval(
              EvalContext(
                variables: {'x': xs[i], 'y': ys[j]},
                angleMode: angleMode,
              ),
            );
          } on MathException {
            z = double.nan;
          }
          zValues[j][i] = z;
          if (z.isFinite) {
            found = true;
            if (z < zMin) zMin = z;
            if (z > zMax) zMax = z;
          }
        }
      }
      if (found) {
        surfaces.add(_SurfaceData(color: layer.color, zValues: zValues));
      }
    }

    final hasSurface = surfaces.isNotEmpty && zMin.isFinite && zMax.isFinite;
    final axisMin = hasSurface ? zMin : -5.0;
    final axisMax = hasSurface ? zMax : 5.0;
    var axisRange = axisMax - axisMin;
    if (axisRange.abs() < 1e-9) axisRange = 1;
    final axisMid = (axisMin + axisMax) / 2;

    final xMid = (xMin + xMax) / 2;
    final yMid = (yMin + yMax) / 2;
    final xScale = (xMax - xMin) / 2;
    final yScale = (yMax - yMin) / 2;

    final focal = size.shortestSide * 0.80 * zoom;
    final cx = size.width / 2;
    final cy = size.height * 0.46;

    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);

    Offset? project(double nx, double ny, double nz, [List<double>? out]) {
      final rx = nx * cosYaw + ny * sinYaw;
      final ry = -nx * sinYaw + ny * cosYaw;
      final ty = ry * cosPitch - nz * sinPitch;
      final tz = ry * sinPitch + nz * cosPitch;
      final depth = tz + _cameraDistance;
      if (depth < 0.4) return null;
      final scale = focal / depth;
      if (out != null) {
        out
          ..[0] = rx
          ..[1] = ry
          ..[2] = nz
          ..[3] = depth;
      }
      return Offset(cx + rx * scale, cy - ty * scale);
    }

    double normalizeZ(double z) => (z - axisMid) / axisRange * 1.6;

    _paintFrame(canvas, project);

    final quads = <_Quad>[];
    for (final surface in surfaces) {
      final projected = List<List<Offset?>>.generate(
        count,
        (_) => List<Offset?>.filled(count, null),
      );
      final buffers = List<List<List<double>>>.generate(
        count,
        (_) => List<List<double>>.generate(
          count,
          (_) => List<double>.filled(4, 0),
        ),
      );
      for (var j = 0; j < count; j++) {
        final ny = (ys[j] - yMid) / yScale;
        for (var i = 0; i < count; i++) {
          final z = surface.zValues[j][i];
          if (!z.isFinite) continue;
          final nx = (xs[i] - xMid) / xScale;
          projected[j][i] = project(nx, ny, normalizeZ(z), buffers[j][i]);
        }
      }

      for (var j = 0; j < resolution; j++) {
        for (var i = 0; i < resolution; i++) {
          final p1 = projected[j][i];
          final p2 = projected[j][i + 1];
          final p3 = projected[j + 1][i + 1];
          final p4 = projected[j + 1][i];
          if (p1 == null || p2 == null || p3 == null || p4 == null) continue;
          final z1 = surface.zValues[j][i];
          final z2 = surface.zValues[j][i + 1];
          final z3 = surface.zValues[j + 1][i + 1];
          final z4 = surface.zValues[j + 1][i];
          if (!z1.isFinite || !z2.isFinite || !z3.isFinite || !z4.isFinite) {
            continue;
          }
          final depth =
              (buffers[j][i][3] +
                  buffers[j][i + 1][3] +
                  buffers[j + 1][i + 1][3] +
                  buffers[j + 1][i][3]) /
              4;
          quads.add(
            _Quad(
              points: [p1, p2, p3, p4],
              depth: depth,
              color: surface.color,
              shade: _shade(
                buffers[j][i],
                buffers[j][i + 1],
                buffers[j + 1][i + 1],
                buffers[j + 1][i],
              ),
            ),
          );
        }
      }
    }

    quads.sort((a, b) => b.depth.compareTo(a.depth));

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeJoin = StrokeJoin.round;

    for (final quad in quads) {
      final shaded = Color.lerp(Colors.black, quad.color, quad.shade)!;
      final path = Path()..addPolygon(quad.points, true);
      if (!wireframe) {
        fillPaint.color = shaded.withValues(alpha: 0.86);
        canvas.drawPath(path, fillPaint);
        edgePaint.color = shaded.withValues(alpha: 0.30);
        canvas.drawPath(path, edgePaint);
      } else {
        edgePaint
          ..color = shaded.withValues(alpha: 0.65)
          ..strokeWidth = 0.8;
        canvas.drawPath(path, edgePaint);
      }
    }

    final zMarks = <double>[];
    if (surfaces.isNotEmpty) {
      if (zMax > zMin) {
        zMarks.addAll([zMin, (zMin + zMax) / 2, zMax]);
      } else {
        zMarks.add(zMin);
      }
    } else {
      zMarks.addAll([-4, -2, 2, 4]);
    }
    _paintAxes(
      canvas,
      project,
      axisMid,
      axisRange,
      zMarks,
      hasSurfaces: surfaces.isNotEmpty,
    );
  }

  /// Bounding cube and the horizontal grid plane through z = 0.
  void _paintFrame(
    Canvas canvas,
    Offset? Function(double, double, double, [List<double>?]) project,
  ) {
    final edgePaint = Paint()
      ..color = axisColor.withValues(alpha: 0.40)
      ..strokeWidth = 0.9;
    const corners = <List<double>>[
      [-1, -1, -1],
      [1, -1, -1],
      [1, 1, -1],
      [-1, 1, -1],
      [-1, -1, 1],
      [1, -1, 1],
      [1, 1, 1],
      [-1, 1, 1],
    ];
    const edges = <List<int>>[
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 0],
      [4, 5],
      [5, 6],
      [6, 7],
      [7, 4],
      [0, 4],
      [1, 5],
      [2, 6],
      [3, 7],
    ];
    for (final edge in edges) {
      final a = corners[edge[0]];
      final b = corners[edge[1]];
      final p1 = project(a[0], a[1], a[2]);
      final p2 = project(b[0], b[1], b[2]);
      if (p1 == null || p2 == null) continue;
      canvas.drawLine(p1, p2, edgePaint);
    }

    final gridPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.20)
      ..strokeWidth = 0.8;
    const divisions = 10;
    for (var i = 0; i <= divisions; i++) {
      final t = -1 + 2 * i / divisions;
      final p1 = project(t, -1, 0);
      final p2 = project(t, 1, 0);
      if (p1 != null && p2 != null) canvas.drawLine(p1, p2, gridPaint);
      final p3 = project(-1, t, 0);
      final p4 = project(1, t, 0);
      if (p3 != null && p4 != null) canvas.drawLine(p3, p4, gridPaint);
    }
  }

  void _paintAxes(
    Canvas canvas,
    Offset? Function(double, double, double, [List<double>?]) project,
    double zMid,
    double zRange,
    List<double> zMarks, {
    required bool hasSurfaces,
  }) {
    final axisPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.3;
    final origin = project(0, 0, 0);
    if (origin == null) return;

    // Negative halves.
    for (final end in [
      project(-1.14, 0, 0),
      project(0, -1.14, 0),
      project(0, 0, -1.14),
    ]) {
      if (end != null) canvas.drawLine(origin, end, axisPaint);
    }

    void drawPositive(double ex, double ey, double ez, String label) {
      final end = project(ex, ey, ez);
      if (end == null) return;
      canvas.drawLine(origin, end, axisPaint);
      _arrowHead(canvas, origin, end, axisPaint);
      _axisLabel(canvas, label, end + const Offset(7, -10), bold: true);
    }

    drawPositive(1.14, 0, 0, 'x');
    drawPositive(0, 1.14, 0, 'y');
    drawPositive(0, 0, 1.14, 'z');

    // Z tick labels: a clean axis like the reference frame.
    for (final value in zMarks) {
      final nz = hasSurfaces ? (value - zMid) / zRange * 1.6 : value / 5 * 0.8;
      final point = project(0, 0, nz);
      if (point == null) continue;
      _axisLabel(
        canvas,
        formatNumber(value, precision: 4),
        point + const Offset(8, 2),
        bold: false,
      );
    }
  }

  void _arrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final direction = to - from;
    final length = direction.distance;
    if (length < 1) return;
    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final tip = to + unit * 2;
    final base = to - unit * 7;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx * 4, base.dy + normal.dy * 4)
      ..lineTo(base.dx - normal.dx * 4, base.dy - normal.dy * 4)
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color);
  }

  void _axisLabel(
    Canvas canvas,
    String text,
    Offset position, {
    required bool bold,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: bold ? 13 : 10.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  double _shade(
    List<double> v1,
    List<double> v2,
    List<double> v3,
    List<double> v4,
  ) {
    final ax = v2[0] - v1[0];
    final ay = v2[1] - v1[1];
    final az = v2[2] - v1[2];
    final bx = v4[0] - v1[0];
    final by = v4[1] - v1[1];
    final bz = v4[2] - v1[2];
    final nx = ay * bz - az * by;
    final ny = az * bx - ax * bz;
    final nz = ax * by - ay * bx;
    final length = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (length < 1e-9) return 0.85;
    final dot = (nx * 0.45 - ny * 0.25 + nz * 0.85) / length;
    if (dot >= 0) {
      return 0.72 + 0.28 * dot.clamp(0.0, 1.0);
    }
    return 0.46 + 0.16 * (-dot).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant Surface3DPainter oldDelegate) => true;
}

class _SurfaceData {
  const _SurfaceData({required this.color, required this.zValues});

  final Color color;
  final List<List<double>> zValues;
}

class _Quad {
  const _Quad({
    required this.points,
    required this.depth,
    required this.color,
    required this.shade,
  });

  final List<Offset> points;
  final double depth;
  final Color color;
  final double shade;
}
