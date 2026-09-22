import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Semantic colors used throughout QuickServe mobile.
abstract final class AppColors {
  static const Color primary = Color(0xFF075B3E);
  static const Color primaryDark = Color(0xFF043D2A);
  static const Color mintSurface = Color(0xFFEAF4F0);
  static const Color pageBackground = Color(0xFFF7F9F7);
  static const Color gold = Color(0xFFF0C95A);
  static const Color outline = Color(0xFFD9E3DE);
  static const Color mutedText = Color(0xFF6D7A74);
  static const Color success = Color(0xFF2E9F5B);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);
  static const Color googleBlue = Color(0xFF4285F4);

  // NEW: brand-consistent accent for dark surfaces (cursor, focus, selection,
  // selected chips, progress indicator) — replaces the borrowed `info` blue
  // so dark mode still reads as QuickServe rather than a generic app.
  static const Color darkAccent = Color(0xFF34D399);

  // Theme surfaces and text tokens. Screens should consume Theme.of(context)
  // or these semantic tokens instead of defining local light/dark colors.
  static const Color lightBackground = Color(0xFFF7F9F7);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1D2A24);
  static const Color lightTextSecondary = Color(0xFF6D7A74);
  static const Color lightDivider = Color(0xFFD9E3DE);
  static const Color lightIcon = Color(0xFF596660);

  static const Color darkBackground = Color(0xFF15191A);
  static const Color darkSurface = Color(0xFF20241F);
  static const Color darkNavigation = Color(0xFF191D1B);
  static const Color darkTextPrimary = Color(0xFFF4F6F5);
  static const Color darkTextSecondary = Color(0xFFB8C0BC);
  static const Color darkDivider = Color(0xFF32362F);
  static const Color darkIcon = Color(0xFFD0D5D2);

  static const Color statusCreated = QuickServeStatusColors.created;
  static const Color statusAssigned = QuickServeStatusColors.assigned;
  static const Color statusAccepted = QuickServeStatusColors.accepted;
  static const Color statusProgress = QuickServeStatusColors.inProgress;
  static const Color statusCompleted = QuickServeStatusColors.completed;
  static const Color statusCancelled = QuickServeStatusColors.cancelled;
}
