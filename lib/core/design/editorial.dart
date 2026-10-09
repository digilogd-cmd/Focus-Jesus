import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// The oversized day number ("01") with a small "/07" — the app's main
/// graphic. The digits rise out of a mask.
class DayNumeral extends StatelessWidget {
  const DayNumeral({
    super.key,
    required this.day,
    this.of,
    this.size = 120,
    this.delay = Duration.zero,
    this.onScreen = false,
  });

  final int day;
  final int? of;
  final double size;
  final Duration delay;
  final bool onScreen;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final numeral = t.numeral.copyWith(fontSize: size);
    // Decorative: capped at 1.2x system text size (the label carries the
    // meaning for screen readers) and shrunk to fit narrow screens.
    return Semantics(
      label: of == null ? '$day일째' : '$of일 중 $day일째',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MaskRise(
                delay: delay,
                onScreen: onScreen,
                child: Text('$day'.padLeft(2, '0'), style: numeral),
              ),
              if (of != null) ...[
                const SizedBox(width: 6),
                Reveal(
                  delay: delay + const Duration(milliseconds: 380),
                  onScreen: onScreen,
                  offset: 8,
                  child: Text(
                    '/ ${'$of'.padLeft(2, '0')}',
                    style: t.latinItalic.copyWith(
                      fontSize: size * 0.2,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of thin segments, one per story; read ones fill with ink in turn.
class SeasonProgress extends StatelessWidget {
  const SeasonProgress({
    super.key,
    required this.total,
    required this.done,
    this.delay = Duration.zero,
  });

  final int total;
  final int done;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    return Semantics(
      label: '$total개 중 $done개 읽음',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Stack(
                children: [
                  Container(height: 2, color: c.divider),
                  if (i < done)
                    DrawnRule(
                      thickness: 2,
                      color: c.textPrimary,
                      duration: const Duration(milliseconds: 520),
                      delay: delay + FjMotion.stagger * i,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A pulled sentence: a rule draws down the left edge while the words ink in.
class PullQuote extends StatelessWidget {
  const PullQuote({
    super.key,
    required this.text,
    required this.style,
    this.textKey,
    this.onScreen = false,
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle style;
  final Key? textKey;
  final bool onScreen;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    // The rule is positioned against the text, so it always matches its
    // height without a second (intrinsic) layout pass.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: FjSpace.m + 3.5),
          child: InkText(
            text,
            key: textKey,
            style: style,
            onScreen: onScreen,
            delay: delay + const Duration(milliseconds: 160),
          ),
        ),
        Positioned(
          left: 0,
          top: 4,
          bottom: 4,
          child: DrawnRule(
            vertical: true,
            thickness: 1.5,
            color: c.textPrimary,
            onScreen: onScreen,
            delay: delay,
          ),
        ),
      ],
    );
  }
}
