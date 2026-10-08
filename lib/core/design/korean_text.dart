// Korean line breaking.
//
// Flutter breaks Hangul between any two syllables, which splits words like
// "합니/다" at line ends. Editorial Korean typesetting keeps words whole
// (CSS `word-break: keep-all`). We get the same result by placing an invisible
// WORD JOINER (U+2060) between the characters of each word, leaving the
// spaces as the only break opportunities. A word longer than the line still
// breaks (Flutter falls back to an emergency break), so nothing overflows.

const String _wordJoiner = '⁠';

final RegExp _space = RegExp(r'\s');

/// Returns [text] with breaks allowed only at whitespace.
String keepAll(String text) {
  if (text.length < 2) return text;
  final out = StringBuffer();
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final ch = String.fromCharCode(runes[i]);
    out.write(ch);
    if (i + 1 < runes.length) {
      final next = String.fromCharCode(runes[i + 1]);
      if (!_space.hasMatch(ch) && !_space.hasMatch(next) && !_breakAfter(ch)) {
        out.write(_wordJoiner);
      }
    }
  }
  return out.toString();
}

/// Characters after which a line may still break inside a "word".
bool _breakAfter(String ch) => ch == '/' || ch == '–' || ch == '—';
