import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../core/time/clock.dart';
import '../../data/journey/journey.dart';
import '../../data/content/program.dart';
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

  /// Expanded seasons; starts with the season the reader is in.
  Set<int>? _expanded;

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
    final t = FjText.of(context);
    final program = ref.watch(programProvider);
    final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
    final today = ref.watch(todayProvider);
    final plan = ref.watch(todayPlanProvider);
    final selected =
        _selected ??
        (today.year == _year && today.month == _month ? today : null);

    final current =
        (plan.nextChapterId == null ? null : program.day(plan.nextChapterId!))
            ?.season
            .number ??
        1;
    final expanded = _expanded ?? {current};
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
                const FjScreenTitle(en: 'JOURNEY', title: '여정'),
                const SizedBox(height: FjSpace.m),
                Reveal(
                  delay: FjMotion.stagger * 3,
                  child: Text(
                    count == 0
                        ? '이번 달의 기록이 여기에 차곡차곡 쌓입니다.'
                        : '이번 달에 $days일, $count편의 이야기를 읽었습니다.',
                    style: t.meta,
                    key: const ValueKey('journey-summary'),
                  ),
                ),
                const SizedBox(height: FjSpace.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    KeyedSubtree(
                      key: ValueKey('month-$_year-$_month'),
                      child: MaskRise(
                        child: ExcludeSemantics(
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.2,
                            child: Text(
                              '$_month'.padLeft(2, '0'),
                              style: t.numeral.copyWith(fontSize: 72),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: FjSpace.m),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '$_year년 $_month월',
                          style: t.meta,
                          key: const ValueKey('journey-month'),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('journey-prev-month'),
                      tooltip: '이전 달',
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.west, size: 20),
                    ),
                    IconButton(
                      key: const ValueKey('journey-next-month'),
                      tooltip: '다음 달',
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.east, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: FjSpace.s),
                const Hairline(strong: true),
                const SizedBox(height: FjSpace.m),
                KeyedSubtree(
                  key: ValueKey('calendar-$_year-$_month'),
                  child: Reveal(
                    offset: 10,
                    child: MonthCalendar(
                      year: _year,
                      month: _month,
                      today: today,
                      selected: selected,
                      chapterCountOn: (d) => journey.chaptersOn(d).length,
                      onSelect: (d) => setState(() => _selected = d),
                    ),
                  ),
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
                      if (program.day(id) case final d?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${d.label}  ${d.title}',
                            style: t.ui,
                            key: ValueKey('journey-day-$id'),
                          ),
                        ),
                ],
                const SizedBox(height: FjSpace.xxl),
                const DrawnRule(onScreen: true),
                const SizedBox(height: FjSpace.xl),
                Reveal(
                  onScreen: true,
                  child: FjDualLabel(
                    'ONE YEAR',
                    '1년 ${program.totalDays}일 · ${program.seasons.length}시즌',
                  ),
                ),
                const SizedBox(height: FjSpace.s),
                Text(
                  '${program.totalDays}일 가운데 ${plan.completedCount}일을 읽었습니다.',
                  style: t.meta,
                  key: const ValueKey('journey-year-summary'),
                ),
                const SizedBox(height: FjSpace.m),
                for (final season in program.seasons)
                  _SeasonBlock(
                    season: season,
                    days: program.daysOf(season),
                    journey: journey,
                    plan: plan,
                    expanded: expanded.contains(season.number),
                    onToggle: () => setState(() {
                      _expanded = {...expanded};
                      if (!_expanded!.remove(season.number)) {
                        _expanded!.add(season.number);
                      }
                    }),
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

String _dayStatus(JourneySnapshot journey, TodayPlan plan, ProgramDay d) {
  final first = journey.firstCompletion(d.chapterId);
  if (first != null) {
    return '읽음 · ${DateFormat('M월 d일', 'ko_KR').format(first.localDate.asDateTime)}';
  }
  if (!d.isAvailable) return '준비 중';
  if (plan.nextChapterId == d.chapterId) return '다음에 읽을 이야기';
  return '아직 읽지 않음';
}

/// One season: a header that opens and closes its list of days.
class _SeasonBlock extends StatelessWidget {
  const _SeasonBlock({
    required this.season,
    required this.days,
    required this.journey,
    required this.plan,
    required this.expanded,
    required this.onToggle,
  });

  final ProgramSeason season;
  final List<ProgramDay> days;
  final JourneySnapshot journey;
  final TodayPlan plan;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final done = days.where((d) => journey.isCompleted(d.chapterId)).length;
    final ready = days.where((d) => d.isAvailable).length;
    final status = ready == 0
        ? '준비 중'
        : ready < days.length
        ? '$done / ${days.length} · 일부 준비 중'
        : '$done / ${days.length}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          label: '${season.label} ${season.title}, $status',
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('journey-season-${season.number}'),
            onTap: onToggle,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.rule, width: 0.8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FjLabel(season.label),
                        const SizedBox(height: 2),
                        Text(
                          season.title,
                          style: t.uiStrong.copyWith(
                            color: ready == 0 ? c.textSecondary : c.textPrimary,
                          ),
                        ),
                        Text(status, style: t.meta),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: FjMotion.of(context, FjMotion.medium),
                    child: Text(
                      '→',
                      style: t.latinItalic.copyWith(
                        fontStyle: FontStyle.normal,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          for (final (i, d) in days.indexed)
            Reveal(
              delay: FjMotion.stagger * (i < 8 ? i : 8),
              offset: 10,
              child: _DayRow(day: d, journey: journey, plan: plan),
            ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.journey, required this.plan});

  final ProgramDay day;
  final JourneySnapshot journey;
  final TodayPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final read = journey.isCompleted(day.chapterId);
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Semantics(
              label: day.label,
              excludeSemantics: true,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Text(
                  '${day.number}'.padLeft(3, '0'),
                  style: t.numeral.copyWith(
                    fontSize: 26,
                    letterSpacing: 0,
                    color: read ? c.textPrimary : c.rule,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: t.uiStrong.copyWith(
                    fontWeight: read ? FontWeight.w600 : FontWeight.w400,
                    color: day.isAvailable ? c.textPrimary : c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dayStatus(journey, plan, day),
                  style: t.meta.copyWith(
                    color: read ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (day.isAvailable)
            ExcludeSemantics(
              child: Text(
                '→',
                style: t.latinItalic.copyWith(
                  fontStyle: FontStyle.normal,
                  color: c.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
    if (!day.isAvailable) return row;
    return InkWell(
      key: ValueKey('journey-chapter-${day.chapterId}'),
      onTap: () => context.push(Routes.read(day.chapterId)),
      child: row,
    );
  }
}
