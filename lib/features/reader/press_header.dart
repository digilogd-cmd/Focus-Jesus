import 'package:flutter/material.dart';

import '../../core/design/editorial.dart';
import '../../core/design/korean_text.dart';
import '../../core/design/motion.dart';
import '../../core/design/press.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/content/chapter_composer.dart';

/// Title block at the top of a chapter, "published" as the reading opens:
/// a small open Bible turns its leaf, then the title is typeset in grey
/// metal and printed in ink by a passing roller.
///
/// Replaces [ChapterHeader] (`chapter_body.dart`, kept for rollback) in the
/// reader; the layout and keys are the same.
class PressChapterHeader extends StatelessWidget {
  const PressChapterHeader({
    super.key,
    required this.composed,
    required this.dayNumber,
  });

  final ComposedChapter composed;

  /// Position in the one-year program (1–365).
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    final chapter = composed.chapter;
    final primary = chapter.references
        .firstWhere((r) => r.primary)
        .reference
        .label;
    const step = FjMotion.stagger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            OpenBookMark(key: ValueKey('reader-book')),
            SizedBox(width: FjSpace.m),
            Flexible(child: Reveal(child: FjDualLabel('STORY', '오늘의 이야기'))),
          ],
        ),
        const SizedBox(height: FjSpace.s),
        DayNumeral(day: dayNumber, digits: 3, size: 96, delay: step * 3),
        const SizedBox(height: FjSpace.l),
        PressedText(
          keepAll(chapter.title),
          key: const ValueKey('reader-title'),
          style: t.chapterTitle,
          delay: step * 7,
        ),
        const SizedBox(height: FjSpace.m),
        Reveal(
          delay: step * 18,
          child: Text(keepAll(chapter.subtitle), style: t.subtitle),
        ),
        const SizedBox(height: FjSpace.l),
        DrawnRule(delay: step * 19),
        const SizedBox(height: FjSpace.s + 2),
        Reveal(
          delay: step * 20,
          child: Text(
            '약 ${composed.displayMinutes}분 · ${composed.level.label} · $primary',
            style: t.meta,
            key: const ValueKey('reader-meta'),
          ),
        ),
      ],
    );
  }
}
