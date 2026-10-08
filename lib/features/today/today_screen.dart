import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/content/chapter.dart';
import '../../data/content/chapter_composer.dart';
import '../../data/journey/journey.dart';
import '../../core/design/korean_text.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final season = ref.watch(seasonProvider);
    final plan = ref.watch(todayPlanProvider);
    final settings = ref.watch(settingsProvider);
    final now = ref.watch(clockProvider).now();
    ref.watch(dayTickProvider);

    final next = plan.nextChapterId == null
        ? null
        : season.chapterById(plan.nextChapterId!);
    final position = next == null
        ? null
        : ref.watch(readingPositionProvider(next.id)).value;
    final resuming = position != null && position.isMeaningful;

    final dateLabel = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);

    final List<Widget> body;
    switch (plan.status) {
      case TodayStatus.ready:
        body = [
          FjLabel('오늘의 이야기 · ${next!.dayLabel}'),
          const SizedBox(height: FjSpace.m),
          _ChapterHeadline(chapter: next),
          const SizedBox(height: FjSpace.l),
          Text(
            _readingMeta(next, settings, resuming),
            style: t.meta,
            key: const ValueKey('today-meta'),
          ),
          const SizedBox(height: FjSpace.xl),
          FjPrimaryButton(
            key: const ValueKey('today-read'),
            label: resuming ? '이어서 읽기' : '오늘의 이야기 읽기',
            onPressed: () => context.push(Routes.read(next.id)),
          ),
        ];
      case TodayStatus.doneToday:
        final finished = [
          for (final id in plan.finishedToday) ?season.chapterById(id),
        ];
        body = [
          const FjLabel('오늘의 이야기'),
          const SizedBox(height: FjSpace.m),
          Text(
            '오늘의 이야기를 마쳤습니다.',
            style: t.displayTitle,
            key: const ValueKey('today-done'),
          ),
          const SizedBox(height: FjSpace.m),
          for (final ch in finished)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                keepAll('${ch.dayLabel}  ${ch.title}'),
                style: t.subtitle,
              ),
            ),
          if (finished.isNotEmpty) ...[
            const SizedBox(height: FjSpace.l),
            Text(
              keepAll('“${finished.last.keyMessage}”'),
              style: t.body.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: FjSpace.xl),
          const Hairline(),
          const SizedBox(height: FjSpace.l),
          FjLabel('조금 더 읽고 싶다면 · ${next!.dayLabel}'),
          const SizedBox(height: FjSpace.s),
          Text(keepAll(next.title), style: t.heading),
          const SizedBox(height: FjSpace.xs),
          Text(_readingMeta(next, settings, resuming), style: t.meta),
          FjQuietButton(
            key: const ValueKey('today-read-more'),
            label: resuming ? '이어서 읽기' : '다음 이야기 읽기',
            alignment: Alignment.centerLeft,
            trailingArrow: true,
            onPressed: () => context.push(Routes.read(next.id)),
          ),
        ];
      case TodayStatus.seasonComplete:
        body = [
          const FjLabel('첫 번째 여정'),
          const SizedBox(height: FjSpace.m),
          Text(
            '일곱 날의 이야기를 모두 읽었습니다.',
            style: t.displayTitle,
            key: const ValueKey('today-season-complete'),
          ),
          const SizedBox(height: FjSpace.m),
          Text(
            '창조에서 아브라함의 부르심까지, 하나님이 사람을 포기하지 않으신 이야기를 따라왔습니다. '
            '지난 이야기는 언제든 여정에서 다시 펼쳐 볼 수 있습니다.',
            style: t.body,
          ),
          const SizedBox(height: FjSpace.xl),
          FjPrimaryButton(
            label: '여정 돌아보기',
            onPressed: () => context.push(Routes.seasonComplete),
          ),
        ];
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ReadingColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: FjSpace.l),
                const Wordmark(size: 15),
                const SizedBox(height: FjSpace.xxl),
                Text(
                  dateLabel,
                  style: t.meta,
                  key: const ValueKey('today-date'),
                ),
                const SizedBox(height: FjSpace.xl),
                ...body,
                const SizedBox(height: FjSpace.xxl),
                Text(
                  _progressLine(plan),
                  style: t.meta,
                  key: const ValueKey('today-progress'),
                ),
                const SizedBox(height: FjSpace.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _readingMeta(Chapter chapter, dynamic settings, bool resuming) {
    final composed = composeChapter(
      chapter,
      minutes: settings.minutes,
      level: settings.level,
    );
    final primary = chapter.references
        .firstWhere((r) => r.primary)
        .reference
        .label;
    final parts = ['약 ${composed.displayMinutes}분', primary];
    if (resuming) parts.add('읽던 곳부터');
    return parts.join(' · ');
  }

  static String _progressLine(TodayPlan plan) {
    if (plan.completedCount == 0) {
      return '${plan.totalCount}개의 이야기가 준비되어 있습니다.';
    }
    return '${plan.totalCount}개의 이야기 중 ${plan.completedCount}개를 읽었습니다.';
  }
}

class _ChapterHeadline extends StatelessWidget {
  const _ChapterHeadline({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          keepAll(chapter.title),
          style: t.displayTitle,
          key: const ValueKey('today-title'),
        ),
        const SizedBox(height: FjSpace.m),
        Text(keepAll(chapter.summary), style: t.subtitle),
      ],
    );
  }
}
