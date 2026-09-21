import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool compactTables = false;
  bool showHints = true;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage portal preferences and security context. Persistent settings require an approved schema.',
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              value: compactTables,
              onChanged: (value) => setState(() => compactTables = value),
              title: const Text('Compact tables'),
              subtitle: const Text('Local to this session.'),
            ),
            SwitchListTile(
              value: showHints,
              onChanged: (value) => setState(() => showHints = value),
              title: const Text('Show operational hints'),
              subtitle: const Text('Local to this session.'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Card(
        child: ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Security and persistence'),
          subtitle: Text(
            'Firebase Auth and Firestore rules remain the source of truth. No unsupported profile, notification, or system-setting writes are performed.',
          ),
        ),
      ),
    ],
  );
}
