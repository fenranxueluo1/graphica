import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/theme/app_theme.dart';
import 'package:graphica/features/graphing/graph_page.dart';
import 'package:graphica/features/three_d/surface3d_page.dart';
import 'package:graphica/core/storage/app_store.dart';
import 'package:graphica/l10n/l10n.dart';
import 'package:graphica/state/app_settings.dart';
import 'package:graphica/ui/widgets/math_keyboard.dart';

void main() {
  testWidgets('math keyboard inserts symbols at the caret', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathKeyboard(controller: controller),
          ),
        ),
      ),
    );

    await tester.tap(find.text('√'));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text(')'));
    await tester.pump();

    expect(controller.text, 'sqrt(9)');
  });

  testWidgets('math keyboard backspace deletes at the caret', (tester) async {
    final controller = TextEditingController(text: '123');
    controller.selection = const TextSelection.collapsed(offset: 2);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathKeyboard(controller: controller),
          ),
        ),
      ),
    );

    await tester.tap(find.text('⌫'));
    await tester.pump();

    expect(controller.text, '13');
    expect(controller.selection.baseOffset, 1);
  });

  testWidgets('implicit equation graphs without errors', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = AppStore.inMemory(
      graph: {
        'expressions': [
          {
            'input': 'x^2 + y^2 = 9',
            'kind': 'implicit',
            'color': 0xFF5EA8FF,
            'visible': true,
          },
        ],
      },
    );
    await tester.pumpWidget(
      AppScope(
        settings: AppSettings()..setLocale(AppLocale.en),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: GraphPage(store: store),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Graphing'), findsOneWidget);
  });

  testWidgets('3D surface renders multiple layers', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = AppStore.inMemory(
      surface: {
        'expressions': [
          {'input': 'x^2 + y^2', 'color': 0xFF8B5CF6, 'visible': true},
          {'input': 'sin(x) * cos(y)', 'color': 0xFF22D3EE, 'visible': true},
        ],
      },
    );
    await tester.pumpWidget(
      AppScope(
        settings: AppSettings()..setLocale(AppLocale.en),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Surface3DPage(store: store),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.text('3D Surface'), findsOneWidget);
    expect(find.text('Surface expressions'), findsOneWidget);
  });
}
