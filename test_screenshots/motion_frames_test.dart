// Captures the entrance motion as a storyboard of frames
// (docs/screenshots/motion/*.png). Not part of the regular suite. Run:
//   flutter test test_screenshots/motion_frames_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/data/models/user_settings.dart';

import '../test/helpers/test_app.dart';

const List<int> frameTimesMs = [0, 150, 300, 500, 800, 1300, 2200];

Future<void> storyboard(
  WidgetTester tester,
  String name,
  Future<void> Function() start,
) async {
  await start();
  var elapsed = 0;
  for (final t in frameTimesMs) {
    await tester.pump(Duration(milliseconds: t - elapsed));
    elapsed = t;
    await expectLater(
      find.byType(FocusJesusApp),
      matchesGoldenFile(
        'goldens/motion/${name}_${t.toString().padLeft(4, '0')}ms.png',
      ),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('today entrance', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await storyboard(tester, 'today', () => tester.pumpWidget(app.widget));
  });

  testWidgets('onboarding entrance', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: UserSettings.defaults);
    addTearDown(app.dispose);
    await storyboard(tester, 'onboarding', () => tester.pumpWidget(app.widget));
  });

  testWidgets('open reader', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await storyboard(
      tester,
      'reader',
      () => tester.tap(find.byKey(const ValueKey('today-read'))),
    );
  });
}
