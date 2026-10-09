import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/motion.dart';
import '../core/design/tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? FjColors.light : FjColors.dark;
  final t = FjText.from(c);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: brightness == Brightness.light
        ? const Color(0xFF7A2722)
        : const Color(0xFFE2A79F),
    onError: c.background,
    surface: c.background,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.divider,
    outlineVariant: c.divider,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.surface,
    inverseSurface: c.textPrimary,
    onInverseSurface: c.background,
    surfaceTint: Colors.transparent,
    shadow: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    fontFamily: FjFonts.sans,
    extensions: [c, t],
    splashFactory: NoSplash.splashFactory,
    highlightColor: c.divider.withValues(alpha: 0.6),
    dividerTheme: DividerThemeData(color: c.divider, thickness: 0.8, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.22),
      selectionHandleColor: c.accent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: t.label,
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
    ),
    iconTheme: IconThemeData(color: c.textPrimary, size: 22),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.textPrimary,
      contentTextStyle: t.meta.copyWith(color: c.background),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.background,
      modalBackgroundColor: c.background,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      showDragHandle: true,
      dragHandleColor: c.divider,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.background,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titleTextStyle: t.heading,
      contentTextStyle: t.ui,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.divider,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: t.ui.copyWith(color: c.textSecondary),
      border: UnderlineInputBorder(borderSide: BorderSide(color: c.divider)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: c.divider),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: c.accent, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.background,
      elevation: 0,
      dialBackgroundColor: c.surface,
      hourMinuteColor: c.surface,
      dayPeriodColor: c.divider,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FjPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FjPageTransitionsBuilder(),
      },
    ),
  );
}
