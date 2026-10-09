import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/editorial.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../core/design/korean_text.dart';

/// Shown after the seven-day pilot: a calm look back, not a trophy.
class SeasonCompleteScreen extends ConsumerWidget {
  const SeasonCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FjText.of(context);
    final season = ref.watch(seasonProvider);
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
                const Reveal(child: FjDualLabel('SEASON ONE', '첫 번째 여정')),
                const SizedBox(height: FjSpace.s),
                DayNumeral(
                  day: season.chapters.length,
                  of: season.chapters.length,
                  delay: FjMotion.stagger * 2,
                ),
                const SizedBox(height: FjSpace.l),
                InkText(
                  '첫 번째 여정을 마쳤습니다',
                  key: const ValueKey('season-complete-title'),
                  style: t.displayTitle,
                  delay: FjMotion.stagger * 5,
                ),
                const SizedBox(height: FjSpace.l),
                Text(
                  keepAll(
                    '하나님은 세상을 좋게 지으셨고, 사람이 그분을 떠났을 때도 포기하지 않으셨습니다. '
                    '심판 속에서도 옷을 지어 입히셨고, 홍수 뒤에 약속을 주셨으며, 흩어진 민족들 가운데서 '
                    '한 사람 아브라함을 불러 모든 민족을 향한 복을 시작하셨습니다.',
                  ),
                  style: t.body,
                ),
                const SizedBox(height: FjSpace.m),
                Text(
                  keepAll(
                    '그 약속은 예수 그리스도 안에서 이루어집니다. 다음 여정에서는 그 약속이 어떻게 이어지는지 함께 따라가려 합니다.',
                  ),
                  style: t.body,
                ),
                const SizedBox(height: FjSpace.xl),
                const DrawnRule(onScreen: true),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('LOOKING BACK', '지나온 이야기'),
                const SizedBox(height: FjSpace.m),
                for (final (i, ch) in season.chapters.indexed)
                  Reveal(
                    onScreen: true,
                    delay: FjMotion.stagger * i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: FjSpace.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ch.dayLabel}  ${ch.title}',
                            style: t.uiStrong,
                          ),
                          const SizedBox(height: 2),
                          Text(keepAll(ch.keyMessage), style: t.meta),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: FjSpace.l),
                Text(
                  '30일 과정의 나머지 ${season.plannedDayCount}일은 준비 중입니다. 그동안 지난 이야기를 다른 읽기 시간이나 '
                  '이해 수준으로 다시 읽어 보셔도 좋습니다.',
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
