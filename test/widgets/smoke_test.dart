import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_jesus/core/design/korean_text.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('app boots to today screen', (tester) async {
    usePhoneSize(tester);
    final app = await TestApp.create(settings: onboarded());
    addTearDown(app.dispose);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-title')), findsOneWidget);
    expect(find.text(keepAll('세상은 왜 창조되었을까?')), findsOneWidget);
  });
}
