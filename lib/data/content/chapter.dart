// Pure Dart content model. Parsing is strict: malformed content fails loudly
// at load time (and in tests) instead of rendering half a chapter.

import '../../core/bible/bible_reference.dart';
import '../models/reading_preferences.dart';

class ContentFormatException implements Exception {
  ContentFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'Content error at $path: $message';
}

/// Editorial review state. Automated checks can never move content past
/// [theologyReviewPending]; only a human reviewer sets [approved].
enum ReviewStatus {
  draft('draft', '초안'),
  technicalQaPassed('technicalQaPassed', '기술 검증 완료'),
  theologyReviewPending('theologyReviewPending', '신학 검수 대기'),
  approved('approved', '검수 완료');

  const ReviewStatus(this.id, this.label);

  final String id;
  final String label;

  static ReviewStatus parse(String id, String path) => values.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ContentFormatException(path, 'unknown review status "$id"'),
  );
}

/// The role a section plays in the chapter's story arc.
enum SectionKind {
  opening, // the question that opens the day
  story, // retelling of the biblical narrative
  context, // narrative/literary context
  history, // historical-cultural background
  covenant, // covenant thread
  christ, // connection to Jesus Christ
  comparison, // related passages compared
  deep, // deeper exposition / interpretation
  today; // closing: what remains for us today

  static SectionKind parse(String id, String path) => values.firstWhere(
    (k) => k.name == id,
    orElse: () => throw ContentFormatException(path, 'unknown section kind "$id"'),
  );
}

enum BlockType { paragraph, emphasis, scripture }

class ContentBlock {
  const ContentBlock({required this.type, required this.text, this.reference});

  final BlockType type;
  final String text;

  /// Only for [BlockType.scripture]: the passage this block points readers to.
  final BibleReference? reference;
}

class ContentSection {
  const ContentSection({
    required this.id,
    required this.tier,
    required this.kind,
    required this.heading,
    required this.blocks,
    required this.levelNotes,
  });

  final String id;

  /// The shortest reading mode that includes this section.
  final ReadingMinutes tier;
  final SectionKind kind;
  final String heading;
  final List<ContentBlock> blocks;

  /// Explanatory layers keyed by level. See [ReadingLevel.noteLayers].
  final Map<ReadingLevel, List<String>> levelNotes;
}

class ChapterReference {
  const ChapterReference({required this.reference, required this.primary});

  final BibleReference reference;
  final bool primary;
}

class Chapter {
  const Chapter({
    required this.schemaVersion,
    required this.id,
    required this.seasonId,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.contentVersion,
    required this.reviewStatus,
    required this.references,
    required this.learningObjectives,
    required this.themes,
    required this.keyMessage,
    required this.sections,
    required this.reflectionQuestions,
  });

  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String seasonId;
  final int order;
  final String title;
  final String subtitle;
  final String summary;
  final String contentVersion;
  final ReviewStatus reviewStatus;
  final List<ChapterReference> references;
  final List<String> learningObjectives;
  final List<String> themes;
  final String keyMessage;
  final List<ContentSection> sections;
  final List<String> reflectionQuestions;

  /// DAY number shown to readers (1-based order inside the season).
  int get day => order;

  String get dayLabel => 'DAY ${day.toString().padLeft(2, '0')}';

  /// External reading links derived from [references] so the label and the
  /// URL can never drift apart.
  List<ExternalLink> get externalLinks => [
    for (final r in references)
      ExternalLink(label: r.reference.label, uri: r.reference.externalUri),
  ];

