import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/theme/app_theme.dart';
import 'package:graphica/features/onboarding/onboarding_page.dart';
import 'package:graphica/l10n/l10n.dart';
import 'package:graphica/state/app_settings.dart';

void main() {
  testWidgets('onboarding walks through pages and finishes', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      AppScope(
        settings: AppSettings()..setLocale(AppLocale.en),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: OnboardingPage(onFinish: () => finished = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to 数绘'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pump();
    expect(finished, isTrue);
  });
}
