import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Central source of truth for QuickServe mobile light and dark styling.
///
/// Screens should use Theme.of(context), ColorScheme, and component themes
/// rather than defining local light/dark colors or button/input styles.
abstract final class AppTheme {
  static const _seedColor = AppColors.primary;
  static const _shape = RoundedRectangleBorder(borderRadius: AppRadius.lgAll);
  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
  );
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 16,
  );

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: primary, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: secondary, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, color: secondary, height: 1.4),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: .3,
      ),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // One semantic accent drives selection, focus, controls, and navigation.
    final accent = dark ? AppColors.darkAccent : AppColors.primary;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: dark ? AppColors.lightTextPrimary : Colors.white,
          surface: dark ? AppColors.darkSurface : AppColors.lightSurface,
          error: AppColors.error,
        );
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final primaryText = dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryText = dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final outline = dark ? AppColors.darkDivider : AppColors.lightDivider;
    final onPrimary = colorScheme.onPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'sans',
      textTheme: _textTheme(primaryText, secondaryText),
      iconTheme: IconThemeData(
        color: dark ? AppColors.darkIcon : AppColors.lightIcon,
        size: 24,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: .28),
        selectionHandleColor: accent,
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryText,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: secondaryText),
        floatingLabelStyle: TextStyle(color: accent),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        errorStyle: TextStyle(
          color: dark ? const Color(0xffffb4ab) : AppColors.error,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: _contentPadding,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: accent,
          foregroundColor: onPrimary,
          disabledBackgroundColor: dark
              ? const Color(0xff39413d)
              : const Color(0xffd6e0da),
          disabledForegroundColor: dark ? Colors.white54 : AppColors.mutedText,
          shape: _buttonShape,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: accent,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: _buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: accent,
          side: BorderSide(color: accent),
          shape: _buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: dark ? 0 : 1,
        color: surface,
        margin: EdgeInsets.zero,
        shape: _shape.copyWith(
          side: BorderSide(color: outline.withValues(alpha: dark ? .7 : .65)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? const Color(0xff34363b)
            : const Color(0xfff0f1f2),
        selectedColor: accent,
        labelStyle: TextStyle(fontSize: 12, color: primaryText),
        secondaryLabelStyle: TextStyle(
          color: dark ? AppColors.lightTextPrimary : Colors.white,
        ),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(
          color: dark ? AppColors.darkIcon : AppColors.mutedText,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return secondaryText;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return outline;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 8,
        backgroundColor: dark ? AppColors.darkNavigation : Colors.white,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? accent : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xff34363b)
            : AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
