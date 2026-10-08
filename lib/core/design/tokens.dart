import 'package:flutter/material.dart';

/// Colour tokens. Colour is reserved for meaning; everything else is ink on paper.
@immutable
class FjColors extends ThemeExtension<FjColors> {
  const FjColors({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.divider,
    required this.surface,
    required this.onAccent,
  });

  static const FjColors light = FjColors(
    background: Color(0xFFF8F7F3),
    textPrimary: Color(0xFF202722),
    // Spec value #707770 gives 4.29:1 on the background, below WCAG AA (4.5:1)
    // for the small meta text that uses it. Same hue, minimally darkened.
    // To restore the exact spec value, change this line back to 0xFF707770.
    textSecondary: Color(0xFF6B726B),
    accent: Color(0xFF365B4C),
    divider: Color(0xFFE5E6DF),
    surface: Color(0xFFFFFFFF),
    onAccent: Color(0xFFF8F7F3),
  );

  static const FjColors dark = FjColors(
    background: Color(0xFF171D1A),
    textPrimary: Color(0xFFECEFE9),
    textSecondary: Color(0xFFA2ABA3),
    accent: Color(0xFFADC5B5),
    divider: Color(0xFF343D36),
    surface: Color(0xFF202823),
    onAccent: Color(0xFF171D1A),
  );

  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color divider;
  final Color surface;

  /// Text on an accent fill.
  final Color onAccent;

  static FjColors of(BuildContext context) =>
      Theme.of(context).extension<FjColors>() ?? light;

  @override
  FjColors copyWith({
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? divider,
    Color? surface,
    Color? onAccent,
  }) => FjColors(
    background: background ?? this.background,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    accent: accent ?? this.accent,
    divider: divider ?? this.divider,
    surface: surface ?? this.surface,
    onAccent: onAccent ?? this.onAccent,
  );

  @override
  FjColors lerp(FjColors? other, double t) {
    if (other == null) return this;
    return FjColors(
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Font families bundled in assets/fonts (see docs/licenses).
abstract final class FjFonts {
  static const String serif = 'NotoSerifKR';
  static const String sans = 'Pretendard';
}

/// Spacing and measure. Logical pixels (dp).
abstract final class FjSpace {
  static const double gutter = 26;
  static const double readingMaxWidth = 560;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 40;
  static const double xxl = 64;
  static const double paragraphGap = 20;
  static const double sectionGap = 56;
  static const double minTouchTarget = 48;
}

/// Type scale. Sizes are in logical pixels and scale with the user's system
/// text size setting (never clamped below the system value).
@immutable
class FjText extends ThemeExtension<FjText> {
  const FjText({
    required this.wordmark,
    required this.displayTitle,
    required this.chapterTitle,
    required this.subtitle,
    required this.heading,
    required this.body,
    required this.emphasis,
    required this.note,
    required this.noteLabel,
    required this.keyMessage,
    required this.label,
    required this.meta,
    required this.ui,
    required this.uiStrong,
    required this.button,
  });

  factory FjText.from(FjColors c) => FjText(
    wordmark: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 24,
      letterSpacing: 4.2,
      height: 1.2,
      color: c.textPrimary,
    ),
    displayTitle: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 30,
      height: 1.42,
      letterSpacing: -0.3,
      color: c.textPrimary,
    ),
    chapterTitle: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 28,
      height: 1.45,
      letterSpacing: -0.3,
      color: c.textPrimary,
    ),
    subtitle: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w400,
      fontSize: 16.5,
      height: 1.7,
      color: c.textSecondary,
    ),
    heading: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      height: 1.55,
      letterSpacing: -0.2,
      color: c.textPrimary,
    ),
    body: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w400,
      fontSize: 17.5,
      height: 1.8,
      color: c.textPrimary,
    ),
    emphasis: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 19.5,
      height: 1.72,
      letterSpacing: -0.2,
      color: c.textPrimary,
    ),
    note: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w400,
      fontSize: 15.5,
      height: 1.75,
      color: c.textSecondary,
    ),
    noteLabel: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 1.4,
      letterSpacing: 0.6,
      color: c.accent,
    ),
    keyMessage: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.6,
      letterSpacing: -0.3,
      color: c.textPrimary,
    ),
    label: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 1.4,
      letterSpacing: 1.6,
      color: c.textSecondary,
    ),
    meta: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w400,
      fontSize: 13.5,
      height: 1.55,
      color: c.textSecondary,
    ),
    ui: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.5,
      color: c.textPrimary,
    ),
    uiStrong: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.5,
      color: c.textPrimary,
    ),
    button: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.3,
      letterSpacing: 0.2,
      color: c.onAccent,
    ),
  );

  final TextStyle wordmark;
  final TextStyle displayTitle;
  final TextStyle chapterTitle;
  final TextStyle subtitle;
  final TextStyle heading;
  final TextStyle body;
  final TextStyle emphasis;
  final TextStyle note;
  final TextStyle noteLabel;
  final TextStyle keyMessage;
  final TextStyle label;
  final TextStyle meta;
  final TextStyle ui;
  final TextStyle uiStrong;
  final TextStyle button;

  static FjText of(BuildContext context) =>
      Theme.of(context).extension<FjText>() ?? FjText.from(FjColors.light);

  @override
  FjText copyWith() => this;

  @override
  FjText lerp(FjText? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return FjText(
      wordmark: l(wordmark, other.wordmark),
      displayTitle: l(displayTitle, other.displayTitle),
      chapterTitle: l(chapterTitle, other.chapterTitle),
      subtitle: l(subtitle, other.subtitle),
      heading: l(heading, other.heading),
      body: l(body, other.body),
      emphasis: l(emphasis, other.emphasis),
      note: l(note, other.note),
      noteLabel: l(noteLabel, other.noteLabel),
      keyMessage: l(keyMessage, other.keyMessage),
      label: l(label, other.label),
      meta: l(meta, other.meta),
      ui: l(ui, other.ui),
      uiStrong: l(uiStrong, other.uiStrong),
      button: l(button, other.button),
    );
  }
}

/// Short, calm motion. Collapses to zero when the OS asks to reduce motion.
abstract final class FjMotion {
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Curve curve = Curves.easeOutCubic;

  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}
