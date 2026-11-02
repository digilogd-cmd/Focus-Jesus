// Pure Dart: used by the app and by tool/validate_content.dart.

part 'bible_books.g.dart';

enum Testament { oldTestament, newTestament }

class BibleBook {
  const BibleBook({
    required this.code,
    required this.koreanName,
    required this.englishName,
    required this.bskoreaCode,
    required this.testament,
    required this.verseCounts,
  });

  /// USFM-style book code, e.g. `GEN`, `JHN`.
  final String code;
  final String koreanName;
  final String englishName;

  /// Book code used by the older 대한성서공회 desktop reading page
  /// (`BibleReference.legacyExternalUri`). The mobile platform uses [code].
  final String bskoreaCode;
  final Testament testament;

  /// verseCounts[i] is the number of verses in chapter i + 1.
  final List<int> verseCounts;

  int get chapterCount => verseCounts.length;

  int versesIn(int chapter) => verseCounts[chapter - 1];

  static BibleBook? byCode(String code) => _byCode[code.toUpperCase()];
}

final Map<String, BibleBook> _byCode = {
  for (final book in kBibleBooks) book.code: book,
};