  factory Chapter.fromJson(Map<String, Object?> json, {String path = r'$'}) {
    final r = _Reader(json, path);
    final schemaVersion = r.integer('schemaVersion');
    if (schemaVersion != supportedSchemaVersion) {
      throw ContentFormatException(path, 'unsupported schemaVersion $schemaVersion');
    }
    final sections = r.list('sections', (item, p) {
      final s = _Reader(_asMap(item, p), p);
      final tierValue = s.integer('tier');
      final tier = ReadingMinutes.values.firstWhere(
        (m) => m.minutes == tierValue,
        orElse: () => throw ContentFormatException('$p.tier', 'tier must be 5, 10, 15 or 20'),
      );
      final notesJson = s.optionalMap('levelNotes');
      final notes = <ReadingLevel, List<String>>{};
      for (final entry in notesJson.entries) {
        final level = ReadingLevel.values.firstWhere(
          (l) => l.id == entry.key,
          orElse: () => throw ContentFormatException('$p.levelNotes', 'unknown level "${entry.key}"'),
        );
        final value = entry.value;
        if (value is! List) {
          throw ContentFormatException('$p.levelNotes.${entry.key}', 'must be a list');
        }
        notes[level] = [
          for (var i = 0; i < value.length; i++)
            _nonEmptyString(value[i], '$p.levelNotes.${entry.key}[$i]'),
        ];
      }
      return ContentSection(
        id: s.string('id'),
        tier: tier,
        kind: SectionKind.parse(s.string('kind'), '$p.kind'),
        heading: s.string('heading'),
        blocks: s.list('blocks', (b, bp) {
          final br = _Reader(_asMap(b, bp), bp);
          final type = BlockType.values.firstWhere(
            (t) => t.name == br.string('type'),
            orElse: () => throw ContentFormatException('$bp.type', 'unknown block type'),
          );
          BibleReference? ref;
          if (type == BlockType.scripture) {
            ref = _parseRef(br.string('ref'), '$bp.ref');
          }
          return ContentBlock(type: type, text: br.string('text'), reference: ref);
        }),
        levelNotes: notes,
      );
    });

    return Chapter(
      schemaVersion: schemaVersion,
      id: r.string('id'),
      seasonId: r.string('seasonId'),
      order: r.integer('order'),
      title: r.string('title'),
      subtitle: r.string('subtitle'),
      summary: r.string('summary'),
      contentVersion: r.string('contentVersion'),
      reviewStatus: ReviewStatus.parse(r.string('reviewStatus'), '$path.reviewStatus'),
      references: r.list('references', (item, p) {
        final m = _Reader(_asMap(item, p), p);
        final role = m.string('role');
        if (role != 'primary' && role != 'related') {
          throw ContentFormatException('$p.role', 'must be primary or related');
        }
        return ChapterReference(
          reference: _parseRef(m.string('ref'), '$p.ref'),
          primary: role == 'primary',
        );
      }),
      learningObjectives: r.list('learningObjectives', _nonEmptyString),
      themes: r.list('themes', _nonEmptyString),
      keyMessage: r.string('keyMessage'),
      sections: sections,
      reflectionQuestions: r.list('reflectionQuestions', _nonEmptyString),
    );
  }
}

class ExternalLink {
  const ExternalLink({required this.label, required this.uri});

  final String label;
  final Uri uri;
}

BibleReference _parseRef(String source, String path) {
  try {
    return BibleReference.parse(source);
  } on BibleReferenceFormatException catch (e) {
    throw ContentFormatException(path, e.toString());
  }
}

Map<String, Object?> _asMap(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw ContentFormatException(path, 'expected an object');
}

String _nonEmptyString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw ContentFormatException(path, 'expected a non-empty string');
  }
  return value.trim();
}

class _Reader {
  _Reader(this.json, this.path);

  final Map<String, Object?> json;
  final String path;

  String string(String key) => _nonEmptyString(json[key], '$path.$key');

  int integer(String key) {
    final v = json[key];
    if (v is! int) throw ContentFormatException('$path.$key', 'expected an integer');
    return v;
  }

  Map<String, Object?> optionalMap(String key) {
    final v = json[key];
    if (v == null) return const {};
    return _asMap(v, '$path.$key');
  }

  List<T> list<T>(String key, T Function(Object? item, String path) parse) {
    final v = json[key];
    if (v is! List || v.isEmpty) {
      throw ContentFormatException('$path.$key', 'expected a non-empty list');
    }
    return [for (var i = 0; i < v.length; i++) parse(v[i], '$path.$key[$i]')];
  }
}
