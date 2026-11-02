import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/providers.dart';
import 'package:focus_jesus/data/models/user_settings.dart';

import '../helpers/test_app.dart';

void main() {
  const reminderOn = ReminderPreference(enabled: true, hour: 21, minute: 0);

  Future<TestApp> launch(WidgetTester tester, {required bool granted}) async {
    usePhoneSize(tester);
    final app = await TestApp.create(
      settings: onboarded().copyWith(reminder: reminderOn),
      permissionGranted: granted,
    );
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('allowed: no request, no notice, reminders scheduled', (
    tester,
  ) async {
    final app = await launch(tester, granted: true);
    expect(app.scheduler.permissionRequests, 0);
    expect(find.byKey(const ValueKey('reminder-notice')), findsNothing);
    expect(
      await app.container.read(reminderHealthProvider.future),
      ReminderHealth.ok,
    );
  });

  testWidgets(
    'reminders on but blocked by the OS: asks once at launch, then keeps a notice',
    (tester) async {
      final app = await launch(tester, granted: false);
      expect(app.scheduler.permissionRequests, 1);
      expect(find.byKey(const ValueKey('reminder-notice')), findsOneWidget);

      // The in-app request is refused again → the system settings page.
      await tester.ensureVisible(find.byKey(const ValueKey('reminder-allow')));
      await tester.tap(find.byKey(const ValueKey('reminder-allow')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('open-notification-settings')),
      );
      await tester.pumpAndSettle();
      expect(app.scheduler.settingsOpened, 1);

      // The user switches notifications on there and comes back.
      app.scheduler.enabled = true;
      await resumeApp(tester);
      expect(find.byKey(const ValueKey('reminder-notice')), findsNothing);
      expect(
        await app.container.read(reminderHealthProvider.future),
        ReminderHealth.ok,
      );
    },
  );

  testWidgets('reminders off: never asks for the permission', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(
      settings: onboarded(),
      permissionGranted: false,
    );
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(app.scheduler.permissionRequests, 0);
    expect(find.byKey(const ValueKey('reminder-notice')), findsNothing);
  });
}
