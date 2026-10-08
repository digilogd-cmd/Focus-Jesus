import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/app/router.dart';
import 'package:focus_jesus/core/design/korean_text.dart';
import 'package:focus_jesus/core/design/tokens.dart';
import 'package:focus_jesus/core/notifications/reminder_planner.dart';
import 'package:focus_jesus/data/content/chapter_composer.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';
import 'package:focus_jesus/data/models/user_settings.dart';
import 'package:focus_jesus/data/repositories/progress_repository.dart';
import 'package:focus_jesus/data/repositories/reflection_repository.dart';
import 'package:focus_jesus/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

Future<TestApp> pumpApp(
  WidgetTester tester, {
  UserSettings? settings,
  DateTime? now,
  bool permissionGranted = true,
  bool linkSucceeds = true,
}) async {
  final app = await TestApp.create(
    settings: settings ?? onboarded(),
    now: now,
    permissionGranted: permissionGranted,
    linkSucceeds: linkSucceeds,
  );
  addTearDown(app.dispose);
  await tester.pumpWidget(app.widget);
  await tester.pumpAndSettle();
  return app;
}

/// Taps [target] after scrolling it into view (large text pushes it down).
Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

Future<void> openReader(WidgetTester tester) async {
  await tapVisible(tester, byKey('today-read'));
  await tester.pumpAndSettle();
}

Future<void> scrollReaderTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  // Centre it so the overlaid top bar never covers the target.
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void expectNoOverflow(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout exception: $error');
}

