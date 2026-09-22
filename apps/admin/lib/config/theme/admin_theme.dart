import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_colors.dart';

/// Central source of truth for QuickServe Admin styling, mapped to the shared Mobile theme.
abstract final class AdminTheme {
  // Map admin specific colors to mobile theme colors
  static const ink = AppColors.primary;
  static const accent = AppColors.primary;
  
  static const sidebar = Color(0xff09110E); // Dark subtle green for sidebar
  static const sidebarText = Colors.white;
  static const sidebarMuted = Colors.white70;
  static const sidebarLabel = Colors.white54;
  static const sidebarDivider = Colors.white12;
  static const sidebarLogout = AppColors.error;
  
  static const shadow = Color(0x22000000);
  
  static const lightBackground = AppColors.lightBackground;
  static const darkTextPrimary = AppColors.darkTextPrimary;
  static const darkTextSecondary = AppColors.darkTextSecondary;
  
  static const error = AppColors.error;
  static const googleBlue = AppColors.googleBlue;

  static ThemeData light() => AppTheme.light();
  static ThemeData dark() => AppTheme.dark();
}
