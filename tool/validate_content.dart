// Validates chapter JSON files and prints reading-time statistics.
//
// Usage:
//   dart run tool/validate_content.dart                 # whole season 1
//   dart run tool/validate_content.dart path/day03.json # specific files
//
// Exits with code 1 when any issue is found.

import 'dart:convert';
import 'dart:io';

import 'package:focus_jesus/data/content/chapter.dart';
import 'package:focus_jesus/data/content/chapter_composer.dart';
import 'package:focus_jesus/data/content/content_validator.dart';
import 'package:focus_jesus/data/content/curriculum.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';

const String seasonDir = 'assets/content/season1';

void main(List<String> args) {
  final files = args.isNotEmpty
      ? args
      : (Directory(seasonDir)
            .listSync()
            .whereType<File>()
            .map((f) => f.path)
            .where((p) => RegExp(r'day\d\d\.json$').hasMatch(p))
            .toList()
          ..sort());

  final issues = <ContentIssue>[];
  final chapters = <Chapter>[];
  for (final path in files) {
    try {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
      final chapter = Chapter.fromJson(json, path: path);
      chapters.add(chapter);
      issues.addAll(validateChapter(chapter));
      _printStats(chapter);
    } on Object catch (e) {
      issues.add(ContentIssue(path, 'failed to load: $e'));
    }
  }
  if (args.isEmpty) {
    issues.addAll(validateSeason(chapters));
    final curriculumFile = File('$seasonDir/curriculum.json');
    if (curriculumFile.existsSync()) {
      try {
        final curriculum = Curriculum.fromJson(
          jsonDecode(curriculumFile.readAsStringSync()) as Map<String, Object?>,
        );
        issues.addAll(validateCurriculum(curriculum, chapters));
        stdout.writeln(
          'curriculum: ${curriculum.days.length} days, '
          '${curriculum.days.where((d) => d.isAvailable).length} available',
        );
      } on Object catch (e) {
        issues.add(ContentIssue(curriculumFile.path, 'failed to load: $e'));
      }
    } else {
      issues.add(const ContentIssue('$seasonDir/curriculum.json', 'missing'));
    }
  }

  if (issues.isEmpty) {
    stdout.writeln('\nOK: ${chapters.length} chapter(s), no issues.');
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
