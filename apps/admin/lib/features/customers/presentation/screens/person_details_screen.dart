import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class PersonDetailsScreen extends StatelessWidget {
  const PersonDetailsScreen({
    required this.repository,
    required this.userId,
    required this.role,
    required this.data,
    super.key,
  });

  final AdminRepository repository;
  final String userId;
  final String role;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackButton(),
      title: Text(
        role == RoleNames.customer ? 'Customer profile' : 'Agent profile',
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.watchRequests(),
      builder: (context, snapshot) {
        final requests = (snapshot.data?.docs ?? const []).where((doc) {
          final item = doc.data();
          return role == RoleNames.customer
              ? item['customerId'] == userId
              : item['agentId'] == userId;
        }).toList();
        final active = requests
            .where(
              (doc) => ![
                StatusNames.completed,
                StatusNames.cancelled,
              ].contains(doc.data()['status']),
            )
            .toList();
        final completed = requests
            .where((doc) => doc.data()['status'] == StatusNames.completed)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final profile = _ProfileCard(
                  data: data,
                  userId: userId,
                  role: role,
                );
                final summary = _ProfileSummary(
                  requests: requests,
                  active: active,
                  completed: completed,
                );
                return constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 320, child: profile),
                          const SizedBox(width: 20),
                          Expanded(child: summary),
                        ],
                      )
                    : Column(
                        children: [
                          profile,
                          const SizedBox(height: 16),
                          summary,
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            DefaultTabController(
              length: 2,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Service History'),
                        Tab(text: 'Activity Log'),
                      ],
                    ),
                    SizedBox(
                      height: 430,
                      child: TabBarView(
                        children: [
                          _RequestTable(
                            title: 'Recent service history',
                            docs: completed,
                          ),
                          _ActivityPlaceholder(
                            repository: repository,
                            userId: userId,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _RequestTable(title: 'Active requests', docs: active),
          ],
        );
      },
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.data,
    required this.userId,
    required this.role,
  });

  final Map<String, dynamic> data;
  final String userId;
  final String role;

  @override
  Widget build(BuildContext context) {
    final name = '${data['name'] ?? userId}';
    final status = '${data['status'] ?? 'active'}';
    final scheme = Theme.of(context).colorScheme;
    final statusColor = status == 'active'
        ? scheme.tertiary
        : scheme.outline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                adminInitial(name),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(role == RoleNames.customer ? 'Customer' : 'Service agent'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                adminLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 30),
            _ContactLine(
              icon: Icons.mail_outline,
              value: '${data['email'] ?? 'No email'}',
            ),
            _ContactLine(
              icon: Icons.phone_outlined,
              value: '${data['phone'] ?? 'No phone'}',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Profile editing is not enabled in the current admin scope.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.requests,
    required this.active,
    required this.completed,
  });
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> requests;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> active;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> completed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Profile overview', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricCard(
            label: 'Total requests',
            value: requests.length.toString(),
            icon: Icons.assignment_outlined,
          ),
          _MetricCard(
            label: 'Active requests',
            value: active.length.toString(),
            icon: Icons.pending_actions_outlined,
          ),
          _MetricCard(
            label: 'Completed',
            value: completed.length.toString(),
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Membership, spend, payment methods, and profile photos are not stored in the current QuickServe user schema.',
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RequestTable extends StatelessWidget {
  const _RequestTable({required this.title, required this.docs});
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No requests in this section.'),
            ),
          if (docs.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 46,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 70,
                columns: const [
                  DataColumn(label: Text('REQUEST')),
                  DataColumn(label: Text('SERVICE')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: [
                  for (final doc in docs)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${doc.data()['requestCode'] ?? doc.id}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(
                          Text(
                            adminLabel(
                              '${doc.data()['serviceType'] ?? 'Service'}',
                            ),
                          ),
                        ),
                        DataCell(Text(_date(doc.data()['preferredDateTime']))),
                        DataCell(
                          _StatusBadge('${doc.data()['status'] ?? 'unknown'}'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
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

class _ActivityPlaceholder extends StatelessWidget {
  const _ActivityPlaceholder({required this.repository, required this.userId});
  final AdminRepository repository;
  final String userId;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: repository.watchAuditLogs(),
    builder: (context, snapshot) {
      final docs = (snapshot.data?.docs ?? const []).where((doc) {
        final data = doc.data();
        return data['actorUserId'] == userId || data['targetId'] == userId;
      }).toList();
      if (docs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No activity is recorded for this profile yet.'),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: docs.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final data = docs[index].data();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.history, size: 18)),
            title: Text(adminLabel('${data['action'] ?? 'event'}')),
            subtitle: Text(
              '${data['targetType'] ?? 'Target'} · ${data['targetId'] ?? '—'}',
            ),
            trailing: Text(_dateTime(data['timestamp'])),
          );
        },
      );
    },
  );
}

String _dateTime(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  return '—';
}

String _date(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  return '—';
}
