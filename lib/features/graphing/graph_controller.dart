import 'package:flutter/material.dart';

import '../../core/storage/app_store.dart';

enum GraphExpressionKind {
  cartesian,
  polar,
  implicit;

  String get prefix => switch (this) {
    GraphExpressionKind.cartesian => 'y =',
    GraphExpressionKind.polar => 'r =',
    GraphExpressionKind.implicit => '=',
  };
}

class GraphExpression {
  GraphExpression({
    required this.id,
    required this.input,
    required this.color,
    this.visible = true,
    this.kind = GraphExpressionKind.cartesian,
  });

  final int id;
  String input;
  Color color;
  bool visible;
  GraphExpressionKind kind;

  /// The part of [input] that is actually evaluated (prefix stripped).
  String get body {
    var text = input.trim();
    final lower = text.toLowerCase();
    if (kind == GraphExpressionKind.cartesian) {
      if (lower.startsWith('y=')) return text.substring(2).trim();
      if (lower.startsWith('f(x)=')) return text.substring(5).trim();
    } else if (kind == GraphExpressionKind.polar) {
      if (lower.startsWith('r=')) return text.substring(2).trim();
    }
    return text;
  }

  /// Left and right sides of an implicit equation; a bare expression is
  /// treated as `expression = 0`.
  (String, String) get implicitSides {
    final text = body;
    final index = text.indexOf('=');
    if (index < 0) return (text, '0');
    return (text.substring(0, index).trim(), text.substring(index + 1).trim());
  }

  Map<String, dynamic> toJson() => {
    'input': input,
    'color': color.toARGB32(),
    'visible': visible,
    'kind': kind.name,
  };
}

/// Holds the expression list and the panned/zoomed viewport.
class GraphController extends ChangeNotifier {
  GraphController({AppStore? store}) : _store = store {
    final data = store?.graph;
    if (data != null && data.isNotEmpty) {
      _restore(data);
    } else {
      _seed();
    }
  }

  static const curveColors = <Color>[
    Color(0xFF5EA8FF),
    Color(0xFF22D3EE),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
  ];

  final AppStore? _store;
  final List<GraphExpression> _expressions = [];
  int _nextId = 0;

  double centerX = 0;
  double centerY = 0;
  double scale = 56;

  List<GraphExpression> get expressions => List.unmodifiable(_expressions);

  void _seed() {
    _expressions.addAll([
      GraphExpression(id: _nextId++, input: 'sin(x)', color: curveColors[0]),
      GraphExpression(
        id: _nextId++,
        input: 'x^2 / 4 - 2',
        color: curveColors[1],
      ),
    ]);
  }

  void _restore(Map<String, dynamic> data) {
    centerX = (data['centerX'] as num?)?.toDouble() ?? 0;
    centerY = (data['centerY'] as num?)?.toDouble() ?? 0;
    scale = ((data['scale'] as num?)?.toDouble() ?? 56).clamp(2.0, 40000.0);
    final list = data['expressions'];
    if (list is! List) {
      _seed();
      return;
    }
    for (final item in list) {
      if (item is! Map) continue;
      final input = item['input'] as String? ?? '';
      final colorValue = (item['color'] as num?)?.toInt();
      final color = colorValue == null
          ? curveColors[_nextId % curveColors.length]
          : Color(colorValue);
      final kindName = item['kind'] as String? ?? 'cartesian';
      final kind = GraphExpressionKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => GraphExpressionKind.cartesian,
      );
      _expressions.add(
        GraphExpression(
          id: _nextId++,
          input: input,
          color: color,
          visible: item['visible'] as bool? ?? true,
          kind: kind,
        ),
      );
    }
  }

  void _persist() {
    _store?.saveGraph({
      'centerX': centerX,
      'centerY': centerY,
      'scale': scale,
      'expressions': [
        for (final expression in _expressions) expression.toJson(),
      ],
    });
  }

  void addExpression() {
    final color = curveColors[_nextId % curveColors.length];
    _expressions.add(GraphExpression(id: _nextId++, input: '', color: color));
    _persist();
    notifyListeners();
  }

  void removeExpression(int id) {
    _expressions.removeWhere((expression) => expression.id == id);
    _persist();
    notifyListeners();
  }

  void updateInput(int id, String input) {
    final expression = _expression(id);
    if (expression == null) return;
    expression.input = input;
    _persist();
    notifyListeners();
  }

  void updateColor(int id, Color color) {
    final expression = _expression(id);
    if (expression == null) return;
    expression.color = color;
    _persist();
    notifyListeners();
  }

  void updateKind(int id, GraphExpressionKind kind) {
    final expression = _expression(id);
    if (expression == null) return;
    expression.kind = kind;
    _persist();
    notifyListeners();
  }

  void toggleVisible(int id) {
    final expression = _expression(id);
    if (expression == null) return;
    expression.visible = !expression.visible;
    _persist();
    notifyListeners();
  }

  GraphExpression? _expression(int id) {
    for (final expression in _expressions) {
      if (expression.id == id) return expression;
    }
    return null;
  }

  void panByPixels(double dx, double dy) {
    centerX -= dx / scale;
    centerY += dy / scale;
    _persist();
    notifyListeners();
  }

  /// Zooms by [factor] while keeping the graph point under [focal] fixed.
  void zoomAt(double factor, Offset focal, Size size) {
    final nextScale = (scale * factor).clamp(2.0, 40000.0);
    if (nextScale == scale) return;
    final graphX = centerX + (focal.dx - size.width / 2) / scale;
    final graphY = centerY - (focal.dy - size.height / 2) / scale;
    scale = nextScale;
    centerX = graphX - (focal.dx - size.width / 2) / scale;
    centerY = graphY + (focal.dy - size.height / 2) / scale;
    _persist();
    notifyListeners();
  }

  void zoomBy(double factor) {
    scale = (scale * factor).clamp(2.0, 40000.0);
    _persist();
    notifyListeners();
  }

  void resetView() {
    centerX = 0;
    centerY = 0;
    scale = 56;
    _persist();
    notifyListeners();
  }

  void fitView(Size size) {
    centerX = 0;
    centerY = 0;
    final horizontal = size.width / 12;
    final vertical = size.height / 8;
    scale = horizontal < vertical ? horizontal : vertical;
    scale = scale.clamp(10.0, 400.0);
    _persist();
    notifyListeners();
  }
}
