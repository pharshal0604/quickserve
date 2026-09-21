import 'package:flutter/material.dart';

abstract final class AdminTheme {
  static const seed = Color(0xff145c72);
  static const sidebar = Color(0xff07120f);
  static const accent = Color(0xffb9f36b);
  static const ink = Color(0xff12372d);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
