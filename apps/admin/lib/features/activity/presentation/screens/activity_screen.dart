import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({required this.repository, super.key});
  final AdminRepository repository;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String search = '';
  String result = 'all';

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: widget.repository.watchAuditLogs(),
    builder: (context, snapshot) {
      final all =
          snapshot.data?.docs ??
          const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final filtered = all.where((doc) {
        final data = doc.data();
        final needle = search.trim().toLowerCase();
        final searchable = [
          data['action'],
          data['actorUserId'],
          data['targetId'],
          data['targetType'],
        ].join(' ').toLowerCase();
        return (needle.isEmpty || searchable.contains(needle)) &&
            (result == 'all' || data['result'] == result);
      }).toList();

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.repository.watchUsers(),
        builder: (context, usersSnapshot) {
          final usersById = <String, Map<String, dynamic>>{
            for (final doc in usersSnapshot.data?.docs ?? const [])
              doc.id: doc.data(),
          };
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Audit & Activity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Review administrative actions, authorization failures, and database events.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 420,
                        child: TextField(
                          maxLength: 100,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Search activity, actor, target, or ID',
                            counterText: '',
                          ),
                          onChanged: (value) => setState(() => search = value),
                        ),
                      ),
                      DropdownButton<String>(
                        value: result,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All results'),
                          ),
                          DropdownMenuItem(
                            value: 'success',
                            child: Text('Success'),
                          ),
                          DropdownMenuItem(
                            value: 'failure',
                            child: Text('Failure'),
                          ),
                          DropdownMenuItem(
                            value: 'denied',
                            child: Text('Denied'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => result = value ?? 'all'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Unable to load activity: ${snapshot.error}',
                        ),
                      )
                    : filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No activity matches the current filters.'),
                      )
                    : _ActivityTable(docs: filtered, usersById: usersById),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({required this.docs, required this.usersById});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Map<String, Map<String, dynamic>> usersById;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth < 1050 ? 1050 : constraints.maxWidth,
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 86,
          columnSpacing: 28,
          horizontalMargin: 24,
          columns: const [
            DataColumn(label: Text('TIMESTAMP')),
            DataColumn(label: Text('USER / ACTOR')),
            DataColumn(label: Text('ACTION / CATEGORY')),
            DataColumn(label: Text('TARGET OBJECT')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: [
            for (final doc in docs)
              DataRow(
                cells: [
                  DataCell(Text(_timestamp(doc.data()['timestamp']))),
                  DataCell(
                    _ActorCell(
                      data: usersById[doc.data()['actorUserId']],
                      id: '${doc.data()['actorUserId'] ?? '—'}',
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        adminLabel('${doc.data()['action'] ?? 'event'}'),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        '${doc.data()['targetType'] ?? '—'} · ${doc.data()['targetId'] ?? '—'}',
                      ),
                    ),
                  ),
                  DataCell(
                    _ResultBadge('${doc.data()['result'] ?? 'unknown'}'),
                  ),
                  DataCell(
                    IconButton(
                      tooltip: 'View activity event',
                      onPressed: () => _showDetails(
                        context,
                        doc.data(),
                        actor: _actorLabel(
                          usersById[doc.data()['actorUserId']],
                          '${doc.data()['actorUserId'] ?? 'Unknown actor'}',
                        ),
                      ),
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );

  void _showDetails(
    BuildContext context,
    Map<String, dynamic> data, {
    required String actor,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _AuditDetailsDialog(data: data, actor: actor),
    );
  }
}

class _AuditDetailsDialog extends StatelessWidget {
  const _AuditDetailsDialog({required this.data, required this.actor});

  final Map<String, dynamic> data;
  final String actor;

  static const _preferredFields = [
    'newValue',
    'timestamp',
    'targetType',
    'oldValue',
    'result',
    'actorUserId',
    'actorRole',
    'action',
    'targetId',
  ];

  @override
  Widget build(BuildContext context) {
    final fields = <String>[
      ..._preferredFields.where(data.containsKey),
      ...data.keys.where((key) => !_preferredFields.contains(key)),
    ];
    final action = '${data['action'] ?? 'activity event'}';
    final result = '${data['result'] ?? 'unknown'}';
    final targetType = '${data['targetType'] ?? 'record'}';
    final targetId = '${data['targetId'] ?? 'Unknown'}';
    final oldStatus = _mapValue(data['oldValue'], 'status');
    final newStatus = _mapValue(data['newValue'], 'status');
    final hasStatusChange = oldStatus != null && newStatus != null;

    return AlertDialog(
      title: Text(adminLabel(action)),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuditSummaryCard(
                action: action,
                result: result,
                targetType: targetType,
                targetId: targetId,
                actor: actor,
                oldStatus: oldStatus,
                newStatus: newStatus,
                hasStatusChange: hasStatusChange,
                timestamp: data['timestamp'],
              ),
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text(
                  'Technical details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Original audit record values'),
                children: [
                  for (final field in fields) ...[
                    _AuditDetailRow(
                      label: field,
                      value: _formatAuditValue(data[field]),
                    ),
                    if (field != fields.last) const Divider(height: 20),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AuditSummaryCard extends StatelessWidget {
  const _AuditSummaryCard({
    required this.action,
    required this.result,
    required this.targetType,
    required this.targetId,
    required this.actor,
    required this.oldStatus,
    required this.newStatus,
    required this.hasStatusChange,
    required this.timestamp,
  });

  final String action;
  final String result;
  final String targetType;
  final String targetId;
  final String actor;
  final String? oldStatus;
  final String? newStatus;
  final bool hasStatusChange;
  final dynamic timestamp;

  @override
  Widget build(BuildContext context) {
    final success = result == 'success';
    final resultColor = success
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasStatusChange)
            Text(
              'Status changed from ${adminLabel(oldStatus!)} to ${adminLabel(newStatus!)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              adminLabel(action),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 12),
          _SummaryLine(label: 'Result', value: adminLabel(result), color: resultColor),
          _SummaryLine(
            label: 'Target',
            value: '${adminLabel(targetType)} · $targetId',
          ),
          _SummaryLine(label: 'Performed by', value: actor),
          if (dataTimestamp(timestamp).isNotEmpty)
            _SummaryLine(label: 'When', value: dataTimestamp(timestamp)),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: color == null ? null : FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

String _actorLabel(Map<String, dynamic>? data, String fallback) {
  final name = data?['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  final email = data?['email'];
  if (email is String && email.trim().isNotEmpty) return email.trim();
  return fallback;
}

String? _mapValue(dynamic value, String key) {
  if (value is Map && value[key] != null) return '${value[key]}';
  return null;
}

String dataTimestamp(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} at $hour:$minute';
  }
  return '';
}

class _AuditDetailRow extends StatelessWidget {
  const _AuditDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(height: 1.45),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

String _formatAuditValue(dynamic value) {
  if (value == null) return '—';
  if (value is Timestamp) {
    return 'Timestamp(seconds=${value.seconds}, nanoseconds=${value.nanoseconds})';
  }
  if (value is Map) {
    final entries = value.entries
        .map((entry) => '${entry.key}: ${_formatAuditValue(entry.value)}')
        .join(', ');
    return '{$entries}';
  }
  if (value is Iterable) {
    return '[${value.map(_formatAuditValue).join(', ')}]';
  }
  return '$value';
}

class _ActorCell extends StatelessWidget {
  const _ActorCell({required this.data, required this.id});
  final Map<String, dynamic>? data;
  final String id;

  @override
  Widget build(BuildContext context) {
    final name = adminUserLabel(data);
    return SizedBox(
      width: 180,
      child: Row(
        children: [
          CircleAvatar(radius: 16, child: Text(adminInitial(name))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name == 'Profile unavailable' ? id : name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge(this.result);
  final String result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      'success' => Theme.of(context).colorScheme.tertiary,
      'failure' || 'denied' => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        adminLabel(result),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _timestamp(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  return '—';
}
