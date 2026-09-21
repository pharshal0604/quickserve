import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/core/network/admin_repository_service_extensions.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({required this.repository, super.key});
  final AdminRepository repository;
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String search = '';
  String filter = 'all';

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.repository.watchServices(),
        builder: (context, snapshot) {
          final docs = (snapshot.data?.docs ?? const []).where((doc) {
            final data = doc.data();
            final needle = search.trim().toLowerCase();
            final matchesText =
                needle.isEmpty ||
                '${data['name'] ?? ''} ${data['description'] ?? ''}'
                    .toLowerCase()
                    .contains(needle);
            final active = data['active'] == true;
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
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
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
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final data = doc?.data() ?? const <String, dynamic>{};
    final name = TextEditingController(text: data['name'] as String? ?? '');
    final description = TextEditingController(
      text: data['description'] as String? ?? '',
    );
    var active = data['active'] as bool? ?? true;
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
        await widget.repository.createService(
          name: result.name,
          description: result.description,
          active: result.active,
        );
      } else {
        await widget.repository.updateService(
          serviceId: doc.id,
          name: result.name,
          description: result.description,
          active: result.active,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.doc, required this.onEdit});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final active = data['active'] == true;
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
            Text(
              '${data['name'] ?? doc.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${data['description'] ?? 'No description'}',
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
