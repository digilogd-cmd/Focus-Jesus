import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Runs a one-shot 0 → 1 entrance and hands the eased value to [builder].
///
/// It starts on mount (after [delay]) or, with [onScreen], the first time the
/// widget scrolls into view. Content that is already above the viewport when
/// first checked (for example after the reader jumps back to a saved
/// position) is shown in its end state without animating. When the OS asks to
/// reduce motion everything is drawn in its end state immediately.
class EntranceBuilder extends StatefulWidget {
  const EntranceBuilder({
    super.key,
    required this.builder,
    this.child,
    this.delay = Duration.zero,
    this.duration = FjMotion.reveal,
    this.curve = FjMotion.emphasized,
    this.onScreen = false,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final bool onScreen;

  @override
  State<EntranceBuilder> createState() => _EntranceBuilderState();
}

class _EntranceBuilderState extends State<EntranceBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _value;
  ScrollPosition? _position;
  bool _initialised = false;
  bool _started = false;

  /// Content already in view when a screen opens waits this long, so the
  /// screen's header leads and the body follows.
  static const Duration _firstViewLead = Duration(milliseconds: 560);

  /// Fraction of the timeline spent on [_firstViewLead]; skipped when the
  /// entrance is triggered later by scrolling.
  double _leadFraction = 0;

  @override
  void initState() {
    super.initState();
    final lead = widget.onScreen ? _firstViewLead : Duration.zero;
    final total = lead + widget.delay + widget.duration;
    _controller = AnimationController(
      vsync: this,
      duration: total == Duration.zero
          ? const Duration(milliseconds: 1)
          : total,
    );
    final micros = total.inMicroseconds;
    _leadFraction = micros == 0 ? 0 : lead.inMicroseconds / micros;
    final start = micros == 0
        ? 0.0
        : (lead + widget.delay).inMicroseconds / micros;
    _value = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    if (FjMotion.reduced(context)) {
      _started = true;
      _controller.value = 1;
      return;
    }
    if (!widget.onScreen) {
      _start();
      return;
    }
    _position = Scrollable.maybeOf(context)?.position;
    if (_position == null) {
      _start();
      return;
    }
    _position!.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstCheck = true;
      _check();
      _firstCheck = false;
    });
  }

  bool _firstCheck = false;

  void _start() {
    if (_started) return;
    _started = true;
    _detach();
    // Visible on arrival: keep the lead-in. Scrolled into view: start now.
    _controller.forward(from: _firstCheck ? 0 : _leadFraction);
  }

  void _detach() {
    _position?.removeListener(_check);
    _position = null;
  }

  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (box is! RenderBox ||
        viewport is! RenderBox ||
        !box.hasSize ||
        !box.attached) {
      _start();
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    if (top + box.size.height < 0) {
      // Scrolled past before it was ever seen: no entrance to replay.
      _started = true;
      _detach();
      _controller.value = 1;
      return;
    }
    if (top < viewport.size.height * 0.94) _start();
  }

  @override
  void dispose() {
    _detach();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _value,
    builder: (context, child) => widget.builder(context, _value.value, child),
    child: widget.child,
  );
}

/// Fades in while rising a few pixels — the default entrance for blocks.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.onScreen = false,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final bool onScreen;
  final double offset;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
    delay: delay,
    onScreen: onScreen,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - t) * offset),
        child: child,
      ),
    ),
  );
}

/// Type rises out of an invisible baseline mask, like a title card.
class MaskRise extends StatelessWidget {
  const MaskRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.onScreen = false,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final Duration delay;
  final bool onScreen;
  final Duration duration;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
    delay: delay,
    onScreen: onScreen,
    duration: duration,
    child: child,
    builder: (context, t, child) => ClipRect(
      child: FractionalTranslation(translation: Offset(0, 1 - t), child: child),
    ),
  );
}

