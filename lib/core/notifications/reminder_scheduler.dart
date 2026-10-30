import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Whether the OS currently lets this app post notifications (permission
  /// granted and notifications not switched off for the app). Never throws.
  Future<bool> notificationsEnabled();

  /// Opens the system notification settings page for this app, for when the
  /// permission can no longer be requested in-app. Returns false on failure.
  Future<bool> openNotificationSettings();

  /// Posts one notification immediately so the user can confirm delivery.
  Future<bool> showTestNotification();

  /// Replaces all scheduled reminders with [plan]. Returns false when the
  /// reminders could not be scheduled (the reason is logged).
  Future<bool> apply(ReminderPlan plan);
}

/// Used where scheduled notifications are unsupported (desktop test runs).
/// Records the last plan so tests can assert on it.
class RecordingReminderScheduler implements ReminderScheduler {
  ReminderPlan? lastPlan;
  int applyCount = 0;
  int permissionRequests = 0;
  int settingsOpened = 0;
  int testNotifications = 0;

  /// What the OS answers when asked for the permission.
  bool permissionGranted;

  /// Current OS state. Starts granted only when [permissionGranted].
  bool enabled;

  RecordingReminderScheduler({this.permissionGranted = true, bool? enabled})
    : enabled = enabled ?? permissionGranted;

  @override
  Future<bool> initialize({required VoidCallback onOpen}) async => false;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (permissionGranted) enabled = true;
    return permissionGranted;
  }

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<bool> openNotificationSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> showTestNotification() async {
    testNotifications++;
    return enabled;
  }

  @override
  Future<bool> apply(ReminderPlan plan) async {
    lastPlan = plan;
    applyCount++;
    return true;
  }
}

class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int todayId = 1001;
  static const int dailyId = 1002;
  static const int testId = 1003;
  static const String payload = 'continue';

  /// App-side channel (MainActivity.kt) for things the plugin does not offer.
  static const MethodChannel systemChannel = MethodChannel(
    'com.focusjesus.story/system',
  );

  /// False when initialisation failed; scheduling would then fail too.
  bool _ready = false;

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
      _ready = true;
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
  Future<bool> notificationsEnabled() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final p = await ios.checkPermissions();
        return p?.isEnabled ?? false;
      }
      return false;
    } on Object catch (e) {
      debugPrint('Notification status check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> openNotificationSettings() async {
    try {
      return await systemChannel.invokeMethod<bool>(
            'openNotificationSettings',
          ) ??
          false;
    } on Object catch (e) {
      debugPrint('Opening notification settings failed: $e');
      return false;
    }
  }

  @override
  Future<bool> showTestNotification() async {
    if (!_ready) return false;
    try {
      await _plugin.show(
        id: testId,
        title: _title,
        body: '알림이 잘 도착합니다. 정해 둔 시간에 이렇게 알려 드릴게요.',
        notificationDetails: _details,
        payload: payload,
      );
      return true;
    } on Object catch (e, s) {
      debugPrint('Test notification failed: $e\n$s');
      return false;
    }
  }

  @override
  Future<bool> apply(ReminderPlan plan) async {
    if (!_ready) {
      debugPrint('Reminders not scheduled: notifications failed to initialise');
      return false;
    }
    try {
      await _plugin.cancel(id: todayId);
      await _plugin.cancel(id: dailyId);
      if (!plan.enabled) return true;
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
      return true;
    } on Object catch (e, s) {
      // Reminders are a convenience; reading must keep working without them,
      // but the failure is reported so the UI can say so.
      debugPrint('Scheduling reminders failed: $e\n$s');
      return false;
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
