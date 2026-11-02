import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/editorial.dart';
import '../../core/design/korean_text.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/journey/journey.dart';

/// A quiet pause after finishing a chapter.
class CompletionScreen extends ConsumerWidget {
  const CompletionScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FjText.of(context);
    final program = ref.watch(programProvider);
    final day = program.day(chapterId);
    final chapter = ref.watch(chapterProvider(chapterId)).value;
    final plan = ref.watch(todayPlanProvider);
    final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
    final nextDay = plan.nextChapterId == null
        ? null
        : program.day(plan.nextChapterId!);
    const step = FjMotion.stagger;

    final season = day?.season;
    final seasonDays = season == null ? const [] : program.daysOf(season);
    final seasonDone = seasonDays
        .where((d) => journey.isCompleted(d.chapterId))
        .length;
    // This reading closed its season: every day of it is now read.
    final closedSeason =
        season != null &&
        seasonDone == seasonDays.length &&
        seasonDays.isNotEmpty;
    final yearDone = plan.status == TodayStatus.allRead && program.isComplete;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ReadingColumn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: FjSpace.xxl),
                      const Reveal(
                        child: FjDualLabel('FINISHED', '이야기를 마쳤습니다'),
                      ),
                      const SizedBox(height: FjSpace.s),
                      if (day != null)
                        DayNumeral(
                          day: day.number,
                          of: program.totalDays,
                          digits: 3,
                          size: 96,
                          delay: step,
                        ),
                      const SizedBox(height: FjSpace.l),
                      InkText(
                        keepAll(
                          day == null
                              ? '이야기를 마쳤습니다.'
                              : '${day.title}\n이야기를 마쳤습니다.',
                        ),
                        key: const ValueKey('completion-title'),
                        style: t.chapterTitle,
                        delay: step * 4,
                      ),
                      if (season != null) ...[
                        const SizedBox(height: FjSpace.xl),
                        SeasonProgress(
                          total: season.dayCount,
                          done: seasonDone,
                          delay: step * 7,
                        ),
                        const SizedBox(height: FjSpace.s),
                        Reveal(
                          delay: step * 8,
                          child: Text(
                            '${season.label} · ${season.title} — '
                            '${season.dayCount}일 중 $seasonDone일',
                            style: t.meta,
                          ),
                        ),
                      ],
                      if (chapter != null) ...[
                        const SizedBox(height: FjSpace.xxl),
                        Reveal(
                          delay: step * 10,
                          child: const FjDualLabel('KEY MESSAGE', '오늘의 핵심'),
                        ),
                        const SizedBox(height: FjSpace.m),
                        PullQuote(
                          text: keepAll(chapter.keyMessage),
                          style: t.keyMessage.copyWith(fontSize: 21),
                          delay: step * 11,
                        ),
                      ],
                      const SizedBox(height: FjSpace.xl),
                      Reveal(
                        delay: step * 16,
                        child: Text(
                          keepAll(
                            yearDone
                                ? '${program.totalDays}일의 이야기를 모두 마쳤습니다. 천천히 돌아보며 마음에 남은 이야기를 다시 펼쳐 보세요.'
                                : closedSeason
                                ? '${season.label} ‘${season.title}’을 모두 읽었습니다. 지나온 이야기를 한번 돌아보고 다음 시즌으로 이어 가도 좋습니다.'
                                : '오늘 읽은 기록은 여정에 남았습니다. 조금 더 읽고 싶다면 다음 이야기로 이어 가도 좋습니다.',
                          ),
                          style: t.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ReadingColumn(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: FjSpace.m,
                  bottom: FjSpace.l,
                ),
                child: Reveal(
                  delay: step * 14,
                  child: Column(
                    children: [
                      if (closedSeason)
                        FjPrimaryButton(
                          key: const ValueKey('completion-season'),
                          label: yearDone ? '1년 돌아보기' : '시즌 돌아보기',
                          onPressed: () =>
                              context.go(Routes.seasonComplete(season.number)),
                        )
                      else
                        FjPrimaryButton(
                          key: const ValueKey('completion-home'),
                          label: '오늘은 여기까지',
                          onPressed: () => context.go(Routes.today),
                        ),
                      if (nextDay != null)
                        FjQuietButton(
                          key: const ValueKey('completion-next'),
                          label: '다음 이야기 읽기 · ${nextDay.label}',
                          onPressed: () {
                            context.go(Routes.today);
                            context.push(Routes.read(nextDay.chapterId));
                          },
                        ),
                      if (closedSeason)
                        FjQuietButton(
                          label: '홈으로',
                          onPressed: () => context.go(Routes.today),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
