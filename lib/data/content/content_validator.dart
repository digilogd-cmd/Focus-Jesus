// Pure Dart editorial/technical validation for chapter content.
// Run via `dart run tool/validate_content.dart` and test/content/*.

import '../models/reading_preferences.dart';
import 'chapter.dart';
import 'chapter_composer.dart';

class ContentIssue {
  const ContentIssue(this.where, this.message);

  final String where;
  final String message;

  @override
  String toString() => '$where: $message';
}

/// Acceptable estimate window for each reading mode, as a fraction of target.
const double kMinTimeRatio = 0.7;
const double kMaxTimeRatio = 1.35;

/// Each longer mode must add at least this much body text.
const int kMinTierIncrementChars = 1500;

/// Quoted passages longer than this risk reproducing a copyrighted
/// translation, so content must paraphrase instead.
const int kMaxQuotedChars = 50;

const List<String> _forbiddenMarkers = [
  'lorem', 'ipsum', 'todo', 'tbd', 'placeholder', 'xxx', '더미', '예시 문단',
  '내용 추가', '추후 작성', '작성 예정', '(생략)',
];

final RegExp _quoted = RegExp(r'[“"「『]([^”"」』]*)[”"」』]');

String normalizeForDuplicateCheck(String text) =>
    text.replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '');

List<ContentIssue> validateChapter(Chapter c) {
  final issues = <ContentIssue>[];
  void err(String where, String message) =>
      issues.add(ContentIssue('${c.id} $where', message));

  // Identity.
  final expectedId = '${c.seasonId}-d${c.order.toString().padLeft(2, '0')}';
  if (c.id != expectedId) err('id', 'expected "$expectedId"');
  if (c.reviewStatus == ReviewStatus.approved) {
    err('reviewStatus', 'AI-assisted drafts cannot be marked approved without a human theology review');
  }

  // Lengths of display strings.
  if (c.title.length > 32) err('title', 'too long (${c.title.length} > 32)');
  if (c.summary.length > 70) err('summary', 'too long (${c.summary.length} > 70)');
  if (c.keyMessage.length > 120) err('keyMessage', 'too long (${c.keyMessage.length} > 120)');

  // References.
  if (!c.references.any((r) => r.primary)) err('references', 'needs a primary reference');

  // Questions.
  if (c.reflectionQuestions.length != 3) {
    err('reflectionQuestions', 'exactly 3 questions required, found ${c.reflectionQuestions.length}');
  }
  for (final q in c.reflectionQuestions) {
    if (!q.endsWith('?')) err('reflectionQuestions', 'question must end with "?": $q');
  }
  if (c.learningObjectives.length < 2) err('learningObjectives', 'at least 2 required');

  // Sections: ids, block content.
  final ids = <String>{};
  for (final s in c.sections) {
    if (!ids.add(s.id)) err('sections', 'duplicate section id ${s.id}');
    if (!s.blocks.any((b) => b.type == BlockType.paragraph)) {
      err('section ${s.id}', 'needs at least one paragraph');
    }
    for (final b in s.blocks) {
      final len = countReadableCharacters(b.text);
      if (b.type == BlockType.paragraph && len < 30) {
        err('section ${s.id}', 'paragraph too short ($len chars): ${b.text}');
      }
      if (len > 900) err('section ${s.id}', 'block too long ($len chars) for comfortable reading');
      if (b.type == BlockType.emphasis && len > 140) {
        err('section ${s.id}', 'emphasis must be a single sentence (≤140 chars)');
      }
    }
  }
  if (!c.sections.any((s) => s.blocks.any((b) => b.type == BlockType.emphasis))) {
    err('sections', 'at least one emphasis sentence required');
  }

  // Story arc must hold in every mode.
  for (final mode in ReadingMinutes.values) {
    final included = c.sections.where((s) => mode.includes(s.tier)).toList();
    if (included.isEmpty) {
      err('mode ${mode.label}', 'no sections');
      continue;
    }
    if (included.first.kind != SectionKind.opening) {
      err('mode ${mode.label}', 'must start with an opening section');
    }
    if (included.last.kind != SectionKind.today) {
      err('mode ${mode.label}', 'must end with a today section');
    }
    for (final required in const [SectionKind.story, SectionKind.christ]) {
      if (!included.any((s) => s.kind == required)) {
        err('mode ${mode.label}', 'missing ${required.name} section');
      }
    }
    if (!included.any((s) => s.blocks.any((b) => b.type == BlockType.scripture))) {
      err('mode ${mode.label}', 'needs at least one scripture pointer in the reading flow');
    }
  }

  // Level layers must change the reading in every mode.
  final coreSections = c.sections.where((s) => s.tier == ReadingMinutes.five);
  for (final layer in ReadingLevel.values) {
    final inCore = coreSections.fold<int>(0, (n, s) => n + (s.levelNotes[layer]?.length ?? 0));
    final total = c.sections.fold<int>(0, (n, s) => n + (s.levelNotes[layer]?.length ?? 0));
    if (inCore < 1) err('levelNotes', '${layer.id} needs a note in a 5-minute section');
    if (total < 4) err('levelNotes', '${layer.id} needs at least 4 notes (found $total)');
  }

  // Reading time per mode/level.
  for (final level in ReadingLevel.values) {
    var previousChars = -1;
    for (final mode in ReadingMinutes.values) {
      final composed = composeChapter(c, minutes: mode, level: level);
      final minutes = composed.estimatedMinutes;
      final lo = mode.minutes * kMinTimeRatio;
      final hi = mode.minutes * kMaxTimeRatio;
      if (minutes < lo || minutes > hi) {
        err(
          'time ${mode.label}/${level.label}',
          'estimate ${minutes.toStringAsFixed(1)}분 outside ${lo.toStringAsFixed(1)}–${hi.toStringAsFixed(1)}분',
        );
      }
      final chars = composed.characterCount;
      if (previousChars >= 0 && chars - previousChars < kMinTierIncrementChars) {
        err('time ${mode.label}/${level.label}', 'adds only ${chars - previousChars} chars over the shorter mode');
      }
      previousChars = chars;
    }
  }

  // Text hygiene.
  final seen = <String, String>{};
  for (final (where, text) in chapterTexts(c)) {
    final lower = text.toLowerCase();
    for (final marker in _forbiddenMarkers) {
      if (lower.contains(marker)) err(where, 'contains placeholder marker "$marker"');
    }
    for (final m in _quoted.allMatches(text)) {
      final quoted = countReadableCharacters(m.group(1)!);
      if (quoted > kMaxQuotedChars) {
        err(where, 'quoted passage of $quoted chars; paraphrase instead of quoting a translation');
      }
    }
    final key = normalizeForDuplicateCheck(text);
    if (key.length >= 20) {
      final previous = seen[key];
      if (previous != null) err(where, 'duplicates text in $previous');
      seen[key] = where;
    }
  }
  return issues;
}

