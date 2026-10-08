import 'package:shared_preferences/shared_preferences.dart';

import '../models/reading_preferences.dart';
import '../models/user_settings.dart';

/// Persists [UserSettings] in shared preferences under versioned keys.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const int settingsVersion = 1;
  static const String _kVersion = 'settings.version';
  static const String _kOnboarding = 'settings.onboardingComplete';
  static const String _kLevel = 'settings.level';
  static const String _kMinutes = 'settings.minutes';
  static const String _kReminderEnabled = 'settings.reminder.enabled';
  static const String _kReminderHour = 'settings.reminder.hour';
  static const String _kReminderMinute = 'settings.reminder.minute';
  static const String _kTheme = 'settings.theme';
  static const String _kScheduledZone = 'reminder.scheduledTimeZone';

  UserSettings load() {
    final d = UserSettings.defaults;
    final hour = _prefs.getInt(_kReminderHour);
    final minute = _prefs.getInt(_kReminderMinute);
    return UserSettings(
      onboardingComplete: _prefs.getBool(_kOnboarding) ?? d.onboardingComplete,
      level: ReadingLevel.fromId(_prefs.getString(_kLevel)),
      minutes: ReadingMinutes.fromMinutes(_prefs.getInt(_kMinutes)),
      reminder: ReminderPreference(
        enabled: _prefs.getBool(_kReminderEnabled) ?? d.reminder.enabled,
        hour: hour != null && hour >= 0 && hour < 24 ? hour : d.reminder.hour,
        minute: minute != null && minute >= 0 && minute < 60
            ? minute
            : d.reminder.minute,
      ),
      theme: ThemePreference.fromId(_prefs.getString(_kTheme)),
    );
  }

  Future<void> save(UserSettings s) async {
    await Future.wait([
      _prefs.setInt(_kVersion, settingsVersion),
      _prefs.setBool(_kOnboarding, s.onboardingComplete),
      _prefs.setString(_kLevel, s.level.id),
      _prefs.setInt(_kMinutes, s.minutes.minutes),
      _prefs.setBool(_kReminderEnabled, s.reminder.enabled),
      _prefs.setInt(_kReminderHour, s.reminder.hour),
      _prefs.setInt(_kReminderMinute, s.reminder.minute),
      _prefs.setString(_kTheme, s.theme.id),
    ]);
  }

  /// The IANA zone the reminders were last scheduled in, to detect zone changes.
  String? get scheduledTimeZone => _prefs.getString(_kScheduledZone);

  Future<void> setScheduledTimeZone(String? zone) async {
    if (zone == null) {
      await _prefs.remove(_kScheduledZone);
    } else {
      await _prefs.setString(_kScheduledZone, zone);
    }
  }
}
