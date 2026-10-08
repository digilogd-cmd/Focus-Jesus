import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/app/router.dart';
import 'package:focus_jesus/data/models/user_settings.dart';

import '../helpers/test_app.dart';

Future<void> resumeApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  const reminderOn = ReminderPreference(enabled: true, hour: 21, minute: 0);

  testWidgets(
    'opening the app from a reminder goes straight to the next story',
    (tester) async {
      usePhoneSize(tester);
      final app = await TestApp.create(
        settings: onboarded(),
        launchedFromReminder: true,
      );
      addTearDown(app.dispose);
      await app.container.read(journeyProvider.notifier).complete('s1-d01');
      app.clock.advance(const Duration(days: 1));
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reader-title')), findsOneWidget);
      expect(find.text('DAY 02'), findsWidgets);
      // Back returns to home rather than closing the app.
      await tester.tap(find.byKey(const ValueKey('reader-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('today-title')), findsOneWidget);
    },
  );

  testWidgets('a reminder tap while running opens the next story', (
    tester,
  ) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    app.container.read(routerProvider).go(Routes.continueReading);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-title')), findsOneWidget);
    expect(find.text('DAY 01'), findsWidgets);
  });

  testWidgets(
    'resume after a time-zone change records the new zone and re-plans reminders',
    (tester) async {
      usePhoneSize(tester);
      var zone = 'Asia/Seoul';
      final app = await TestApp.create(
        settings: onboarded().copyWith(reminder: reminderOn),
        timeZoneRefresher: () async => zone,
      );
      addTearDown(app.dispose);
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      final before = app.scheduler.applyCount;

      zone = 'America/Los_Angeles';
      await resumeApp(tester);
      expect(app.container.read(timeZoneNameProvider), 'America/Los_Angeles');
      expect(app.scheduler.applyCount, greaterThan(before));
      expect(
        app.scheduler.lastPlan!.dailyFrom!.hour,
        21,
        reason: 'same wall-clock time in the new zone',
      );

      // Completions after the change carry the new zone; earlier ones keep theirs.
      await app.container.read(journeyProvider.notifier).complete('s1-d01');
      final event = app.container
          .read(journeyProvider)
          .value!
          .firstCompletion('s1-d01')!;
      expect(event.timeZone, 'America/Los_Angeles');
    },
  );

  testWidgets('resuming after midnight refreshes today', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(
      settings: onboarded(),
      now: DateTime(2026, 10, 6, 23, 50),
    );
    addTearDown(app.dispose);
    await app.container.read(journeyProvider.notifier).complete('s1-d01');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-done')), findsOneWidget);

    app.clock.advance(const Duration(minutes: 20)); // 00:10 on the 7th
    await resumeApp(tester);
    expect(find.text('10월 7일 수요일'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-done')), findsNothing);
    expect(find.text('오늘의 이야기 읽기'), findsOneWidget);
  });

  testWidgets('position is saved when the app goes to the background', (
    tester,
  ) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('today-read')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('reader-scroll')),
      const Offset(0, -1800),
    );
    await tester.pump(); // no debounce wait: backgrounding must flush
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    final saved = await app.container
        .read(progressRepositoryProvider)
        .loadPosition('s1-d01');
    expect(saved, isNotNull);
    expect(saved!.offset, greaterThan(1000));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });
}
