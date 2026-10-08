import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/notifications/reminder_planner.dart';
import '../core/notifications/reminder_scheduler.dart';
import '../core/time/clock.dart';
import '../data/content/content_repository.dart';
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

final seasonProvider = Provider<Season>(
  (ref) => throw UnimplementedError('seasonProvider must be overridden'),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) =>
      throw UnimplementedError('reminderSchedulerProvider must be overridden'),
);

/// IANA zone in use, recorded with completions. Null when unknown.
final timeZoneNameProvider = Provider<String?>((ref) => null);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

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
  final season = ref.watch(seasonProvider);
  final journey = ref.watch(journeyProvider).value ?? JourneySnapshot.empty;
  return planToday(
    orderedIds: season.orderedIds,
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

  Future<ReminderPlan> sync() async {
    final settings = _ref.read(settingsProvider);
    final journey = await _ref.read(journeyProvider.future);
    final now = _ref.read(clockProvider).now();
    final plan = planReminders(
      now: now,
      preference: settings.reminder,
      finishedToday: journey.chaptersOn(LocalDate.of(now)).isNotEmpty,
    );
    await _ref.read(reminderSchedulerProvider).apply(plan);
    await _ref
        .read(settingsRepositoryProvider)
        .setScheduledTimeZone(
          plan.enabled ? _ref.read(timeZoneNameProvider) : null,
        );
    return plan;
  }

  Future<bool> requestPermission() =>
      _ref.read(reminderSchedulerProvider).requestPermission();
}

final reminderCoordinatorProvider = Provider<ReminderCoordinator>(
  ReminderCoordinator.new,
);

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
