import 'package:sqflite/sqflite.dart';

/// SQLite schema for reading progress, completion history and reflection notes.
///
/// Bump [schemaVersion] and add a step to [_migrations] for every change; never
/// edit a released step. Each step upgrades from version (index + 1) to
/// (index + 2).
abstract final class AppDatabase {
  static const String fileName = 'focus_jesus.db';
  static const int schemaVersion = 1;

  static const String progressTable = 'reading_progress';
  static const String completionTable = 'completion_event';
  static const String noteTable = 'reflection_note';

  static final List<Future<void> Function(DatabaseExecutor db)> _migrations =
      [];

  /// [singleInstance] = false gives every caller its own connection (tests use
  /// a fresh in-memory database each time).
  static Future<Database> open(
    DatabaseFactory factory,
    String path, {
    bool singleInstance = true,
  }) {
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: singleInstance,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _create(db),
        onUpgrade: (db, from, to) async {
          for (var v = from; v < to; v++) {
            await _migrations[v - 1](db);
          }
        },
      ),
    );
  }

  static Future<void> _create(DatabaseExecutor db) async {
    // Where the reader left off in a chapter. One row per chapter.
    await db.execute('''
      CREATE TABLE $progressTable (
        chapter_id TEXT PRIMARY KEY,
        scroll_offset REAL NOT NULL,
        scroll_fraction REAL NOT NULL,
        layout_key TEXT NOT NULL,
        updated_at_utc INTEGER NOT NULL
      )''');
    // Every time a reader presses "완료하기". The first event per chapter is the
    // chapter's completion record; later events are re-reads. Rows are never
    // deleted or rewritten by app logic.
    await db.execute('''
      CREATE TABLE $completionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id TEXT NOT NULL,
        completed_at_utc INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        utc_offset_minutes INTEGER NOT NULL,
        time_zone TEXT,
        is_first INTEGER NOT NULL CHECK (is_first IN (0, 1))
      )''');
    await db.execute(
      'CREATE INDEX idx_completion_local_date ON $completionTable(local_date)',
    );
    await db.execute(
      'CREATE INDEX idx_completion_chapter ON $completionTable(chapter_id)',
    );
    await db.execute('''
      CREATE TABLE $noteTable (
        chapter_id TEXT NOT NULL,
        question_index INTEGER NOT NULL,
        body TEXT NOT NULL,
        updated_at_utc INTEGER NOT NULL,
        PRIMARY KEY (chapter_id, question_index)
      )''');
  }
}
