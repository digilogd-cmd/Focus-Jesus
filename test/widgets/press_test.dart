import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/app/theme.dart';
import 'package:focus_jesus/core/design/press.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: buildTheme(Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  group('opening press', () {
    testWidgets('plays through, hands over, then finishes', (tester) async {
      var handedOver = 0;
      var done = 0;
      await tester.pumpWidget(
        _app(PressIntro(onHandOver: () => handedOver++, onDone: () => done++)),
      );
      expect(find.byKey(const ValueKey('press-intro')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      expect((handedOver, done), (0, 0), reason: 'still printing');
      await tester.pump(const Duration(milliseconds: 1800));
      expect((handedOver, done), (1, 0), reason: 'fading out');
      await tester.pumpAndSettle();
      expect((handedOver, done), (1, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap skips to the fade-out', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _app(PressIntro(onHandOver: () {}, onDone: () => done++)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('press-intro')));
      // The fade is the last 350ms of the sequence; the restarted
      // animation takes its first tick on the next frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(done, 1);
    });

    testWidgets('reduced motion skips it entirely', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _app(
          PressIntro(onHandOver: () {}, onDone: () => done++),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(done, 1);
    });

    testWidgets('the gate builds the app only once the press hands over', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const PressIntroGate(enabled: true, child: Text('HOME'))),
      );
      expect(find.text('HOME'), findsNothing);
      await tester.pump(const Duration(milliseconds: 3200));
      expect(find.text('HOME'), findsOneWidget, reason: 'built under the fade');
      expect(find.byType(PressIntro), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(PressIntro), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('a disabled gate shows the app straight away', (tester) async {
      await tester.pumpWidget(
        _app(const PressIntroGate(enabled: false, child: Text('HOME'))),
      );
      expect(find.text('HOME'), findsOneWidget);
      expect(find.byType(PressIntro), findsNothing);
    });

    testWidgets('fits a small phone with large text', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: PressIntro(onHandOver: () {}, onDone: () {}),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('printed title', () {
    const title = '세상은 왜 창조되었을까?';

    testWidgets('is typeset, printed, and ends as plain text', (tester) async {
      await tester.pumpWidget(
        _app(
          const PressedText(
            title,
            key: ValueKey('t'),
            style: TextStyle(fontSize: 29),
          ),
        ),
      );
      // The real paragraph is in the tree from the first frame (it is only
      // clipped while the roller passes), so readers and tests find it.
      expect(find.text(title), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('t')),
          matching: find.byType(ClipRect),
        ),
        findsOneWidget,
        reason: 'mid-press',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('t')),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('reduced motion prints it at once', (tester) async {
      await tester.pumpWidget(
        _app(
          const PressedText(
            title,
            key: ValueKey('t'),
            style: TextStyle(fontSize: 29),
          ),
          reduceMotion: true,
        ),
      );
      expect(find.text(title), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('t')),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('the open book mark draws and settles', (tester) async {
    await tester.pumpWidget(_app(const Center(child: OpenBookMark())));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
