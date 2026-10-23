// Validates chapter JSON files and prints reading-time statistics.
//
// Usage:
//   dart run tool/validate_content.dart                       # the whole year
//   dart run tool/validate_content.dart path/s2/day03.json    # specific files
//
// With no arguments every season in assets/content/program.json is checked:
// each manuscript on disk, duplicates across the whole year, each season's
// curriculum against its manuscripts, and the program itself. Manuscripts
// written for days still marked "planned" are validated but reported as
// pending, not as errors.
//
// Exits with code 1 when any issue is found.

import 'dart:convert';
import 'dart:io';

import 'package:focus_jesus/data/content/chapter.dart';
import 'package:focus_jesus/data/content/chapter_composer.dart';
import 'package:focus_jesus/data/content/content_validator.dart';
import 'package:focus_jesus/data/content/curriculum.dart';
import 'package:focus_jesus/data/content/program.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';

const String contentDir = 'assets/content';

void main(List<String> args) {
  final issues = <ContentIssue>[];
  if (args.isNotEmpty) {
    for (final path in args) {
      final c = _load(path, issues);
      if (c != null) issues.addAll(validateChapter(c));
    }
    _finish(issues, args.length);
    return;
  }

  final program = Program.fromJson(
    jsonDecode(File('$contentDir/program.json').readAsStringSync())
        as Map<String, Object?>,
    curriculumFor: (path) {
      final f = File('$contentDir/$path/curriculum.json');
      if (!f.existsSync()) return null;
      try {
        return Curriculum.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
        );
      } on Object catch (e) {
        issues.add(ContentIssue(f.path, 'failed to load: $e'));
        return null;
      }
    },
  );
  issues.addAll(validateProgram(program));

  final all = <Chapter>[];
  var pending = 0;
  for (final season in program.seasons) {
    final dir = Directory('$contentDir/${season.path}');
    final files = dir.existsSync()
        ? (dir
              .listSync()
              .whereType<File>()
              .map((f) => f.path)
              .where((p) => RegExp(r'day\d\d\.json$').hasMatch(p))
              .toList()
            ..sort())
        : <String>[];
    final available = <Chapter>[];
    for (final path in files) {
      final c = _load(path, issues);
      if (c == null) continue;
      issues.addAll(validateChapter(c));
      if (c.seasonId != season.id) {
        issues.add(ContentIssue(path, 'seasonId must be ${season.id}'));
      }
      all.add(c);
      if (program.day(c.id)?.isAvailable ?? false) {
        available.add(c);
      } else {
        pending++;
      }
    }
    final curriculum = season.curriculum;
    if (curriculum != null) {
      issues.addAll(validateCurriculum(curriculum, available));
    } else {
      issues.add(ContentIssue(season.label, 'no curriculum.json yet'));
    }
    stdout.writeln(
      '${season.label} ${season.title}: ${files.length} manuscript(s), '
      '${program.daysOf(season).where((d) => d.isAvailable).length}/${season.dayCount} available',
    );
  }
  // Duplicates anywhere in the year, not only inside one season.
  issues.addAll(validateSeason(all, checkOrder: false));
  stdout.writeln(
    'year: ${program.totalDays} days, ${program.availableDays.length} available, '
    '$pending written but not yet available',
  );
  _finish(issues, all.length);
}

Chapter? _load(String path, List<ContentIssue> issues) {
  try {
    final json =
        jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    final chapter = Chapter.fromJson(json, path: path);
    _printStats(chapter);
    return chapter;
  } on Object catch (e) {
    issues.add(ContentIssue(path, 'failed to load: $e'));
    return null;
  }
}

void _finish(List<ContentIssue> issues, int count) {
  if (issues.isEmpty) {
    stdout.writeln('\nOK: $count chapter(s), no issues.');
    return;
  }
  stderr.writeln('\n${issues.length} issue(s):');
  for (final issue in issues) {
    stderr.writeln('  - $issue');
  }
  exitCode = 1;
}

void _printStats(Chapter c) {
  stdout.writeln('\n${c.dayLabel} ${c.title}  [${c.reviewStatus.label}]');
  stdout.writeln(
    '            ${ReadingMinutes.values.map((m) => m.label.padLeft(14)).join()}',
  );
  for (final level in ReadingLevel.values) {
    final cells = ReadingMinutes.values.map((m) {
      final composed = composeChapter(c, minutes: m, level: level);
      return '${composed.characterCount}자 ${composed.estimatedMinutes.toStringAsFixed(1)}분'
          .padLeft(14);
    });
    stdout.writeln('  ${level.label.padRight(8)}${cells.join()}');
  }
}
