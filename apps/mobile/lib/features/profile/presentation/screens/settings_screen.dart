import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const _SettingsSection(
            title: 'Preferences',
            children: [
              ListTile(
                leading: Icon(
                  Icons.notifications_none,
                  color: AppColors.primary,
                ),
                title: Text('Request notifications'),
                subtitle: Text(
                  'Notification delivery will follow the approved backend contract.',
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.dark_mode_outlined,
                  color: AppColors.primary,
                ),
                title: Text('Appearance'),
                subtitle: Text('QuickServe follows your device theme.'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SettingsSection(
            title: 'Privacy and security',
            children: [
              ListTile(
                leading: Icon(Icons.lock_outline, color: AppColors.primary),
                title: Text('Account security'),
                subtitle: Text('Authentication is managed by Firebase Auth.'),
              ),
              ListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.primary,
                ),
                title: Text('Privacy'),
                subtitle: Text(
                  'Your profile and requests are protected by Firestore rules.',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
      const SizedBox(height: AppSpacing.sm),
      Card(child: Column(children: children)),
    ],
  );
}
