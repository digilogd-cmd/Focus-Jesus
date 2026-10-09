import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/models/reading_preferences.dart';

/// Reading time and level, adjustable without leaving the chapter.
Future<void> showReadingSettingsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ReadingSettingsSheet(),
    );

class _ReadingSettingsSheet extends ConsumerWidget {
  const _ReadingSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return SafeArea(
      child: SingleChildScrollView(
        child: ReadingColumn(
          child: Padding(
            padding: const EdgeInsets.only(bottom: FjSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FjDualLabel('TIME', '읽기 시간'),
                const SizedBox(height: FjSpace.s),
                Row(
                  children: [
                    for (final m in ReadingMinutes.values)
                      Expanded(
                        child: Semantics(
                          selected: settings.minutes == m,
                          button: true,
                          child: InkWell(
                            key: ValueKey('sheet-minutes-${m.minutes}'),
                            onTap: () => controller.update(
                              (s) => s.copyWith(minutes: m),
                            ),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: settings.minutes == m
                                        ? c.accent
                                        : c.divider,
                                    width: settings.minutes == m ? 1.5 : 0.8,
                                  ),
                                ),
                              ),
                              child: Text(
                                m.label,
                                style:
                                    (settings.minutes == m ? t.uiStrong : t.ui)
                                        .copyWith(
                                          color: settings.minutes == m
                                              ? c.textPrimary
                                              : c.textSecondary,
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('LEVEL', '이해 수준'),
                for (final level in ReadingLevel.values)
                  FjOptionTile(
                    key: ValueKey('sheet-level-${level.id}'),
                    title: level.label,
                    description: level.description,
                    selected: settings.level == level,
                    onTap: () =>
                        controller.update((s) => s.copyWith(level: level)),
                  ),
                const SizedBox(height: FjSpace.m),
                Text('바꾼 설정은 다른 이야기에도 그대로 적용됩니다.', style: t.meta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
