import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/app/bootstrap.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/data/content/program.dart';
import 'package:focus_jesus/core/notifications/reminder_scheduler.dart';
import 'package:focus_jesus/core/storage/app_database.dart';
import 'package:focus_jesus/core/time/clock.dart';
import 'package:focus_jesus/data/content/chapter.dart';
import 'package:focus_jesus/data/content/curriculum.dart';
import 'package:focus_jesus/data/models/user_settings.dart';
import 'package:focus_jesus/data/repositories/settings_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String contentDir = 'assets/content';
const String seasonDir = '$contentDir/season1';

/// The real bundled program (all season outlines) straight from disk.
Program loadProgramFromDisk() {
  final json = jsonDecode(
    File('$contentDir/program.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return Program.fromJson(
    json,
    curriculumFor: (path) {
      final f = File('$contentDir/$path/curriculum.json');
      if (!f.existsSync()) return null;
      return Curriculum.fromJson(
        jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
      );
    },
  );
}

/// Reads manuscripts synchronously from disk (completes inside fake async).
ChapterStore diskChapterStore(Program program) => ChapterStore(
  program,
  (path) => Future.value(File(path).readAsStringSync()),
);

/// Every readable chapter of the year, parsed (for content tests).
List<Chapter> loadAllChaptersFromDisk([Program? program]) {
  final p = program ?? loadProgramFromDisk();
  return [
    for (final d in p.availableDays)
      Chapter.fromJson(
        jsonDecode(File(d.assetPath!).readAsStringSync())
            as Map<String, Object?>,
        path: d.assetPath!,
      ),
  ];
}

/// One season as files on disk: its outline and readable chapters.
class DiskSeason {
  DiskSeason(this.curriculum, this.chapters);

  final Curriculum curriculum;
  final List<Chapter> chapters;

  Chapter? chapterById(String id) =>
      chapters.where((c) => c.id == id).firstOrNull;

  bool get isComplete => curriculum.days.every((d) => d.isAvailable);
}

DiskSeason loadSeasonFromDisk([int number = 1]) {
  final program = loadProgramFromDisk();
  final season = program.seasonByNumber(number)!;
  return DiskSeason(season.curriculum!, [
    for (final d in program.daysOf(season))
      if (d.isAvailable)
        Chapter.fromJson(
          jsonDecode(File(d.assetPath!).readAsStringSync())
              as Map<String, Object?>,
          path: d.assetPath!,
        ),
  ]);
}

/// Season 1's chapters (DAY 01–30), parsed.
List<Chapter> loadSeasonOneFromDisk() =>
    loadAllChaptersFromDisk().where((c) => c.seasonId == 's1').toList();

Chapter loadChapter(int day) => loadSeasonOneFromDisk()[day - 1];

/// A fresh in-memory database with the production schema.
Future<Database> openTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase.open(
    databaseFactoryFfiNoIsolate,
    inMemoryDatabasePath,
    singleInstance: false,
  );
}

bool _fontsLoaded = false;

/// Loads the bundled fonts so text renders with real glyphs (screenshots).
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('NotoSerifKR', [
    'NotoSerifKR-Regular.ttf',
    'NotoSerifKR-SemiBold.ttf',
  ]);
  await load('Pretendard', [
    'Pretendard-Regular.otf',
    'Pretendard-Medium.otf',
    'Pretendard-SemiBold.otf',
  ]);
  await load('CormorantGaramond', [
    'CormorantGaramond-Regular.ttf',
    'CormorantGaramond-Medium.ttf',
    'CormorantGaramond-SemiBold.ttf',
    'CormorantGaramond-Italic.ttf',
  ]);
  // Material icons for back/chevron glyphs.
  final iconFont = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (iconFont.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(iconFont.readAsBytesSync().buffer)));
    await loader.load();
  }
  _fontsLoaded = true;
}

class FakeLinkOpener implements LinkOpener {
  FakeLinkOpener({this.succeed = true});

  bool succeed;
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeed;
  }
}

class TestApp {
  TestApp._(
    this.container,
    this.clock,
    this.scheduler,
    this.links,
    this.database,
  );

  final ProviderContainer container;
  final FixedClock clock;
  final RecordingReminderScheduler scheduler;
  final FakeLinkOpener links;
  final Database database;

  /// Builds the real app with test doubles only at the system edges
  /// (clock, notifications, URL launcher). Storage is a real SQLite database.
  static Future<TestApp> create({
    UserSettings? settings,
    DateTime? now,
    bool permissionGranted = true,
    bool linkSucceeds = true,
    Database? database,
    Map<String, Object> preferences = const {},
    bool launchedFromReminder = false,
    Future<String?> Function()? timeZoneRefresher,
  }) async {
    await initializeDateFormatting('ko_KR');
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    if (settings != null) await SettingsRepository(prefs).save(settings);
    final db = database ?? await openTestDatabase();
    final clock = FixedClock(now ?? DateTime(2026, 10, 6, 8, 0));
    final program = loadProgramFromDisk();
    final scheduler = RecordingReminderScheduler(
      permissionGranted: permissionGranted,
    );
    final links = FakeLinkOpener(succeed: linkSucceeds);
    final container = await createAppContainer(
      AppDependencies(
        database: db,
        preferences: prefs,
        program: program,
        chapters: diskChapterStore(program),
        scheduler: scheduler,
        timeZoneName: 'Asia/Seoul',
        clock: clock,
        linkOpener: links,
        launchedFromReminder: launchedFromReminder,
        timeZoneRefresher: timeZoneRefresher,
      ),
    );
    return TestApp._(container, clock, scheduler, links, db);
  }

  Widget get widget => UncontrolledProviderScope(
    container: container,
    child: const FocusJesusApp(),
  );

  void dispose() {
    container.dispose();
    database.close();
  }
}

UserSettings onboarded({ThemePreference theme = ThemePreference.light}) =>
    UserSettings.defaults.copyWith(onboardingComplete: true, theme: theme);

/// Sets a phone-like surface size for the duration of a test.
void usePhoneSize(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double dpr = 3,
}) {
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// Drives the lifecycle through background → foreground, like a user
/// switching away and coming back.
Future<void> resumeApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}
