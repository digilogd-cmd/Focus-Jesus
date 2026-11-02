import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/data/content/chapter.dart';
import 'package:focus_jesus/data/content/chapter_composer.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';

import '../helpers/test_app.dart';

Map<String, Object?> rawChapter(int day) => jsonDecode(
  File('$seasonDir/day${day.toString().padLeft(2, '0')}.json')
      .readAsStringSync(),
) as Map<String, Object?>;

void main() {
  final season = loadSeasonFromDisk();

  test('reading modes are 1, 3, 5, 10, 15, 20 minutes; 1 and 3 are brief', () {
    expect(ReadingMinutes.values.map((m) => m.minutes), [1, 3, 5, 10, 15, 20]);
    expect(ReadingMinutes.briefs, [ReadingMinutes.one, ReadingMinutes.three]);
    expect(ReadingMinutes.tiers.any((m) => m.isBrief), isFalse);
    expect(ReadingMinutes.fromMinutes(3), ReadingMinutes.three);
    // A brief mode never pulls sections from the tiered manuscript.
    expect(ReadingMinutes.three.includes(ReadingMinutes.five), isFalse);
  });

  test('every chapter has its own 1- and 3-minute text', () {
    for (final c in season.chapters) {
      final tieredIds = c.sections.map((s) => s.id).toSet();
      for (final mode in ReadingMinutes.briefs) {
        for (final level in ReadingLevel.values) {
          final composed = composeChapter(c, minutes: mode, level: level);
          expect(composed.sections, isNotEmpty, reason: '${c.id} $mode');
          expect(
            composed.sections
                .map((s) => s.section.id)
                .toSet()
                .intersection(tieredIds),
            isEmpty,
            reason: '${c.id} ${mode.label} reads only its brief',
          );
        }
      }
      final one = composeChapter(
        c,
        minutes: ReadingMinutes.one,
        level: ReadingLevel.deep,
      );
      expect(
        one.sections.expand((s) => s.notes),
        isEmpty,
        reason: '${c.id}: no level notes in 1 minute',
      );
      final three = {
        for (final level in ReadingLevel.values)
          level: composeChapter(
            c,
            minutes: ReadingMinutes.three,
            level: level,
          ).sections.expand((s) => s.notes).map((n) => n.layer).toSet(),
      };
      expect(three[ReadingLevel.beginner], {ReadingLevel.beginner});
      expect(three[ReadingLevel.growth], {ReadingLevel.growth});
      expect(three[ReadingLevel.deep], {
        ReadingLevel.growth,
        ReadingLevel.deep,
      });
    }
  });

  test('reading time grows 1 < 3 < 5 minutes for every chapter and level', () {
    for (final c in season.chapters) {
      for (final level in ReadingLevel.values) {
        int chars(ReadingMinutes m) =>
            composeChapter(c, minutes: m, level: level).characterCount;
        expect(
          chars(ReadingMinutes.one) < chars(ReadingMinutes.three) &&
              chars(ReadingMinutes.three) < chars(ReadingMinutes.five),
          isTrue,
          reason: '${c.id} ${level.id}',
        );
      }
    }
  });

  test('brief keys other than 1 and 3, and brief tiers in the manuscript, are rejected', () {
    final badKey = rawChapter(1);
    (badKey['briefs'] as Map)['2'] = (badKey['briefs'] as Map)['1'];
    expect(
      () => Chapter.fromJson(badKey),
      throwsA(isA<ContentFormatException>()),
    );
    final briefTier = rawChapter(1);
    ((briefTier['sections'] as List).first as Map)['tier'] = 3;
    expect(
      () => Chapter.fromJson(briefTier),
      throwsA(isA<ContentFormatException>()),
    );
  });
}
