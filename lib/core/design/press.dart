import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

// "Publishing the Word": a Bible page is typeset, inked by a passing press
// roller, bound into a book and closed. Everything is drawn with the app's
// two inks (paper and ink) as lines and slugs: no images, no gradients.

/// Where one segment of a timeline starts and ends, in milliseconds.
class _Span {
  const _Span(this.start, this.end);

  final int start;
  final int end;

  /// Progress through this span for [ms] elapsed, 0 → 1.
  double at(double ms, [Curve curve = Curves.linear]) =>
      curve.transform(((ms - start) / (end - start)).clamp(0.0, 1.0));
}

/// A line of set type on a page: a slug in [_PageLayout] coordinates.
class _Slug {
  const _Slug(this.rect, this.order);

  /// Fraction of the page (0–1 in both axes).
  final Rect rect;

  /// Typesetting order, 0 → 1: slugs appear as the forme is set.
  final double order;
}

/// A two-column Bible page: running cross ornament, double rule, a large
/// initial and two columns of verse lines with a hairline between them.
class _PageLayout {
  _PageLayout(int seed) : slugs = _build(seed);

  final List<_Slug> slugs;

  static const double margin = 0.13;
  static const double headerBottom = 0.215;
  static const double columnGap = 0.07;
  static const int lines = 11;

  static List<_Slug> _build(int seed) {
    final random = math.Random(seed);
    const inner = 1 - 2 * margin;
    const column = (inner - columnGap) / 2;
    const top = headerBottom + 0.05;
    const bottom = 1 - margin;
    const pitch = (bottom - top) / lines;
    const thickness = pitch * 0.34;
    final out = <_Slug>[];
    final total = lines * 2;
    for (var c = 0; c < 2; c++) {
      final left = margin + c * (column + columnGap);
      for (var i = 0; i < lines; i++) {
        final y = top + i * pitch + (pitch - thickness) / 2;
        // A large initial takes the first two lines of the first column.
        final indent = c == 0 && i < 2 ? column * 0.32 : 0.0;
        // Paragraph ends leave a short last line now and then.
        final short = i == lines - 1 || random.nextDouble() < 0.12;
        final width =
            (column - indent) *
            (short
                ? 0.35 + random.nextDouble() * 0.3
                : 0.9 + random.nextDouble() * 0.1);
        out.add(
          _Slug(
            Rect.fromLTWH(left + indent, y, width, thickness),
            (c * lines + i) / total,
          ),
        );
      }
    }
    return out;
  }

  static Rect get initial {
    const inner = 1 - 2 * margin;
    const column = (inner - columnGap) / 2;
    const top = headerBottom + 0.05;
    const pitch = (1 - margin - top) / lines;
    return Rect.fromLTWH(
      margin,
      top + pitch * 0.18,
      column * 0.24,
      pitch * 1.66,
    );
  }
}

