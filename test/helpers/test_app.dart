import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/app/bootstrap.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/core/notifications/reminder_scheduler.dart';
import 'package:focus_jesus/core/storage/app_database.dart';
import 'package:focus_jesus/core/time/clock.dart';
import 'package:focus_jesus/data/content/chapter.dart';
import 'package:focus_jesus/data/content/content_repository.dart';
import 'package:focus_jesus/data/content/curriculum.dart';
import 'package:focus_jesus/data/models/user_settings.dart';
import 'package:focus_jesus/data/repositories/settings_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String seasonDir = 'assets/content/season1';

/// Loads the real bundled season straight from disk.
Season loadSeasonFromDisk() {
  final curriculum = Curriculum.fromJson(
    jsonDecode(File('$seasonDir/curriculum.json').readAsStringSync())
        as Map<String, Object?>,
  );
  final chapters = [
    for (final d in curriculum.availableDays)
      Chapter.fromJson(
        jsonDecode(File('$seasonDir/${d.file}').readAsStringSync())
            as Map<String, Object?>,
        path: d.file!,
      ),
  ];
  return Season(curriculum: curriculum, chapters: chapters);
}

Chapter loadChapter(int day) => loadSeasonFromDisk().chapters[day - 1];

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
  }) async {
    await initializeDateFormatting('ko_KR');
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    if (settings != null) await SettingsRepository(prefs).save(settings);
    final db = database ?? await openTestDatabase();
    final clock = FixedClock(now ?? DateTime(2026, 10, 6, 8, 0));
    final scheduler = RecordingReminderScheduler(
      permissionGranted: permissionGranted,
    );
    final links = FakeLinkOpener(succeed: linkSucceeds);
    final container = await createAppContainer(
      AppDependencies(
        database: db,
        preferences: prefs,
        season: loadSeasonFromDisk(),
        scheduler: scheduler,
        timeZoneName: 'Asia/Seoul',
        clock: clock,
        linkOpener: links,
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
