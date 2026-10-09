import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/core/bible/bible_reference.dart';
import 'package:focus_jesus/data/content/chapter.dart';
import 'package:focus_jesus/data/content/chapter_composer.dart';
import 'package:focus_jesus/data/content/content_validator.dart';
import 'package:focus_jesus/data/content/curriculum.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';

import '../helpers/test_app.dart';

Map<String, Object?> rawChapter(int day) => jsonDecode(
  File('$seasonDir/day${day.toString().padLeft(2, '0')}.json')
      .readAsStringSync(),
) as Map<String, Object?>;

void main() {
  final season = loadSeasonFromDisk();

  group('content JSON parsing', () {
    test('all 7 pilot chapters parse in order', () {
      expect(season.chapters.map((c) => c.id), [
        for (var d = 1; d <= 7; d++) 's1-d0$d',
      ]);
      for (final c in season.chapters) {
        expect(
          c.reviewStatus,
          ReviewStatus.theologyReviewPending,
          reason: c.id,
        );
        expect(c.reflectionQuestions, hasLength(3));
        expect(c.keyMessage, isNotEmpty);
      }
    });

    test('missing required field fails loudly with its path', () {
      final json = rawChapter(1)..remove('keyMessage');
      expect(
        () => Chapter.fromJson(json, path: 'day01'),
        throwsA(
          isA<ContentFormatException>().having(
            (e) => e.path,
            'path',
            'day01.keyMessage',
          ),
        ),
      );
    });

    test('invalid Bible reference is rejected', () {
      final json = rawChapter(1);
      (json['references'] as List).add({'ref': 'GEN 51:1', 'role': 'related'});
      expect(
        () => Chapter.fromJson(json),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('unknown tier and unsupported schema are rejected', () {
      final badTier = rawChapter(2);
      ((badTier['sections'] as List).first as Map)['tier'] = 7;
      expect(
        () => Chapter.fromJson(badTier),
        throwsA(isA<ContentFormatException>()),
      );
      final badSchema = rawChapter(2)..['schemaVersion'] = 99;
      expect(
        () => Chapter.fromJson(badSchema),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test(
      'curriculum lists 30 days, 7 available, planned days have no file',
      () {
        final cur = season.curriculum;
        expect(cur.days, hasLength(30));
        expect(cur.availableDays.map((d) => d.day), [1, 2, 3, 4, 5, 6, 7]);
        for (final d in cur.days.where((d) => !d.isAvailable)) {
          expect(d.file, isNull, reason: 'day ${d.day}');
          expect(d.status, CurriculumDayStatus.planned);
        }
        expect(
          season.chapterById('s1-d08'),
          isNull,
          reason: 'planned days are not readable',
        );
      },
    );
  });

  group('editorial validation', () {
    test('every chapter passes the validator', () {
      for (final c in season.chapters) {
        expect(validateChapter(c), isEmpty, reason: c.id);
      }
    });

    test('season and curriculum cross-checks pass', () {
      expect(validateSeason(season.chapters), isEmpty);
      expect(validateCurriculum(season.curriculum, season.chapters), isEmpty);
    });

    test('validator catches placeholder text, duplicates and quotes', () {
      final json = rawChapter(3);
      final section = (json['sections'] as List).first as Map;
      final blocks = section['blocks'] as List;
      final firstText = (blocks.first as Map)['text'];
      blocks.add({'type': 'paragraph', 'text': firstText});
      blocks.add({
        'type': 'paragraph',
        'text': '이 문단은 추후 작성 예정입니다. 내용을 보강해야 합니다.',
      });
      blocks.add({
        'type': 'paragraph',
        'text': '“태초에 하나님이 천지를 창조하시니라 땅이 혼돈하고 공허하며 흑암이 깊음 위에 있고 하나님의 영은 수면 위에 운행하시니라”',
      });
      final issues = validateChapter(Chapter.fromJson(json))
          .map((i) => i.message)
          .join('\n');
      expect(issues, contains('duplicates'));
      expect(issues, contains('추후 작성'));
      expect(issues, contains('quoted passage'));
    });

    test('approved status cannot be set by automation', () {
      final json = rawChapter(4)..['reviewStatus'] = 'approved';
      final issues = validateChapter(Chapter.fromJson(json));
      expect(
        issues.map((i) => i.message).join(),
        contains('human theology review'),
      );
    });
  });

  group('reading time composition', () {
    test('longer modes add content and keep the same core in order', () {
      for (final c in season.chapters) {
        for (final level in ReadingLevel.values) {
          var previous = <String>[];
          var previousChars = 0;
          for (final m in ReadingMinutes.values) {
            final composed = composeChapter(c, minutes: m, level: level);
            final ids = composed.sections.map((s) => s.section.id).toList();
            expect(
              ids.toSet().containsAll(previous),
              isTrue,
              reason: '${c.id} $m',
            );
            expect(
              composed.characterCount,
              greaterThan(previousChars + kMinTierIncrementChars - 1),
            );
            previous = ids;
            previousChars = composed.characterCount;
          }
        }
      }
    });

    test('every mode starts with the opening, ends with today, includes Christ and Scripture', () {
      for (final c in season.chapters) {
        for (final m in ReadingMinutes.values) {
          final sections = composeChapter(
            c,
            minutes: m,
            level: ReadingLevel.beginner,
          ).sections;
          expect(sections.first.section.kind, SectionKind.opening);
          expect(sections.last.section.kind, SectionKind.today);
          expect(
            sections.any((s) => s.section.kind == SectionKind.christ),
            isTrue,
          );
          expect(
            sections.any(
              (s) => s.section.blocks.any((b) => b.type == BlockType.scripture),
            ),
            isTrue,
          );
        }
      }
    });

    test('estimated minutes stay within the target window', () {
      for (final c in season.chapters) {
        for (final level in ReadingLevel.values) {
          for (final m in ReadingMinutes.values) {
            final est = composeChapter(
              c,
              minutes: m,
              level: level,
            ).estimatedMinutes;
            expect(
              est,
              inInclusiveRange(
                m.minutes * kMinTimeRatio,
                m.minutes * kMaxTimeRatio,
              ),
              reason: '${c.id} ${m.label} ${level.label}',
            );
          }
        }
      }
    });

    test(
      'no text is cut mid-sentence: every block ends with sentence punctuation',
      () {
        final ending = RegExp(r'[.?!다요”’)]$');
        for (final c in season.chapters) {
          final composed = composeChapter(
            c,
            minutes: ReadingMinutes.twenty,
            level: ReadingLevel.deep,
          );
          for (final s in composed.sections) {
            for (final b in s.section.blocks) {
              expect(
                ending.hasMatch(b.text.trim()),
                isTrue,
                reason: '${c.id} ${s.section.id}: ${b.text}',
              );
            }
            for (final n in s.notes) {
              expect(
                ending.hasMatch(n.text.trim()),
                isTrue,
                reason: '${c.id} ${s.section.id} note',
              );
            }
          }
        }
      },
    );
  });

  group('level layers', () {
    final chapter = season.chapters.first;

    test('beginner shows only beginner notes', () {
      final notes = composeChapter(
        chapter,
        minutes: ReadingMinutes.twenty,
        level: ReadingLevel.beginner,
      ).sections.expand((s) => s.notes);
      expect(notes, isNotEmpty);
      expect(notes.every((n) => n.layer == ReadingLevel.beginner), isTrue);
    });

    test('growth shows growth notes; deep adds deep notes on top', () {
      Iterable<ComposedNote> notes(ReadingLevel l) => composeChapter(
        chapter,
        minutes: ReadingMinutes.twenty,
        level: l,
      ).sections.expand((s) => s.notes);
      final growth = notes(ReadingLevel.growth);
      final deep = notes(ReadingLevel.deep);
      expect(growth.every((n) => n.layer == ReadingLevel.growth), isTrue);
      expect(
        deep.where((n) => n.layer == ReadingLevel.growth).length,
        growth.length,
      );
      expect(deep.any((n) => n.layer == ReadingLevel.deep), isTrue);
    });

    test('level never changes the story sections themselves', () {
      for (final m in ReadingMinutes.values) {
        List<String> ids(ReadingLevel l) => composeChapter(
          chapter,
          minutes: m,
          level: l,
        ).sections.map((s) => s.section.id).toList();
        expect(ids(ReadingLevel.beginner), ids(ReadingLevel.deep));
        expect(ids(ReadingLevel.growth), ids(ReadingLevel.deep));
      }
    });
  });

  group('Bible references', () {
    test('parses every notation and formats Korean labels', () {
      expect(BibleReference.parse('GEN 3').label, '창세기 3장');
      expect(BibleReference.parse('GEN 6-9').label, '창세기 6–9장');
      expect(BibleReference.parse('GEN 12:1-3').label, '창세기 12:1–3');
      expect(BibleReference.parse('GEN 3:15').label, '창세기 3:15');
      expect(BibleReference.parse('GEN 11:27-12:9').label, '창세기 11:27–12:9');
      expect(BibleReference.parse('1JN 3:11-15').label, '요한일서 3:11–15');
    });

    test('rejects impossible chapters and verses', () {
      for (final bad in [
        'GEN 51',
        'GEN 1:32',
        'JHN 1:0',
        'GEN 3:5-2',
        'XYZ 1',
        'GEN 6-9:3',
        'gen1',
      ]) {
        expect(
          () => BibleReference.parse(bad),
          throwsA(isA<BibleReferenceFormatException>()),
          reason: bad,
        );
      }
    });

    test('external link opens the passage on the mobile bible platform', () {
      String link(String ref) =>
          BibleReference.parse(ref).externalUri.toString();
      const base = 'https://bible.bskorea.or.kr/bible/NKRV';
      expect(link('GAL 3:6-16'), '$base/GAL.3.6-GAL.3.16');
      expect(link('GAL 3:16'), '$base/GAL.3.16');
      expect(link('GEN 3'), '$base/GEN.3');
      expect(link('1JN 3:8'), '$base/1JN.3.8');
      // Cross-chapter ranges are not supported by the platform: open at the
      // first verse.
      expect(link('GEN 6:1-9:17'), '$base/GEN.6.1');
    });

    test('legacy desktop link is kept for rollback', () {
      final uri = BibleReference.parse('GAL 3:6-16').legacyExternalUri;
      expect(uri.host, 'www.bskorea.or.kr');
      expect(uri.queryParameters, {
        'version': 'GAE',
        'book': 'gal',
        'chap': '3',
        'sec': '6',
      });
    });

    test('table covers 66 books, 1,189 chapters', () {
      expect(kBibleBooks, hasLength(66));
      expect(kBibleBooks.fold<int>(0, (n, b) => n + b.chapterCount), 1189);
      expect(
        kBibleBooks.fold<int>(
          0,
          (n, b) => n + b.verseCounts.fold(0, (a, v) => a + v),
        ),
        31102,
      );
    });
  });
}
