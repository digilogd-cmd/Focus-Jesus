// Runs in a NEW process after app_test.dart: proves the data written there
// survived a real application restart (not just an in-process rebuild).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/app.dart';
import 'package:focus_jesus/app/bootstrap.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/data/models/reading_preferences.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('after a real restart, progress, settings and notes are intact', (
    tester,
  ) async {
    final container = await createAppContainer(await loadAppDependencies());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FocusJesusApp(),
      ),
    );
    await tester.pumpAndSettle();

    final settings = container.read(settingsProvider);
    expect(
      settings.onboardingComplete,
      isTrue,
      reason: 'no onboarding again after restart',
    );
    expect(settings.minutes, ReadingMinutes.five);
    final journey = container.read(journeyProvider).value!;
    expect(journey.completedChapterIds, {'s1-d01', 's1-d02'});
    expect(
      await container.read(reflectionRepositoryProvider).loadNotes('s1-d01'),
      {0: '세상은 우연이 아니라 뜻으로 지어졌다'},
    );
    expect(
      find.byKey(const ValueKey('today-title')).evaluate().isNotEmpty ||
          find.byKey(const ValueKey('today-done')).evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('7개의 이야기 중 2개를 읽었습니다.'), findsOneWidget);
  });
}
