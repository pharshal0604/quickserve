import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/injection_container.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});
  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String search = '';
  String filter = 'all';

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<({String id, ServiceEntity service})>>(
    stream: ref.watch(watchServicesProvider).call(),
    builder: (context, snapshot) {
      final docs = (snapshot.data ?? const []).where((doc) {
        final data = doc.service;
        final needle = search.trim().toLowerCase();
        final matchesText =
            needle.isEmpty ||
            '${data.name} ${data.description}'.toLowerCase().contains(needle);
        final active = data.active;
        return matchesText &&
            (filter == 'all' ||
                filter == 'active' && active ||
                filter == 'inactive' && !active);
      }).toList();
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
                      'Service Management',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${docs.length} matching services',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Add service'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 360,
                    child: TextField(
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Search services',
                        counterText: '',
                      ),
                      onChanged: (value) => setState(() => search = value),
                    ),
                  ),
                  DropdownButton<String>(
                    value: filter,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All services'),
                      ),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => filter = value ?? 'all'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (snapshot.hasError)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load services: ${snapshot.error}'),
              ),
            ),
          if (docs.isEmpty && !snapshot.hasError)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No services match the current filters.'),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final doc in docs)
                SizedBox(
                  width: 300,
                  child: _ServiceCard(
                    doc: doc,
                    onEdit: () => _edit(context, doc),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );

  Future<void> _edit(
    BuildContext context, [
    ({String id, ServiceEntity service})? doc,
  ]) async {
    final data = doc?.service;
    final name = TextEditingController(text: data?.name);
    final description = TextEditingController(text: data?.description);
    var active = data?.active ?? true;
    final result =
        await showDialog<({String name, String description, bool active})>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(doc == null ? 'Add service' : 'Edit service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Service name',
                    ),
                  ),
                  TextField(
                    controller: description,
                    maxLength: 1000,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  SwitchListTile(
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                    title: const Text('Active'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, (
                    name: name.text,
                    description: description.text,
                    active: active,
                  )),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
    name.dispose();
    description.dispose();
    if (result == null || !mounted) return;
    try {
      if (doc == null) {
        await ref
            .read(createServiceProvider)
            .call(result.name, result.description, result.active);
      } else {
        await ref
            .read(updateServiceProvider)
            .call(doc.id, result.name, result.description, result.active);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.doc, required this.onEdit});
  final ({String id, ServiceEntity service}) doc;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final data = doc.service;
    final active = data.active;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.home_repair_service_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                Chip(label: Text(active ? 'Active' : 'Inactive')),
              ],
            ),
            const SizedBox(height: 12),
            Text(data.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              data.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
