import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/router.dart';
import 'package:focus_jesus/core/design/tokens.dart';
import 'package:focus_jesus/data/models/user_settings.dart';

import '../helpers/test_app.dart';

/// Relative luminance contrast ratio (WCAG 2.x).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('palette contrast (WCAG)', () {
    for (final (name, c) in [('light', FjColors.light), ('dark', FjColors.dark)]) {
      test('$name: body text ≥ 7:1, secondary ≥ 4.5:1, accent ≥ 4.5:1, button label ≥ 4.5:1', () {
        expect(contrast(c.textPrimary, c.background), greaterThanOrEqualTo(7));
        expect(contrast(c.textSecondary, c.background), greaterThanOrEqualTo(4.5));
        expect(contrast(c.accent, c.background), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      });
    }
  });

  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    testWidgets('main screens meet tap-target and labelling guidelines (${theme.id})', (tester) async {
      usePhoneSize(tester);
      final handle = tester.ensureSemantics();
      final app = await TestApp.create(settings: onboarded(theme: theme));
      addTearDown(app.dispose);
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      Future<void> check() async {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }

      await check(); // today
      await tester.tap(find.byKey(const ValueKey('today-read')));
      await tester.pumpAndSettle();
      await check(); // reader
      final router = app.container.read(routerProvider);
      router.go(Routes.journey);
      await tester.pumpAndSettle();
      await check();
      router.go(Routes.settings);
      await tester.pumpAndSettle();
      await check();
      handle.dispose();
    });
  }

  testWidgets('onboarding meets tap-target guideline', (tester) async {
    usePhoneSize(tester);
    final handle = tester.ensureSemantics();
    final app = await TestApp.create(settings: UserSettings.defaults);
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    for (var step = 0; step < 4; step++) {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      if (step < 3) {
        await tester.tap(find.byType(TextButton).last);
        await tester.pumpAndSettle();
      }
    }
    handle.dispose();
  });

  testWidgets('reduced motion: transitions collapse to zero duration', (tester) async {
    late Duration measured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            measured = FjMotion.of(context, FjMotion.medium);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(measured, Duration.zero);
  });
}
