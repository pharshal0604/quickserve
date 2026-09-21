import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';
import 'person_details_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({
    required this.repository,
    required this.role,
    this.detailsBuilder,
    super.key,
  });

  final AdminRepository repository;
  final String role;
  final Widget Function(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  )?
  detailsBuilder;

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String search = '';
  String stateFilter = 'all';
  int page = 0;
  static const pageSize = 25;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: widget.repository.watchUsers(role: widget.role),
    builder: (context, snapshot) {
      final all =
          snapshot.data?.docs ??
          const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final filtered = all.where((doc) {
        final data = doc.data();
        final needle = search.trim().toLowerCase();
        final text = [
          data['name'],
          data['email'],
          data['phone'],
          doc.id,
        ].join(' ').toLowerCase();
        final accountState = '${data['status'] ?? 'active'}';
        return (needle.isEmpty || text.contains(needle)) &&
            (stateFilter == 'all' || accountState == stateFilter);
      }).toList();
      final start = page * pageSize;
      final end = (start + pageSize).clamp(0, filtered.length);
      final docs = start >= filtered.length
          ? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]
          : filtered.sublist(start, end);
      final title = widget.role == RoleNames.customer
          ? 'Customers'
          : 'Service Agents';

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Showing ${filtered.length} matching records',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export'),
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
                          labelText: 'Search by name, email, phone, or ID',
                          counterText: '',
                        ),
                        onChanged: (value) => setState(() {
                          search = value;
                          page = 0;
                        }),
                      ),
                    ),
                    DropdownButton<String>(
                      value: stateFilter,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All states'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactive'),
                        ),
                        DropdownMenuItem(
                          value: 'suspended',
                          child: Text('Suspended'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        stateFilter = value ?? 'all';
                        page = 0;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: snapshot.hasError
                    ? Center(
                        child: Text('Unable to load $title: ${snapshot.error}'),
                      )
                    : docs.isEmpty
                    ? const Center(
                        child: Text('No records match the current filters.'),
                      )
                    : ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(adminInitial(data['name'])),
                            ),
                            title: Text('${data['name'] ?? doc.id}'),
                            subtitle: Text(
                              '${data['email'] ?? 'No email'}\n'
                              '${data['phone'] ?? 'No phone'}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  label: Text('${data['status'] ?? 'active'}'),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    widget.detailsBuilder?.call(
                                      context,
                                      doc.id,
                                      data,
                                    ) ??
                                    PersonDetailsScreen(
                                      repository: widget.repository,
                                      userId: doc.id,
                                      role: widget.role,
                                      data: data,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Page ${page + 1}'),
                IconButton(
                  onPressed: page == 0 ? null : () => setState(() => page--),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: docs.length < pageSize
                      ? null
                      : () => setState(() => page++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
