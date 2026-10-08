import 'reading_preferences.dart';

enum ThemePreference {
  light('light', '라이트'),
  dark('dark', '다크'),
  system('system', '시스템 설정 따르기');

  const ThemePreference(this.id, this.label);

  final String id;
  final String label;

  static ThemePreference fromId(String? id) =>
      values.firstWhere((t) => t.id == id, orElse: () => ThemePreference.light);
}

class ReminderPreference {
  const ReminderPreference({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  static const ReminderPreference defaults = ReminderPreference(
    enabled: false,
    hour: 7,
    minute: 30,
  );

  final bool enabled;
  final int hour;
  final int minute;

  String get timeLabel {
    final period = hour < 12 ? '오전' : '오후';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $h12:${minute.toString().padLeft(2, '0')}';
  }

  ReminderPreference copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderPreference(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderPreference &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}

class UserSettings {
  const UserSettings({
    required this.onboardingComplete,
    required this.level,
    required this.minutes,
    required this.reminder,
    required this.theme,
  });

  static const UserSettings defaults = UserSettings(
    onboardingComplete: false,
    level: ReadingLevel.beginner,
    minutes: ReadingMinutes.ten,
    reminder: ReminderPreference.defaults,
    theme: ThemePreference.light,
  );

  final bool onboardingComplete;
  final ReadingLevel level;
  final ReadingMinutes minutes;
  final ReminderPreference reminder;
  final ThemePreference theme;

  UserSettings copyWith({
    bool? onboardingComplete,
    ReadingLevel? level,
    ReadingMinutes? minutes,
    ReminderPreference? reminder,
    ThemePreference? theme,
  }) => UserSettings(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    level: level ?? this.level,
    minutes: minutes ?? this.minutes,
    reminder: reminder ?? this.reminder,
    theme: theme ?? this.theme,
  );
}
