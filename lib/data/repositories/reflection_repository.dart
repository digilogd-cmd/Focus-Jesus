import 'package:sqflite/sqflite.dart';

import '../../core/storage/app_database.dart';

/// Personal notes written under each reflection question. Optional by design:
/// an empty note is simply not stored.
class ReflectionRepository {
  ReflectionRepository(this._db);

  final Database _db;

  Future<Map<int, String>> loadNotes(String chapterId) async {
    final rows = await _db.query(
      AppDatabase.noteTable,
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
    return {
      for (final r in rows) r['question_index']! as int: r['body']! as String,
    };
  }

  Future<void> saveNote({
    required String chapterId,
    required int questionIndex,
    required String body,
    required DateTime now,
  }) async {
    if (body.trim().isEmpty) {
      await _db.delete(
        AppDatabase.noteTable,
        where: 'chapter_id = ? AND question_index = ?',
        whereArgs: [chapterId, questionIndex],
      );
      return;
    }
    await _db.insert(AppDatabase.noteTable, {
      'chapter_id': chapterId,
      'question_index': questionIndex,
      'body': body,
      'updated_at_utc': now.toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
