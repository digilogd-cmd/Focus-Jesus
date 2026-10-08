import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/core/design/korean_text.dart';
import 'package:focus_jesus/core/notifications/reminder_planner.dart';
import 'package:focus_jesus/core/time/clock.dart';
import 'package:focus_jesus/data/journey/journey.dart';
import 'package:focus_jesus/data/models/progress.dart';
import 'package:focus_jesus/data/models/user_settings.dart';

CompletionEvent event(
  String chapter,
  LocalDate date, {
  int id = 0,
  bool first = true,
}) => CompletionEvent(
  id: id,
  chapterId: chapter,
  completedAtUtc: date.asDateTime.toUtc(),
  localDate: date,
  utcOffsetMinutes: 540,
  timeZone: 'Asia/Seoul',
  isFirst: first,
);

void main() {
  const ids = [
    's1-d01',
    's1-d02',
    's1-d03',
    's1-d04',
    's1-d05',
    's1-d06',
    's1-d07',
  ];

  group('today plan and missed days', () {
    test('fresh start reads DAY 01', () {
      final plan = planToday(
        orderedIds: ids,
        journey: JourneySnapshot.empty,
        today: const LocalDate(2026, 10, 6),
      );
      expect(plan.status, TodayStatus.ready);
      expect(plan.nextChapterId, 's1-d01');
      expect(plan.completedCount, 0);
    });

    test('after missing several days, continue with the first unread chapter — no penalty', () {
      final journey = JourneySnapshot([
        event('s1-d01', const LocalDate(2026, 10, 1)),
        event('s1-d02', const LocalDate(2026, 10, 2)),
      ]);
      final plan = planToday(
        orderedIds: ids,
        journey: journey,
        today: const LocalDate(2026, 10, 9),
      );
      expect(plan.status, TodayStatus.ready);
      expect(plan.nextChapterId, 's1-d03');
      expect(plan.completedCount, 2);
    });

    test(
      'chapters read out of order still continue from the earliest unread',
      () {
        final journey = JourneySnapshot([
          event('s1-d01', const LocalDate(2026, 10, 1)),
          event('s1-d03', const LocalDate(2026, 10, 2)),
        ]);
        expect(nextChapterId(ids, journey.completedChapterIds), 's1-d02');
      },
    );

    test('done today still offers the next story as extra reading', () {
      final journey = JourneySnapshot([
        event('s1-d01', const LocalDate(2026, 10, 6)),
      ]);
      final plan = planToday(
        orderedIds: ids,
        journey: journey,
        today: const LocalDate(2026, 10, 6),
      );
      expect(plan.status, TodayStatus.doneToday);
      expect(plan.finishedToday, ['s1-d01']);
      expect(plan.nextChapterId, 's1-d02');
    });

    test('next day after finishing resets to ready', () {
      final journey = JourneySnapshot([
        event('s1-d01', const LocalDate(2026, 10, 6)),
      ]);
      final plan = planToday(
        orderedIds: ids,
        journey: journey,
        today: const LocalDate(2026, 10, 7),
      );
      expect(plan.status, TodayStatus.ready);
    });

    test('all seven completed = season complete', () {
      final journey = JourneySnapshot([
        for (var i = 0; i < 7; i++) event(ids[i], LocalDate(2026, 10, 1 + i)),
      ]);
      final plan = planToday(
        orderedIds: ids,
        journey: journey,
        today: const LocalDate(2026, 10, 20),
      );
      expect(plan.status, TodayStatus.seasonComplete);
      expect(plan.nextChapterId, isNull);
    });

    test('unknown chapter ids in history do not count toward the season', () {
      final journey = JourneySnapshot([
        event('old-chapter', const LocalDate(2026, 9, 1)),
      ]);
      final plan = planToday(
        orderedIds: ids,
        journey: journey,
        today: const LocalDate(2026, 10, 1),
      );
      expect(plan.completedCount, 0);
    });
  });

  group('reminder planner', () {
    const pref = ReminderPreference(enabled: true, hour: 7, minute: 30);

    test('disabled preference cancels everything', () {
      final plan = planReminders(
        now: DateTime(2026, 10, 6, 6),
        preference: pref.copyWith(enabled: false),
        finishedToday: false,
      );
      expect(plan, const ReminderPlan.disabled());
    });

    test('before the time: remind today and daily from tomorrow', () {
      final plan = planReminders(
        now: DateTime(2026, 10, 6, 6),
        preference: pref,
        finishedToday: false,
      );
      expect(plan.todayAt, DateTime(2026, 10, 6, 7, 30));
      expect(plan.dailyFrom, DateTime(2026, 10, 7, 7, 30));
    });

    test('already read today: no reminder today', () {
      final plan = planReminders(
        now: DateTime(2026, 10, 6, 6),
        preference: pref,
        finishedToday: true,
      );
      expect(plan.todayAt, isNull);
      expect(plan.dailyFrom, DateTime(2026, 10, 7, 7, 30));
    });

    test('after the time has passed: nothing today', () {
      final plan = planReminders(
        now: DateTime(2026, 10, 6, 7, 30),
        preference: pref,
        finishedToday: false,
      );
      expect(plan.todayAt, isNull);
    });

    test('month and year boundaries roll over by calendar', () {
      final plan = planReminders(
        now: DateTime(2026, 12, 31, 22),
        preference: pref,
        finishedToday: false,
      );
      expect(plan.dailyFrom, DateTime(2027, 1, 1, 7, 30));
    });

    test('changing the reminder time re-plans to the new wall-clock time', () {
      final plan = planReminders(
        now: DateTime(2026, 10, 6, 6),
        preference: pref.copyWith(hour: 21, minute: 5),
        finishedToday: false,
      );
      expect(plan.todayAt, DateTime(2026, 10, 6, 21, 5));
      expect(plan.dailyFrom, DateTime(2026, 10, 7, 21, 5));
    });
  });

  group('fake clock', () {
    test('advances without touching system time', () {
      final clock = FixedClock(DateTime(2026, 10, 6, 23, 59));
      clock.advance(const Duration(minutes: 2));
      expect(LocalDate.of(clock.now()), const LocalDate(2026, 10, 7));
    });
  });

  group('keep-all Korean line breaking', () {
    test('only whitespace remains as a break opportunity', () {
      final out = keepAll('하나님은 사람을');
      expect(out.replaceAll('⁠', ''), '하나님은 사람을');
      expect(out.split(' ').every((w) => !w.contains(' ')), isTrue);
      expect(out, contains('하⁠나'));
      expect(out, isNot(contains('⁠ ')));
      expect(out, isNot(contains(' ⁠')));
    });

    test('ranges may still break after a dash', () {
      expect(keepAll('1–3'), '1–3'.replaceFirst('1', '1⁠'));
      expect(keepAll(''), '');
      expect(keepAll('가'), '가');
    });
  });
}