/// Paints one page into [page]: the outline, then whatever of the type has
/// been [set] (0–1, in typesetting order), with everything above
/// [printed] (0–1, a fraction of the page height) in ink and the rest still
/// grey, unprinted metal.
void _paintPage(
  Canvas canvas,
  Rect page,
  _PageLayout layout, {
  required Color ink,
  required Color metal,
  required Color paper,
  double set = 1,
  double printed = 1,
  double outline = 1,
  bool fill = true,
}) {
  if (fill) canvas.drawRect(page, Paint()..color = paper);
  final stroke = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  if (outline >= 1) {
    canvas.drawRect(page, stroke);
  } else if (outline > 0) {
    _drawPartial(canvas, Path()..addRect(page), outline, stroke);
  }
  if (set <= 0) return;

  Offset at(double x, double y) =>
      Offset(page.left + x * page.width, page.top + y * page.height);
  Rect rectOf(Rect r) =>
      Rect.fromPoints(at(r.left, r.top), at(r.right, r.bottom));
  Color colourAt(double y) => y <= printed ? ink : metal;

  // Running head: a small cross over a double rule.
  if (set > 0.02) {
    final head = Paint()
      ..color = colourAt(0.1)
      ..strokeWidth = math.max(1, page.width * 0.012);
    final c = at(0.5, 0.11);
    final arm = page.height * 0.045;
    canvas.drawLine(c.translate(0, -arm), c.translate(0, arm * 1.25), head);
    canvas.drawLine(
      c.translate(-arm * 0.7, -arm * 0.35),
      c.translate(arm * 0.7, -arm * 0.35),
      head,
    );
    final rule = Paint()
      ..color = colourAt(_PageLayout.headerBottom)
      ..strokeWidth = 1;
    for (final dy in const [0.0, 0.018]) {
      final y = _PageLayout.headerBottom - 0.02 + dy;
      canvas.drawLine(
        at(_PageLayout.margin, y),
        at(1 - _PageLayout.margin, y),
        rule,
      );
    }
  }
  // Large initial.
  if (set > 0.04) {
    canvas.drawRect(
      rectOf(_PageLayout.initial),
      Paint()..color = colourAt(_PageLayout.initial.center.dy),
    );
  }
  // Column hairline.
  final mid = 0.5;
  final hair = Paint()
    ..color = colourAt(0.6).withValues(alpha: 0.6)
    ..strokeWidth = 0.6;
  canvas.drawLine(
    at(mid, _PageLayout.headerBottom + 0.05),
    at(
      mid,
      _PageLayout.headerBottom +
          0.05 +
          (1 - _PageLayout.margin - _PageLayout.headerBottom - 0.05) * set,
    ),
    hair,
  );
  // Verse lines, each sliding in from its left edge as it is set.
  for (final slug in layout.slugs) {
    final local = ((set - slug.order) * 8).clamp(0.0, 1.0);
    if (local <= 0) continue;
    final r = rectOf(slug.rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.top, r.width * local, r.height),
        Radius.circular(r.height / 2),
      ),
      Paint()..color = colourAt(slug.rect.center.dy),
    );
  }
}

/// Strokes the first [t] (0–1) of [path]'s length.
void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
  var remaining = total * t;
  for (final PathMetric m in metrics) {
    if (remaining <= 0) break;
    final len = math.min(remaining, m.length);
    canvas.drawPath(m.extractPath(0, len), paint);
    remaining -= len;
  }
}

/// The press roller: a heavy ink bar wider than the page, with its axle ends.
void _paintRoller(Canvas canvas, Rect page, double y, Color ink, double fade) {
  if (fade <= 0) return;
  final overhang = page.width * 0.09;
  final p = Paint()
    ..color = ink.withValues(alpha: fade)
    ..strokeWidth = math.max(2.5, page.width * 0.022)
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(page.left - overhang, y),
    Offset(page.right + overhang, y),
    p,
  );
  final axle = Paint()..color = ink.withValues(alpha: fade);
  canvas.drawCircle(Offset(page.left - overhang, y), p.strokeWidth * 0.9, axle);
  canvas.drawCircle(
    Offset(page.right + overhang, y),
    p.strokeWidth * 0.9,
    axle,
  );
}

