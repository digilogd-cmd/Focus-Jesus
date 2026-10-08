import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'
    show Database, DatabaseFactory, databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import '../core/notifications/reminder_scheduler.dart';
import '../core/storage/app_database.dart';
import '../core/time/clock.dart';
import '../core/time/time_zone_service.dart';
import '../data/content/content_repository.dart';
import 'providers.dart';
import 'router.dart';

/// Everything the app needs before the first frame. Tests build their own.
class AppDependencies {
  AppDependencies({
    required this.database,
    required this.preferences,
    required this.season,
    required this.scheduler,
    this.timeZoneName,
    this.clock = const SystemClock(),
    this.launchedFromReminder = false,
    this.linkOpener,
  });

  final Database database;
  final SharedPreferences preferences;
  final Season season;
  final ReminderScheduler scheduler;
  final String? timeZoneName;
  final Clock clock;
  final bool launchedFromReminder;
  final LinkOpener? linkOpener;
}

bool get _isDesktop =>
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

DatabaseFactory platformDatabaseFactory() {
  if (_isDesktop) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactorySqflitePlugin;
}

Future<Database> openAppDatabase([DatabaseFactory? factory]) async {
  final f = factory ?? platformDatabaseFactory();
  final dir = await f.getDatabasesPath();
  return AppDatabase.open(f, p.join(dir, AppDatabase.fileName));
}

/// Production bootstrap.
Future<AppDependencies> loadAppDependencies() async {
  await initializeDateFormatting('ko_KR');
  final timeZone = await TimeZoneService().configureLocal();
  final results = await Future.wait<Object>([
    openAppDatabase(),
    SharedPreferences.getInstance(),
    ContentRepository(rootBundle).loadSeason(),
  ]);
  final scheduler = (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      ? LocalNotificationScheduler()
      : RecordingReminderScheduler();
  // Taps arrive later, once createAppContainer has registered the container.
  final launched = await scheduler.initialize(
    onOpen: () =>
        _containerForTaps?.read(routerProvider).go(Routes.continueReading),
  );
  return AppDependencies(
    database: results[0] as Database,
    preferences: results[1] as SharedPreferences,
    season: results[2] as Season,
    scheduler: scheduler,
    timeZoneName: timeZone,
    launchedFromReminder: launched,
  );
}

ProviderContainer? _containerForTaps;

/// Builds the root container and performs startup work that must happen
/// before the first frame (loading history, re-planning reminders).
Future<ProviderContainer> createAppContainer(AppDependencies deps) async {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(deps.database),
      sharedPreferencesProvider.overrideWithValue(deps.preferences),
      seasonProvider.overrideWithValue(deps.season),
      reminderSchedulerProvider.overrideWithValue(deps.scheduler),
      timeZoneNameProvider.overrideWithValue(deps.timeZoneName),
      clockProvider.overrideWithValue(deps.clock),
      initialLocationProvider.overrideWithValue(
        deps.launchedFromReminder ? Routes.continueReading : Routes.today,
      ),
      if (deps.linkOpener != null)
        linkOpenerProvider.overrideWithValue(deps.linkOpener!),
    ],
  );
  _containerForTaps = container;
  await container.read(journeyProvider.future);
  // Re-plan reminders on every launch: covers app updates, reboots handled by
  // the OS receiver, time-zone changes and days that passed while closed.
  await container.read(reminderCoordinatorProvider).sync();
  return container;
}
