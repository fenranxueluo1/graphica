import 'dart:math' as math;

import 'package:flutter/material.dart';

class GeoPoint {
  GeoPoint({required this.id, required this.position});

  final String id;
  Offset position;
}

class GeoSegment {
  GeoSegment({required this.id, required this.a, required this.b});

  final String id;
  final String a;
  final String b;
}

class GeoCircle {
  GeoCircle({required this.id, required this.center, required this.radius});

  final String id;
  final String center;
  final double radius;
}

/// Stores the geometry construction and offers small editing helpers.
class GeometryController extends ChangeNotifier {
  final List<GeoPoint> points = [];
  final List<GeoSegment> segments = [];
  final List<GeoCircle> circles = [];

  int _nextId = 0;

  String _id() => 'e${_nextId++}';

  String labelFor(GeoPoint point) {
    final index = points.indexOf(point);
    if (index < 0) return '?';
    return String.fromCharCode(65 + (index % 26));
  }

  GeoPoint addPoint(Offset position) {
    final point = GeoPoint(id: _id(), position: position);
    points.add(point);
    notifyListeners();
    return point;
  }

  GeoSegment addSegment(String a, String b) {
    final segment = GeoSegment(id: _id(), a: a, b: b);
    segments.add(segment);
    notifyListeners();
    return segment;
  }

  GeoCircle addCircle(String center, double radius) {
    final circle = GeoCircle(id: _id(), center: center, radius: radius);
    circles.add(circle);
    notifyListeners();
    return circle;
  }

  GeoPoint? pointById(String id) {
    for (final point in points) {
      if (point.id == id) return point;
    }
    return null;
  }

  void movePoint(String id, Offset position) {
    final point = pointById(id);
    if (point == null) return;
    point.position = position;
    notifyListeners();
  }

  void removePoint(String id) {
    points.removeWhere((point) => point.id == id);
    segments.removeWhere((segment) => segment.a == id || segment.b == id);
    circles.removeWhere((circle) => circle.center == id);
    notifyListeners();
  }

  void clear() {
    points.clear();
    segments.clear();
    circles.clear();
    notifyListeners();
  }

  double segmentLength(GeoSegment segment) {
    final a = pointById(segment.a);
    final b = pointById(segment.b);
    if (a == null || b == null) return 0;
    return (b.position - a.position).distance;
  }

  Offset? segmentMidpoint(GeoSegment segment) {
    final a = pointById(segment.a);
    final b = pointById(segment.b);
    if (a == null || b == null) return null;
    return (a.position + b.position) / 2;
  }

  String measurementForSegment(GeoSegment segment) {
    final a = pointById(segment.a);
    final b = pointById(segment.b);
    final length = segmentLength(segment);
    final label = a != null && b != null
        ? '${labelFor(a)}${labelFor(b)}'
        : 'Segment';
    return '$label = ${_format(length)}';
  }

  String measurementForCircle(GeoCircle circle) {
    final center = pointById(circle.center);
    final label = center != null ? labelFor(center) : 'Circle';
    return '◯$label  r = ${_format(circle.radius)}';
  }

  String _format(double value) {
    final rounded = (value * 1000).round() / 1000;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toString();
  }

  /// Returns the closest point to [position] within [tolerance] units.
  GeoPoint? nearestPoint(Offset position, double tolerance) {
    GeoPoint? best;
    var bestDistance = tolerance;
    for (final point in points) {
      final distance = (point.position - position).distance;
      if (distance <= bestDistance) {
        bestDistance = distance;
        best = point;
      }
    }
    return best;
  }

  double distanceBetween(GeoPoint a, GeoPoint b) =>
      (b.position - a.position).distance;

  double angleBetween(GeoPoint a, GeoPoint b, GeoPoint c) {
    final ab = a.position - b.position;
    final cb = c.position - b.position;
    final denom = ab.distance * cb.distance;
    if (denom == 0) return 0;
    final cosine = ((ab.dx * cb.dx + ab.dy * cb.dy) / denom).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }
}
