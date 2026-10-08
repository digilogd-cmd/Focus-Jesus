import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/journey/journey_screen.dart';
import '../features/journey/season_complete_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reader/completion_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/continue_screen.dart';
import '../features/today/today_screen.dart';
import 'home_shell.dart';
import 'providers.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const journey = '/journey';
  static const settings = '/settings';
  static const continueReading = '/continue';
  static const seasonComplete = '/season-complete';

  static String read(String chapterId) => '/read/$chapterId';
  static String done(String chapterId) => '/read/$chapterId/done';
}

/// Notifies go_router when onboarding state flips.
class _OnboardingListenable extends ChangeNotifier {
  _OnboardingListenable(Ref ref) {
    ref.listen(
      settingsProvider.select((s) => s.onboardingComplete),
      (_, _) => notifyListeners(),
    );
  }
}

final initialLocationProvider = Provider<String>((ref) => Routes.today);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _OnboardingListenable(ref);
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    initialLocation: ref.read(initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final onboarded = ref.read(settingsProvider).onboardingComplete;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.today),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.continueReading,
        builder: (_, _) => const ContinueScreen(),
      ),
      GoRoute(
        path: Routes.seasonComplete,
        builder: (_, _) => const SeasonCompleteScreen(),
      ),
      GoRoute(
        path: '/read/:chapterId',
        builder: (_, state) =>
            ReaderScreen(chapterId: state.pathParameters['chapterId']!),
        routes: [
          GoRoute(
            path: 'done',
            builder: (_, state) =>
                CompletionScreen(chapterId: state.pathParameters['chapterId']!),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (_, _) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.journey,
                builder: (_, _) => const JourneyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
