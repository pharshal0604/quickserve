import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/core/utils/admin_filters.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

import 'request_details_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({required this.repository, super.key});

  final AdminRepository repository;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  AdminRequestFilters filters = const AdminRequestFilters();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: widget.repository.watchRequests(),
    builder: (context, snapshot) {
      final all =
          snapshot.data?.docs ??
          const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final docs = filters.apply(all);
      final totalMatches = all
          .where((doc) => filters.matches(doc.data()))
          .length;

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.repository.watchUsers(role: RoleNames.customer),
        builder: (context, usersSnapshot) {
          final usersById = {
            for (final doc in usersSnapshot.data?.docs ?? const [])
              doc.id: doc.data(),
          };
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
                            'Service Requests',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalMatches matching requests',
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
                    child: _FilterBar(
                      filters: filters,
                      onChanged: (next) => setState(() => filters = next),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: snapshot.hasError
                        ? Center(
                            child: Text(
                              'Unable to load requests: ${snapshot.error}',
                            ),
                          )
                        : docs.isEmpty
                        ? const Center(
                            child: Text(
                              'No requests match the current filters.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data();
                              final status = '${data['status'] ?? 'unknown'}';
                              return ListTile(
                                leading: Checkbox(
                                  value: false,
                                  onChanged: null,
                                ),
                                title: Text(
                                  '${data['requestCode'] ?? doc.id} · '
                                  '${data['serviceType'] ?? 'Service'}',
                                ),
                                subtitle: Text(
                                  '${adminUserLabel(usersById[data['customerId']])}\n'
                                  '${data['address'] ?? 'No address'}',
                                ),
                                isThreeLine: true,
                                trailing: Chip(
                                  label: Text(
                                    adminLabel(status),
                                    style: TextStyle(
                                      color: adminStatusColor(context, status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: adminStatusColor(
                                    context,
                                    status,
                                  ).withValues(alpha: .12),
                                  side: BorderSide.none,
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RequestDetailsScreen(
                                      repository: widget.repository,
                                      requestId: doc.id,
                                      data: data,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Page ${filters.page + 1} · max ${filters.pageSize} per page',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed: filters.page == 0
                          ? null
                          : () => setState(
                              () => filters = filters.copyWith(
                                page: filters.page - 1,
                              ),
                            ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      onPressed: docs.length < filters.pageSize
                          ? null
                          : () => setState(
                              () => filters = filters.copyWith(
                                page: filters.page + 1,
                              ),
                            ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.filters, required this.onChanged});

  final AdminRequestFilters filters;
  final ValueChanged<AdminRequestFilters> onChanged;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final TextEditingController search = TextEditingController(
    text: widget.filters.search,
  );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: constraints.maxWidth > 700 ? 360 : constraints.maxWidth,
          child: TextField(
            controller: search,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Search request, customer, or address',
              counterText: '',
            ),
            onChanged: (value) => widget.onChanged(
              widget.filters.copyWith(search: value, page: 0),
            ),
          ),
        ),
        DropdownButton<String>(
          value: widget.filters.status,
          items: ['all', ...StatusNames.values]
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == 'all' ? 'All statuses' : adminLabel(value),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) =>
              widget.onChanged(widget.filters.copyWith(status: value, page: 0)),
        ),
        DropdownButton<String>(
          value: widget.filters.priority,
          items: ['all', ...PriorityNames.values]
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == 'all' ? 'All priorities' : adminLabel(value),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => widget.onChanged(
            widget.filters.copyWith(priority: value, page: 0),
          ),
        ),
      ],
    ),
  );
}
