import 'package:flutter/material.dart';

import '../../core/storage/app_store.dart';

class SurfaceExpression {
  SurfaceExpression({
    required this.id,
    required this.input,
    required this.color,
    this.visible = true,
  });

  final int id;
  String input;
  Color color;
  bool visible;

  Map<String, dynamic> toJson() => {
    'input': input,
    'color': color.toARGB32(),
    'visible': visible,
  };
}

/// Holds the 3D surface layers and the shared domain/render settings.
class Surface3DController extends ChangeNotifier {
  Surface3DController({AppStore? store}) : _store = store {
    final data = store?.surface;
    if (data != null && data.isNotEmpty) {
      _restore(data);
    } else {
      _seed();
    }
  }

  static const palette = <Color>[
    Color(0xFF8B5CF6),
    Color(0xFF22D3EE),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
    Color(0xFF5EA8FF),
  ];

  final AppStore? _store;
  final List<SurfaceExpression> _expressions = [];
  int _nextId = 0;

  double xMin = -5;
  double xMax = 5;
  double yMin = -5;
  double yMax = 5;
  double resolution = 36;
  bool wireframe = false;

  List<SurfaceExpression> get expressions => List.unmodifiable(_expressions);

  /// Non-empty, visible layers ready to render.
  List<SurfaceExpression> get visibleLayers => [
    for (final expression in _expressions)
      if (expression.visible && expression.input.trim().isNotEmpty) expression,
  ];

  void _seed() {
    _expressions.add(
      SurfaceExpression(id: _nextId++, input: '', color: palette[0]),
    );
  }

  void _restore(Map<String, dynamic> data) {
    xMin = (data['xMin'] as num?)?.toDouble() ?? -5;
    xMax = (data['xMax'] as num?)?.toDouble() ?? 5;
    yMin = (data['yMin'] as num?)?.toDouble() ?? -5;
    yMax = (data['yMax'] as num?)?.toDouble() ?? 5;
    resolution = ((data['resolution'] as num?)?.toDouble() ?? 36).clamp(10, 60);
    wireframe = data['wireframe'] as bool? ?? false;
    final list = data['expressions'];
    if (list is! List) {
      _seed();
      return;
    }
    for (final item in list) {
      if (item is! Map) continue;
      final colorValue = (item['color'] as num?)?.toInt();
      _expressions.add(
        SurfaceExpression(
          id: _nextId++,
          input: item['input'] as String? ?? '',
          color: colorValue == null
              ? palette[_nextId % palette.length]
              : Color(colorValue),
          visible: item['visible'] as bool? ?? true,
        ),
      );
    }
  }

  void _persist() {
    _store?.saveSurface({
      'xMin': xMin,
      'xMax': xMax,
      'yMin': yMin,
      'yMax': yMax,
      'resolution': resolution,
      'wireframe': wireframe,
      'expressions': [
        for (final expression in _expressions) expression.toJson(),
      ],
    });
  }

  void addExpression({String input = '', Color? color}) {
    final tone = color ?? palette[_nextId % palette.length];
    _expressions.add(
      SurfaceExpression(id: _nextId++, input: input, color: tone),
    );
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

  void toggleVisible(int id) {
    final expression = _expression(id);
    if (expression == null) return;
    expression.visible = !expression.visible;
    _persist();
    notifyListeners();
  }

  SurfaceExpression? _expression(int id) {
    for (final expression in _expressions) {
      if (expression.id == id) return expression;
    }
    return null;
  }

  void setDomain({double? xMin, double? xMax, double? yMin, double? yMax}) {
    this.xMin = xMin ?? this.xMin;
    this.xMax = xMax ?? this.xMax;
    this.yMin = yMin ?? this.yMin;
    this.yMax = yMax ?? this.yMax;
    _persist();
    notifyListeners();
  }

  void setResolution(double value) {
    resolution = value.clamp(10, 60);
    _persist();
    notifyListeners();
  }

  void setWireframe(bool value) {
    wireframe = value;
    _persist();
    notifyListeners();
  }
}
