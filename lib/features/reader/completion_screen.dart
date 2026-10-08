import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/journey/journey.dart';
import '../../core/design/korean_text.dart';

/// A quiet pause after finishing a chapter.
class CompletionScreen extends ConsumerWidget {
  const CompletionScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FjText.of(context);
    final season = ref.watch(seasonProvider);
    final chapter = season.chapterById(chapterId);
    final plan = ref.watch(todayPlanProvider);
    final next = plan.nextChapterId == null
        ? null
        : season.chapterById(plan.nextChapterId!);
    final seasonDone = plan.status == TodayStatus.seasonComplete;

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
                      if (chapter != null) FjLabel(chapter.dayLabel),
                      const SizedBox(height: FjSpace.m),
                      Text(
                        keepAll(
                          chapter == null
                              ? '이야기를 마쳤습니다.'
                              : '${chapter.title}\n이야기를 마쳤습니다.',
                        ),
                        style: t.chapterTitle,
                        key: const ValueKey('completion-title'),
                      ),
                      if (chapter != null) ...[
                        const SizedBox(height: FjSpace.xl),
                        const Hairline(width: 40),
                        const SizedBox(height: FjSpace.xl),
                        const FjLabel('오늘의 핵심'),
                        const SizedBox(height: FjSpace.m),
                        Text(keepAll(chapter.keyMessage), style: t.keyMessage),
                      ],
                      const SizedBox(height: FjSpace.xl),
                      Text(
                        keepAll(
                          seasonDone
                              ? '일곱 날의 이야기를 모두 마쳤습니다. 천천히 돌아보며 마음에 남은 이야기를 다시 펼쳐 보세요.'
                              : '오늘 읽은 기록은 여정에 남았습니다. 조금 더 읽고 싶다면 다음 이야기로 이어 가도 좋습니다.',
                        ),
                        style: t.subtitle,
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
                child: Column(
                  children: [
                    if (seasonDone)
                      FjPrimaryButton(
                        key: const ValueKey('completion-season'),
                        label: '첫 여정 돌아보기',
                        onPressed: () => context.go(Routes.seasonComplete),
                      )
                    else
                      FjPrimaryButton(
                        key: const ValueKey('completion-home'),
                        label: '오늘은 여기까지',
                        onPressed: () => context.go(Routes.today),
                      ),
                    if (next != null)
                      FjQuietButton(
                        key: const ValueKey('completion-next'),
                        label: '다음 이야기 읽기 · ${next.dayLabel}',
                        onPressed: () {
                          context.go(Routes.today);
                          context.push(Routes.read(next.id));
                        },
                      ),
                    if (seasonDone)
                      FjQuietButton(
                        label: '홈으로',
                        onPressed: () => context.go(Routes.today),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
