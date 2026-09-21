import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../admin_repository.dart';
import '../../../../shared/admin_formatters.dart';

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
      final docs = (snapshot.data?.docs ?? const []).where((doc) {
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
                    const Text(
                      'Review administrative actions, authorization failures, and database events.',
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export logs'),
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
                    width: 420,
                    child: TextField(
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Search by action, actor, target, or ID',
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
                      DropdownMenuItem(value: 'denied', child: Text('Denied')),
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
                    child: Text('Unable to load activity: ${snapshot.error}'),
                  )
                : docs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No activity matches the current filters.'),
                  )
                : Column(
                    children: [
                      for (final doc in docs) _ActivityRow(data: doc.data()),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final outcome = '${data['result'] ?? 'unknown'}';
    final time = data['timestamp'] as Timestamp?;
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          outcome == 'success' ? Icons.check : Icons.warning_amber_outlined,
        ),
      ),
      title: Text(adminLabel('${data['action'] ?? 'event'}')),
      subtitle: Text(
        'Actor: ${data['actorUserId'] ?? '—'} · Target: ${data['targetId'] ?? '—'}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Chip(label: Text(outcome)),
          if (time != null)
            Text(
              time.toDate().toLocal().toString().split('.').first,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
