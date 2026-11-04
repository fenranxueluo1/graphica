import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/math/expression.dart';
import 'package:graphica/core/storage/app_store.dart';
import 'package:graphica/features/graphing/graph_controller.dart';
import 'package:graphica/features/three_d/surface3d_controller.dart';
import 'package:graphica/l10n/l10n.dart';
import 'package:graphica/state/app_settings.dart';

void main() {
  test('settings are restored and persisted', () {
    final store = AppStore.inMemory(
      settings: {
        'theme': 'light',
        'accent': 2,
        'angle': 'degrees',
        'locale': 'en',
      },
    );
    final settings = AppSettings(store: store);
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.accentIndex, 2);
    expect(settings.angleMode, AngleMode.degrees);
    expect(settings.locale, AppLocale.en);
    expect(settings.onboardingComplete, isFalse);

    settings.setLocale(AppLocale.zh);
    settings.setAngleMode(AngleMode.radians);
    settings.completeOnboarding();
    expect(store.settings['locale'], 'zh');
    expect(store.settings['angle'], 'radians');
    expect(store.settings['onboarding'], isTrue);
  });

  test('graph expressions are restored and persisted', () {
    final store = AppStore.inMemory();
    final controller = GraphController(store: store);
    expect(controller.expressions.length, 2);

    controller.updateInput(controller.expressions.first.id, 'cos(x)');
    controller.addExpression();
    controller.updateInput(controller.expressions.last.id, 'x^2 + y^2 = 9');
    controller.updateKind(
      controller.expressions.last.id,
      GraphExpressionKind.implicit,
    );

    final saved = store.graph['expressions'] as List;
    expect(saved.length, 3);
    expect((saved.first as Map)['input'], 'cos(x)');
    expect((saved.last as Map)['kind'], 'implicit');

    final restored = GraphController(store: store);
    expect(restored.expressions.length, 3);
    expect(restored.expressions.first.input, 'cos(x)');
    expect(restored.expressions.last.kind, GraphExpressionKind.implicit);
  });

  test('3D surfaces are restored and persisted', () {
    final store = AppStore.inMemory();
    final controller = Surface3DController(store: store);
    expect(controller.expressions.length, 1);
    expect(controller.expressions.first.input, isEmpty);

    controller.updateInput(controller.expressions.first.id, 'x + y');
    controller.addExpression(input: 'x^2 - y^2');
    controller.setDomain(xMin: -4, xMax: 4);
    controller.setWireframe(true);

    expect((store.surface['expressions'] as List).length, 2);
    final restored = Surface3DController(store: store);
    expect(restored.expressions.length, 2);
    expect(restored.expressions.first.input, 'x + y');
    expect(restored.expressions.last.input, 'x^2 - y^2');
    expect(restored.xMin, -4);
    expect(restored.wireframe, isTrue);
  });
}