/// Cross-chapter checks for a season.
List<ContentIssue> validateSeason(List<Chapter> chapters) {
  final issues = <ContentIssue>[];
  final orders = chapters.map((c) => c.order).toList()..sort();
  for (var i = 0; i < orders.length; i++) {
    if (orders[i] != i + 1) {
      issues.add(ContentIssue('season', 'chapter orders must be 1..${orders.length} without gaps: $orders'));
      break;
    }
  }
  final ids = <String>{};
  for (final c in chapters) {
    if (!ids.add(c.id)) issues.add(ContentIssue('season', 'duplicate chapter id ${c.id}'));
  }
  final seen = <String, String>{};
  for (final c in chapters) {
    for (final (where, text) in chapterTexts(c)) {
      final key = normalizeForDuplicateCheck(text);
      if (key.length < 40) continue;
      final previous = seen[key];
      if (previous != null && !previous.startsWith('${c.id} ')) {
        issues.add(ContentIssue('${c.id} $where', 'repeats text from $previous'));
      }
      seen[key] = '${c.id} $where';
    }
  }
  return issues;
}

Iterable<(String, String)> chapterTexts(Chapter c) sync* {
  yield ('title', c.title);
  yield ('subtitle', c.subtitle);
  yield ('summary', c.summary);
  yield ('keyMessage', c.keyMessage);
  for (final s in c.sections) {
    yield ('section ${s.id} heading', s.heading);
    for (var i = 0; i < s.blocks.length; i++) {
      yield ('section ${s.id} block $i', s.blocks[i].text);
    }
    for (final e in s.levelNotes.entries) {
      for (var i = 0; i < e.value.length; i++) {
        yield ('section ${s.id} ${e.key.id} note $i', e.value[i]);
      }
    }
  }
  for (var i = 0; i < c.reflectionQuestions.length; i++) {
    yield ('question $i', c.reflectionQuestions[i]);
  }
}
