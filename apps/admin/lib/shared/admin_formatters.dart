import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

String adminLabel(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

String adminInitial(dynamic value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? '?' : text[0].toUpperCase();
}

String adminUserLabel(Map<String, dynamic>? data) {
  final name = data?['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  final email = data?['email'];
  if (email is String && email.trim().isNotEmpty) return email.trim();
  return 'Profile unavailable';
}

IconData adminStatusIcon(String value) => switch (value) {
  'created' => Icons.fiber_new,
  'assigned' => Icons.person_add_alt_1,
  'accepted' => Icons.thumb_up_alt_outlined,
  'in_progress' => Icons.sync,
  'completed' => Icons.check_circle_outline,
  'cancelled' => Icons.cancel_outlined,
  _ => Icons.help_outline,
};

Color adminStatusColor(BuildContext context, String value) => switch (value) {
  'created' => QuickServeStatusColors.created,
  'assigned' => QuickServeStatusColors.assigned,
  'accepted' => QuickServeStatusColors.accepted,
  'in_progress' => QuickServeStatusColors.inProgress,
  'completed' => QuickServeStatusColors.completed,
  'cancelled' => QuickServeStatusColors.cancelled,
  _ => Theme.of(context).colorScheme.primary,
};
