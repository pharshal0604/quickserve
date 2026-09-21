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

  static const Color statusCreated = QuickServeStatusColors.created;
  static const Color statusAssigned = QuickServeStatusColors.assigned;
  static const Color statusAccepted = QuickServeStatusColors.accepted;
  static const Color statusProgress = QuickServeStatusColors.inProgress;
  static const Color statusCompleted = QuickServeStatusColors.completed;
  static const Color statusCancelled = QuickServeStatusColors.cancelled;
}
