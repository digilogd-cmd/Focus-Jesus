// Pure Dart reading-journey logic: what to read next, what happened on which
// day. No streaks, no penalties: missed days simply continue where you left off.

import '../../core/time/clock.dart';
import '../models/progress.dart';

class JourneySnapshot {
  JourneySnapshot(List<CompletionEvent> events)
    : events = List.unmodifiable(events) {
    for (final e in this.events) {
      _firstByChapter.putIfAbsent(e.chapterId, () => e);
      final day = _byDate.putIfAbsent(e.localDate, () => <String>[]);
      if (!day.contains(e.chapterId)) day.add(e.chapterId);
    }
  }

  static final JourneySnapshot empty = JourneySnapshot(const []);

  final List<CompletionEvent> events;
  final Map<String, CompletionEvent> _firstByChapter = {};
  final Map<LocalDate, List<String>> _byDate = {};

  /// Chapters completed at least once.
  Set<String> get completedChapterIds => _firstByChapter.keys.toSet();

  bool isCompleted(String chapterId) => _firstByChapter.containsKey(chapterId);

  /// The original completion record of a chapter (never replaced by re-reads).
  CompletionEvent? firstCompletion(String chapterId) =>
      _firstByChapter[chapterId];

  /// Chapter ids finished (first time or re-read) on [date], in order.
  List<String> chaptersOn(LocalDate date) =>
      List.unmodifiable(_byDate[date] ?? const []);

  /// Dates in a month with at least one finished chapter.
  Set<LocalDate> readingDaysIn(int year, int month) =>
      _byDate.keys.where((d) => d.year == year && d.month == month).toSet();

  /// Number of chapters finished in a month (re-reads included).
  int chapterCountIn(int year, int month) => _byDate.entries
      .where((e) => e.key.year == year && e.key.month == month)
      .fold(0, (n, e) => n + e.value.length);
}

enum TodayStatus {
  /// Nothing finished today yet.
  ready,

  /// At least one chapter finished today; more can still be read.
  doneToday,

  /// Every available chapter has been completed.
  seasonComplete,
}

class TodayPlan {
  const TodayPlan({
    required this.status,
    required this.nextChapterId,
    required this.finishedToday,
    required this.completedCount,
    required this.totalCount,
  });

  final TodayStatus status;

  /// The chapter to read now: the first not-yet-completed chapter in order.
  /// After missed days this is simply where the reader left off.
  final String? nextChapterId;

  /// Chapters finished today (first time or re-read).
  final List<String> finishedToday;
  final int completedCount;
  final int totalCount;
}

String? nextChapterId(List<String> orderedIds, Set<String> completed) {
  for (final id in orderedIds) {
    if (!completed.contains(id)) return id;
  }
  return null;
}

TodayPlan planToday({
  required List<String> orderedIds,
  required JourneySnapshot journey,
  required LocalDate today,
}) {
  final completed = journey.completedChapterIds.intersection(
    orderedIds.toSet(),
  );
  final next = nextChapterId(orderedIds, completed);
  final finishedToday = journey.chaptersOn(today);
  final TodayStatus status;
  if (next == null) {
    status = TodayStatus.seasonComplete;
  } else if (finishedToday.isNotEmpty) {
    status = TodayStatus.doneToday;
  } else {
    status = TodayStatus.ready;
  }
  return TodayPlan(
    status: status,
    nextChapterId: next,
    finishedToday: finishedToday,
    completedCount: completed.length,
    totalCount: orderedIds.length,
  );
}
