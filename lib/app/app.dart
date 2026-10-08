import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_settings.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class FocusJesusApp extends ConsumerStatefulWidget {
  const FocusJesusApp({super.key});

  @override
  ConsumerState<FocusJesusApp> createState() => _FocusJesusAppState();
}

class _FocusJesusAppState extends ConsumerState<FocusJesusApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  /// Returning to the app may cross midnight or a time-zone change: refresh
  /// date-based views and re-plan reminders.
  Future<void> _onResume() async {
    // Read everything before the first await: the app may be torn down while
    // the zone lookup is in flight, and `ref` is unusable after that.
    final timeZone = ref.read(timeZoneNameProvider.notifier);
    final dayTick = ref.read(dayTickProvider.notifier);
    final reminders = ref.read(reminderCoordinatorProvider);
    await timeZone.refresh();
    if (!mounted) return;
    dayTick.bump();
    await reminders.sync();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp.router(
      title: 'FOCUS JESUS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
