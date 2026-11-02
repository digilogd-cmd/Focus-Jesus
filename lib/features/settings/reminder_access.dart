import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';

/// Asks the OS for the notification permission; when it can no longer be
/// asked in-app (denied before), offers the app's system settings page.
/// Returns true when notifications are allowed afterwards.
Future<bool> allowNotifications(BuildContext context, WidgetRef ref) async {
  final coordinator = ref.read(reminderCoordinatorProvider);
  if (await coordinator.ensurePermission()) return true;
  if (!context.mounted) return false;
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('알림을 허용해 주세요'),
      content: const Text(
        '휴대전화 설정에서 FOCUS JESUS의 알림이 꺼져 있습니다. '
        '설정 화면에서 알림을 켜면 정해 둔 시간에 오늘의 이야기를 알려 드립니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('나중에'),
        ),
        TextButton(
          key: const ValueKey('open-notification-settings'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('설정 열기'),
        ),
      ],
    ),
  );
  if (open == true) await coordinator.openSystemSettings();
  return false;
}

/// A quiet notice shown while reminders are on but cannot be delivered.
class ReminderNotice extends ConsumerWidget {
  const ReminderNotice({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(reminderHealthProvider).value;
    final message = switch (health) {
      ReminderHealth.needsPermission =>
        '휴대전화에서 이 앱의 알림이 꺼져 있어, 정해 둔 시간에 알려 드릴 수 없습니다.',
      ReminderHealth.scheduleFailed =>
        '이 기기에서 알림 예약에 실패했습니다. 알림을 한 번 껐다가 다시 켜 보세요.',
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    final c = FjColors.of(context);
    final t = FjText.of(context);
    return Padding(
      padding: padding,
      child: Reveal(
        key: const ValueKey('reminder-notice'),
        child: Container(
          padding: const EdgeInsets.only(left: FjSpace.m),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.textPrimary, width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FjDualLabel('REMINDER', '알림'),
              const SizedBox(height: FjSpace.xs),
              Text(message, style: t.meta.copyWith(color: c.inkSoft)),
              if (health == ReminderHealth.needsPermission)
                FjQuietButton(
                  key: const ValueKey('reminder-allow'),
                  label: '알림 허용하기',
                  alignment: Alignment.centerLeft,
                  trailingArrow: true,
                  onPressed: () async {
                    if (await allowNotifications(context, ref)) {
                      await ref.read(reminderCoordinatorProvider).sync();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
