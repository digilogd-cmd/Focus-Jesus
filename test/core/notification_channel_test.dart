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
  bool? enabledAnswer = true;

  /// A scheduler that initialised like it does on a device.
  Future<LocalNotificationScheduler> ready() async {
    final scheduler = LocalNotificationScheduler();
    await scheduler.initialize(onOpen: () {});
    calls.clear();
    return scheduler;
  }

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
            'areNotificationsEnabled' => enabledAnswer,
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
  // The wall-clock times are read in Asia/Seoul while `now` is the machine's
  // zone, so stay two days out: "tomorrow 07:30" built from a UTC evening is
  // already past in Seoul (this failed depending on the time of day).
  final now = DateTime.now();
  final todayAt = DateTime(now.year, now.month, now.day + 2, 7, 30);
  final dailyFrom = DateTime(now.year, now.month, now.day + 3, 7, 30);

  test('enabled plan: cancels old reminders, then schedules inexact one-off and daily repeat', () async {
    expect(
      await (await ready()).apply(
        ReminderPlan.enabled(todayAt: todayAt, dailyFrom: dailyFrom),
      ),
      isTrue,
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
    await (await ready()).apply(
      ReminderPlan.enabled(todayAt: null, dailyFrom: dailyFrom),
    );
    expect(calls.map((c) => c.method), ['cancel', 'cancel', 'zonedSchedule']);
    expect(
      (calls.last.arguments as Map)['id'],
      LocalNotificationScheduler.dailyId,
    );
  });

  test('disabled plan cancels both reminders and schedules nothing', () async {
    await (await ready()).apply(const ReminderPlan.disabled());
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

  test('a platform failure while scheduling is reported, not thrown', () async {
    final scheduler = await ready();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(code: 'boom'),
        );
    expect(
      await scheduler.apply(
        ReminderPlan.enabled(todayAt: todayAt, dailyFrom: dailyFrom),
      ),
      isFalse,
    );
  });

  test(
    'failed initialisation (e.g. icon stripped from the build) is reported',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') {
              throw PlatformException(code: 'invalid_icon');
            }
            return null;
          });
      final scheduler = LocalNotificationScheduler();
      await scheduler.initialize(onOpen: () {});
      calls.clear();
      expect(
        await scheduler.apply(
          ReminderPlan.enabled(todayAt: todayAt, dailyFrom: dailyFrom),
        ),
        isFalse,
      );
      expect(await scheduler.showTestNotification(), isFalse);
      expect(
        calls,
        isEmpty,
        reason: 'nothing is sent to an uninitialised plugin',
      );
    },
  );

  test('notification status maps the OS answer; never throws', () async {
    final scheduler = await ready();
    enabledAnswer = true;
    expect(await scheduler.notificationsEnabled(), isTrue);
    enabledAnswer = false;
    expect(await scheduler.notificationsEnabled(), isFalse);
    enabledAnswer = null;
    expect(await scheduler.notificationsEnabled(), isFalse);
    enabledAnswer = true;
  });

  test(
    'test notification is shown immediately on the reading channel',
    () async {
      final scheduler = await ready();
      expect(await scheduler.showTestNotification(), isTrue);
      expect(calls.single.method, 'show');
      final args = calls.single.arguments as Map;
      expect(args['id'], LocalNotificationScheduler.testId);
      expect((args['platformSpecifics'] as Map)['channelId'], 'daily_reading');
    },
  );

  test('opening the system settings goes through the app channel', () async {
    final system = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalNotificationScheduler.systemChannel, (
          call,
        ) async {
          system.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            LocalNotificationScheduler.systemChannel,
            null,
          ),
    );
    expect(
      await LocalNotificationScheduler().openNotificationSettings(),
      isTrue,
    );
    expect(system.single.method, 'openNotificationSettings');
  });
}
