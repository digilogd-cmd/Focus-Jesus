import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/models/reading_preferences.dart';
import '../../data/models/user_settings.dart';
import 'reminder_time_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = FjText.of(context);
    final s = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    Future<void> updateReminder(ReminderPreference next) async {
      var value = next;
      if (next.enabled && !s.reminder.enabled) {
        final granted = await ref
            .read(reminderCoordinatorProvider)
            .requestPermission();
        if (!granted) {
          value = next.copyWith(enabled: false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '알림 권한이 꺼져 있습니다. 휴대전화 설정 > 애플리케이션에서 FOCUS JESUS의 알림을 허용해 주세요.',
                ),
              ),
            );
          }
        }
      }
      await controller.update((cur) => cur.copyWith(reminder: value));
      await ref.read(reminderCoordinatorProvider).sync();
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ReadingColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: FjSpace.xl),
                const FjScreenTitle(en: 'SETTINGS', title: '설정'),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('READING', '읽기'),
                FjListRow(
                  key: const ValueKey('settings-level'),
                  title: '이해 수준',
                  value: s.level.label,
                  onTap: () => _choose<ReadingLevel>(
                    context,
                    title: '이해 수준',
                    options: ReadingLevel.values,
                    selected: s.level,
                    label: (l) => l.label,
                    description: (l) => l.description,
                    keyOf: (l) => 'level-${l.id}',
                    onSelected: (l) =>
                        controller.update((c) => c.copyWith(level: l)),
                  ),
                ),
                FjListRow(
                  key: const ValueKey('settings-minutes'),
                  title: '하루 독서 시간',
                  value: s.minutes.label,
                  onTap: () => _choose<ReadingMinutes>(
                    context,
                    title: '하루 독서 시간',
                    options: ReadingMinutes.values,
                    selected: s.minutes,
                    label: (m) => m.label,
                    description: (_) => null,
                    keyOf: (m) => 'minutes-${m.minutes}',
                    onSelected: (m) =>
                        controller.update((c) => c.copyWith(minutes: m)),
                  ),
                ),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('REMINDER', '알림'),
                FjListRow(
                  key: const ValueKey('settings-reminder-toggle'),
                  title: '매일 읽기 알림',
                  subtitle: s.reminder.enabled
                      ? '그날 이야기를 읽었다면 알리지 않습니다.'
                      : null,
                  onTap: () => updateReminder(
                    s.reminder.copyWith(enabled: !s.reminder.enabled),
                  ),
                  trailing: Switch(
                    value: s.reminder.enabled,
                    onChanged: (v) =>
                        updateReminder(s.reminder.copyWith(enabled: v)),
                  ),
                ),
                if (s.reminder.enabled)
                  FjListRow(
                    key: const ValueKey('settings-reminder-time'),
                    title: '알림 시간',
                    value: s.reminder.timeLabel,
                    onTap: () async {
                      final picked = await pickReminderTime(
                        context,
                        hour: s.reminder.hour,
                        minute: s.reminder.minute,
                      );
                      if (picked != null) {
                        await updateReminder(
                          s.reminder.copyWith(
                            hour: picked.$1,
                            minute: picked.$2,
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('DISPLAY', '화면'),
                FjListRow(
                  key: const ValueKey('settings-theme'),
                  title: '화면 테마',
                  value: s.theme.label,
                  onTap: () => _choose<ThemePreference>(
                    context,
                    title: '화면 테마',
                    options: ThemePreference.values,
                    selected: s.theme,
                    label: (th) => th.label,
                    description: (_) => null,
                    keyOf: (th) => 'theme-${th.id}',
                    onSelected: (th) =>
                        controller.update((c) => c.copyWith(theme: th)),
                  ),
                ),
                const SizedBox(height: FjSpace.s),
                Text('글자 크기는 휴대전화의 글꼴 크기 설정을 따릅니다.', style: t.meta),
                const SizedBox(height: FjSpace.xl),
                const FjDualLabel('ABOUT', '이 앱에 대하여'),
                FjListRow(
                  title: '콘텐츠 안내',
                  onTap: () => _showContentNotice(context),
                ),
                FjListRow(
                  title: '오픈소스 라이선스',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'FOCUS JESUS',
                    applicationVersion: appVersion,
                  ),
                ),
                FjListRow(title: '버전', value: appVersion),
                const SizedBox(height: FjSpace.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _choose<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T) label,
    required String? Function(T) description,
    required String Function(T) keyOf,
    required ValueChanged<T> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: ReadingColumn(
            child: Padding(
              padding: const EdgeInsets.only(bottom: FjSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FjLabel(title),
                  for (final o in options)
                    FjOptionTile(
                      key: ValueKey('choice-${keyOf(o)}'),
                      title: label(o),
                      description: description(o),
                      selected: o == selected,
                      onTap: () {
                        onSelected(o);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showContentNotice(BuildContext context) {
    final t = FjText.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: ReadingColumn(
            child: Padding(
              padding: const EdgeInsets.only(bottom: FjSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FjDualLabel('NOTICE', '콘텐츠 안내'),
                  const SizedBox(height: FjSpace.m),
                  Text(
                    '이 앱의 해설은 성경 본문을 인용하지 않고 독립적으로 쓴 원고입니다. 실제 성경 본문은 '
                    '대한성서공회 성경플랫폼의 개역개정 본문으로 연결해 드립니다.',
                    style: t.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: FjSpace.m),
                  Text(
                    '현재 모든 원고는 AI의 도움을 받아 작성된 뒤 자동 검증을 거쳤으며, 신학 검수자의 최종 검토를 '
                    '기다리고 있습니다. 해석이 갈리는 문제는 한쪽으로 단정하지 않고 여러 견해를 소개하려고 했습니다.',
                    style: t.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: FjSpace.m),
                  Text(
                    '모든 기록과 메모는 이 기기에만 저장되며 어디에도 전송되지 않습니다.',
                    style: t.body.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
