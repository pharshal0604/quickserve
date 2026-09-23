import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/injection_container.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String search = '';
  String result = 'all';

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<({String id, AuditLogEntity log})>>(
    stream: ref.watch(watchAuditLogsProvider).call(),
    builder: (context, snapshot) {
      final all = snapshot.data ?? const [];
      final filtered = all.where((doc) {
        final data = doc.log;
        final needle = search.trim().toLowerCase();
        final searchable = [
          data.action.name,
          data.actorUserId,
          data.targetId,
          data.targetType,
        ].join(' ').toLowerCase();
        return (needle.isEmpty || searchable.contains(needle)) &&
            (result == 'all' || data.result == result);
      }).toList();

      return StreamBuilder<List<({String id, UserEntity user})>>(
        stream: ref.watch(watchUsersProvider).call(),
        builder: (context, usersSnapshot) {
          final usersById = <String, UserEntity>{
            for (final doc in usersSnapshot.data ?? const [])
              doc.id: doc.user,
          };
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
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/activity/notifications'),
                    icon: const Icon(Icons.notifications_none),
                    label: const Text('System Notifications'),
                  ),
                ],
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
  final List<({String id, AuditLogEntity log})> docs;
  final Map<String, UserEntity> usersById;

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
                  DataCell(Text(_timestamp(doc.log.timestamp))),
                  DataCell(
                    _ActorCell(
                      user: usersById[doc.log.actorUserId],
                      id: doc.log.actorUserId,
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        adminLabel(doc.log.action.name),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        '${doc.log.targetType} · ${doc.log.targetId}',
                      ),
                    ),
                  ),
                  DataCell(
                    _ResultBadge(doc.log.result),
                  ),
                  DataCell(
                    IconButton(
                      tooltip: 'View activity event',
                      onPressed: () => _showDetails(
                        context,
                        doc.log,
                        actor: _actorLabel(
                          usersById[doc.log.actorUserId],
                          doc.log.actorUserId,
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
    AuditLogEntity log, {
    required String actor,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _AuditDetailsDialog(log: log, actor: actor),
    );
  }
}

class _AuditDetailsDialog extends StatelessWidget {
  const _AuditDetailsDialog({required this.log, required this.actor});

  final AuditLogEntity log;
  final String actor;

  @override
  Widget build(BuildContext context) {
    final action = log.action.name;
    final result = log.result;
    final targetType = log.targetType;
    final targetId = log.targetId;
    final oldStatus = _mapValue(log.oldValue, 'status');
    final newStatus = _mapValue(log.newValue, 'status');
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
                timestamp: log.timestamp,
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
                  _AuditDetailRow(label: 'actorUserId', value: log.actorUserId),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'actorRole', value: log.actorRole.name),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'action', value: log.action.name),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'targetType', value: log.targetType),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'targetId', value: log.targetId),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'oldValue', value: _formatAuditValue(log.oldValue)),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'newValue', value: _formatAuditValue(log.newValue)),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'result', value: log.result),
                  const Divider(height: 20),
                  _AuditDetailRow(label: 'timestamp', value: log.timestamp.toString()),
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
  final DateTime timestamp;

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

String _actorLabel(UserEntity? user, String fallback) {
  final name = user?.name;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  final email = user?.email;
  if (email != null && email.trim().isNotEmpty) return email.trim();
  return fallback;
}

String? _mapValue(dynamic value, String key) {
  if (value is Map && value[key] != null) return '${value[key]}';
  return null;
}

String dataTimestamp(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} at $hour:$minute';
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
  const _ActorCell({required this.user, required this.id});
  final UserEntity? user;
  final String id;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Profile unavailable';
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

String _timestamp(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}\n${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
