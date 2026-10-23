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
import '../../data/content/program.dart';
import '../../data/journey/journey.dart';
import '../../core/design/korean_text.dart';
import '../settings/reminder_access.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final program = ref.watch(programProvider);
    final plan = ref.watch(todayPlanProvider);
    final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
    final settings = ref.watch(settingsProvider);
    final now = ref.watch(clockProvider).now();
    ref.watch(dayTickProvider);

    final nextDay = plan.nextChapterId == null
        ? null
        : program.day(plan.nextChapterId!);
    final next = nextDay == null
        ? null
        : ref.watch(chapterProvider(nextDay.chapterId)).value;
    final position = nextDay == null
        ? null
        : ref.watch(readingPositionProvider(nextDay.chapterId)).value;
    final resuming = position != null && position.isMeaningful;

    // The season the reader is in: where the next story is, or the last one.
    final lastReadDay = [
      for (final d in program.days)
        if (journey.isCompleted(d.chapterId)) d,
    ].lastOrNull;
    final season = (nextDay ?? lastReadDay ?? program.days.first).season;
    final seasonDays = program.daysOf(season);
    final seasonDone = seasonDays
        .where((d) => journey.isCompleted(d.chapterId))
        .length;

    final dateLabel = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);

    const step = FjMotion.stagger;
    final List<Widget> body;
    switch (plan.status) {
      case TodayStatus.ready:
        body = [
          const Reveal(child: FjDualLabel('TODAY', '오늘의 이야기')),
          const SizedBox(height: FjSpace.m),
          DayNumeral(
            day: nextDay!.number,
            of: program.totalDays,
            digits: 3,
            delay: step * 2,
          ),
          const SizedBox(height: FjSpace.s),
          Reveal(
            delay: step * 4,
            child: Text(
              '${season.label} · ${season.title}',
              style: t.label.copyWith(letterSpacing: 1.2),
              key: const ValueKey('today-season'),
            ),
          ),
          const SizedBox(height: FjSpace.l),
          if (next == null)
            // Parsed before the first frame in practice; a brief gap at most.
            const SizedBox(height: 160)
          else ...[
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
          ],
          const SizedBox(height: FjSpace.xl),
          Reveal(
            delay: step * 12,
            child: FjPrimaryButton(
              key: const ValueKey('today-read'),
              label: resuming ? '이어서 읽기' : '오늘의 이야기 읽기',
              onPressed: () => context.push(Routes.read(nextDay.chapterId)),
            ),
          ),
        ];
      case TodayStatus.doneToday:
        final finished = [
          for (final id in plan.finishedToday) ?program.day(id),
        ];
        final lastFinished = finished.isEmpty
            ? null
            : ref.watch(chapterProvider(finished.last.chapterId)).value;
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
          for (final d in finished)
            Reveal(
              delay: step * 5,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  keepAll('${d.label}  ${d.title}'),
                  style: t.subtitle,
                ),
              ),
            ),
          if (lastFinished != null) ...[
            const SizedBox(height: FjSpace.l),
            PullQuote(
              text: keepAll(lastFinished.keyMessage),
              style: t.body.copyWith(color: c.inkSoft),
              delay: step * 6,
            ),
          ],
          const SizedBox(height: FjSpace.xxl),
          DrawnRule(delay: step * 8),
          const SizedBox(height: FjSpace.l),
          Reveal(
            delay: step * 9,
            child: FjDualLabel('NEXT', '조금 더 읽고 싶다면 · ${nextDay!.label}'),
          ),
          const SizedBox(height: FjSpace.s),
          Reveal(
            delay: step * 10,
            child: Text(keepAll(nextDay.title), style: t.heading),
          ),
          if (next != null) ...[
            const SizedBox(height: FjSpace.xs),
            Reveal(
              delay: step * 10,
              child: Text(
                _readingMeta(next, settings, resuming),
                style: t.meta,
              ),
            ),
          ],
          Reveal(
            delay: step * 11,
            child: FjQuietButton(
              key: const ValueKey('today-read-more'),
              label: resuming ? '이어서 읽기' : '다음 이야기 읽기',
              alignment: Alignment.centerLeft,
              trailingArrow: true,
              onPressed: () => context.push(Routes.read(nextDay.chapterId)),
            ),
          ),
        ];
      case TodayStatus.allRead:
        final yearDone = program.isComplete;
        final upcoming = program.days
            .where((d) => !d.isAvailable)
            .firstOrNull
            ?.season;
        body = [
          Reveal(
            child: FjDualLabel(
              yearDone ? 'ONE YEAR' : 'ALL CAUGHT UP',
              yearDone ? '1년의 여정' : '준비된 이야기',
            ),
          ),
          const SizedBox(height: FjSpace.m),
          InkText(
            yearDone
                ? '${program.totalDays}일의 이야기를 모두 읽었습니다.'
                : '준비된 ${plan.totalCount}일의 이야기를 모두 읽었습니다.',
            key: const ValueKey('today-season-complete'),
            style: t.displayTitle,
            delay: step * 2,
          ),
          const SizedBox(height: FjSpace.m),
          Reveal(
            delay: step * 6,
            child: Text(
              keepAll(
                yearDone
                    ? '창조에서 새 창조까지, 하나님이 사람을 포기하지 않으시고 그리스도 안에서 약속을 이루어 가시는 '
                          '이야기를 일 년 동안 따라왔습니다. 지난 이야기는 언제든 여정에서 다시 펼쳐 볼 수 있습니다.'
                    : '${upcoming == null ? '다음 이야기는' : '${upcoming.label} ‘${upcoming.title}’은'} 정성껏 준비하고 있습니다. '
                          '그동안 지난 이야기를 다른 읽기 시간이나 이해 수준으로 다시 읽어 보셔도 좋습니다.',
              ),
              style: t.body,
            ),
          ),
          const SizedBox(height: FjSpace.xl),
          Reveal(
            delay: step * 8,
            child: FjPrimaryButton(
              label: yearDone ? '1년 돌아보기' : '시즌 돌아보기',
              onPressed: () => context.push(
                Routes.seasonComplete(
                  (lastReadDay ?? program.days.last).season.number,
                ),
              ),
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
                const ReminderNotice(padding: EdgeInsets.only(top: FjSpace.xl)),
                const SizedBox(height: FjSpace.xxl),
                SeasonProgress(
                  total: season.dayCount,
                  done: seasonDone,
                  delay: step * 12,
                ),
                const SizedBox(height: FjSpace.s),
                Reveal(
                  delay: step * 13,
                  child: Text(
                    _progressLine(plan, program, season, seasonDone),
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

  static String _progressLine(
    TodayPlan plan,
    Program program,
    ProgramSeason season,
    int seasonDone,
  ) {
    if (plan.completedCount == 0) {
      return '1년 ${program.totalDays}일 가운데 ${plan.totalCount}일의 이야기가 준비되어 있습니다.';
    }
    return '${season.label} ${season.dayCount}일 중 $seasonDone일 · '
        '1년 ${program.totalDays}일 중 ${plan.completedCount}일을 읽었습니다.';
  }
}
