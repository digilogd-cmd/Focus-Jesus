import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/core/storage/app_database.dart';
import 'package:focus_jesus/core/time/clock.dart';
import 'package:focus_jesus/data/journey/journey.dart';
import 'package:focus_jesus/data/models/progress.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';
import 'package:focus_jesus/data/models/user_settings.dart';
import 'package:focus_jesus/data/repositories/progress_repository.dart';
import 'package:focus_jesus/data/repositories/reflection_repository.dart';
import 'package:focus_jesus/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_app.dart';

void main() {
  group('settings', () {
    test('defaults before onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsRepository(await SharedPreferences.getInstance())
          .load();
      expect(s.onboardingComplete, isFalse);
      expect(s.level, ReadingLevel.beginner);
      expect(s.minutes, ReadingMinutes.ten);
      expect(s.reminder.enabled, isFalse);
      expect(s.theme, ThemePreference.light);
    });

    test('onboarding choices save and load back', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const chosen = UserSettings(
        onboardingComplete: true,
        level: ReadingLevel.deep,
        minutes: ReadingMinutes.twenty,
        reminder: ReminderPreference(enabled: true, hour: 21, minute: 15),
        theme: ThemePreference.system,
      );
      await SettingsRepository(prefs).save(chosen);
      final loaded = SettingsRepository(prefs).load();
      expect(loaded.onboardingComplete, isTrue);
      expect(loaded.level, ReadingLevel.deep);
      expect(loaded.minutes, ReadingMinutes.twenty);
      expect(loaded.reminder, chosen.reminder);
      expect(loaded.theme, ThemePreference.system);
    });

    test('corrupt stored values fall back safely', () async {
      SharedPreferences.setMockInitialValues({
        'settings.level': 'expert',
        'settings.minutes': 7,
        'settings.reminder.hour': 99,
        'settings.theme': 'neon',
      });
      final s = SettingsRepository(await SharedPreferences.getInstance())
          .load();
      expect(s.level, ReadingLevel.beginner);
      expect(s.minutes, ReadingMinutes.ten);
      expect(s.reminder.hour, ReminderPreference.defaults.hour);
      expect(s.theme, ThemePreference.light);
    });
  });

  group('completion records', () {
    late Database db;
    late ProgressRepository repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = ProgressRepository(db);
    });
    tearDown(() => db.close());

    test('completing a chapter records the local date', () async {
      final outcome = await repo.recordCompletion(
        chapterId: 's1-d01',
        localNow: DateTime(2026, 10, 6, 23, 50),
        timeZone: 'Asia/Seoul',
      );
      expect(outcome.firstCompletion, isTrue);
      expect(outcome.event.localDate, const LocalDate(2026, 10, 6));
      expect(outcome.event.timeZone, 'Asia/Seoul');
    });

    test('re-reading keeps the original completion record', () async {
      await repo.recordCompletion(
        chapterId: 's1-d01',
        localNow: DateTime(2026, 10, 1, 8),
      );
      final again = await repo.recordCompletion(
        chapterId: 's1-d01',
        localNow: DateTime(2026, 10, 5, 8),
      );
      expect(again.firstCompletion, isFalse);
      final journey = JourneySnapshot(await repo.allCompletionEvents());
      expect(
        journey.firstCompletion('s1-d01')!.localDate,
        const LocalDate(2026, 10, 1),
      );
      // The re-read appears on the calendar day it happened.
      expect(journey.chaptersOn(const LocalDate(2026, 10, 5)), ['s1-d01']);
      expect(journey.chaptersOn(const LocalDate(2026, 10, 1)), ['s1-d01']);
    });

    test('pressing complete twice on the same day is idempotent', () async {
      await repo.recordCompletion(
        chapterId: 's1-d02',
        localNow: DateTime(2026, 10, 6, 8),
      );
      final dup = await repo.recordCompletion(
        chapterId: 's1-d02',
        localNow: DateTime(2026, 10, 6, 9),
      );
      expect(dup.duplicateToday, isTrue);
      expect(await repo.allCompletionEvents(), hasLength(1));
    });

    test('two different chapters on one day are both recorded', () async {
      await repo.recordCompletion(
        chapterId: 's1-d01',
        localNow: DateTime(2026, 10, 6, 8),
      );
      await repo.recordCompletion(
        chapterId: 's1-d02',
        localNow: DateTime(2026, 10, 6, 21),
      );
      final journey = JourneySnapshot(await repo.allCompletionEvents());
      expect(journey.chaptersOn(const LocalDate(2026, 10, 6)), [
        's1-d01',
        's1-d02',
      ]);
      expect(journey.completedChapterIds, {'s1-d01', 's1-d02'});
      expect(journey.readingDaysIn(2026, 10), {const LocalDate(2026, 10, 6)});
      expect(journey.chapterCountIn(2026, 10), 2);
    });

    test('stored local date never moves when the zone changes later', () async {
      // Completed at 23:30 in Seoul (UTC+9) = 14:30 UTC the same day.
      final seoul = DateTime.utc(2026, 10, 6, 14, 30);
      await db.insert(AppDatabase.completionTable, {
        'chapter_id': 's1-d01',
        'completed_at_utc': seoul.millisecondsSinceEpoch,
        'local_date': '2026-10-06',
        'utc_offset_minutes': 540,
        'time_zone': 'Asia/Seoul',
        'is_first': 1,
      });
      // Reading the record back is independent of the device's current zone.
      final events = await repo.allCompletionEvents();
      expect(events.single.localDate, const LocalDate(2026, 10, 6));
      expect(events.single.utcOffsetMinutes, 540);
      expect(events.single.completedAtUtc, seoul);
    });

    test('local date uses the local wall clock, not UTC', () {
      // 00:30 local on the 7th is still the 7th even if UTC is the 6th.
      expect(
        LocalDate.of(DateTime(2026, 10, 7, 0, 30)),
        const LocalDate(2026, 10, 7),
      );
      expect(
        const LocalDate(2026, 12, 31).addDays(1),
        const LocalDate(2027, 1, 1),
      );
      expect(
        LocalDate.parse('2026-02-28').addDays(1),
        const LocalDate(2026, 3, 1),
      );
    });
  });

  group('reading position', () {
    late Database db;
    late ProgressRepository repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = ProgressRepository(db);
    });
    tearDown(() => db.close());

    test('saves, replaces and clears a position', () async {
      ReadingPosition at(double offset) => ReadingPosition(
        chapterId: 's1-d01',
        offset: offset,
        fraction: offset / 10000,
        layoutKey: '10|beginner|100|390',
        updatedAt: DateTime(2026, 10, 6),
      );
      await repo.savePosition(at(1200));
      await repo.savePosition(at(3400));
      final p = await repo.loadPosition('s1-d01');
      expect(p!.offset, 3400);
      expect(p.fraction, closeTo(0.34, 1e-9));
      expect(p.layoutKey, '10|beginner|100|390');
      await repo.clearPosition('s1-d01');
      expect(await repo.loadPosition('s1-d01'), isNull);
    });
  });

  group('reflection notes', () {
    late Database db;
    late ReflectionRepository repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = ReflectionRepository(db);
    });
    tearDown(() => db.close());

    test('notes save and restore per question', () async {
      final now = DateTime(2026, 10, 6);
      await repo.saveNote(
        chapterId: 's1-d01',
        questionIndex: 0,
        body: '첫 번째 생각',
        now: now,
      );
      await repo.saveNote(
        chapterId: 's1-d01',
        questionIndex: 2,
        body: '세 번째\n여러 줄',
        now: now,
      );
      await repo.saveNote(
        chapterId: 's1-d02',
        questionIndex: 0,
        body: '다른 챕터',
        now: now,
      );
      expect(await repo.loadNotes('s1-d01'), {0: '첫 번째 생각', 2: '세 번째\n여러 줄'});
    });

    test('an emptied note is removed, not stored blank', () async {
      final now = DateTime(2026, 10, 6);
      await repo.saveNote(
        chapterId: 's1-d01',
        questionIndex: 1,
        body: '메모',
        now: now,
      );
      await repo.saveNote(
        chapterId: 's1-d01',
        questionIndex: 1,
        body: '   ',
        now: now,
      );
      expect(await repo.loadNotes('s1-d01'), isEmpty);
    });
  });

  group('database file', () {
    test(
      'data survives closing and reopening the same file (app restart)',
      () async {
        sqfliteFfiInit();
        final dir = await Directory.systemTemp.createTemp('fj_db_');
        final path = '${dir.path}/${AppDatabase.fileName}';
        var db = await AppDatabase.open(
          databaseFactoryFfiNoIsolate,
          path,
          singleInstance: false,
        );
        await ProgressRepository(db).recordCompletion(
          chapterId: 's1-d01',
          localNow: DateTime(2026, 10, 6, 8),
        );
        await ReflectionRepository(db).saveNote(
          chapterId: 's1-d01',
          questionIndex: 0,
          body: '남는 메모',
          now: DateTime(2026, 10, 6),
        );
        await db.close();

        db = await AppDatabase.open(
          databaseFactoryFfiNoIsolate,
          path,
          singleInstance: false,
        );
        expect(await db.getVersion(), AppDatabase.schemaVersion);
        expect(
          await ProgressRepository(db).allCompletionEvents(),
          hasLength(1),
        );
        expect(await ReflectionRepository(db).loadNotes('s1-d01'), {
          0: '남는 메모',
        });
        await db.close();
        await dir.delete(recursive: true);
      },
    );
  });
}
