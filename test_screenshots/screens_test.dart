// Renders key screens with the real fonts into docs/screenshots/*.png.
// Not part of the regular suite. Run:
//   flutter test test_screenshots --update-goldens
// then copy test_screenshots/goldens/*.png to docs/screenshots/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/app/router.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';
import 'package:focus_jesus/data/models/user_settings.dart';

import '../test/helpers/test_app.dart';

Future<void> shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(FocusJesusApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final dark in [false, true]) {
    final suffix = dark ? '_dark' : '';
    final theme = dark ? ThemePreference.dark : ThemePreference.light;

    testWidgets('onboarding$suffix', (tester) async {
      usePhoneSize(tester);
      final app = await TestApp.create(
        settings: UserSettings.defaults.copyWith(theme: theme),
      );
      addTearDown(app.dispose);
      await tester.pumpWidget(app.widget);
      await shot(tester, '01_onboarding_welcome$suffix');
      await tester.tap(find.text('시작하기'));
      await shot(tester, '02_onboarding_level$suffix');
      await tester.tap(find.text('다음'));
      await shot(tester, '03_onboarding_minutes$suffix');
      await tester.tap(find.text('다음'));
      await shot(tester, '04_onboarding_reminder$suffix');
    });

    testWidgets('today and reader$suffix', (tester) async {
      usePhoneSize(tester);
      final app = await TestApp.create(settings: onboarded(theme: theme));
      addTearDown(app.dispose);
      await tester.pumpWidget(app.widget);
      await shot(tester, '10_today$suffix');
      await tester.tap(find.byKey(const ValueKey('today-read')));
      await shot(tester, '11_reader_top$suffix');
      await tester.drag(
        find.byKey(const ValueKey('reader-scroll')),
        const Offset(0, -1400),
      );
      await shot(tester, '12_reader_body$suffix');
      await tester.drag(
        find.byKey(const ValueKey('reader-scroll')),
        const Offset(0, 300),
      );
      await shot(tester, '13_reader_bar_returns$suffix');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reader-key-message')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await shot(tester, '14_reader_key_message$suffix');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('reflection-note-0')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await shot(tester, '15_reader_reflection$suffix');
      await tester.tap(find.byKey(const ValueKey('reader-settings')));
      await shot(tester, '16_reader_settings_sheet$suffix');
    });

    testWidgets('journey, settings, completion$suffix', (tester) async {
      usePhoneSize(tester);
      final app = await TestApp.create(
        settings: onboarded(theme: theme),
        now: DateTime(2026, 10, 8, 20),
      );
      addTearDown(app.dispose);
      final journey = app.container.read(journeyProvider.notifier);
      app.clock.current = DateTime(2026, 10, 2, 7);
      await journey.complete('s1-d01');
      app.clock.current = DateTime(2026, 10, 3, 7);
      await journey.complete('s1-d02');
      app.clock.current = DateTime(2026, 10, 6, 21);
      await journey.complete('s1-d03');
      await journey.complete('s1-d04');
      app.clock.current = DateTime(2026, 10, 8, 20);
      await tester.pumpWidget(app.widget);
      await shot(tester, '20_today_continue$suffix');
      app.container.read(routerProvider).go(Routes.journey);
      await shot(tester, '21_journey$suffix');
      app.container.read(routerProvider).go(Routes.settings);
      await shot(tester, '22_settings$suffix');
      app.container.read(routerProvider).push(Routes.done('s1-d04'));
      await shot(tester, '23_completion$suffix');
    });
  }

  testWidgets('small screen 360 + large text', (tester) async {
    usePhoneSize(tester, width: 360, height: 740);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await TestApp.create(
      settings: onboarded().copyWith(
        minutes: ReadingMinutes.five,
        level: ReadingLevel.deep,
      ),
    );
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await shot(tester, '30_today_small_large_text');
    await tester.tap(find.byKey(const ValueKey('today-read')));
    await shot(tester, '31_reader_small_large_text');
  });

  testWidgets('tablet reading measure', (tester) async {
    usePhoneSize(tester, width: 820, height: 1180, dpr: 2);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.tap(find.byKey(const ValueKey('today-read')));
    await shot(tester, '32_reader_tablet');
  });
}
