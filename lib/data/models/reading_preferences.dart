// Pure Dart reading preference enums shared by content composition and settings.

/// 성경 이해 수준. Changes the depth of explanatory layers, never the story.
enum ReadingLevel {
  beginner('beginner', '입문', '처음 읽는 분께 인물·지명·용어를 쉽게 풀어 드립니다.'),
  growth('growth', '성장', '언약의 흐름과 구약·신약의 연결을 더 살펴봅니다.'),
  deep('deep', '심화', '본문의 구조와 주요 해석을 더 깊이 다룹니다.');

  const ReadingLevel(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  /// Which note layers are shown at this level. Deep readers also receive the
  /// covenant-thread notes, because the deep layer builds on them.
  List<ReadingLevel> get noteLayers => switch (this) {
    ReadingLevel.beginner => const [ReadingLevel.beginner],
    ReadingLevel.growth => const [ReadingLevel.growth],
    ReadingLevel.deep => const [ReadingLevel.growth, ReadingLevel.deep],
  };

  /// Small label shown above a note of this layer.
  String get noteLabel => switch (this) {
    ReadingLevel.beginner => '쉽게 풀어 보기',
    ReadingLevel.growth => '언약의 흐름',
    ReadingLevel.deep => '더 깊이',
  };

  static ReadingLevel fromId(String? id) =>
      values.firstWhere((l) => l.id == id, orElse: () => ReadingLevel.beginner);
}

/// 하루 독서 시간 (target, not a guarantee).
enum ReadingMinutes {
  five(5),
  ten(10),
  fifteen(15),
  twenty(20);

  const ReadingMinutes(this.minutes);

  final int minutes;

  String get label => '$minutes분';

  bool includes(ReadingMinutes tier) => tier.minutes <= minutes;

  static ReadingMinutes fromMinutes(int? minutes) =>
      values.firstWhere((m) => m.minutes == minutes, orElse: () => ReadingMinutes.ten);
}