void main() {
  group('onboarding', () {
    testWidgets('choices persist and lead to home; reminder scheduled', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester, settings: UserSettings.defaults);
      expect(find.text('시작하기'), findsOneWidget);
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('level-growth'));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('minutes-15'));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('onboarding-enable-reminder'));
      await tester.pumpAndSettle();

      expect(byKey('today-title'), findsOneWidget);
      final saved = SettingsRepository(await SharedPreferences.getInstance())
          .load();
      expect(saved.onboardingComplete, isTrue);
      expect(saved.level, ReadingLevel.growth);
      expect(saved.minutes, ReadingMinutes.fifteen);
      expect(saved.reminder.enabled, isTrue);
      expect(app.scheduler.lastPlan!.enabled, isTrue);
    });

    testWidgets('denied notification permission still completes onboarding', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await pumpApp(
        tester,
        settings: UserSettings.defaults,
        permissionGranted: false,
      );
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('onboarding-enable-reminder'));
      await tester.pumpAndSettle();
      expect(byKey('today-title'), findsOneWidget);
      expect(app.container.read(settingsProvider).reminder.enabled, isFalse);
      expect(app.scheduler.lastPlan, const ReminderPlan.disabled());
      expectNoOverflow(tester);
    });
  });

  group('home', () {
    testWidgets(
      'shows date, today\'s story, one primary action and quiet progress',
      (tester) async {
        usePhoneSize(tester);
        await pumpApp(tester, now: DateTime(2026, 10, 6, 8));
        expect(find.text('10월 6일 화요일'), findsOneWidget);
        expect(find.text(keepAll('세상은 왜 창조되었을까?')), findsOneWidget);
        expect(find.text('오늘의 이야기 읽기'), findsOneWidget);
        expect(find.text('7개의 이야기가 준비되어 있습니다.'), findsOneWidget);
        expect(
          find.textContaining('끊어'),
          findsNothing,
          reason: 'no streak language',
        );
      },
    );

    testWidgets(
      'after finishing today, offers the next story as extra reading',
      (tester) async {
        usePhoneSize(tester);
        final app = await TestApp.create(settings: onboarded());
        addTearDown(app.dispose);
        await app.container.read(journeyProvider.notifier).complete('s1-d01');
        await tester.pumpWidget(app.widget);
        await tester.pumpAndSettle();
        expect(byKey('today-done'), findsOneWidget);
        expect(byKey('today-read-more'), findsOneWidget);
        expect(find.text(keepAll('사람들은 왜 바벨탑을 세웠을까?')), findsNothing);
        expect(find.text(keepAll('인간은 왜 하나님을 떠났을까?')), findsOneWidget);
        expect(find.text('7개의 이야기 중 1개를 읽었습니다.'), findsOneWidget);
      },
    );
  });

  group('reader', () {
    testWidgets(
      'renders the composed chapter, key message, links and complete action',
      (tester) async {
        usePhoneSize(tester);
        await pumpApp(tester);
        await openReader(tester);
        expect(byKey('reader-title'), findsOneWidget);
        expect(find.text('DAY 01'), findsWidgets);
        await scrollReaderTo(tester, byKey('reader-key-message'));
        await scrollReaderTo(tester, byKey('scripture-link-GEN 1:1-2:25'));
        await scrollReaderTo(tester, byKey('reader-complete'));
        expect(find.text('오늘의 이야기 완료하기'), findsOneWidget);
        expectNoOverflow(tester);
      },
    );

    testWidgets('scrolling alone never completes a chapter', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      await scrollReaderTo(tester, byKey('reader-complete'));
      expect(
        app.container.read(journeyProvider).value!.isCompleted('s1-d01'),
        isFalse,
      );
    });

    testWidgets('changing reading time changes the amount of text', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await pumpApp(
        tester,
        settings: onboarded().copyWith(minutes: ReadingMinutes.five),
      );
      await openReader(tester);
      final chapter = app.container.read(seasonProvider).chapters.first;
      String meta(ReadingMinutes m) =>
          '약 ${composeChapter(chapter, minutes: m, level: ReadingLevel.beginner).displayMinutes}분 · 입문 · 창세기 1:1–2:25';
      expect(find.text(meta(ReadingMinutes.five)), findsOneWidget);

      await tester.tap(byKey('reader-settings'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('sheet-minutes-20'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
      await tester.pumpAndSettle();
      expect(find.text(meta(ReadingMinutes.twenty)), findsOneWidget);
      expect(
        app.container.read(settingsProvider).minutes,
        ReadingMinutes.twenty,
      );
      final extension = chapter.sections.firstWhere(
        (s) => s.tier == ReadingMinutes.twenty,
      );
      await scrollReaderTo(tester, find.text(keepAll(extension.heading)));
    });

    testWidgets('level change swaps the explanatory layer', (tester) async {
      usePhoneSize(tester);
      await pumpApp(tester);
      await openReader(tester);
      await scrollReaderTo(tester, find.text('쉽게 풀어 보기').first);
      await tester.tap(byKey('reader-settings'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('sheet-level-deep'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('쉽게 풀어 보기'), findsNothing);
      await tester.dragUntilVisible(
        find.text('더 깊이').first,
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
    });

    testWidgets('external link failure shows a calm message', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester, linkSucceeds: false);
      await openReader(tester);
      final link = byKey('scripture-link-GEN 1:1-2:25');
      await scrollReaderTo(tester, link);
      await tester.tap(link);
      await tester.pump();
      expect(find.textContaining('본문을 열 수 없습니다'), findsOneWidget);
      expect(app.links.opened.single.queryParameters['book'], 'gen');
    });

    testWidgets('external link success opens bskorea at the right verse', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      final link = byKey('scripture-link-JHN 1:1-5');
      await scrollReaderTo(tester, link);
      await tester.tap(link);
      await tester.pump();
      expect(
        app.links.opened.single.toString(),
        'https://www.bskorea.or.kr/bible/korbibReadpage.php?version=GAE&book=jhn&chap=1&sec=1',
      );
      expect(find.textContaining('본문을 열 수 없습니다'), findsNothing);
    });
  });

  group('reflection', () {
    testWidgets('memo saves while typing and restores on reopen', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      await scrollReaderTo(tester, byKey('reflection-note-1'));
      await tester.enterText(byKey('reflection-note-1'), '말씀으로 지어진 세상');
      await tester.pump(const Duration(seconds: 1));
      expect(await ReflectionRepository(app.database).loadNotes('s1-d01'), {
        1: '말씀으로 지어진 세상',
      });

      await tester.tap(byKey('reader-back'));
      await tester.pumpAndSettle();
      await openReader(tester);
      await scrollReaderTo(tester, byKey('reflection-note-1'));
      expect(find.text('말씀으로 지어진 세상'), findsOneWidget);
    });

    testWidgets('empty memo still allows completion', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      await scrollReaderTo(tester, byKey('reader-complete'));
      await tester.tap(byKey('reader-complete'));
      await tester.pumpAndSettle();
      expect(byKey('completion-title'), findsOneWidget);
      expect(
        app.container.read(journeyProvider).value!.isCompleted('s1-d01'),
        isTrue,
      );
      expect(
        await ReflectionRepository(app.database).loadNotes('s1-d01'),
        isEmpty,
      );
    });

    testWidgets('typing right before completing is not lost', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      await scrollReaderTo(tester, byKey('reflection-note-2'));
      await tester.enterText(byKey('reflection-note-2'), '바로 완료');
      await scrollReaderTo(tester, byKey('reader-complete'));
      await tester.tap(byKey('reader-complete'));
      await tester.pumpAndSettle();
      expect(await ReflectionRepository(app.database).loadNotes('s1-d01'), {
        2: '바로 완료',
      });
    });
  });

  group('completion and calendar', () {
    testWidgets(
      'completing records the day on the calendar and cancels today\'s reminder',
      (tester) async {
        usePhoneSize(tester);
        final app = await pumpApp(
          tester,
          settings: onboarded().copyWith(
            reminder: const ReminderPreference(
              enabled: true,
              hour: 21,
              minute: 0,
            ),
          ),
          now: DateTime(2026, 10, 6, 8),
        );
        expect(app.scheduler.lastPlan!.todayAt, DateTime(2026, 10, 6, 21));
        await openReader(tester);
        await scrollReaderTo(tester, byKey('reader-complete'));
        await tester.tap(byKey('reader-complete'));
        await tester.pumpAndSettle();
        expect(
          app.scheduler.lastPlan!.todayAt,
          isNull,
          reason: 'already read today',
        );
        expect(app.scheduler.lastPlan!.dailyFrom, DateTime(2026, 10, 7, 21));

        await tester.tap(byKey('completion-home'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('nav-1'));
        await tester.pumpAndSettle();
        expect(find.text('이번 달에 1일, 1편의 이야기를 읽었습니다.'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'10월 6일, 오늘, 이야기 1개 읽음')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^10월 5일$')),
          findsOneWidget,
          reason: 'unread days are plain',
        );
      },
    );

    testWidgets('two chapters in one day show twice on that day', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      await scrollReaderTo(tester, byKey('reader-complete'));
      await tester.tap(byKey('reader-complete'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('completion-next'));
      await tester.pumpAndSettle();
      expect(find.text('DAY 02'), findsWidgets);
      await scrollReaderTo(tester, byKey('reader-complete'));
      await tester.tap(byKey('reader-complete'));
      await tester.pumpAndSettle();
      app.container.read(routerProvider).go(Routes.journey);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'이야기 2개 읽음')), findsOneWidget);
      expect(byKey('journey-day-s1-d01'), findsOneWidget);
      expect(byKey('journey-day-s1-d02'), findsOneWidget);
    });

    testWidgets('calendar navigates months', (tester) async {
      usePhoneSize(tester);
      await pumpApp(tester, now: DateTime(2026, 1, 15, 9));
      await tester.tap(byKey('nav-1'));
      await tester.pumpAndSettle();
      expect(find.text('2026년 1월'), findsOneWidget);
      await tester.tap(byKey('journey-prev-month'));
      await tester.pumpAndSettle();
      expect(find.text('2025년 12월'), findsOneWidget);
      await tester.tap(byKey('journey-next-month'));
      await tester.tap(byKey('journey-next-month'));
      await tester.pumpAndSettle();
      expect(find.text('2026년 2월'), findsOneWidget);
    });

    testWidgets('finishing all seven shows the season completion', (
      tester,
    ) async {
      usePhoneSize(tester);
      final app = await TestApp.create(settings: onboarded());
      addTearDown(app.dispose);
      for (var d = 1; d <= 6; d++) {
        await app.container.read(journeyProvider.notifier).complete('s1-d0$d');
      }
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      await tapVisible(tester, byKey('today-read-more'));
      await tester.pumpAndSettle();
      await scrollReaderTo(tester, byKey('reader-complete'));
      await tester.tap(byKey('reader-complete'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('completion-season'));
      await tester.pumpAndSettle();
      expect(byKey('season-complete-title'), findsOneWidget);
      expect(find.textContaining('준비 중'), findsWidgets);
    });
  });

  group('reading position', () {
    testWidgets('leaving mid-chapter restores the same place', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await openReader(tester);
      await tester.drag(byKey('reader-scroll'), const Offset(0, -2500));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scrollable.position.pixels;
      expect(offset, greaterThan(1000));

      await tester.tap(byKey('reader-back'));
      await tester.pumpAndSettle();
      final saved = await ProgressRepository(app.database)
          .loadPosition('s1-d01');
      expect(saved!.offset, closeTo(offset, 1));
      expect(find.text('이어서 읽기'), findsOneWidget);

      await tapVisible(tester, byKey('today-read'));
      await tester.pumpAndSettle();
      final restored = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(restored, closeTo(offset, 1));
      expect(find.text('지난번 읽던 곳에서 이어집니다.'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('theme switch to dark applies dark palette', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(tester);
      await tester.tap(byKey('nav-2'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('settings-theme'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('choice-theme-dark'));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('설정').first);
      expect(FjColors.of(context).background, FjColors.dark.background);
      expect(app.container.read(settingsProvider).theme, ThemePreference.dark);
    });

    testWidgets('turning reminders off cancels the schedule', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(
        tester,
        settings: onboarded().copyWith(
          reminder: const ReminderPreference(
            enabled: true,
            hour: 7,
            minute: 30,
          ),
        ),
      );
      await tester.tap(byKey('nav-2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(app.scheduler.lastPlan, const ReminderPlan.disabled());
      expect(byKey('settings-reminder-time'), findsNothing);
    });

    testWidgets(
      'turning reminders on without permission keeps them off and explains',
      (tester) async {
        usePhoneSize(tester);
        final app = await pumpApp(tester, permissionGranted: false);
        await tester.tap(byKey('nav-2'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(app.container.read(settingsProvider).reminder.enabled, isFalse);
        expect(find.textContaining('알림 권한이 꺼져 있습니다'), findsOneWidget);
      },
    );
  });

  group('layout robustness', () {
    for (final (name, width, height, scale) in [
      ('small 360dp', 360.0, 640.0, 1.0),
      ('large text 1.6x', 390.0, 844.0, 1.6),
      ('small + 2.0x text', 360.0, 740.0, 2.0),
    ]) {
      testWidgets('no overflow: $name', (tester) async {
        usePhoneSize(tester, width: width, height: height);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final app = await pumpApp(tester);
        expectNoOverflow(tester);
        expect(byKey('today-read'), findsOneWidget);
        await openReader(tester);
        expectNoOverflow(tester);
        await scrollReaderTo(tester, byKey('reader-complete'));
        expect(
          tester.getSize(byKey('reader-complete')).height,
          greaterThanOrEqualTo(48),
        );
        app.container.read(routerProvider).go(Routes.journey);
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
        app.container.read(routerProvider).go(Routes.settings);
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
      });
    }

    testWidgets('onboarding fits at 2.0x text on a small phone', (
      tester,
    ) async {
      usePhoneSize(tester, width: 360, height: 640);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, settings: UserSettings.defaults);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(TextButton).last);
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
      }
      expect(byKey('onboarding-skip-reminder'), findsOneWidget);
    });

    testWidgets('dark mode renders every main screen', (tester) async {
      usePhoneSize(tester);
      final app = await pumpApp(
        tester,
        settings: onboarded(theme: ThemePreference.dark),
      );
      final context = tester.element(byKey('today-title'));
      expect(Theme.of(context).brightness, Brightness.dark);
      await openReader(tester);
      expectNoOverflow(tester);
      app.container.read(routerProvider).go(Routes.journey);
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
    });

    testWidgets('long chapter titles wrap without overflow', (tester) async {
      usePhoneSize(tester, width: 360, height: 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final app = await TestApp.create(settings: onboarded());
      addTearDown(app.dispose);
      for (var d = 1; d <= 6; d++) {
        await app.container.read(journeyProvider.notifier).complete('s1-d0$d');
      }
      app.clock.advance(const Duration(days: 1));
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      // DAY 07 has the longest title.
      expect(find.text(keepAll('하나님은 왜 아브라함 한 사람을 부르셨을까?')), findsOneWidget);
      expectNoOverflow(tester);
      await openReader(tester);
      expectNoOverflow(tester);
    });
  });
}
