// Pure Dart: builds what a reader actually sees for a (mode, level) pair.

import '../models/reading_preferences.dart';
import 'chapter.dart';

/// Assumed contemplative silent-reading speed for Korean prose, counted in
/// non-whitespace characters. Reading-time targets are estimates, not promises.
const int kReadingCharsPerMinute = 500;

class ComposedNote {
  const ComposedNote({required this.layer, required this.text});

  final ReadingLevel layer;
  final String text;
}

class ComposedSection {
  const ComposedSection({required this.section, required this.notes});

  final ContentSection section;
  final List<ComposedNote> notes;
}

class ComposedChapter {
  const ComposedChapter({
    required this.chapter,
    required this.minutes,
    required this.level,
    required this.sections,
  });

  final Chapter chapter;
  final ReadingMinutes minutes;
  final ReadingLevel level;
  final List<ComposedSection> sections;

  /// Every piece of text the reader will meet, in order.
  Iterable<String> get allText sync* {
    for (final s in sections) {
      yield s.section.heading;
      for (final b in s.section.blocks) {
        yield b.text;
      }
      for (final n in s.notes) {
        yield n.text;
      }
    }
    yield chapter.keyMessage;
    yield* chapter.reflectionQuestions;
  }

  int get characterCount =>
      allText.fold(0, (sum, t) => sum + countReadableCharacters(t));

  double get estimatedMinutes => characterCount / kReadingCharsPerMinute;

  /// Rounded estimate shown in the UI (never below 1).
  int get displayMinutes {
    final m = estimatedMinutes.round();
    return m < 1 ? 1 : m;
  }
}

int countReadableCharacters(String text) =>
    text.replaceAll(RegExp(r'\s'), '').length;

ComposedChapter composeChapter(
  Chapter chapter, {
  required ReadingMinutes minutes,
  required ReadingLevel level,
}) {
  final layers = level.noteLayers;
  return ComposedChapter(
    chapter: chapter,
    minutes: minutes,
    level: level,
    sections: [
      for (final section in chapter.sections)
        if (minutes.includes(section.tier))
          ComposedSection(
            section: section,
            notes: [
              for (final layer in layers)
                for (final text
                    in section.levelNotes[layer] ?? const <String>[])
                  ComposedNote(layer: layer, text: text),
            ],
          ),
    ],
  );
}
