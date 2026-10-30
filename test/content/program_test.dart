import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/core/time/clock.dart';
import 'package:focus_jesus/data/content/program.dart';
import 'package:focus_jesus/data/journey/journey.dart';

import '../helpers/test_app.dart';

void main() {
  final program = loadProgramFromDisk();

  test('the year is twelve seasons and 365 days', () {
    expect(program.seasons, hasLength(12));
    expect(program.totalDays, 365);
    expect(program.seasons.fold<int>(0, (n, s) => n + s.dayCount), 365);
    expect(validateProgram(program), isEmpty);
    // Every season has its outline.
    for (final s in program.seasons) {
      expect(s.curriculum, isNotNull, reason: s.label);
      expect(s.curriculum!.days, hasLength(s.dayCount), reason: s.label);
    }
  });

  test('days are numbered across the year; ids stay per season', () {
    final first = program.days.first;
    expect(first.chapterId, 's1-d01');
    expect(first.label, 'DAY 001');
    final s2 = program.day('s2-d01')!;
    expect(s2.number, 31, reason: 'season 1 has 30 days');
    expect(s2.label, 'DAY 031');
    expect(s2.season.label, 'SEASON 02');
    expect(program.days.last.chapterId, 's12-d30');
    expect(program.days.last.number, 365);
    // Numbers are 1..365 without gaps.
    expect(program.days.map((d) => d.number), [
      for (var i = 1; i <= 365; i++) i,
    ]);
  });

  test('only days with a manuscript are readable, in year order', () {
    final ids = program.orderedIds;
    expect(ids.take(30), [
      for (var d = 1; d <= 30; d++) 's1-d${d.toString().padLeft(2, '0')}',
    ]);
    for (final d in program.days) {
      expect(d.isAvailable, d.outline?.isAvailable ?? false);
      expect(d.assetPath != null, d.isAvailable, reason: d.chapterId);
    }
  });

  test('the chapter store loads readable days and nothing else', () async {
    final store = diskChapterStore(program);
    final c = await store.load('s1-d01');
    expect(c?.title, program.day('s1-d01')!.title);
    expect(store.peek('s1-d01'), same(c), reason: 'parsed once, then cached');
    final planned = program.days.firstWhere((d) => !d.isAvailable);
    expect(await store.load(planned.chapterId), isNull);
    expect(await store.load('s99-d01'), isNull);
  });

  test('a planned season is skipped: reading continues where content is', () {
    // Finishing every readable day leaves nothing "next" — never a planned day.
    final plan = planToday(
      orderedIds: program.orderedIds,
      journey: JourneySnapshot(const []),
      today: const LocalDate(2026, 10, 6),
    );
    expect(plan.nextChapterId, 's1-d01');
    expect(plan.totalCount, program.availableDays.length);
  });
}
