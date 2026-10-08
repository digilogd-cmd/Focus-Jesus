import '../../core/time/clock.dart';

/// Where the reader stopped inside a chapter.
class ReadingPosition {
  const ReadingPosition({
    required this.chapterId,
    required this.offset,
    required this.fraction,
    required this.layoutKey,
    required this.updatedAt,
  });

  final String chapterId;

  /// Pixel offset, valid only for the same [layoutKey].
  final double offset;

  /// 0..1 position, used when the layout changed (mode, level, font size, width).
  final double fraction;

  /// Identifies the layout the offset was measured in.
  final String layoutKey;
  final DateTime updatedAt;

  bool get isMeaningful => fraction > 0.02;
}

/// One press of "완료하기". The first event per chapter is the chapter's
/// completion record; later events are re-reads.
class CompletionEvent {
  const CompletionEvent({
    required this.id,
    required this.chapterId,
    required this.completedAtUtc,
    required this.localDate,
    required this.utcOffsetMinutes,
    required this.timeZone,
    required this.isFirst,
  });

  final int id;
  final String chapterId;
  final DateTime completedAtUtc;

  /// The calendar date in the reader's zone at the moment of completion.
  /// Stored, never recomputed, so later zone or clock changes cannot move it.
  final LocalDate localDate;
  final int utcOffsetMinutes;
  final String? timeZone;
  final bool isFirst;
}

class CompletionOutcome {
  const CompletionOutcome({
    required this.event,
    required this.firstCompletion,
    required this.duplicateToday,
  });

  final CompletionEvent event;

  /// True when this press completed the chapter for the first time.
  final bool firstCompletion;

  /// True when the chapter had already been completed earlier the same day;
  /// no new row is written in that case.
  final bool duplicateToday;
}
