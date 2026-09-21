import 'package:flutter/material.dart';

/// Shared semantic colors for the request lifecycle across QuickServe apps.
abstract final class QuickServeStatusColors {
  static const Color created = Color(0xFF6B7280);
  static const Color assigned = Color(0xFF3B82F6);
  static const Color accepted = Color(0xFF9B6DFF);
  static const Color inProgress = Color(0xFFF5A623);
  static const Color completed = Color(0xFF2E9F5B);
  static const Color cancelled = Color(0xFFE5484D);

  static Color forStatus(String status) => switch (status) {
    'created' => created,
    'assigned' => assigned,
    'accepted' => accepted,
    'in_progress' => inProgress,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => created,
  };
}
