import 'package:flutter/material.dart';

/// Semantic and lifecycle-status colors not covered by Material 3's
/// ColorScheme. Values are chosen to read on both light and dark surfaces.
abstract final class AppColors {
  static const Color success = Color(0xFF2E9F5B);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  static const Color statusCreated = Color(0xFF6B7280);
  static const Color statusAssigned = Color(0xFF3B82F6);
  static const Color statusAccepted = Color(0xFF9B6DFF);
  static const Color statusProgress = Color(0xFFF5A623);
  static const Color statusCompleted = Color(0xFF2E9F5B);
  static const Color statusCancelled = Color(0xFFE5484D);
}
