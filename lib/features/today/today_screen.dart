import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/editorial.dart';
import '../../core/design/motion.dart';
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

    const step = FjMotion.stagger;
    final List<Widget> body;
    switch (plan.status) {
      case TodayStatus.ready:
        body = [
          const Reveal(child: FjDualLabel('TODAY', '오늘의 이야기')),
          const SizedBox(height: FjSpace.m),
          DayNumeral(day: next!.day, of: plan.totalCount, delay: step * 2),
          const SizedBox(height: FjSpace.l),
          InkText(
            keepAll(next.title),
            key: const ValueKey('today-title'),
            style: t.displayTitle,
            delay: step * 5,
          ),
          const SizedBox(height: FjSpace.m),
          Reveal(
            delay: step * 9,
            child: Text(keepAll(next.summary), style: t.subtitle),
          ),
          const SizedBox(height: FjSpace.l),
          DrawnRule(delay: step * 10),
          const SizedBox(height: FjSpace.m),
          Reveal(
            delay: step * 11,
            child: Text(
              _readingMeta(next, settings, resuming),
              style: t.meta,
              key: const ValueKey('today-meta'),
            ),
          ),
          const SizedBox(height: FjSpace.xl),
          Reveal(
            delay: step * 12,
            child: FjPrimaryButton(
              key: const ValueKey('today-read'),
              label: resuming ? '이어서 읽기' : '오늘의 이야기 읽기',
              onPressed: () => context.push(Routes.read(next.id)),
            ),
          ),
        ];
      case TodayStatus.doneToday:
        final finished = [
          for (final id in plan.finishedToday) ?season.chapterById(id),
        ];
        body = [
          const Reveal(child: FjDualLabel('TODAY', '오늘의 이야기')),
          const SizedBox(height: FjSpace.m),
          InkText(
            '오늘의 이야기를 마쳤습니다.',
            key: const ValueKey('today-done'),
            style: t.displayTitle,
            delay: step * 2,
          ),
          const SizedBox(height: FjSpace.m),
          for (final ch in finished)
            Reveal(
              delay: step * 5,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  keepAll('${ch.dayLabel}  ${ch.title}'),
                  style: t.subtitle,
                ),
              ),
            ),
          if (finished.isNotEmpty) ...[
            const SizedBox(height: FjSpace.l),
            PullQuote(
              text: keepAll(finished.last.keyMessage),
              style: t.body.copyWith(color: c.inkSoft),
              delay: step * 6,
            ),
          ],
          const SizedBox(height: FjSpace.xxl),
          DrawnRule(delay: step * 8),
          const SizedBox(height: FjSpace.l),
          Reveal(
            delay: step * 9,
            child: FjDualLabel('NEXT', '조금 더 읽고 싶다면 · ${next!.dayLabel}'),
          ),
          const SizedBox(height: FjSpace.s),
          Reveal(
            delay: step * 10,
            child: Text(keepAll(next.title), style: t.heading),
          ),
          const SizedBox(height: FjSpace.xs),
          Reveal(
            delay: step * 10,
            child: Text(_readingMeta(next, settings, resuming), style: t.meta),
          ),
          Reveal(
            delay: step * 11,
            child: FjQuietButton(
              key: const ValueKey('today-read-more'),
              label: resuming ? '이어서 읽기' : '다음 이야기 읽기',
              alignment: Alignment.centerLeft,
              trailingArrow: true,
              onPressed: () => context.push(Routes.read(next.id)),
            ),
          ),
        ];
      case TodayStatus.seasonComplete:
        body = [
          const Reveal(child: FjDualLabel('SEASON ONE', '첫 번째 여정')),
          const SizedBox(height: FjSpace.m),
          InkText(
            '일곱 날의 이야기를 모두 읽었습니다.',
            key: const ValueKey('today-season-complete'),
            style: t.displayTitle,
            delay: step * 2,
          ),
          const SizedBox(height: FjSpace.m),
          Reveal(
            delay: step * 6,
            child: Text(
              keepAll(
                '창조에서 아브라함의 부르심까지, 하나님이 사람을 포기하지 않으신 이야기를 따라왔습니다. '
                '지난 이야기는 언제든 여정에서 다시 펼쳐 볼 수 있습니다.',
              ),
              style: t.body,
            ),
          ),
          const SizedBox(height: FjSpace.xl),
          Reveal(
            delay: step * 8,
            child: FjPrimaryButton(
              label: '여정 돌아보기',
              onPressed: () => context.push(Routes.seasonComplete),
            ),
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
                const Wordmark(size: 17, animate: true),
                const SizedBox(height: FjSpace.m),
                DrawnRule(color: c.textPrimary, thickness: 1),
                const SizedBox(height: 3),
                const DrawnRule(delay: Duration(milliseconds: 120)),
                const SizedBox(height: FjSpace.s),
                Reveal(
                  delay: step,
                  child: Text(
                    dateLabel,
                    style: t.meta,
                    key: const ValueKey('today-date'),
                  ),
                ),
                const SizedBox(height: FjSpace.xl),
                ...body,
                const SizedBox(height: FjSpace.xxl),
                SeasonProgress(
                  total: plan.totalCount,
                  done: plan.completedCount,
                  delay: step * 12,
                ),
                const SizedBox(height: FjSpace.s),
                Reveal(
                  delay: step * 13,
                  child: Text(
                    _progressLine(plan),
                    style: t.meta,
                    key: const ValueKey('today-progress'),
                  ),
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
