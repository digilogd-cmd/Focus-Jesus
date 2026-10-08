// End-to-end user journey on a real device/desktop build, using the production
// bootstrap (bundled assets, on-disk SQLite, persisted settings).
//
//   flutter test integration_test/app_test.dart -d <device>
//   flutter test integration_test/app_restart_test.dart -d <device>   (run after)
//
// The second file runs in a fresh process and checks that everything written
// here survived a real application restart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/app/bootstrap.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/core/design/korean_text.dart';
import 'package:focus_jesus/core/storage/app_database.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

/// Launches the app exactly as main() does.
Future<ProviderContainer> launch(WidgetTester tester) async {
  final deps = await loadAppDependencies();
  final container = await createAppContainer(deps);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FocusJesusApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Tears the app down the way process death does: widget tree gone, DB closed.
Future<void> terminate(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  final db = container.read(databaseProvider);
  container.dispose();
  await db.close();
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'first-run journey: onboarding → read → resume → note → complete → calendar → more → restart',
    (tester) async {
      // Fresh install: remove any previous database and settings.
      final dbDir = await platformDatabaseFactory().getDatabasesPath();
      final dbFile = File(p.join(dbDir, AppDatabase.fileName));
      if (dbFile.existsSync()) dbFile.deleteSync();
      (await SharedPreferences.getInstance()).clear();

      // 1. Onboarding.
      var container = await launch(tester);
      expect(find.text('시작하기'), findsOneWidget);
      await tapVisible(tester, find.text('시작하기'));
      await tapVisible(tester, byKey('level-beginner'));
      await tapVisible(tester, find.text('다음'));
      await tapVisible(tester, byKey('minutes-10'));
      await tapVisible(tester, find.text('다음'));
      await tapVisible(tester, byKey('onboarding-skip-reminder'));
      expect(byKey('today-title'), findsOneWidget);
      expect(find.text(keepAll('세상은 왜 창조되었을까?')), findsOneWidget);

      // 2. Read DAY 01.
      await tapVisible(tester, byKey('today-read'));
      expect(byKey('reader-title'), findsOneWidget);
      await binding.watchPerformance(() async {
        for (var i = 0; i < 6; i++) {
          await tester.fling(
            byKey('reader-scroll'),
            const Offset(0, -500),
            1500,
          );
          await tester.pumpAndSettle();
        }
      }, reportKey: 'reader_scroll');
      final scrolled = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(scrolled, greaterThan(1000));

      // 3. Quit mid-chapter, relaunch, continue where we left off.
      // The real OS sequence when the user leaves the app.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      await terminate(tester, container);
      // A new process starts in the foreground.
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        binding.handleAppLifecycleStateChanged(state);
      }
      container = await launch(tester);
      expect(find.text('이어서 읽기'), findsOneWidget);
      await tapVisible(tester, byKey('today-read'));
      final restored = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(restored, closeTo(scrolled, 2));

      // 4. Change reading mode while reading.
      await tapVisible(tester, byKey('reader-settings'));
      await tapVisible(tester, byKey('sheet-minutes-5'));
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).minutes, ReadingMinutes.five);

      // 5. Write a reflection note.
      await scrollTo(tester, byKey('reflection-note-0'));
      await tester.enterText(
        byKey('reflection-note-0'),
        '세상은 우연이 아니라 뜻으로 지어졌다',
      );
      await tester.pump(const Duration(seconds: 1));

      // 6. Complete the story.
      await scrollTo(tester, byKey('reader-complete'));
      await tapVisible(tester, byKey('reader-complete'));
      expect(byKey('completion-title'), findsOneWidget);

      // 7. The calendar shows today.
      await tapVisible(tester, byKey('completion-home'));
      await tapVisible(tester, byKey('nav-1'));
      expect(find.bySemanticsLabel(RegExp(r'오늘, 이야기 1개 읽음')), findsOneWidget);

      // 8. Read one more story the same day.
      await tapVisible(tester, byKey('nav-0'));
      expect(byKey('today-done'), findsOneWidget);
      await tapVisible(tester, byKey('today-read-more'));
      expect(find.text('DAY 02'), findsWidgets);
      await scrollTo(tester, byKey('reader-complete'));
      await tapVisible(tester, byKey('reader-complete'));
      await tapVisible(tester, byKey('completion-home'));
      await tapVisible(tester, byKey('nav-1'));
      expect(find.bySemanticsLabel(RegExp(r'오늘, 이야기 2개 읽음')), findsOneWidget);

      // 9. Quit and relaunch (in-process), 10. everything is still there.
      await terminate(tester, container);
      container = await launch(tester);
      final journey = container.read(journeyProvider).value!;
      expect(journey.completedChapterIds, {'s1-d01', 's1-d02'});
      expect(container.read(settingsProvider).minutes, ReadingMinutes.five);
      expect(container.read(settingsProvider).onboardingComplete, isTrue);
      expect(
        await container.read(reflectionRepositoryProvider).loadNotes('s1-d01'),
        {0: '세상은 우연이 아니라 뜻으로 지어졌다'},
      );
      expect(find.text('7개의 이야기 중 2개를 읽었습니다.'), findsOneWidget);
      await terminate(tester, container);
    },
  );
}
