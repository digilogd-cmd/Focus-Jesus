import 'package:flutter/material.dart';

import '../../core/bible/bible_reference.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FjLabel(chapter.dayLabel),
        const SizedBox(height: FjSpace.m),
        Text(
          keepAll(chapter.title),
          style: t.chapterTitle,
          key: const ValueKey('reader-title'),
        ),
        const SizedBox(height: FjSpace.m),
        Text(keepAll(chapter.subtitle), style: t.subtitle),
        const SizedBox(height: FjSpace.l),
        Text(
          '약 ${composed.displayMinutes}분 · ${composed.level.label} · $primary',
          style: t.meta,
          key: const ValueKey('reader-meta'),
        ),
        const SizedBox(height: FjSpace.xl),
        const Hairline(width: 40),
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
  });

  final ComposedSection section;
  final ValueChanged<BibleReference> onOpenReference;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    final s = section.section;
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(keepAll(s.heading), style: t.heading),
          ),
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
    final c = FjColors.of(context);
    final t = FjText.of(context);
    switch (block.type) {
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: FjSpace.paragraphGap),
          child: Text(keepAll(block.text), style: t.body),
        );
      case BlockType.emphasis:
        return Padding(
          padding: const EdgeInsets.only(top: FjSpace.s, bottom: FjSpace.l + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 24, height: 1.5, color: c.accent),
              const SizedBox(height: FjSpace.m),
              Text(keepAll(block.text), style: t.emphasis),
            ],
          ),
        );
      case BlockType.scripture:
        final ref = block.reference!;
        return Padding(
          padding: const EdgeInsets.only(top: FjSpace.xs, bottom: FjSpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FjLabel('함께 읽을 본문 · ${ref.label}', color: c.accent),
              const SizedBox(height: FjSpace.s),
              Text(
                keepAll(block.text),
                style: t.note.copyWith(
                  color: c.textPrimary.withValues(alpha: 0.82),
                ),
              ),
              FjQuietButton(
                label: '본문 열기',
                alignment: Alignment.centerLeft,
                trailingArrow: true,
                onPressed: () => onOpenReference(ref),
              ),
            ],
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
      child: Container(
        padding: const EdgeInsets.only(left: FjSpace.m),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.divider, width: 2)),
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
    );
  }
}

/// "오늘의 핵심" — the one sentence to carry out of the chapter.
class KeyMessageView extends StatelessWidget {
  const KeyMessageView({super.key, required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Hairline(),
          const SizedBox(height: FjSpace.xl),
          const FjLabel('오늘의 핵심'),
          const SizedBox(height: FjSpace.m),
          Text(
            keepAll(chapter.keyMessage),
            style: t.keyMessage,
            key: const ValueKey('reader-key-message'),
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
          const FjLabel('성경 본문 읽기'),
          const SizedBox(height: FjSpace.s),
          Text(
            '이야기의 바탕이 된 본문입니다. 대한성서공회 개역개정 본문으로 연결되며 인터넷 연결이 필요합니다.',
            style: t.meta,
          ),
          const SizedBox(height: FjSpace.s),
          for (final r in chapter.references)
            InkWell(
              key: ValueKey('scripture-link-${r.reference.source}'),
              onTap: () => onOpen(r.reference),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.divider)),
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
                    Text('읽기 ↗', style: t.meta.copyWith(color: c.accent)),
                  ],
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
