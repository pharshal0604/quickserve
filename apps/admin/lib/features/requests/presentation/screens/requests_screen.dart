import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/utils/admin_filters.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';
import 'package:quickserve_admin/injection_container.dart';

import 'request_details_screen.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  AdminRequestFilters filters = const AdminRequestFilters();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<({String id, RequestEntity request})>>(
    stream: ref.watch(watchRequestsProvider).call(),
    builder: (context, snapshot) {
      final all = snapshot.data ?? [];
      final docs = filters.apply(all);
      final totalMatches = all
          .where((doc) => filters.matches(doc.request))
          .length;

      return StreamBuilder<List<({String id, UserEntity user})>>(
        stream: ref.watch(watchCustomersProvider).call(),
        builder: (context, usersSnapshot) {
          final usersById = <String, UserEntity>{
            for (final doc in usersSnapshot.data ?? []) doc.id: doc.user,
          };
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Service Requests',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalMatches matching requests',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
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
                        : _RequestsTable(
                            docs: docs,
                            usersById: usersById,
                            onOpen: (doc) => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RequestDetailsScreen(requestId: doc.id),
                              ),
                            ),
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

class _RequestsTable extends StatelessWidget {
  const _RequestsTable({
    required this.docs,
    required this.usersById,
    required this.onOpen,
  });

  final List<({String id, RequestEntity request})> docs;
  final Map<String, UserEntity> usersById;
  final ValueChanged<({String id, RequestEntity request})> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth < 980 ? 980 : constraints.maxWidth,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 52,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 82,
            columnSpacing: 28,
            horizontalMargin: 24,
            columns: const [
              DataColumn(label: Text('REQUEST')),
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('SERVICE')),
              DataColumn(label: Text('SCHEDULED')),
              DataColumn(label: Text('STATUS')),
            ],
            rows: [
              for (final doc in docs)
                DataRow(
                  onSelectChanged: (_) => onOpen(doc),
                  cells: [
                    DataCell(
                      _RequestCell(request: doc.request, requestId: doc.id),
                      onTap: () => onOpen(doc),
                    ),
                    DataCell(
                      _CustomerCell(user: usersById[doc.request.customerId]),
                    ),
                    DataCell(Text(adminLabel(doc.request.serviceType))),
                    DataCell(Text(_dateTime(doc.request.preferredDateTime))),
                    DataCell(_StatusBadge(doc.request.status.toStoredValue())),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RequestCell extends StatelessWidget {
  const _RequestCell({required this.request, required this.requestId});

  final RequestEntity request;
  final String requestId;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.requestCode,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          request.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Unknown Customer';
    return SizedBox(
      width: 170,
      child: Row(
        children: [
          CircleAvatar(radius: 16, child: Text(adminInitial(name))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = adminStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        adminLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
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
              prefixIcon: Icon(Icons.search),
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

String _dateTime(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  return 'Not scheduled';
}
