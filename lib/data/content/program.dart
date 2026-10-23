// The one-year reading program: twelve seasons, 365 days.
//
// Only the small indexes (program.json and each season's curriculum) are read
// at start-up. Chapter manuscripts (~45 KB each, ~16 MB for the year) are
// parsed on demand by [ChapterStore].

import 'dart:async';
import 'dart:convert';

import 'chapter.dart';
import 'content_validator.dart';
import 'curriculum.dart';

class ProgramSeason {
  const ProgramSeason({
    required this.number,
    required this.id,
    required this.path,
    required this.dayCount,
    required this.title,
    required this.scope,
    this.curriculum,
  });

  final int number;
  final String id;

  /// Folder under assets/content, e.g. `season2`.
  final String path;
  final int dayCount;
  final String title;
  final String scope;

  /// Null while the season's outline is not bundled yet.
  final Curriculum? curriculum;

  /// "SEASON 02".
  String get label => 'SEASON ${number.toString().padLeft(2, '0')}';

  ProgramSeason withCurriculum(Curriculum? c) => ProgramSeason(
    number: number,
    id: id,
    path: path,
    dayCount: dayCount,
    title: title,
    scope: scope,
    curriculum: c,
  );
}

/// One day of the year, readable or still in preparation.
class ProgramDay {
  const ProgramDay({
    required this.season,
    required this.number,
    required this.indexInSeason,
    this.outline,
  });

  final ProgramSeason season;

  /// 1-based position in the year (1–365).
  final int number;

  /// 1-based position inside its season.
  final int indexInSeason;

  /// The curriculum entry; null while the season has no outline yet.
  final CurriculumDay? outline;

  String get chapterId =>
      '${season.id}-d${indexInSeason.toString().padLeft(2, '0')}';

  bool get isAvailable => outline?.isAvailable ?? false;

  String get title => outline?.title ?? '준비 중인 이야기';

  /// "DAY 045".
  String get label => 'DAY ${number.toString().padLeft(3, '0')}';

  /// Bundled manuscript path, for readable days.
  String? get assetPath =>
      isAvailable ? 'assets/content/${season.path}/${outline!.file}' : null;
}

class Program {
  Program({required this.title, required List<ProgramSeason> seasons})
    : seasons = List.unmodifiable(seasons) {
    var number = 0;
    final days = <ProgramDay>[];
    for (final s in this.seasons) {
      final outlineDays = s.curriculum?.days ?? const <CurriculumDay>[];
      for (var i = 1; i <= s.dayCount; i++) {
        days.add(
          ProgramDay(
            season: s,
            number: ++number,
            indexInSeason: i,
            outline: i <= outlineDays.length ? outlineDays[i - 1] : null,
          ),
        );
      }
    }
    this.days = List.unmodifiable(days);
    _byId = {for (final d in this.days) d.chapterId: d};
  }

  final String title;
  final List<ProgramSeason> seasons;

  /// Every day of the year in reading order.
  late final List<ProgramDay> days;
  late final Map<String, ProgramDay> _byId;

  int get totalDays => days.length;

  List<ProgramDay> get availableDays =>
      days.where((d) => d.isAvailable).toList();

  /// Readable chapter ids in reading order.
  List<String> get orderedIds => [
    for (final d in days)
      if (d.isAvailable) d.chapterId,
  ];

  ProgramDay? day(String chapterId) => _byId[chapterId];

  List<ProgramDay> daysOf(ProgramSeason season) =>
      days.where((d) => d.season.number == season.number).toList();

  bool isSeasonAvailable(ProgramSeason season) =>
      daysOf(season).every((d) => d.isAvailable);

  /// Every day of the year has a readable manuscript.
  bool get isComplete => days.every((d) => d.isAvailable);

  ProgramSeason? seasonByNumber(int number) =>
      seasons.where((s) => s.number == number).firstOrNull;

  factory Program.fromJson(
    Map<String, Object?> json, {
    required Curriculum? Function(String path) curriculumFor,
  }) {
    final seasons = <ProgramSeason>[];
    final list = json['seasons'];
    if (list is! List || list.isEmpty) {
      throw ContentFormatException('program.seasons', 'expected a list');
    }
    for (var i = 0; i < list.length; i++) {
      final m = (list[i] as Map).cast<String, Object?>();
      String str(String k) {
        final v = m[k];
        if (v is! String || v.isEmpty) {
          throw ContentFormatException(
            'program.seasons[$i].$k',
            'expected a string',
          );
        }
        return v;
      }

      int integer(String k) {
        final v = m[k];
        if (v is! int) {
          throw ContentFormatException(
            'program.seasons[$i].$k',
            'expected an integer',
          );
        }
        return v;
      }

      final path = str('path');
      seasons.add(
        ProgramSeason(
          number: integer('number'),
          id: str('id'),
          path: path,
          dayCount: integer('days'),
          title: str('title'),
          scope: str('scope'),
          curriculum: curriculumFor(path),
        ),
      );
    }
    return Program(title: json['title'] as String? ?? '', seasons: seasons);
  }
}

/// Parses manuscripts on demand and keeps them for the session.
class ChapterStore {
  ChapterStore(this.program, this._loadString);

  final Program program;
  final Future<String> Function(String path) _loadString;
  final Map<String, Future<Chapter?>> _loading = {};
  final Map<String, Chapter> _ready = {};

  /// The chapter if it was already loaded.
  Chapter? peek(String chapterId) => _ready[chapterId];

  /// Null for unknown or not-yet-written days.
  Future<Chapter?> load(String chapterId) {
    final cached = _ready[chapterId];
    if (cached != null) return Future.value(cached);
    return _loading.putIfAbsent(chapterId, () async {
      final path = program.day(chapterId)?.assetPath;
      if (path == null) return null;
      final raw = await _loadString(path);
      final chapter = Chapter.fromJson(
        jsonDecode(raw) as Map<String, Object?>,
        path: path,
      );
      _ready[chapterId] = chapter;
      return chapter;
    });
  }
}

/// Program-level consistency: season outlines match program.json.
List<ContentIssue> validateProgram(Program program) {
  final issues = <ContentIssue>[];
  var expected = 1;
  for (final s in program.seasons) {
    final where = 'program ${s.label}';
    if (s.number != expected++) {
      issues.add(ContentIssue(where, 'seasons must be numbered 1..n in order'));
    }
    if (s.id != 's${s.number}') {
      issues.add(ContentIssue(where, 'id must be s${s.number}'));
    }
    final c = s.curriculum;
    if (c == null) continue;
    if (c.seasonId != s.id) {
      issues.add(ContentIssue(where, 'curriculum seasonId is ${c.seasonId}'));
    }
    if (c.days.length != s.dayCount) {
      issues.add(
        ContentIssue(
          where,
          'curriculum has ${c.days.length} days, program.json says ${s.dayCount}',
        ),
      );
    }
  }
  return issues;
}
