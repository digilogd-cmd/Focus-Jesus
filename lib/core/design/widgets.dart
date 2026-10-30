import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// The FOCUS JESUS wordmark: tracked Latin serif capitals. With [animate]
/// the letters gather in from wide tracking, like a title card settling.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size, this.animate = false});

  final double? size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final base = FjText.of(context).wordmark;
    final fontSize = size ?? base.fontSize!;
    final style = base.copyWith(fontSize: fontSize);
    Widget text(double tracking, double opacity) => Opacity(
      opacity: opacity,
      child: Text(
        'FOCUS JESUS',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: style.copyWith(letterSpacing: fontSize * tracking),
      ),
    );
    return Semantics(
      label: 'FOCUS JESUS',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: animate
            ? EntranceBuilder(
                duration: const Duration(milliseconds: 1400),
                builder: (context, t, _) =>
                    text(0.24 + (1 - t) * 0.5, t.clamp(0.0, 1.0)),
              )
            : text(0.24, 1),
      ),
    );
  }
}

/// Centres content in a comfortable reading measure with side gutters.
class ReadingColumn extends StatelessWidget {
  const ReadingColumn({
    super.key,
    required this.child,
    this.maxWidth = FjSpace.readingMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + FjSpace.gutter * 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FjSpace.gutter),
          child: child,
        ),
      ),
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.width, this.strong = false});

  final double? width;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    return Container(
      height: strong ? 1 : 0.8,
      width: width,
      color: strong ? c.rule : c.divider,
    );
  }
}

/// The single primary action of a screen: an ink slab with paper type and a
/// small arrow that leans forward while pressed.
class FjPrimaryButton extends StatefulWidget {
  const FjPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<FjPrimaryButton> createState() => _FjPrimaryButtonState();
}

class _FjPrimaryButtonState extends State<FjPrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onPressed == null || v == _pressed) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final d = FjMotion.of(context, FjMotion.short);
    final enabled = widget.onPressed != null;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: d,
        curve: FjMotion.curve,
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              backgroundColor: c.accent,
              disabledBackgroundColor: c.divider,
              foregroundColor: c.onAccent,
              disabledForegroundColor: c.textSecondary,
              overlayColor: c.onAccent,
              minimumSize: const Size.fromHeight(58),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: t.button,
            ),
            child: Row(
              children: [
                const SizedBox(width: 22),
                Expanded(
                  child: Text(widget.label, textAlign: TextAlign.center),
                ),
                AnimatedSlide(
                  offset: Offset(_pressed ? 0.25 : 0, 0),
                  duration: d,
                  curve: FjMotion.curve,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 22,
                      child: Text(
                        '→',
                        textAlign: TextAlign.end,
                        style: t.button.copyWith(
                          fontFamily: FjFonts.latin,
                          fontSize: 20,
                          color: enabled ? c.onAccent : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action rendered as understated ink text.
class FjQuietButton extends StatelessWidget {
  const FjQuietButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.alignment = Alignment.center,
    this.trailingArrow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Alignment alignment;
  final bool trailingArrow;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c.textPrimary,
        overlayColor: c.textPrimary,
        minimumSize: const Size(FjSpace.minTouchTarget, FjSpace.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.padded,
        alignment: alignment,
        textStyle: t.uiStrong.copyWith(fontSize: 15),
      ),
      child: Text(trailingArrow ? '$label  →' : label),
    );
    // A centred action hugs its label; a left-aligned one ("다음 이야기 읽기 →")
    // spans the row so the whole line is the touch target.
    if (alignment == Alignment.center) return Center(child: button);
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Small label, e.g. "DAY 01", "오늘의 핵심". Latin is tracked wide; Hangul
/// stays solid.
class FjLabel extends StatelessWidget {
  const FjLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  static final RegExp _hangul = RegExp(r'[가-힣]');

  @override
  Widget build(BuildContext context) {
    var style = FjText.of(context).label;
    if (_hangul.hasMatch(text)) {
      style = style.copyWith(letterSpacing: 0, fontSize: 12);
    }
    if (color != null) style = style.copyWith(color: color);
    return Text(text, style: style);
  }
}

/// Section label pairing tracked English capitals with the Korean name:
/// "KEY MESSAGE  오늘의 핵심".
class FjDualLabel extends StatelessWidget {
  const FjDualLabel(this.en, this.ko, {super.key, this.color});

  final String en;
  final String ko;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final style = FjText.of(context).label.copyWith(color: color);
    return Semantics(
      header: true,
      label: ko,
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 2,
        children: [
          Text(en, style: style.copyWith(color: color ?? c.textPrimary)),
          Text(
            ko,
            style: style.copyWith(
              letterSpacing: 0,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen title: oversized Korean serif under a dual label, rising into frame.
class FjScreenTitle extends StatelessWidget {
  const FjScreenTitle({
    super.key,
    required this.en,
    required this.title,
    this.titleKey,
  });

  final String en;
  final String title;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: FjLabel(en)),
        const SizedBox(height: FjSpace.s),
        MaskRise(
          delay: const Duration(milliseconds: 80),
          child: Text(
            title,
            key: titleKey,
            style: t.displayTitle.copyWith(fontSize: 36, height: 1.25),
          ),
        ),
        const SizedBox(height: FjSpace.m),
        const DrawnRule(delay: Duration(milliseconds: 200)),
      ],
    );
  }
}

/// A selectable option with a title and a description. Selection is a small
/// ink dot and weight — never a heavy fill.
class FjOptionTile extends StatelessWidget {
  const FjOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final d = FjMotion.of(context, FjMotion.medium);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider, width: 0.8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedSlide(
                  offset: Offset(selected ? 0.012 : 0, 0),
                  duration: d,
                  curve: FjMotion.curve,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: d,
                        style: (selected ? t.uiStrong : t.ui).copyWith(
                          fontSize: 17,
                          color: selected ? c.textPrimary : c.inkSoft,
                        ),
                        child: Text(title),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(description!, style: t.meta),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? c.textPrimary : c.rule,
                      width: 1,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: d,
                    curve: FjMotion.emphasized,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A settings row: label on the left, value on the right.
class FjListRow extends StatelessWidget {
  const FjListRow({
    super.key,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  final String title;
  final String? value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    // MergeSemantics: a trailing switch is announced together with its title
    // ("매일 읽기 알림, 스위치, 켜짐") instead of as an unlabeled control.
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider, width: 0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: t.ui),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: t.meta),
                    ],
                  ],
                ),
              ),
              if (value != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      value!,
                      style: t.ui.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
