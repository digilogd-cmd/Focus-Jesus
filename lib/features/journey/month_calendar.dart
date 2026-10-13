import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/time/clock.dart';

/// A traditional Sunday-first month grid. Days with finished chapters carry
/// small dots (one per chapter, up to three). Empty days are simply empty —
/// never marked as missed.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.today,
    required this.selected,
    required this.chapterCountOn,
    required this.onSelect,
  });

  final int year;
  final int month;
  final LocalDate today;
  final LocalDate? selected;
  final int Function(LocalDate date) chapterCountOn;
  final ValueChanged<LocalDate> onSelect;

  static const List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final first = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = first.weekday % 7; // Sunday = 0
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: FjSpace.s),
                    child: Text(w, style: t.meta.copyWith(fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final dayNumber = r * 7 + col - leading + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(height: 52);
                      }
                      final date = LocalDate(year, month, dayNumber);
                      final count = chapterCountOn(date);
                      final isToday = date == today;
                      final isSelected = date == selected;
                      final label =
                          '$month월 $dayNumber일'
                          '${isToday ? ', 오늘' : ''}'
                          '${count > 0 ? ', 이야기 $count개 읽음' : ''}';
                      return Semantics(
                        label: label,
                        selected: isSelected,
                        button: true,
                        excludeSemantics: true,
                        child: InkWell(
                          key: ValueKey('calendar-${date.iso}'),
                          onTap: () => onSelect(date),
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            height: 52,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: isToday
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: c.textPrimary,
                                        )
                                      : isSelected
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: c.textPrimary,
                                            width: 0.8,
                                          ),
                                        )
                                      : null,
                                  child: Text(
                                    '$dayNumber',
                                    style: (isToday ? t.uiStrong : t.ui)
                                        .copyWith(
                                          fontSize: 14.5,
                                          height: 1.2,
                                          color: isToday
                                              ? c.background
                                              : c.textPrimary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SizedBox(
                                  height: 5,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < count.clamp(0, 3);
                                        i++
                                      )
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
