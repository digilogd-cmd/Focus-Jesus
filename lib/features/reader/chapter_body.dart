import 'package:flutter/material.dart';

import '../../core/bible/bible_reference.dart';
import '../../core/design/editorial.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/content/chapter.dart';
import '../../data/content/chapter_composer.dart';
import '../../data/models/reading_preferences.dart';
import '../../core/design/korean_text.dart';

/// Title block at the top of a chapter.
class ChapterHeader extends StatelessWidget {
  const ChapterHeader({super.key, required this.composed});

  final ComposedChapter composed;

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
        const Reveal(child: FjDualLabel('STORY', '오늘의 이야기')),
        const SizedBox(height: FjSpace.s),
        DayNumeral(day: chapter.day, size: 96, delay: step),
        const SizedBox(height: FjSpace.l),
        InkText(
          keepAll(chapter.title),
          key: const ValueKey('reader-title'),
          style: t.chapterTitle,
          delay: step * 4,
        ),
        const SizedBox(height: FjSpace.m),
        Reveal(
          delay: step * 8,
          child: Text(keepAll(chapter.subtitle), style: t.subtitle),
        ),
        const SizedBox(height: FjSpace.l),
        DrawnRule(delay: step * 9),
        const SizedBox(height: FjSpace.s + 2),
        Reveal(
          delay: step * 10,
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

/// One section: heading, blocks, then the level notes that belong to it.
class SectionView extends StatelessWidget {
  const SectionView({
    super.key,
    required this.section,
    required this.onOpenReference,
    this.index,
  });

  final ComposedSection section;

  /// 1-based position, drawn as a roman numeral above the heading.
  final int? index;

  static const List<String> _roman = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', //
    'XI', 'XII', 'XIII', 'XIV', 'XV',
  ];
  final ValueChanged<BibleReference> onOpenReference;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final s = section.section;
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index != null && index! <= _roman.length)
            Reveal(
              onScreen: true,
              child: ExcludeSemantics(
                child: Text(
                  _roman[index! - 1],
                  style: t.latinItalic.copyWith(
                    fontSize: 22,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: FjSpace.xs),
          Semantics(
            header: true,
            child: MaskRise(
              onScreen: true,
              child: Text(keepAll(s.heading), style: t.heading),
            ),
          ),
          const SizedBox(height: FjSpace.m),
          const DrawnRule(length: 32, onScreen: true),
          const SizedBox(height: FjSpace.l),
          for (final block in s.blocks)
            _BlockView(block: block, onOpenReference: onOpenReference),
          for (final note in section.notes) _NoteView(note: note),
        ],
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.onOpenReference});

  final ContentBlock block;
  final ValueChanged<BibleReference> onOpenReference;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    switch (block.type) {
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: FjSpace.paragraphGap),
          child: Reveal(
            onScreen: true,
            offset: 14,
            child: Text(keepAll(block.text), style: t.body),
          ),
        );
      case BlockType.emphasis:
        return Padding(
          padding: const EdgeInsets.only(top: FjSpace.m, bottom: FjSpace.xl),
          child: PullQuote(
            text: keepAll(block.text),
            style: t.emphasis,
            onScreen: true,
          ),
        );
      case BlockType.scripture:
        final ref = block.reference!;
        return Padding(
          padding: const EdgeInsets.only(top: FjSpace.xs, bottom: FjSpace.l),
          child: Reveal(
            onScreen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrawnRule(onScreen: true),
                const SizedBox(height: FjSpace.m),
                FjDualLabel('SCRIPTURE', '함께 읽을 본문 · ${ref.label}'),
                const SizedBox(height: FjSpace.s),
                Text(keepAll(block.text), style: t.note),
                FjQuietButton(
                  label: '본문 열기',
                  alignment: Alignment.centerLeft,
                  trailingArrow: true,
                  onPressed: () => onOpenReference(ref),
                ),
                const Hairline(),
              ],
            ),
          ),
        );
    }
  }
}

class _NoteView extends StatelessWidget {
  const _NoteView({required this.note});

  final ComposedNote note;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.xs, bottom: FjSpace.l),
      child: Reveal(
        onScreen: true,
        child: Container(
          padding: const EdgeInsets.only(left: FjSpace.m),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.rule, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.layer.noteLabel, style: t.noteLabel),
              const SizedBox(height: 6),
              Text(keepAll(note.text), style: t.note),
            ],
          ),
        ),
      ),
    );
  }
}

/// "오늘의 핵심" — the one sentence to carry out of the chapter.
class KeyMessageView extends StatelessWidget {
  const KeyMessageView({super.key, required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawnRule(onScreen: true, color: c.textPrimary),
          const SizedBox(height: 3),
          const DrawnRule(onScreen: true, delay: Duration(milliseconds: 120)),
          const SizedBox(height: FjSpace.xl),
          const Reveal(
            onScreen: true,
            child: FjDualLabel('KEY MESSAGE', '오늘의 핵심'),
          ),
          const SizedBox(height: FjSpace.l),
          InkText(
            keepAll(chapter.keyMessage),
            key: const ValueKey('reader-key-message'),
            style: t.keyMessage,
            onScreen: true,
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// List of passages with links to an external Bible reader.
class ScriptureLinksView extends StatelessWidget {
  const ScriptureLinksView({
    super.key,
    required this.chapter,
    required this.onOpen,
  });

  final Chapter chapter;
  final ValueChanged<BibleReference> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(
            onScreen: true,
            child: FjDualLabel('READ THE BIBLE', '성경 본문 읽기'),
          ),
          const SizedBox(height: FjSpace.s),
          Reveal(
            onScreen: true,
            child: Text(
              '이야기의 바탕이 된 본문입니다. 대한성서공회 개역개정 본문으로 연결되며 인터넷 연결이 필요합니다.',
              style: t.meta,
            ),
          ),
          const SizedBox(height: FjSpace.s),
          for (final (i, r) in chapter.references.indexed)
            Reveal(
              onScreen: true,
              delay: FjMotion.stagger * i,
              child: InkWell(
                key: ValueKey('scripture-link-${r.reference.source}'),
                onTap: () => onOpen(r.reference),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.divider, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.reference.label,
                          style: (r.primary ? t.uiStrong : t.ui).copyWith(
                            fontSize: 16.5,
                          ),
                        ),
                      ),
                      Text(
                        '읽기 ↗',
                        style: t.meta.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Honest note about the editorial state of the manuscript.
class ManuscriptStatusView extends StatelessWidget {
  const ManuscriptStatusView({super.key, required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    final pending = chapter.reviewStatus != ReviewStatus.approved;
    return Text(
      pending
          ? '원고 상태 · ${chapter.reviewStatus.label} (v${chapter.contentVersion}). '
                '이 해설은 신학 검수자의 최종 검토를 기다리는 원고입니다.'
          : '원고 상태 · ${chapter.reviewStatus.label} (v${chapter.contentVersion})',
      style: t.meta,
    );
  }
}

String readingSettingsLabel(ReadingMinutes minutes, ReadingLevel level) =>
    '${minutes.label} · ${level.label}';
