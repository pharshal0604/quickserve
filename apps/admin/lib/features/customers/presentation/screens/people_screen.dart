import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/injection_container.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

import 'person_details_screen.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({
    required this.role,
    this.detailsBuilder,
    this.onDetails,
    super.key,
  });

  final String role;
  final ValueChanged<({String userId, UserEntity user})>? onDetails;
  final Widget Function(BuildContext context, String userId, UserEntity user)?
  detailsBuilder;

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleDataSource extends DataTableSource {
  _PeopleDataSource(this.docs, this.context, this.widget);

  final List<({String id, UserEntity user})> docs;
  final BuildContext context;
  final PeopleScreen widget;

  @override
  DataRow? getRow(int index) {
    if (index >= docs.length) return null;
    final doc = docs[index];
    final user = doc.user;

    return DataRow(
      onSelectChanged: (_) {
        final onDetails = widget.onDetails;
        if (onDetails != null) {
          onDetails((userId: doc.id, user: user));
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                widget.detailsBuilder?.call(context, doc.id, user) ??
                PersonDetailsScreen(customerId: doc.id),
          ),
        );
      },
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
                child: Text(
                  adminInitial(user.name),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(Text(user.phone)),
        DataCell(
          Chip(
            label: const Text('active'),
            labelStyle: const TextStyle(fontSize: 11),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => docs.length;

  @override
  int get selectedRowCount => 0;
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  String search = '';
  String stateFilter = 'all';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<({String id, UserEntity user})>>(
    stream: widget.role == RoleNames.customer
        ? ref.watch(watchCustomersProvider).call()
        : ref.watch(watchAgentsProvider).call(),
    builder: (context, snapshot) {
      final all = snapshot.data ?? [];
      final filtered = all.where((doc) {
        final user = doc.user;
        final needle = search.trim().toLowerCase();
        final text = [
          user.name,
          user.email,
          user.phone,
          doc.id,
        ].join(' ').toLowerCase();
        final accountState = 'active';
        return (needle.isEmpty || text.contains(needle)) &&
            (stateFilter == 'all' || accountState == stateFilter);
      }).toList();

      if (_sortColumnIndex == 0) {
        filtered.sort((a, b) {
          final aName = (a.user.name).toLowerCase();
          final bName = (b.user.name).toLowerCase();
          return _sortAscending
              ? aName.compareTo(bName)
              : bName.compareTo(aName);
        });
      } else if (_sortColumnIndex == 1) {
        filtered.sort((a, b) {
          final aEmail = (a.user.email).toLowerCase();
          final bEmail = (b.user.email).toLowerCase();
          return _sortAscending
              ? aEmail.compareTo(bEmail)
              : bEmail.compareTo(aEmail);
        });
      }

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
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Showing ${filtered.length} matching records',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Search by name, email, phone, or ID',
                          counterText: '',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() {
                          search = value;
                        }),
                      ),
                    ),
                    DropdownButton<String>(
                      value: stateFilter,
                      underline: const SizedBox(),
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
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: snapshot.hasError
                  ? Center(
                      child: Text(
                        'Unable to load $title: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        PaginatedDataTable(
                          source: _PeopleDataSource(filtered, context, widget),
                          header: const Text('Directory'),
                          rowsPerPage: _rowsPerPage,
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _rowsPerPage =
                                  value ??
                                  PaginatedDataTable.defaultRowsPerPage;
                            });
                          },
                          availableRowsPerPage: const [10, 25, 50, 100],
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          showCheckboxColumn: false,
                          columns: [
                            DataColumn(
                              label: const Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (columnIndex, ascending) => setState(() {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = ascending;
                              }),
                            ),
                            DataColumn(
                              label: const Text(
                                'Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (columnIndex, ascending) => setState(() {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = ascending;
                              }),
                            ),
                            const DataColumn(
                              label: Text(
                                'Phone',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}
