// Verifies what the Android notification plugin is actually asked to do, at
// the platform-channel boundary (no device needed).

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/core/notifications/reminder_planner.dart';
import 'package:focus_jesus/core/notifications/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  bool? permissionAnswer = true;

  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'getNotificationAppLaunchDetails' => null,
            'requestNotificationsPermission' => permissionAnswer,
            _ => null,
          };
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // Real "now", because the plugin itself validates one-off dates against it.
  final now = DateTime.now();
  final todayAt = DateTime(now.year, now.month, now.day + 1, 7, 30);
  final dailyFrom = DateTime(now.year, now.month, now.day + 2, 7, 30);

  test('enabled plan: cancels old reminders, then schedules inexact one-off and daily repeat', () async {
    await LocalNotificationScheduler().apply(
      ReminderPlan.enabled(todayAt: todayAt, dailyFrom: dailyFrom),
    );
    expect(calls.map((c) => c.method), [
      'cancel',
      'cancel',
      'zonedSchedule',
      'zonedSchedule',
    ]);

    final once = calls[2].arguments as Map;
    expect(once['id'], LocalNotificationScheduler.todayId);
    expect(once['matchDateTimeComponents'], isNull);
    expect(once['timeZoneName'], 'Asia/Seoul');
    expect(
      once['scheduledDateTime'],
      startsWith(
        '${todayAt.year}-${todayAt.month.toString().padLeft(2, '0')}-${todayAt.day.toString().padLeft(2, '0')}T07:30',
      ),
    );
    final android = (once['platformSpecifics'] as Map);
    expect(
      android['scheduleMode'],
      'inexactAllowWhileIdle',
      reason: 'no exact-alarm permission needed',
    );
    expect(android['channelId'], 'daily_reading');
    expect(android['icon'], 'ic_stat_notify');

    final daily = calls[3].arguments as Map;
    expect(daily['id'], LocalNotificationScheduler.dailyId);
    expect(daily['matchDateTimeComponents'], DateTimeComponents.time.index);
    expect(daily['payload'], LocalNotificationScheduler.payload);
  });

  test('read today: only the daily repeat is scheduled', () async {
    await LocalNotificationScheduler().apply(
      ReminderPlan.enabled(todayAt: null, dailyFrom: dailyFrom),
    );
    expect(calls.map((c) => c.method), ['cancel', 'cancel', 'zonedSchedule']);
    expect(
      (calls.last.arguments as Map)['id'],
      LocalNotificationScheduler.dailyId,
    );
  });

  test('disabled plan cancels both reminders and schedules nothing', () async {
    await LocalNotificationScheduler().apply(const ReminderPlan.disabled());
    expect(calls.map((c) => c.method), ['cancel', 'cancel']);
    expect(calls.map((c) => (c.arguments as Map)['id']), [
      LocalNotificationScheduler.todayId,
      LocalNotificationScheduler.dailyId,
    ]);
  });

  test('permission request maps grant and denial; never throws', () async {
    permissionAnswer = true;
    expect(await LocalNotificationScheduler().requestPermission(), isTrue);
    permissionAnswer = false;
    expect(await LocalNotificationScheduler().requestPermission(), isFalse);
    permissionAnswer = null;
    expect(await LocalNotificationScheduler().requestPermission(), isFalse);
  });

  test('a platform failure while scheduling does not crash the app', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(code: 'boom'),
        );
    await expectLater(
      LocalNotificationScheduler().apply(
        ReminderPlan.enabled(todayAt: todayAt, dailyFrom: dailyFrom),
      ),
      completes,
    );
  });
}
