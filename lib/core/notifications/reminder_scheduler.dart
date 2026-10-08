import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_planner.dart';

/// Abstraction over the OS notification system so logic stays testable.
abstract class ReminderScheduler {
  /// Sets up the plugin. [onOpen] runs when the user taps a reminder while the
  /// app is alive. Returns true when the app was launched by a reminder tap.
  Future<bool> initialize({required VoidCallback onOpen});

  /// Asks for the notification permission (Android 13+). Never throws.
  Future<bool> requestPermission();

  /// Replaces all scheduled reminders with [plan].
  Future<void> apply(ReminderPlan plan);
}

/// Used where scheduled notifications are unsupported (desktop test runs).
/// Records the last plan so tests can assert on it.
class RecordingReminderScheduler implements ReminderScheduler {
  ReminderPlan? lastPlan;
  int applyCount = 0;
  bool permissionGranted;

  RecordingReminderScheduler({this.permissionGranted = true});

  @override
  Future<bool> initialize({required VoidCallback onOpen}) async => false;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> apply(ReminderPlan plan) async {
    lastPlan = plan;
    applyCount++;
  }
}

class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int todayId = 1001;
  static const int dailyId = 1002;
  static const String payload = 'continue';

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'daily_reading',
    '매일 읽기 알림',
    channelDescription: '설정한 시간에 오늘의 이야기를 알려 드립니다.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: 'ic_stat_notify',
    category: AndroidNotificationCategory.reminder,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _android,
    iOS: DarwinNotificationDetails(),
  );

  static const String _title = 'FOCUS JESUS';
  static const String _body = '오늘의 이야기가 기다리고 있어요. 천천히 읽어 보세요.';

  @override
  Future<bool> initialize({required VoidCallback onOpen}) async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notify'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => onOpen(),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      return launch?.didNotificationLaunchApp ?? false;
    } on Object catch (e, s) {
      debugPrint('Notification init failed: $e\n$s');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      return false;
    } on Object catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  @override
  Future<void> apply(ReminderPlan plan) async {
    try {
      await _plugin.cancel(id: todayId);
      await _plugin.cancel(id: dailyId);
      if (!plan.enabled) return;
      final today = plan.todayAt;
      if (today != null) {
        await _plugin.zonedSchedule(
          id: todayId,
          scheduledDate: _inLocalZone(today),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: _title,
          body: _body,
          payload: payload,
        );
      }
      await _plugin.zonedSchedule(
        id: dailyId,
        scheduledDate: _inLocalZone(plan.dailyFrom!),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: _title,
        body: _body,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object catch (e, s) {
      // Reminders are a convenience; reading must keep working without them.
      debugPrint('Scheduling reminders failed: $e\n$s');
    }
  }

  static tz.TZDateTime _inLocalZone(DateTime wallClock) => tz.TZDateTime(
    tz.local,
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
  );
}
