import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/theme/app_theme.dart';
import 'package:graphica/features/calculator/calculator_page.dart';
import 'package:graphica/features/geometry/geometry_page.dart';
import 'package:graphica/features/matrix/matrix_page.dart';
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

Future<void> pumpDesktop(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(harness(child));
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> tapKeys(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await tester.tap(find.text(label).first);
    await tester.pump();
  }
}

void main() {
  testWidgets('scientific calculator evaluates a product', (tester) async {
    await pumpDesktop(tester, const CalculatorPage());
    await tapKeys(tester, ['7', '×', '8']);
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('= 56'), findsOneWidget);
    expect(find.textContaining('7*8'), findsWidgets);
  });

  testWidgets('scientific calculator adds with the plus key', (tester) async {
    await pumpDesktop(tester, const CalculatorPage());
    await tapKeys(tester, ['7', '+', '8']);
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('= 15'), findsOneWidget);
  });

  testWidgets('four-function calculator evaluates and updates the tape', (
    tester,
  ) async {
    await pumpDesktop(tester, const CalculatorPage());
    await tester.tap(find.text('Four-function'));
    await tester.pumpAndSettle();

    await tapKeys(tester, ['7', '−', '3']);
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('= 4'), findsOneWidget);
    expect(find.textContaining('7−3'), findsWidgets);
  });

  testWidgets('matrix page evaluates determinant and inverse', (tester) async {
    await pumpDesktop(tester, const MatrixPage());

    final determinant = find.text('det(A)');
    await tester.ensureVisible(determinant);
    await tester.pumpAndSettle();
    await tester.tap(determinant);
    await tester.pumpAndSettle();
    expect(find.text('-2'), findsOneWidget);

    final inverse = find.text('A⁻¹');
    await tester.ensureVisible(inverse);
    await tester.pumpAndSettle();
    await tester.tap(inverse);
    await tester.pumpAndSettle();
    expect(find.textContaining('1.5'), findsOneWidget);
    expect(find.textContaining('-0.5'), findsOneWidget);
  });

  testWidgets('geometry tool adds points and a segment', (tester) async {
    await pumpDesktop(tester, const GeometryPage());

    await tester.tap(find.text('Point'));
    await tester.pump();
    await tester.tapAt(const Offset(640, 430));
    await tester.pump();
    expect(find.textContaining('1 pts'), findsOneWidget);

    await tester.tap(find.text('Segment'));
    await tester.pump();
    await tester.tapAt(const Offset(560, 430));
    await tester.pump();
    await tester.tapAt(const Offset(860, 430));
    await tester.pump();

    expect(find.textContaining('3 pts'), findsOneWidget);
    expect(find.textContaining('1 seg'), findsOneWidget);
  });
}
