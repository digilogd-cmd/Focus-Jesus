// Pure Dart: the 30-day season outline. Only days whose manuscript is
// complete are marked available; planned days are never shown as readable.

import '../../core/bible/bible_reference.dart';
import 'chapter.dart';
import 'content_validator.dart';

enum CurriculumDayStatus { available, planned }

class CurriculumDay {
  const CurriculumDay({
    required this.day,
    required this.chapterId,
    required this.title,
    required this.references,
    required this.objective,
    required this.themes,
    required this.status,
    this.file,
  });

  final int day;
  final String chapterId;
  final String title;
  final List<BibleReference> references;
  final String objective;
  final List<String> themes;
  final CurriculumDayStatus status;

  /// Asset file name for available days, relative to the season folder.
  final String? file;

  bool get isAvailable => status == CurriculumDayStatus.available;
}

class Curriculum {
  const Curriculum({
    required this.seasonId,
    required this.title,
    required this.description,
    required this.days,
  });

  final String seasonId;
  final String title;
  final String description;
  final List<CurriculumDay> days;

  List<CurriculumDay> get availableDays =>
      days.where((d) => d.isAvailable).toList();

  factory Curriculum.fromJson(Map<String, Object?> json) {
    String str(Map<String, Object?> m, String key, String path) {
      final v = m[key];
      if (v is! String || v.trim().isEmpty) {
        throw ContentFormatException(
          '$path.$key',
          'expected a non-empty string',
        );
      }
      return v.trim();
    }

    final rawDays = json['days'];
    if (rawDays is! List || rawDays.isEmpty) {
      throw ContentFormatException(r'$.days', 'expected a non-empty list');
    }
    final days = <CurriculumDay>[];
    for (var i = 0; i < rawDays.length; i++) {
      final path = '\$.days[$i]';
      final m = (rawDays[i] as Map).cast<String, Object?>();
      final day = m['day'];
      if (day is! int) {
        throw ContentFormatException('$path.day', 'expected an integer');
      }
      final status = switch (m['status']) {
        'available' => CurriculumDayStatus.available,
        'planned' => CurriculumDayStatus.planned,
        final other => throw ContentFormatException(
          '$path.status',
          'unknown status $other',
        ),
      };
      final refs = m['references'];
      if (refs is! List || refs.isEmpty) {
        throw ContentFormatException(
          '$path.references',
          'expected a non-empty list',
        );
      }
      final themes = m['themes'];
      days.add(
        CurriculumDay(
          day: day,
          chapterId: str(m, 'chapterId', path),
          title: str(m, 'title', path),
          references: [
            for (final r in refs)
              () {
                try {
                  return BibleReference.parse(r as String);
                } on BibleReferenceFormatException catch (e) {
                  throw ContentFormatException(
                    '$path.references',
                    e.toString(),
                  );
                }
              }(),
          ],
          objective: str(m, 'objective', path),
          themes: themes is List ? themes.cast<String>() : const [],
          status: status,
          file: m['file'] as String?,
        ),
      );
    }
    return Curriculum(
      seasonId: str(json, 'seasonId', r'$'),
      title: str(json, 'title', r'$'),
      description: str(json, 'description', r'$'),
      days: days,
    );
  }
}

List<ContentIssue> validateCurriculum(
  Curriculum curriculum,
  List<Chapter> chapters,
) {
  final issues = <ContentIssue>[];
  final byId = {for (final c in chapters) c.id: c};
  for (var i = 0; i < curriculum.days.length; i++) {
    final d = curriculum.days[i];
    final where = 'curriculum day ${d.day}';
    if (d.day != i + 1) {
      issues.add(ContentIssue(where, 'days must be numbered 1..n in order'));
    }
    final expectedId =
        '${curriculum.seasonId}-d${d.day.toString().padLeft(2, '0')}';
    if (d.chapterId != expectedId) {
      issues.add(ContentIssue(where, 'chapterId must be $expectedId'));
    }
    if (d.isAvailable) {
      final chapter = byId[d.chapterId];
      if (chapter == null) {
        issues.add(
          ContentIssue(
            where,
            'marked available but no chapter manuscript exists',
          ),
        );
      } else if (chapter.title != d.title) {
        issues.add(
          ContentIssue(where, 'title differs from chapter: "${chapter.title}"'),
        );
      }
      if (d.file == null) {
        issues.add(ContentIssue(where, 'available day needs a file'));
      }
    } else if (d.file != null) {
      issues.add(
        ContentIssue(where, 'planned day must not reference a manuscript file'),
      );
    }
  }
  for (final c in chapters) {
    final listed = curriculum.days.any(
      (d) => d.chapterId == c.id && d.isAvailable,
    );
    if (!listed) {
      issues.add(
        ContentIssue(
          c.id,
          'chapter exists but is not available in the curriculum',
        ),
      );
    }
  }
  return issues;
}
