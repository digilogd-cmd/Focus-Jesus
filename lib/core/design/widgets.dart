import 'package:flutter/material.dart';

import 'tokens.dart';

/// The FOCUS JESUS wordmark: letter-spaced serif capitals.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final style = FjText.of(context).wordmark;
    return Semantics(
      label: 'FOCUS JESUS',
      excludeSemantics: true,
      child: Text(
        'FOCUS JESUS',
        style: size == null
            ? style
            : style.copyWith(fontSize: size, letterSpacing: size! * 0.175),
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
  const Hairline({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, width: width, color: FjColors.of(context).divider);
}

/// The single primary action of a screen. Quiet: flat accent fill, no shadow.
class FjPrimaryButton extends StatelessWidget {
  const FjPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: c.accent,
          disabledBackgroundColor: c.divider,
          foregroundColor: c.onAccent,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: t.button,
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Secondary action rendered as understated text.
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
        foregroundColor: c.accent,
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

/// Small letter-spaced uppercase-like label, e.g. "DAY 01", "오늘의 핵심".
class FjLabel extends StatelessWidget {
  const FjLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  static final RegExp _hangul = RegExp(r'[\uAC00-\uD7A3]');

  @override
  Widget build(BuildContext context) {
    var style = FjText.of(context).label;
    // Wide tracking suits Latin capitals ("DAY 01"); Hangul stays near-solid.
    if (_hangul.hasMatch(text)) style = style.copyWith(letterSpacing: 0.3);
    if (color != null) style = style.copyWith(color: color);
    return Text(text, style: style);
  }
}

/// A selectable option with a title and a description. Selection is shown with
/// a fine accent rule and weight, never with heavy fills.
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
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: FjMotion.of(context, FjMotion.short),
                margin: const EdgeInsets.only(top: 4, right: 14),
                width: 3,
                height: description == null ? 18 : 40,
                color: selected ? c.accent : Colors.transparent,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (selected ? t.uiStrong : t.ui).copyWith(
                        fontSize: 17,
                        color: selected
                            ? c.textPrimary
                            : c.textPrimary.withValues(alpha: 0.86),
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(description!, style: t.meta),
                    ],
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Icon(Icons.check, size: 20, color: c.accent),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider)),
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
