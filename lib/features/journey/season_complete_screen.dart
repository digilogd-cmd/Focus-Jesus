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
import '../../data/content/program.dart';
import '../../data/journey/journey.dart';

/// A calm look back over one season (or, after the last one, the year):
/// not a trophy.
class SeasonCompleteScreen extends ConsumerWidget {
  const SeasonCompleteScreen({super.key, required this.seasonNumber});

  final int seasonNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FjText.of(context);
    final program = ref.watch(programProvider);
    final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
    final season =
        program.seasonByNumber(seasonNumber) ?? program.seasons.first;
    final days = program.daysOf(season);
    final read = days.where((d) => journey.isCompleted(d.chapterId)).length;
    final yearDone =
        program.isComplete &&
        program.days.every((d) => journey.isCompleted(d.chapterId));
    final nextSeason = program.seasonByNumber(season.number + 1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ReadingColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: FjSpace.xxl),
                const Wordmark(size: 17, animate: true),
                const SizedBox(height: FjSpace.m),
                const DrawnRule(),
                const SizedBox(height: FjSpace.xxl),
                Reveal(child: FjDualLabel(season.label, season.title)),
                const SizedBox(height: FjSpace.s),
                DayNumeral(
                  day: read,
                  of: season.dayCount,
                  delay: FjMotion.stagger * 2,
                ),
                const SizedBox(height: FjSpace.l),
                InkText(
                  yearDone ? '1년의 여정을 마쳤습니다' : '${season.title}을 걸어왔습니다',
                  key: const ValueKey('season-complete-title'),
                  style: t.displayTitle,
                  delay: FjMotion.stagger * 5,
                ),
                const SizedBox(height: FjSpace.l),
                Reveal(
                  delay: FjMotion.stagger * 8,
                  child: Text(
                    keepAll(
                      yearDone
                          ? '창조에서 새 창조까지, 하나님이 사람을 포기하지 않으시고 그리스도 안에서 약속을 이루어 가시는 '
                                '이야기를 일 년 동안 따라왔습니다. 지난 이야기는 언제든 다시 펼쳐 볼 수 있습니다.'
                          : '${season.scope}. 이 시즌에서 만난 이야기들을 한 줄씩 돌아봅니다.',
                    ),
                    style: t.body,
                  ),
                ),
                const SizedBox(height: FjSpace.xl),
                const DrawnRule(onScreen: true),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('LOOKING BACK', '지나온 이야기'),
                const SizedBox(height: FjSpace.m),
                for (final (i, d) in days.indexed)
                  if (d.isAvailable)
                    Reveal(
                      onScreen: true,
                      delay: FjMotion.stagger * (i % 6),
                      child: _LookBackRow(day: d),
                    ),
                const SizedBox(height: FjSpace.l),
                Text(
                  nextSeason == null
                      ? '지난 이야기를 다른 읽기 시간이나 이해 수준으로 다시 읽어 보셔도 좋습니다.'
                      : program.isSeasonAvailable(nextSeason)
                      ? '다음은 ${nextSeason.label} ‘${nextSeason.title}’입니다.'
                      : '다음 ${nextSeason.label} ‘${nextSeason.title}’은 정성껏 준비하고 있습니다. '
                            '그동안 지난 이야기를 다른 읽기 시간이나 이해 수준으로 다시 읽어 보셔도 좋습니다.',
                  style: t.meta,
                ),
                const SizedBox(height: FjSpace.xl),
                FjPrimaryButton(
                  label: '홈으로',
                  onPressed: () => context.go(Routes.today),
                ),
                const SizedBox(height: FjSpace.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LookBackRow extends ConsumerWidget {
  const _LookBackRow({required this.day});

  final ProgramDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FjText.of(context);
    final chapter = ref.watch(chapterProvider(day.chapterId)).value;
    return Padding(
      padding: const EdgeInsets.only(bottom: FjSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${day.label}  ${day.title}', style: t.uiStrong),
          if (chapter != null) ...[
            const SizedBox(height: 2),
            Text(keepAll(chapter.keyMessage), style: t.meta),
          ],
        ],
      ),
    );
  }
}
