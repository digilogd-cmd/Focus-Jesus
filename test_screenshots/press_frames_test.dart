// Captures the "publishing" motion as storyboards
// (docs/screenshots/motion/press_*.png). Not part of the regular suite. Run:
//   flutter test test_screenshots/press_frames_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/app/theme.dart';
import 'package:focus_jesus/core/design/press.dart';

import '../test/helpers/test_app.dart';

Future<void> frames(
  WidgetTester tester,
  String name,
  Finder target,
  List<int> times,
) async {
  var elapsed = 0;
  for (final t in times) {
    await tester.pump(Duration(milliseconds: t - elapsed));
    elapsed = t;
    await expectLater(
      target,
      matchesGoldenFile(
        'goldens/motion/${name}_${t.toString().padLeft(4, '0')}ms.png',
      ),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  for (final brightness in Brightness.values) {
    testWidgets('opening press (${brightness.name})', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: PressIntro(onHandOver: () {}, onDone: () {}),
        ),
      );
      await frames(
        tester,
        'press_intro_${brightness.name}',
        find.byType(PressIntro),
        const [
          0,
          200,
          500,
          800,
          1100,
          1400,
          1700,
          2000,
          2250,
          2400,
          2550,
          2800,
          3100,
          3350,
        ],
      );
    });
  }

  testWidgets('reading opens with the press header', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('today-read')));
    await frames(tester, 'press_reader', find.byType(FocusJesusApp), const [
      0,
      300,
      600,
      900,
      1100,
      1300,
      1500,
      1800,
      2400,
    ]);
  });
}
