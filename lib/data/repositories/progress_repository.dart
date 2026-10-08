import 'package:sqflite/sqflite.dart';

import '../../core/storage/app_database.dart';
import '../../core/time/clock.dart';
import '../models/progress.dart';

class ProgressRepository {
  ProgressRepository(this._db);

  final Database _db;

  // Reading position -------------------------------------------------------

  Future<void> savePosition(ReadingPosition p) =>
      _db.insert(AppDatabase.progressTable, {
        'chapter_id': p.chapterId,
        'scroll_offset': p.offset,
        'scroll_fraction': p.fraction.clamp(0.0, 1.0),
        'layout_key': p.layoutKey,
        'updated_at_utc': p.updatedAt.toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<ReadingPosition?> loadPosition(String chapterId) async {
    final rows = await _db.query(
      AppDatabase.progressTable,
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
    if (rows.isEmpty) return null;
    return _positionFromRow(rows.single);
  }

  Future<Map<String, ReadingPosition>> loadAllPositions() async {
    final rows = await _db.query(AppDatabase.progressTable);
    return {
      for (final r in rows) r['chapter_id']! as String: _positionFromRow(r),
    };
  }

  Future<void> clearPosition(String chapterId) => _db.delete(
    AppDatabase.progressTable,
    where: 'chapter_id = ?',
    whereArgs: [chapterId],
  );

  ReadingPosition _positionFromRow(Map<String, Object?> r) => ReadingPosition(
    chapterId: r['chapter_id']! as String,
    offset: (r['scroll_offset']! as num).toDouble(),
    fraction: (r['scroll_fraction']! as num).toDouble(),
    layoutKey: r['layout_key']! as String,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      r['updated_at_utc']! as int,
      isUtc: true,
    ),
  );

  // Completion history -------------------------------------------------------

  /// Records a completion at [localNow] (a local DateTime from the clock).
  ///
  /// - The first completion of a chapter becomes its permanent record.
  /// - Re-reading on a later day adds a re-read event (shown on the calendar),
  ///   leaving the original record untouched.
  /// - Pressing again on the same local day is idempotent.
  Future<CompletionOutcome> recordCompletion({
    required String chapterId,
    required DateTime localNow,
    String? timeZone,
  }) {
    final date = LocalDate.of(localNow);
    return _db.transaction((txn) async {
      final existing = await txn.query(
        AppDatabase.completionTable,
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
        orderBy: 'completed_at_utc ASC, id ASC',
      );
      final events = existing.map(_eventFromRow).toList();
      final sameDay = events.where((e) => e.localDate == date);
      if (sameDay.isNotEmpty) {
        return CompletionOutcome(
          event: sameDay.first,
          firstCompletion: false,
          duplicateToday: true,
        );
      }
      final isFirst = events.isEmpty;
      final row = {
        'chapter_id': chapterId,
        'completed_at_utc': localNow.toUtc().millisecondsSinceEpoch,
        'local_date': date.iso,
        'utc_offset_minutes': localNow.timeZoneOffset.inMinutes,
        'time_zone': timeZone,
        'is_first': isFirst ? 1 : 0,
      };
      final id = await txn.insert(AppDatabase.completionTable, row);
      return CompletionOutcome(
        event: _eventFromRow({...row, 'id': id}),
        firstCompletion: isFirst,
        duplicateToday: false,
      );
    });
  }

  Future<List<CompletionEvent>> allCompletionEvents() async {
    final rows = await _db.query(
      AppDatabase.completionTable,
      orderBy: 'completed_at_utc ASC, id ASC',
    );
    return rows.map(_eventFromRow).toList();
  }

  CompletionEvent _eventFromRow(Map<String, Object?> r) => CompletionEvent(
    id: r['id']! as int,
    chapterId: r['chapter_id']! as String,
    completedAtUtc: DateTime.fromMillisecondsSinceEpoch(
      r['completed_at_utc']! as int,
      isUtc: true,
    ),
    localDate: LocalDate.parse(r['local_date']! as String),
    utcOffsetMinutes: r['utc_offset_minutes']! as int,
    timeZone: r['time_zone'] as String?,
    isFirst: (r['is_first']! as int) == 1,
  );
}
