import 'package:flutter/material.dart';

/// Central source of truth for QuickServe Admin light and dark styling.
///
/// Feature screens should consume Theme.of(context) and ColorScheme rather
/// than defining local button, input, surface, or text colors.
abstract final class AdminTheme {
  static const seed = Color(0xff145c72);
  static const sidebar = Color(0xff07120f);
  static const accent = Color(0xffb9f36b);
  static const ink = Color(0xff12372d);

  static const lightBackground = Color(0xfff6f8f7);
  static const lightSurface = Colors.white;
  static const lightTextPrimary = Color(0xff12372d);
  static const lightTextSecondary = Color(0xff60736b);
  static const lightDivider = Color(0xffd9e3de);
  static const lightInput = Color(0xfffbfcfb);

  static const darkBackground = Color(0xff101514);
  static const darkSurface = Color(0xff18201d);
  static const darkInput = Color(0xff202925);
  static const darkTextPrimary = Color(0xfff1f5f3);
  static const darkTextSecondary = Color(0xffb8c4be);
  static const darkDivider = Color(0xff3b4a43);
  static const googleBlue = Color(0xff4285f4);
  static const success = Color(0xff2e9f5b);
  static const warning = Color(0xfff5a623);
  static const error = Color(0xffb3261e);
  static const sidebarText = Color(0xfff1f5f3);
  static const sidebarMuted = Color(0xb3f1f5f3);
  static const sidebarLabel = Color(0x66f1f5f3);
  static const sidebarDivider = Color(0x24f1f5f3);
  static const sidebarLogout = Color(0xffffc107);
  static const shadow = Color(0x22000000);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: primary, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, color: secondary, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, color: secondary, height: 1.35),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: .3,
      ),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? darkBackground : lightBackground;
    final surface = dark ? darkSurface : lightSurface;
    final input = dark ? darkInput : lightInput;
    final primaryText = dark ? darkTextPrimary : lightTextPrimary;
    final secondaryText = dark ? darkTextSecondary : lightTextSecondary;
    final divider = dark ? darkDivider : lightDivider;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(surface: surface, error: const Color(0xffb3261e));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(primaryText, secondaryText),
      iconTheme: IconThemeData(
        color: dark ? darkTextSecondary : lightTextSecondary,
        size: 20,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .25),
        selectionHandleColor: scheme.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: secondaryText),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        errorStyle: TextStyle(
          color: dark ? const Color(0xffffb4ab) : const Color(0xffb3261e),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          backgroundColor: dark ? accent : ink,
          foregroundColor: dark ? sidebar : Colors.white,
          disabledBackgroundColor: dark
              ? const Color(0xff38423d)
              : const Color(0xffd8e1dc),
          disabledForegroundColor: secondaryText,
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 44),
          backgroundColor: dark ? accent : ink,
          foregroundColor: dark ? sidebar : Colors.white,
          elevation: 0,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          foregroundColor: dark ? accent : ink,
          side: BorderSide(color: dark ? accent : ink),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? accent : ink,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: shape.copyWith(
          side: BorderSide(color: divider.withValues(alpha: .75)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? const Color(0xff28332e) : const Color(0xffeef3f0),
        selectedColor: dark ? accent : ink,
        labelStyle: TextStyle(fontSize: 12, color: primaryText),
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return dark ? accent : ink;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(dark ? sidebar : Colors.white),
        side: BorderSide(color: secondaryText),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dark ? sidebar : Colors.white;
          }
          return secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return dark ? accent : ink;
          return divider;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: secondaryText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .6,
          color: secondaryText,
        ),
        dataTextStyle: TextStyle(fontSize: 13, color: primaryText),
        headingRowColor: WidgetStatePropertyAll(
          dark ? darkInput : const Color(0xfff7faf8),
        ),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? scheme.primary.withValues(alpha: .05)
              : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xff28332e) : ink,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
