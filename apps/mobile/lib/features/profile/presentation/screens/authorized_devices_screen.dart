import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';

class AuthorizedDevicesScreen extends StatelessWidget {
  const AuthorizedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text('Authorized Devices'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Currently active sessions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.phone_android,
                  size: 32,
                  color: AppColors.primary,
                ),
                title: const Text('This Device'),
                subtitle: const Text('Mobile App · Active now'),
                trailing: Chip(
                  label: const Text('Current', style: TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.computer, size: 32),
                title: const Text('Windows PC'),
                subtitle: const Text(
                  'Chrome Browser · Last active 2 hours ago',
                ),
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session revoked (Mock)')),
                    );
                  },
                  child: const Text(
                    'Revoke',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Note: Device tracking is currently running in mocked mode. A backend update is required to track actual sessions.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
