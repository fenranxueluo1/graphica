import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/storage/app_store.dart';
import 'package:graphica/core/theme/app_theme.dart';
import 'package:graphica/features/geometry/geometry_page.dart';
import 'package:graphica/features/graphing/graph_page.dart';
import 'package:graphica/features/home/home_page.dart';
import 'package:graphica/features/matrix/matrix_page.dart';
import 'package:graphica/features/settings/settings_page.dart';
import 'package:graphica/features/three_d/surface3d_page.dart';
import 'package:graphica/l10n/l10n.dart';
import 'package:graphica/state/app_settings.dart';

Widget harness(Widget child) {
  return AppScope(
    settings: AppSettings()..setLocale(AppLocale.en),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: child,
    ),
  );
}

Future<void> pumpAt(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(harness(child));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  final sizes = <String, Size>{
    'desktop': const Size(1400, 900),
    'phone': const Size(390, 844),
  };

  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets('home renders', (tester) async {
        await pumpAt(tester, HomePage(onNavigate: (_) {}), entry.value);
        expect(find.text('Math, beautifully\nplotted.'), findsOneWidget);
        expect(find.text('Graphing'), findsWidgets);
      });

      testWidgets('graphing renders', (tester) async {
        await pumpAt(
          tester,
          GraphPage(store: AppStore.inMemory()),
          entry.value,
        );
        expect(find.text('Graphing'), findsOneWidget);
        expect(find.textContaining('Expressions'), findsWidgets);
      });

      testWidgets('matrix renders', (tester) async {
        await pumpAt(tester, const MatrixPage(), entry.value);
        expect(find.text('Matrix'), findsOneWidget);
        expect(find.text('Operations'), findsOneWidget);
      });

      testWidgets('geometry renders', (tester) async {
        await pumpAt(tester, const GeometryPage(), entry.value);
        expect(find.text('Geometry'), findsOneWidget);
        expect(find.text('Select'), findsOneWidget);
      });

      testWidgets('3D surface renders', (tester) async {
        await pumpAt(
          tester,
          Surface3DPage(store: AppStore.inMemory()),
          entry.value,
        );
        expect(find.text('3D Surface'), findsOneWidget);
      });

      testWidgets('settings renders', (tester) async {
        await pumpAt(tester, const SettingsPage(), entry.value);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
      });
    });
  }
}
