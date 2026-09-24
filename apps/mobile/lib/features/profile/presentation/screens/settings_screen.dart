import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickserve_mobile/config/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme across the app'),
            value: false, // TODO: Wire to themeProvider
            onChanged: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not fully implemented yet')),
              );
            },
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English (US)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement language picker
            },
          ),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on interactions'),
            value: true,
            onChanged: (val) {},
            secondary: const Icon(Icons.vibration),
          ),

          const Divider(),
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts for new requests and updates'),
            value: true,
            onChanged: (val) {},
            secondary: const Icon(Icons.notifications_active_outlined),
          ),

          const Divider(),
          _buildSectionHeader(context, 'Security & Data'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security Settings'),
            subtitle: const Text('Passwords and authentication'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(AppRoutes.securitySettings);
            },
          ),
          SwitchListTile(
            title: const Text('App Lock'),
            subtitle: const Text('Require biometrics to open'),
            value: false,
            onChanged: (val) {},
            secondary: const Icon(Icons.fingerprint),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear Offline Cache'),
            subtitle: const Text('Free up storage space'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared (stub)')),
              );
            },
          ),

          const Divider(),
          _buildSectionHeader(context, 'Support & About'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About QuickServe'),
            subtitle: const Text('Version 1.0.0 (Build 42)'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('System Updates'),
            subtitle: const Text('App is up to date'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