/// Text whose words ink in one after another. Layout is a single paragraph
/// from the first frame, so line breaks never jump while it animates.
class InkText extends StatelessWidget {
  const InkText(
    this.text, {
    super.key,
    required this.style,
    this.delay = Duration.zero,
    this.onScreen = false,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Duration delay;
  final bool onScreen;
  final TextAlign? textAlign;

  static const Duration _wordFade = Duration(milliseconds: 420);
  static final RegExp _split = RegExp(r'(\s+)');

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    text.splitMapJoin(
      _split,
      onMatch: (m) {
        parts.add(m[0]!);
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) parts.add(s);
        return '';
      },
    );
    final words = parts.where((p) => p.trim().isNotEmpty).length;
    // Long sentences ink in faster so the whole line lands within ~1.4s.
    final step = math.min(55, 980 ~/ math.max(words, 1));
    final total = Duration(
      milliseconds: _wordFade.inMilliseconds + step * math.max(words - 1, 0),
    );
    final base = style.color ?? DefaultTextStyle.of(context).style.color!;
    final baseAlpha = base.a;

    return EntranceBuilder(
      delay: delay,
      duration: total,
      curve: Curves.linear,
      onScreen: onScreen,
      builder: (context, t, _) {
        final elapsed = t * total.inMilliseconds;
        var index = 0;
        final spans = <TextSpan>[];
        for (final part in parts) {
          if (part.trim().isEmpty) {
            spans.add(TextSpan(text: part));
            continue;
          }
          final local = ((elapsed - index * step) / _wordFade.inMilliseconds)
              .clamp(0.0, 1.0);
          index++;
          final a = Curves.easeOut.transform(local);
          spans.add(
            TextSpan(
              text: part,
              style: a >= 1
                  ? null
                  : TextStyle(color: base.withValues(alpha: baseAlpha * a)),
            ),
          );
        }
        return Text.rich(
          TextSpan(children: spans),
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}

/// A rule that draws itself from the leading edge (or downward when
/// [vertical]). With no [length] it spans the available width.
class DrawnRule extends StatelessWidget {
  const DrawnRule({
    super.key,
    this.length,
    this.thickness = 1,
    this.color,
    this.delay = Duration.zero,
    this.onScreen = false,
    this.vertical = false,
    this.duration = const Duration(milliseconds: 1000),
  });

  final double? length;
  final double thickness;
  final Color? color;
  final Duration delay;
  final bool onScreen;
  final bool vertical;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = color ?? FjColors.of(context).rule;
    return EntranceBuilder(
      delay: delay,
      onScreen: onScreen,
      duration: duration,
      builder: (context, t, _) {
        if (vertical) {
          return SizedBox(
            width: thickness,
            height: length,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: t,
                widthFactor: 1,
                child: ColoredBox(color: c),
              ),
            ),
          );
        }
        return SizedBox(
          width: length ?? double.infinity,
          height: thickness,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: t,
              heightFactor: 1,
              child: ColoredBox(color: c),
            ),
          ),
        );
      },
    );
  }
}

/// A whole number that counts up to [value], zero-padded to [digits].
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.digits = 2,
    this.delay = Duration.zero,
    this.from = 0,
  });

  final int value;
  final int from;
  final TextStyle style;
  final int digits;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final label = '$value'.padLeft(digits, '0');
    return Semantics(
      label: '$value',
      excludeSemantics: true,
      child: EntranceBuilder(
        delay: delay,
        duration: Duration(
          milliseconds: 300 + 90 * (value - from).abs().clamp(0, 8),
        ),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final n = (from + (value - from) * t).round();
          // Reserve the final width so neighbours never shift while counting.
          return Stack(
            children: [
              Opacity(opacity: 0, child: Text(label, style: style)),
              Text('$n'.padLeft(digits, '0'), style: style),
            ],
          );
        },
      ),
    );
  }
}

/// Page transition: the incoming page lifts in from slightly below while
/// the outgoing page dims back — paper being turned forward.
class FjPageTransitionsBuilder extends PageTransitionsBuilder {
  const FjPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (FjMotion.reduced(context)) return child;
    final enter = CurvedAnimation(
      parent: animation,
      curve: FjMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.0,
      ).animate(CurvedAnimation(parent: exit, curve: const Interval(0, 0.6))),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.02),
        ).animate(exit),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.7, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}
