import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/notifications/reminder_planner.dart';
import '../core/notifications/reminder_scheduler.dart';
import '../core/time/clock.dart';
import '../data/content/chapter.dart';
import '../data/content/program.dart';
import '../data/journey/journey.dart';
import '../data/models/progress.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/reflection_repository.dart';
import '../data/repositories/settings_repository.dart';

// Values created during bootstrap (see main.dart) and injected via overrides.

final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// The one-year program: seasons and day outlines (no manuscripts).
final programProvider = Provider<Program>(
  (ref) => throw UnimplementedError('programProvider must be overridden'),
);

/// Loads manuscripts on demand.
final chapterStoreProvider = Provider<ChapterStore>(
  (ref) => throw UnimplementedError('chapterStoreProvider must be overridden'),
);

/// One manuscript, parsed once. Null for days still in preparation.
final chapterProvider = FutureProvider.family<Chapter?, String>(
  (ref, chapterId) => ref.watch(chapterStoreProvider).load(chapterId),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) =>
      throw UnimplementedError('reminderSchedulerProvider must be overridden'),
);

/// Zone detected at launch (overridden in bootstrap).
final initialTimeZoneProvider = Provider<String?>((ref) => null);

/// Re-detects the device zone and points `tz.local` at it. Overridden in tests.
final timeZoneRefresherProvider = Provider<Future<String?> Function()>(
  (ref) =>
      () async => ref.read(timeZoneNameProvider),
);

/// IANA zone in use, recorded with completions. Null when unknown.
class TimeZoneName extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialTimeZoneProvider);

  /// Picks up a zone change made while the app was in the background.
  /// Returns true when the zone changed.
  Future<bool> refresh() async {
    final detected = await ref.read(timeZoneRefresherProvider)();
    if (detected == null || detected == state) return false;
    state = detected;
    return true;
  }
}

final timeZoneNameProvider = NotifierProvider<TimeZoneName, String?>(
  TimeZoneName.new,
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Whether launch plays the opening press sequence (`PressIntro`).
/// On for the real app; off by default so tests start on the first screen.
final introEnabledProvider = Provider<bool>((ref) => false);

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const UrlLauncherLinkOpener(),
);

// Repositories.

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(databaseProvider)),
);

final reflectionRepositoryProvider = Provider<ReflectionRepository>(
  (ref) => ReflectionRepository(ref.watch(databaseProvider)),
);

// Settings.

class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(
    UserSettings Function(UserSettings current) change,
  ) async {
    final next = change(state);
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}

final settingsProvider = NotifierProvider<SettingsController, UserSettings>(
  SettingsController.new,
);

// Journey (completion history).

class JourneyController extends AsyncNotifier<JourneySnapshot> {
  @override
  Future<JourneySnapshot> build() async => JourneySnapshot(
    await ref.watch(progressRepositoryProvider).allCompletionEvents(),
  );

  Future<CompletionOutcome> complete(String chapterId) async {
    final repo = ref.read(progressRepositoryProvider);
    final outcome = await repo.recordCompletion(
      chapterId: chapterId,
      localNow: ref.read(clockProvider).now(),
      timeZone: ref.read(timeZoneNameProvider),
    );
    // A finished chapter starts from the top when re-read.
    await repo.clearPosition(chapterId);
    state = AsyncData(JourneySnapshot(await repo.allCompletionEvents()));
    ref.invalidate(readingPositionProvider(chapterId));
    return outcome;
  }
}

final journeyProvider =
    AsyncNotifierProvider<JourneyController, JourneySnapshot>(
      JourneyController.new,
    );

/// Bumped when the app returns to the foreground so date-dependent views
/// (today, calendar) recompute after midnight.
class DayTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dayTickProvider = NotifierProvider<DayTick, int>(DayTick.new);

final todayProvider = Provider<LocalDate>((ref) {
  ref.watch(dayTickProvider);
  return LocalDate.of(ref.watch(clockProvider).now());
});

final todayPlanProvider = Provider<TodayPlan>((ref) {
  final program = ref.watch(programProvider);
  final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
  return planToday(
    orderedIds: program.orderedIds,
    journey: journey,
    today: ref.watch(todayProvider),
  );
});

final readingPositionProvider = FutureProvider.family<ReadingPosition?, String>(
  (ref, chapterId) =>
      ref.watch(progressRepositoryProvider).loadPosition(chapterId),
);

// Reminders.

/// Keeps OS reminders in sync with settings and today's progress.
class ReminderCoordinator {
  ReminderCoordinator(this._ref);

  final Ref _ref;

  ReminderScheduler get _scheduler => _ref.read(reminderSchedulerProvider);

  Future<ReminderPlan> sync() async {
    final settings = _ref.read(settingsProvider);
    final journey = await _ref.read(journeyProvider.future);
    final now = _ref.read(clockProvider).now();
    final plan = planReminders(
      now: now,
      preference: settings.reminder,
      finishedToday: journey.chaptersOn(LocalDate.of(now)).isNotEmpty,
    );
    final scheduled = await _scheduler.apply(plan);
    _ref.read(reminderScheduleOkProvider.notifier).set(scheduled);
    await _ref
        .read(settingsRepositoryProvider)
        .setScheduledTimeZone(
          plan.enabled ? _ref.read(timeZoneNameProvider) : null,
        );
    _ref.invalidate(reminderHealthProvider);
    return plan;
  }

  Future<bool> requestPermission() => _scheduler.requestPermission();

  /// Makes sure the app may post notifications, asking the OS when needed.
  /// Returns false when the user has to allow it in the system settings.
  Future<bool> ensurePermission() async {
    if (await _scheduler.notificationsEnabled()) return true;
    final granted = await _scheduler.requestPermission();
    // Some devices report the grant only through the status query.
    final enabled = granted || await _scheduler.notificationsEnabled();
    _ref.invalidate(reminderHealthProvider);
    return enabled;
  }

  Future<bool> openSystemSettings() => _scheduler.openNotificationSettings();

  Future<bool> sendTestNotification() => _scheduler.showTestNotification();
}

final reminderCoordinatorProvider = Provider<ReminderCoordinator>(
  ReminderCoordinator.new,
);

/// Whether the last attempt to schedule reminders succeeded.
class ReminderScheduleOk extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final reminderScheduleOkProvider = NotifierProvider<ReminderScheduleOk, bool>(
  ReminderScheduleOk.new,
);

/// What the reader needs to know about their daily reminder right now.
enum ReminderHealth {
  /// The reader has not asked for reminders.
  off,

  /// Reminders are on and can be delivered.
  ok,

  /// Reminders are on, but the OS does not allow this app to notify.
  needsPermission,

  /// Allowed, but scheduling failed on this device.
  scheduleFailed,
}

final reminderHealthProvider = FutureProvider<ReminderHealth>((ref) async {
  final enabled = ref.watch(settingsProvider.select((s) => s.reminder.enabled));
  if (!enabled) return ReminderHealth.off;
  final scheduledOk = ref.watch(reminderScheduleOkProvider);
  final allowed = await ref
      .read(reminderSchedulerProvider)
      .notificationsEnabled();
  if (!allowed) return ReminderHealth.needsPermission;
  return scheduledOk ? ReminderHealth.ok : ReminderHealth.scheduleFailed;
});

// External links.

abstract class LinkOpener {
  /// Returns false when the link could not be opened.
  Future<bool> open(Uri uri);
}

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
