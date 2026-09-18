import 'package:flutter/material.dart';

/// Provides the QuickServe light and dark Material 3 themes.
abstract final class AppTheme {
  static const _seedColor = Color(0xFF1B5E20);
  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  /// Creates the light QuickServe theme.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _theme(colorScheme);
  }

  /// Creates the dark QuickServe theme.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _theme(colorScheme);
  }

  static ThemeData _theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(),
        contentPadding: _contentPadding,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: _buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: _shape,
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
