import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickserve_admin/main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool compactTables = false;
  bool showHints = true;
  bool autoRefresh = true;

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    final textScale = ref.watch(textScaleProvider);

    return ListView(
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage portal preferences and security context. Persistent settings require an approved schema.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text('Appearance & Accessibility', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              value: darkMode,
              onChanged: (val) => ref.read(darkModeProvider.notifier).state = val,
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light and dark themes.'),
              secondary: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_increase),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Global Text Scale', style: Theme.of(context).textTheme.titleMedium),
                            Text('Adjust the font size across the entire portal.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text('${(textScale * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: textScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${(textScale * 100).toInt()}%',
                    onChanged: (val) => ref.read(textScaleProvider.notifier).state = val,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text('Data Preferences', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              value: compactTables,
              onChanged: (value) => setState(() => compactTables = value),
              title: const Text('Compact tables'),
              subtitle: const Text('Reduces padding in directory lists.'),
              secondary: const Icon(Icons.table_rows),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: autoRefresh,
              onChanged: (value) => setState(() => autoRefresh = value),
              title: const Text('Auto-refresh Data'),
              subtitle: const Text('Keep streams open for live database changes.'),
              secondary: const Icon(Icons.autorenew),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: showHints,
              onChanged: (value) => setState(() => showHints = value),
              title: const Text('Show operational hints'),
              subtitle: const Text('Display tooltips and helper text in complex views.'),
              secondary: const Icon(Icons.help_outline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Security and persistence', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text(
                      'Firebase Auth and Firestore rules remain the source of truth. No unsupported profile, notification, or system-setting writes are performed.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  }
}
