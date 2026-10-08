// Pure Dart: used by the app and by tool/validate_content.dart.

import 'bible_books.dart';

export 'bible_books.dart';

class BibleReferenceFormatException implements Exception {
  BibleReferenceFormatException(this.source, this.message);

  final String source;
  final String message;

  @override
  String toString() => 'Invalid Bible reference "$source": $message';
}

/// A contiguous passage inside one book.
///
/// Source notation (used in content JSON):
/// - `GEN 3`            whole chapter
/// - `GEN 6-9`          chapter range
/// - `GEN 12:1-3`       verse range in one chapter
/// - `GEN 3:15`         single verse
/// - `GEN 11:27-12:9`   range across chapters
class BibleReference {
  const BibleReference._({
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.source,
  });

  final BibleBook book;
  final int startChapter;

  /// Null when the reference covers whole chapters.
  final int? startVerse;
  final int endChapter;
  final int? endVerse;
  final String source;

  bool get isWholeChapters => startVerse == null;

  static final RegExp _pattern = RegExp(
    r'^([1-3]?[A-Z]{2,3}) (\d+)(?::(\d+))?(?:-(\d+)(?::(\d+))?)?$',
  );

  /// Parses and validates against the canonical chapter/verse table.
  factory BibleReference.parse(String source) {
    final match = _pattern.firstMatch(source.trim());
    if (match == null) {
      throw BibleReferenceFormatException(source, 'unrecognised notation');
    }
    final book = BibleBook.byCode(match.group(1)!);
    if (book == null) {
      throw BibleReferenceFormatException(source, 'unknown book code');
    }
    final c1 = int.parse(match.group(2)!);
    final v1 = match.group(3) == null ? null : int.parse(match.group(3)!);
    final a = match.group(4) == null ? null : int.parse(match.group(4)!);
    final b = match.group(5) == null ? null : int.parse(match.group(5)!);

    int endChapter;
    int? endVerse;
    if (v1 == null) {
      // Chapter or chapter range. `GEN 6-9:3` is not allowed.
      if (b != null) {
        throw BibleReferenceFormatException(
          source,
          'mixed chapter/verse range',
        );
      }
      endChapter = a ?? c1;
      endVerse = null;
    } else if (a == null) {
      endChapter = c1;
      endVerse = v1;
    } else if (b == null) {
      endChapter = c1;
      endVerse = a;
    } else {
      endChapter = a;
      endVerse = b;
    }

    void checkChapter(int c) {
      if (c < 1 || c > book.chapterCount) {
        throw BibleReferenceFormatException(
          source,
          '${book.koreanName} has ${book.chapterCount} chapters, not $c',
        );
      }
    }

    void checkVerse(int c, int v) {
      if (v < 1 || v > book.versesIn(c)) {
        throw BibleReferenceFormatException(
          source,
          '${book.koreanName} $c장 has ${book.versesIn(c)} verses, not $v',
        );
      }
    }

    checkChapter(c1);
    checkChapter(endChapter);
    if (v1 != null) checkVerse(c1, v1);
    if (endVerse != null) checkVerse(endChapter, endVerse);
    final startKey = c1 * 1000 + (v1 ?? 0);
    final endKey = endChapter * 1000 + (endVerse ?? 0);
    if (endKey < startKey) {
      throw BibleReferenceFormatException(
        source,
        'range ends before it starts',
      );
    }

    return BibleReference._(
      book: book,
      startChapter: c1,
      startVerse: v1,
      endChapter: endChapter,
      endVerse: endVerse,
      source: source.trim(),
    );
  }

  /// Korean display label, e.g. `창세기 11:27–12:9`, `창세기 6–9장`.
  String get label {
    final name = book.koreanName;
    if (isWholeChapters) {
      return startChapter == endChapter
          ? '$name $startChapter장'
          : '$name $startChapter–$endChapter장';
    }
    if (startChapter == endChapter) {
      return startVerse == endVerse
          ? '$name $startChapter:$startVerse'
          : '$name $startChapter:$startVerse–$endVerse';
    }
    return '$name $startChapter:$startVerse–$endChapter:$endVerse';
  }

  /// External reading page (대한성서공회 개역개정) opened at the first verse.
  Uri get externalUri => Uri.https(
    'www.bskorea.or.kr',
    '/bible/korbibReadpage.php',
    <String, String>{
      'version': 'GAE',
      'book': book.bskoreaCode,
      'chap': '$startChapter',
      'sec': '${startVerse ?? 1}',
    },
  );

  @override
  String toString() => source;
}
