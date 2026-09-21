import 'package:flutter/material.dart';

/// Shows one application snackbar at a time.
final class AppSnackBar {
  const AppSnackBar._();

  /// Dismisses any visible or queued snackbar before showing [message].
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }
}
