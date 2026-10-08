// Pure Dart: decides which daily reminders should exist right now.

import '../../data/models/user_settings.dart';

/// Wall-clock time without date; reminders follow the local zone.
class ReminderPlan {
  const ReminderPlan._({required this.enabled, this.todayAt, this.dailyFrom});

  const ReminderPlan.disabled() : this._(enabled: false);

  /// [todayAt] is a one-off reminder later today, omitted when today's reading
  /// is already done or the time has passed. [dailyFrom] starts a repeating
  /// daily reminder from tomorrow, so finishing early in the day can cancel
  /// today's reminder without touching the following days.
  const ReminderPlan.enabled({
    required DateTime? todayAt,
    required DateTime dailyFrom,
  }) : this._(enabled: true, todayAt: todayAt, dailyFrom: dailyFrom);

  final bool enabled;
  final DateTime? todayAt;
  final DateTime? dailyFrom;

  @override
  bool operator ==(Object other) =>
      other is ReminderPlan &&
      other.enabled == enabled &&
      other.todayAt == todayAt &&
      other.dailyFrom == dailyFrom;

  @override
  int get hashCode => Object.hash(enabled, todayAt, dailyFrom);

  @override
  String toString() => enabled
      ? 'ReminderPlan(today: $todayAt, dailyFrom: $dailyFrom)'
      : 'ReminderPlan.disabled';
}

/// [now] is a local DateTime. Day arithmetic uses calendar components so
/// daylight-saving transitions keep the same wall-clock time.
ReminderPlan planReminders({
  required DateTime now,
  required ReminderPreference preference,
  required bool finishedToday,
}) {
  if (!preference.enabled) return const ReminderPlan.disabled();
  final todayTime = DateTime(
    now.year,
    now.month,
    now.day,
    preference.hour,
    preference.minute,
  );
  final tomorrowTime = DateTime(
    now.year,
    now.month,
    now.day + 1,
    preference.hour,
    preference.minute,
  );
  return ReminderPlan.enabled(
    todayAt: !finishedToday && todayTime.isAfter(now) ? todayTime : null,
    dailyFrom: tomorrowTime,
  );
}
