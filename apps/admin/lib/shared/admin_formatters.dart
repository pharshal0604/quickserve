import 'package:flutter/material.dart';

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
  'completed' => Colors.green,
  'cancelled' => Theme.of(context).colorScheme.error,
  'in_progress' => Colors.amber.shade700,
  _ => Theme.of(context).colorScheme.primary,
};
