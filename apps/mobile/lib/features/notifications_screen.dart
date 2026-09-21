import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Notifications surface reserved for the approved backend notification
/// contract. The current Firebase rules do not define notification records.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.mintSurface,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'You\'re all caught up',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Request updates will appear here once the notification data contract is enabled.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
