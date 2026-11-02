import 'package:flutter/material.dart';

/// Colour tokens — design v2 "Ink & Paper": warm paper, ink type, thin rules.
/// Monochrome by intent: order comes from type and line, not from colour.
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
    required this.rule,
    required this.inkSoft,
  });

  static const FjColors light = FjColors(
    background: Color(0xFFF4F0E7), // paper
    textPrimary: Color(0xFF171714), // ink
    // Reference muted #77736A is 4.15:1 on paper (below WCAG AA for the small
    // meta text that uses it); same hue darkened to 4.95:1.
    textSecondary: Color(0xFF6B675E),
    accent: Color(0xFF171714), // ink is the only accent
    divider: Color(0xFFD9D4C9), // light rule
    surface: Color(0xFFFBF8F1), // bright paper
    onAccent: Color(0xFFF4F0E7),
    rule: Color(0xFFB9B4A9),
    inkSoft: Color(0xFF4B4A44),
  );

  /// Night paper: the same system inverted for reading in the dark.
  static const FjColors dark = FjColors(
    background: Color(0xFF121110),
    textPrimary: Color(0xFFEDE8DC),
    textSecondary: Color(0xFF9C978B),
    accent: Color(0xFFEDE8DC),
    divider: Color(0xFF2C2A26),
    surface: Color(0xFF1A1917),
    onAccent: Color(0xFF121110),
    rule: Color(0xFF4A473F),
    inkSoft: Color(0xFFC9C3B6),
  );

  /// Design v1 ("Quiet Editorial", green accent) kept for rollback: point
  /// buildTheme at these to restore the 1.0.x look.
  static const FjColors classicLight = FjColors(
    background: Color(0xFFF8F7F3),
    textPrimary: Color(0xFF202722),
    textSecondary: Color(0xFF6B726B),
    accent: Color(0xFF365B4C),
    divider: Color(0xFFE5E6DF),
    surface: Color(0xFFFFFFFF),
    onAccent: Color(0xFFF8F7F3),
    rule: Color(0xFFC9CBC2),
    inkSoft: Color(0xFF4A524C),
  );

  static const FjColors classicDark = FjColors(
    background: Color(0xFF171D1A),
    textPrimary: Color(0xFFECEFE9),
    textSecondary: Color(0xFFA2ABA3),
    accent: Color(0xFFADC5B5),
    divider: Color(0xFF343D36),
    surface: Color(0xFF202823),
    onAccent: Color(0xFF171D1A),
    rule: Color(0xFF4A544D),
    inkSoft: Color(0xFFC6CDC7),
  );

  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color divider;
  final Color surface;

  /// Text on an accent fill.
  final Color onAccent;

  /// Stronger rule for structural lines (double rule, drawn rules).
  final Color rule;

  /// One step lighter than ink: context and secondary reading text.
  final Color inkSoft;

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
    Color? rule,
    Color? inkSoft,
  }) => FjColors(
    background: background ?? this.background,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    accent: accent ?? this.accent,
    divider: divider ?? this.divider,
    surface: surface ?? this.surface,
    onAccent: onAccent ?? this.onAccent,
    rule: rule ?? this.rule,
    inkSoft: inkSoft ?? this.inkSoft,
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
      rule: Color.lerp(rule, other.rule, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
    );
  }
}

/// Font families bundled in assets/fonts (see docs/licenses).
abstract final class FjFonts {
  static const String serif = 'NotoSerifKR';
  static const String sans = 'Pretendard';

  /// Latin display: wordmark, large numerals, italic accents.
  static const String latin = 'CormorantGaramond';
}

/// Spacing and measure. Logical pixels (dp).
abstract final class FjSpace {
  static const double gutter = 24;
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

/// Type scale (design v2). Korean stays near-solid; only Latin capitals are
/// tracked wide. Sizes scale with the system text size (never clamped below).
@immutable
class FjText extends ThemeExtension<FjText> {
  const FjText({
    required this.wordmark,
    required this.numeral,
    required this.latinItalic,
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
      fontFamily: FjFonts.latin,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      letterSpacing: 22 * 0.24,
      height: 1.1,
      fontFeatures: const [FontFeature.liningFigures()],
      color: c.textPrimary,
    ),
    numeral: TextStyle(
      fontFamily: FjFonts.latin,
      fontWeight: FontWeight.w400,
      fontSize: 120,
      height: 0.92,
      letterSpacing: -3,
      // Cormorant defaults to old-style figures ("01" reads "OI").
      fontFeatures: const [FontFeature.liningFigures()],
      color: c.textPrimary,
    ),
    latinItalic: TextStyle(
      fontFamily: FjFonts.latin,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      fontSize: 19,
      height: 1.3,
      fontFeatures: const [FontFeature.liningFigures()],
      color: c.textSecondary,
    ),
    displayTitle: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 31,
      height: 1.36,
      letterSpacing: -0.8,
      color: c.textPrimary,
    ),
    chapterTitle: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 29,
      height: 1.38,
      letterSpacing: -0.8,
      color: c.textPrimary,
    ),
    subtitle: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w400,
      fontSize: 16.5,
      height: 1.72,
      letterSpacing: -0.2,
      color: c.inkSoft,
    ),
    heading: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 21,
      height: 1.5,
      letterSpacing: -0.5,
      color: c.textPrimary,
    ),
    body: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w400,
      fontSize: 17.5,
      height: 1.85,
      letterSpacing: -0.2,
      color: c.textPrimary,
    ),
    emphasis: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 21,
      height: 1.62,
      letterSpacing: -0.5,
      color: c.textPrimary,
    ),
    note: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w400,
      fontSize: 15.5,
      height: 1.78,
      letterSpacing: -0.1,
      color: c.inkSoft,
    ),
    noteLabel: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: 11.5,
      height: 1.4,
      letterSpacing: 0.4,
      color: c.textSecondary,
    ),
    keyMessage: TextStyle(
      fontFamily: FjFonts.serif,
      fontWeight: FontWeight.w600,
      fontSize: 24,
      height: 1.55,
      letterSpacing: -0.7,
      color: c.textPrimary,
    ),
    label: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: 11,
      height: 1.45,
      letterSpacing: 11 * 0.18,
      color: c.textSecondary,
    ),
    meta: TextStyle(
      fontFamily: FjFonts.sans,
      fontWeight: FontWeight.w400,
      fontSize: 13,
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
      fontSize: 15.5,
      height: 1.3,
      letterSpacing: 0.2,
      color: c.onAccent,
    ),
  );

  final TextStyle wordmark;

  /// Oversized Latin numerals ("01") — the main graphic element.
  final TextStyle numeral;
  final TextStyle latinItalic;
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
      numeral: l(numeral, other.numeral),
      latinItalic: l(latinItalic, other.latinItalic),
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

/// Motion language: type and line move, nothing bounces. Everything collapses
/// to its end state when the OS asks to reduce motion.
abstract final class FjMotion {
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);

  /// Text and line reveals.
  static const Duration reveal = Duration(milliseconds: 720);

  /// Gap between consecutive items of a staggered entrance.
  static const Duration stagger = Duration(milliseconds: 70);
  static const Curve curve = Curves.easeOutCubic;

  /// Long, soft deceleration used for type entering the frame.
  static const Curve emphasized = Cubic(0.16, 1, 0.3, 1);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
