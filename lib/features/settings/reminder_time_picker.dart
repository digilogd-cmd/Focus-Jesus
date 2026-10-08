import 'package:flutter/material.dart';

/// Opens the system time picker; returns (hour, minute) or null if cancelled.
Future<(int, int)?> pickReminderTime(
  BuildContext context, {
  required int hour,
  required int minute,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: hour, minute: minute),
    helpText: '알림 시간',
    cancelText: '취소',
    confirmText: '확인',
    initialEntryMode: TimePickerEntryMode.dial,
  );
  if (picked == null) return null;
  return (picked.hour, picked.minute);
}