/// Front cover: solid ink, a paper border inset and a paper cross.
void _paintCover(Canvas canvas, Rect cover, Color ink, Color paper) {
  canvas.drawRect(cover, Paint()..color = ink);
  final inset = cover.width * 0.07;
  canvas.drawRect(
    cover.deflate(inset),
    Paint()
      ..color = paper.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  final cross = Paint()
    ..color = paper
    ..strokeWidth = math.max(1.5, cover.width * 0.035);
  final c = Offset(cover.center.dx, cover.top + cover.height * 0.42);
  final h = cover.height * 0.2;
  canvas.drawLine(c.translate(0, -h), c.translate(0, h * 1.3), cross);
  canvas.drawLine(
    c.translate(-h * 0.62, -h * 0.35),
    c.translate(h * 0.62, -h * 0.35),
    cross,
  );
}

/// Timeline of the opening sequence.
abstract final class _Intro {
  static const total = Duration(milliseconds: 3500);
  static const outline = _Span(0, 420);
  static const typeset = _Span(240, 980);
  static const press = _Span(920, 1580);
  static const bind = _Span(1560, 2080);
  static const close = _Span(2120, 2680);
  static const wordmark = _Span(2460, 3000);
  static const motto = _Span(2620, 3080);
  static const fade = _Span(3150, 3500);

  /// The app underneath is built from here, so its own entrance plays as
  /// the press fades away.
  static const handOver = 3150;
}

/// The opening sequence: a Bible page is typeset and printed, bound into a
/// book and closed, and the wordmark is set beneath it. Tap to skip. When
/// the OS asks to reduce motion it is skipped entirely.
class PressIntro extends StatefulWidget {
  const PressIntro({super.key, required this.onHandOver, required this.onDone});

  /// Time to build the app underneath (the press starts fading out).
  final VoidCallback onHandOver;

  /// The sequence is over (or was skipped): remove it.
  final VoidCallback onDone;

  static Duration get duration => _Intro.total;

  @override
  State<PressIntro> createState() => _PressIntroState();
}

class _PressIntroState extends State<PressIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _Intro.total,
  );
  final _PageLayout _right = _PageLayout(7);
  final _PageLayout _left = _PageLayout(19);
  bool _handedOver = false;
  bool _finished = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_tick);
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (FjMotion.reduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _controller.forward();
    }
  }

  double get _ms => _controller.value * _Intro.total.inMilliseconds;

  void _tick() {
    if (!_handedOver && _ms >= _Intro.handOver) _handOver();
  }

  void _handOver() {
    if (_handedOver) return;
    _handedOver = true;
    widget.onHandOver();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _handOver();
    _finished = true;
    widget.onDone();
  }

  /// Skips to the fade-out.
  void _skip() {
    if (_finished) return;
    final from = _Intro.fade.start / _Intro.total.inMilliseconds;
    if (_controller.value < from) _controller.value = from;
    _handOver();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colours = FjColors.of(context);
    final t = FjText.of(context);
    if (FjMotion.reduced(context)) {
      return ColoredBox(color: colours.background);
    }
    return Semantics(
      label: 'FOCUS JESUS',
      button: true,
      onTapHint: '건너뛰기',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('press-intro'),
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final ms = _ms;
            final opacity = 1 - _Intro.fade.at(ms, Curves.easeInCubic);
            final word = _Intro.wordmark.at(ms, FjMotion.emphasized);
            final motto = _Intro.motto.at(ms, FjMotion.emphasized);
            // Material: the intro sits above the navigator, where text
            // otherwise has no default style.
            return Opacity(
              opacity: opacity,
              child: Material(
                color: colours.background,
                child: SafeArea(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final pageWidth = math.min(
                          150.0,
                          math.min(box.maxWidth * 0.36, box.maxHeight * 0.2),
                        );
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomPaint(
                              size: Size(pageWidth * 2.6, pageWidth * 1.62),
                              painter: _IntroPainter(
                                ms: ms,
                                pageWidth: pageWidth,
                                right: _right,
                                left: _left,
                                ink: colours.textPrimary,
                                metal: colours.rule,
                                paper: colours.background,
                              ),
                            ),
                            SizedBox(height: pageWidth * 0.32),
                            Opacity(
                              opacity: word,
                              child: Text(
                                'FOCUS JESUS',
                                maxLines: 1,
                                softWrap: false,
                                style: t.wordmark.copyWith(
                                  fontSize: 22,
                                  letterSpacing: 22 * (0.24 + (1 - word) * 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: FjSpace.s),
                            Opacity(
                              opacity: motto,
                              child: Transform.translate(
                                offset: Offset(0, (1 - motto) * 8),
                                child: Text(
                                  'In the beginning was the Word',
                                  style: t.latinItalic.copyWith(
                                    fontSize: 15,
                                    color: colours.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IntroPainter extends CustomPainter {
  _IntroPainter({
    required this.ms,
    required this.pageWidth,
    required this.right,
    required this.left,
    required this.ink,
    required this.metal,
    required this.paper,
  });

  final double ms;
  final double pageWidth;
  final _PageLayout right;
  final _PageLayout left;
  final Color ink;
  final Color metal;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final w = pageWidth;
    final h = w * 1.36;
    final top = (size.height - h) / 2;
    final outline = _Intro.outline.at(ms, Curves.easeInOutCubic);
    final set = _Intro.typeset.at(ms, Curves.easeInOut);
    final press = _Intro.press.at(ms, Curves.easeInOutCubic);
    final bind = _Intro.bind.at(ms, FjMotion.emphasized);
    final close = _Intro.close.at(ms, Curves.easeInOutCubic);

    // Spine position: the single sheet starts centred, then slides right to
    // become the right-hand page; closing the book recentres it.
    final spine = size.width / 2 - w / 2 * (1 - bind) + w / 2 * close;

    // Page edges (the thickness of the book), under both pages.
    if (bind > 0) {
      final edge = Paint()
        ..color = metal.withValues(alpha: bind)
        ..strokeWidth = 0.8;
      for (var i = 1; i <= 3; i++) {
        final d = i * 2.4 * bind;
        final leftEdge = spine - w - d;
        final rightEdge = spine + w * (1 - close) + d * (1 - close);
        canvas.drawLine(
          Offset(leftEdge, top + h + d),
          Offset(rightEdge, top + h + d),
          edge,
        );
        canvas.drawLine(
          Offset(leftEdge, top + d),
          Offset(leftEdge, top + h + d),
          edge,
        );
        if (close < 1) {
          canvas.drawLine(
            Offset(rightEdge, top + d),
            Offset(rightEdge, top + h + d),
            edge..color = metal.withValues(alpha: bind * (1 - close)),
          );
        }
      }
    }

    // Left page unfolds from the spine, already printed.
    if (bind > 0) {
      canvas.save();
      canvas.translate(spine, 0);
      canvas.scale(bind, 1);
      _paintPage(
        canvas,
        Rect.fromLTWH(-w, top, w, h),
        left,
        ink: ink,
        metal: metal,
        paper: paper,
      );
      canvas.restore();
    }

    // Right page: typeset and printed, then turned over to close the book.
    final angle = math.pi * close;
    final cos = math.cos(angle);
    final lift = 1 + 0.07 * math.sin(angle); // a touch of perspective
    canvas.save();
    canvas.translate(spine, top + h / 2);
    canvas.scale(cos.abs() < 0.001 ? 0.001 : cos, lift);
    final page = Rect.fromLTWH(0, -h / 2, w, h);
    if (cos >= 0) {
      _paintPage(
        canvas,
        page,
        right,
        ink: ink,
        metal: metal,
        paper: paper,
        set: set,
        printed: press <= 0 ? 0 : press * 1.06,
        outline: outline,
      );
    } else {
      _paintCover(canvas, page, ink, paper);
    }
    canvas.restore();

    // The roller passes over the right page.
    if (press > 0 && bind <= 0) {
      final y = top + h * press * 1.06 - h * 0.03;
      final fade = press < 0.9 ? 1.0 : (1 - press) / 0.1;
      _paintRoller(
        canvas,
        Rect.fromLTWH(spine, top, w, h),
        y.clamp(top - 2, top + h + 2),
        ink,
        fade,
      );
    }

    // Spine, drawn down as the book is bound.
    if (bind > 0) {
      canvas.drawLine(
        Offset(spine, top),
        Offset(spine, top + h * bind),
        Paint()
          ..color = ink
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(_IntroPainter old) =>
      old.ms != ms ||
      old.pageWidth != pageWidth ||
      old.ink != ink ||
      old.paper != paper;
}

/// Shows [child] behind the opening press sequence. With [enabled] false
/// (tests, reduced motion) the child is shown straight away.
class PressIntroGate extends StatefulWidget {
  const PressIntroGate({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<PressIntroGate> createState() => _PressIntroGateState();
}

class _PressIntroGateState extends State<PressIntroGate> {
  late bool _showIntro = widget.enabled;
  late bool _showChild = !widget.enabled;

  @override
  Widget build(BuildContext context) {
    if (!_showIntro) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showChild) widget.child,
        PressIntro(
          onHandOver: () {
            if (mounted && !_showChild) setState(() => _showChild = true);
          },
          onDone: () {
            if (mounted) {
              setState(() {
                _showChild = true;
                _showIntro = false;
              });
            }
          },
        ),
      ],
    );
  }
}

/// A small open Bible above the reading: its outline is drawn, a leaf turns
/// from the right page to the left, and the lines print as it passes.
class OpenBookMark extends StatelessWidget {
  const OpenBookMark({super.key, this.width = 46, this.delay = Duration.zero});

  final double width;
  final Duration delay;

  static const Duration duration = Duration(milliseconds: 1250);

  @override
  Widget build(BuildContext context) {
    final colours = FjColors.of(context);
    return ExcludeSemantics(
      child: EntranceBuilder(
        delay: delay,
        duration: duration,
        curve: Curves.linear,
        builder: (context, t, _) => CustomPaint(
          size: Size(width, width * 0.62),
          painter: _BookMarkPainter(
            t: t,
            ink: colours.textPrimary,
            metal: colours.rule,
            paper: colours.background,
          ),
        ),
      ),
    );
  }
}

class _BookMarkPainter extends CustomPainter {
  _BookMarkPainter({
    required this.t,
    required this.ink,
    required this.metal,
    required this.paper,
  });

  final double t;
  final Color ink;
  final Color metal;
  final Color paper;

  static const outline = _Span(0, 500);
  static const turn = _Span(380, 1050);
  static const lines = _Span(520, 1250);

  @override
  void paint(Canvas canvas, Size size) {
    final ms = t * OpenBookMark.duration.inMilliseconds;
    final o = outline.at(ms, Curves.easeInOutCubic);
    final turned = turn.at(ms, Curves.easeInOutCubic);
    final inked = lines.at(ms, Curves.easeOut);
    final spine = size.width / 2;
    final pageW = size.width / 2 - 1;
    final sag = size.height * 0.1;

    // Two pages whose top edges dip towards the spine, like an open book.
    Path pagePath(double sign) => Path()
      ..moveTo(spine, sag)
      ..quadraticBezierTo(
        spine + sign * pageW * 0.5,
        -sag * 0.2,
        spine + sign * pageW,
        sag * 0.4,
      )
      ..lineTo(spine + sign * pageW, size.height - sag * 0.2)
      ..quadraticBezierTo(
        spine + sign * pageW * 0.5,
        size.height - sag * 1.2,
        spine,
        size.height,
      );
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round;
    _drawPartial(canvas, pagePath(-1), o, stroke);
    _drawPartial(canvas, pagePath(1), o, stroke);
    if (o > 0) {
      canvas.drawLine(
        Offset(spine, sag),
        Offset(spine, sag + (size.height - sag) * o),
        stroke,
      );
    }

    // Text lines on each page: grey type until the turning leaf passes,
    // then ink.
    if (inked > 0) {
      for (final sign in const [-1.0, 1.0]) {
        // The leaf sweeps right → left: right page prints first.
        final pagePrinted = sign > 0
            ? (turned * 2).clamp(0.0, 1.0)
            : (turned * 2 - 1).clamp(0.0, 1.0);
        for (var i = 0; i < 3; i++) {
          final y = size.height * (0.38 + i * 0.17);
          final len = pageW * (i == 2 ? 0.4 : 0.62) * inked;
          final start = spine + sign * pageW * 0.2;
          canvas.drawLine(
            Offset(start, y),
            Offset(start + sign * len, y),
            Paint()
              ..color = Color.lerp(metal, ink, pagePrinted)!
              ..strokeWidth = 1.2
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // The turning leaf.
    if (turned > 0 && turned < 1) {
      final angle = math.pi * turned;
      final x = spine + pageW * math.cos(angle);
      final lift = size.height * 0.08 * math.sin(angle);
      final leaf = Path()
        ..moveTo(spine, sag)
        ..lineTo(x, sag * 0.4 - lift)
        ..lineTo(x, size.height - sag * 0.2 - lift)
        ..lineTo(spine, size.height)
        ..close();
      canvas.drawPath(leaf, Paint()..color = paper);
      canvas.drawPath(leaf, stroke);
    }
  }

  @override
  bool shouldRepaint(_BookMarkPainter old) =>
      old.t != t || old.ink != ink || old.paper != paper;
}

/// Text that is typeset, then printed: each line first appears as a grey
/// slug of metal type, then a press roller sweeps down the block and leaves
/// the words in ink behind it. The real paragraph is laid out from the first
/// frame, so line breaks never move.
class PressedText extends StatelessWidget {
  const PressedText(
    this.text, {
    super.key,
    required this.style,
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle style;
  final Duration delay;

  static const Duration duration = Duration(milliseconds: 1400);
  static const _Span _set = _Span(0, 420);
  static const _Span _press = _Span(360, 1180);
  static const _Span _settle = _Span(700, 1400);

  @override
  Widget build(BuildContext context) {
    final colours = FjColors.of(context);
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final heightBehavior = DefaultTextHeightBehavior.maybeOf(context);
    final paragraph = Text(text, style: style);
    return EntranceBuilder(
      delay: delay,
      duration: duration,
      curve: Curves.linear,
      builder: (context, t, _) {
        if (t >= 1) return paragraph;
        final ms = t * duration.inMilliseconds;
        final set = _set.at(ms, Curves.easeOut);
        final press = _press.at(ms, Curves.easeInOutCubic);
        final settle = _settle.at(ms, Curves.easeOut);
        return LayoutBuilder(
          builder: (context, box) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: resolved),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              textHeightBehavior: heightBehavior,
            )..layout(maxWidth: box.maxWidth);
            final lines = painter.computeLineMetrics();
            final height = painter.height;
            painter.dispose();
            // The roller starts just above the block and runs out below it,
            // so it never rests on the last line like an underline.
            final rollerY = -6 + (height + 18) * press;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Metal type: one slug per line, set from the left.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SlugPainter(
                      lines: lines,
                      set: set,
                      printedTo: rollerY,
                      colour: colours.rule.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                // The printed paragraph, revealed down to the roller and
                // darkening from a fresh impression to full ink.
                ClipRect(
                  clipper: _TopClipper(rollerY),
                  child: Opacity(
                    opacity: 0.55 + 0.45 * settle,
                    child: paragraph,
                  ),
                ),
                // The roller.
                if (press > 0 && press < 1)
                  Positioned(
                    left: -6,
                    right: -6,
                    top: rollerY - 1.25,
                    child: Opacity(
                      // Gone by the time it clears the last line.
                      opacity: ((height + 2 - rollerY) / 6).clamp(0.0, 1.0),
                      child: Container(height: 2.5, color: colours.textPrimary),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TopClipper extends CustomClipper<Rect> {
  const _TopClipper(this.bottom);

  final double bottom;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-8, -8, size.width + 8, bottom.clamp(-8, size.height + 8));

  @override
  bool shouldReclip(_TopClipper old) => old.bottom != bottom;
}

class _SlugPainter extends CustomPainter {
  _SlugPainter({
    required this.lines,
    required this.set,
    required this.printedTo,
    required this.colour,
  });

  final List<LineMetrics> lines;
  final double set;
  final double printedTo;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colour;
    for (final (i, line) in lines.indexed) {
      final top = line.baseline - line.ascent * 0.72;
      final bottom = line.baseline + line.descent * 0.2;
      if (bottom <= printedTo) continue; // already printed over
      final local = ((set * (lines.length + 1) - i)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final rect = Rect.fromLTWH(
        line.left,
        top,
        line.width * local,
        bottom - top,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SlugPainter old) =>
      old.set != set || old.printedTo != printedTo || old.colour != colour;
}
