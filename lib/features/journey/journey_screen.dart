import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../core/time/clock.dart';
import '../../data/journey/journey.dart';
import 'month_calendar.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  late int _year;
  late int _month;
  LocalDate? _selected;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _year = today.year;
    _month = today.month;
  }

  void _shiftMonth(int delta) {
    final d = DateTime(_year, _month + delta);
    setState(() {
      _year = d.year;
      _month = d.month;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final season = ref.watch(seasonProvider);
    final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
    final today = ref.watch(todayProvider);
    final plan = ref.watch(todayPlanProvider);
    final selected =
        _selected ??
        (today.year == _year && today.month == _month ? today : null);

    final days = journey.readingDaysIn(_year, _month).length;
    final count = journey.chapterCountIn(_year, _month);
    final selectedChapters = selected == null
        ? const <String>[]
        : journey.chaptersOn(selected);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ReadingColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: FjSpace.xl),
                Text('여정', style: t.displayTitle),
                const SizedBox(height: FjSpace.s),
                Text(
                  count == 0
                      ? '이번 달의 기록이 여기에 차곡차곡 쌓입니다.'
                      : '이번 달에 $days일, $count편의 이야기를 읽었습니다.',
                  style: t.meta,
                  key: const ValueKey('journey-summary'),
                ),
                const SizedBox(height: FjSpace.xl),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('journey-prev-month'),
                      tooltip: '이전 달',
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_year년 $_month월',
                          style: t.uiStrong,
                          key: const ValueKey('journey-month'),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('journey-next-month'),
                      tooltip: '다음 달',
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: FjSpace.s),
                MonthCalendar(
                  year: _year,
                  month: _month,
                  today: today,
                  selected: selected,
                  chapterCountOn: (d) => journey.chaptersOn(d).length,
                  onSelect: (d) => setState(() => _selected = d),
                ),
                if (selected != null) ...[
                  const SizedBox(height: FjSpace.l),
                  FjLabel(
                    DateFormat(
                      'M월 d일 EEEE',
                      'ko_KR',
                    ).format(selected.asDateTime),
                  ),
                  const SizedBox(height: FjSpace.s),
                  if (selectedChapters.isEmpty)
                    Text('이날은 기록이 없습니다.', style: t.meta)
                  else
                    for (final id in selectedChapters)
                      if (season.chapterById(id) case final ch?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${ch.dayLabel}  ${ch.title}',
                            style: t.ui,
                            key: ValueKey('journey-day-$id'),
                          ),
                        ),
                ],
                const SizedBox(height: FjSpace.xxl),
                const Hairline(),
                const SizedBox(height: FjSpace.xl),
                const FjLabel('첫 번째 여정 · 일곱 날의 이야기'),
                const SizedBox(height: FjSpace.s),
                for (final ch in season.chapters)
                  InkWell(
                    key: ValueKey('journey-chapter-${ch.id}'),
                    onTap: () => context.push(Routes.read(ch.id)),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.divider)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(ch.dayLabel, style: t.label),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ch.title, style: t.ui),
                                const SizedBox(height: 2),
                                Text(
                                  _chapterStatus(journey, plan, ch.id),
                                  style: t.meta.copyWith(
                                    color: journey.isCompleted(ch.id)
                                        ? c.accent
                                        : c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: FjSpace.l),
                Text(
                  '30일 과정 가운데 나머지 ${season.plannedDayCount}일의 이야기는 정성껏 준비하고 있습니다.',
                  style: t.meta,
                ),
                const SizedBox(height: FjSpace.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _chapterStatus(JourneySnapshot journey, TodayPlan plan, String id) {
    final first = journey.firstCompletion(id);
    if (first != null) {
      return '읽음 · ${DateFormat('M월 d일', 'ko_KR').format(first.localDate.asDateTime)}';
    }
    if (plan.nextChapterId == id) return '다음에 읽을 이야기';
    return '아직 읽지 않음';
  }
}
