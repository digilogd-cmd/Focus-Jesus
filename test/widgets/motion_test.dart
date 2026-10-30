import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_jesus/core/design/motion.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF171714), fontSize: 16),
      child: child,
    ),
  ),
);

double _opacityOf(WidgetTester tester, Finder child) => tester
    .widget<Opacity>(find.ancestor(of: child, matching: find.byType(Opacity)))
    .opacity;

/// Alpha of every span of the first rich text under [finder].
List<double> _spanAlphas(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(
    find.descendant(of: finder, matching: find.byType(Text)).first,
  );
  final alphas = <double>[];
  text.textSpan!.visitChildren((span) {
    final color = span.style?.color;
    if ((span as TextSpan).text?.trim().isNotEmpty ?? false) {
      alphas.add(color?.a ?? 1);
    }
    return true;
  });
  return alphas;
}

void main() {
  testWidgets('Reveal starts hidden and ends fully visible', (tester) async {
    await tester.pumpWidget(_host(const Reveal(child: Text('본문'))));
    expect(_opacityOf(tester, find.text('본문')), 0);
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, find.text('본문')), 1);
  });

  testWidgets('reduced motion draws every entrance in its end state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Reveal(delay: Duration(seconds: 2), child: Text('본문')),
            InkText('하나 둘 셋', key: ValueKey('ink'), style: TextStyle()),
          ],
        ),
        reduceMotion: true,
      ),
    );
    // No pump: the very first frame must already be final.
    expect(_opacityOf(tester, find.text('본문')), 1);
    expect(_spanAlphas(tester, find.byKey(const ValueKey('ink'))), [1, 1, 1]);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('InkText inks words in order and finishes at full colour', (
    tester,
  ) async {
    const key = ValueKey('ink');
    await tester.pumpWidget(
      _host(const InkText('하나 둘 셋 넷', key: key, style: TextStyle())),
    );
    await tester.pump(const Duration(milliseconds: 120));
    final mid = _spanAlphas(tester, find.byKey(key));
    expect(mid.first, greaterThan(mid.last), reason: 'earlier words lead');
    await tester.pumpAndSettle();
    expect(_spanAlphas(tester, find.byKey(key)), [1, 1, 1, 1]);
    // Plain-text lookup keeps working for the composed paragraph.
    expect(find.text('하나 둘 셋 넷'), findsOneWidget);
  });

  testWidgets('DrawnRule ends at its full length', (tester) async {
    await tester.pumpWidget(
      _host(const Center(child: DrawnRule(length: 120, thickness: 2))),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ColoredBox)), const Size(120, 2));
  });

  testWidgets(
    'onScreen content waits for the viewport and skips content already passed',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 600,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  const Reveal(onScreen: true, child: Text('top')),
                  const SizedBox(height: 1400),
                  const Reveal(onScreen: true, child: Text('bottom')),
                  const SizedBox(height: 1400),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, find.text('top')), 1);
      // Far below the fold: not started yet.
      expect(_opacityOf(tester, find.text('bottom')), 0);

      controller.jumpTo(1000);
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, find.text('bottom')), 1);
    },
  );

  testWidgets('a jump past unseen content shows it without replaying', (
    tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 2000);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 600,
          child: SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: [
                SizedBox(height: 200),
                Reveal(onScreen: true, child: Text('passed')),
                SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(_opacityOf(tester, find.text('passed')), 1);
  });
}
