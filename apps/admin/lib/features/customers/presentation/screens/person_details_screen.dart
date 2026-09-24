import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/injection_container.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class PersonDetailsScreen extends ConsumerWidget {
  const PersonDetailsScreen({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: const BackButton(),
      title: const Text('Customer profile'),
    ),
    body: StreamBuilder<List<({String id, RequestEntity request})>>(
      stream: ref.watch(watchRequestsProvider).call(),
      builder: (context, snapshot) {
        final requests = (snapshot.data ?? const []).where((doc) {
          final item = doc.request;
          return item.customerId == customerId;
        }).toList();
        final active = requests
            .where(
              (doc) => ![
                StatusNames.completed,
                StatusNames.cancelled,
              ].contains(doc.request.status.toStoredValue()),
            )
            .toList();
        final completed = requests
            .where(
              (doc) =>
                  doc.request.status.toStoredValue() == StatusNames.completed,
            )
            .toList();

        return FutureBuilder<({String id, UserEntity user})?>(
          future: ref.watch(getCustomerDetailsProvider).call(customerId),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data?.user;
            if (user == null &&
                userSnapshot.connectionState != ConnectionState.waiting) {
              return const Center(child: Text('Customer not found'));
            }
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final profile = _ProfileCard(
                        user: user,
                        userId: customerId,
                        role: RoleNames.customer,
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
                  if (active.isNotEmpty) ...[
                    _RequestTable(title: 'Active requests', docs: active),
                    const SizedBox(height: 20),
                  ],
                  Expanded(
                    child: DefaultTabController(
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
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SingleChildScrollView(
                                    child: _RequestTable(
                                      title: 'Recent service history',
                                      docs: completed,
                                    ),
                                  ),
                                  _ActivityPlaceholder(userId: customerId),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.userId,
    required this.role,
  });

  final UserEntity user;
  final String userId;
  final String role;

  @override
  Widget build(BuildContext context) {
    final name = user.name;
    const status = 'active';
    final scheme = Theme.of(context).colorScheme;
    final statusColor = status == 'active' ? scheme.tertiary : scheme.outline;
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
            _ContactLine(icon: Icons.mail_outline, value: user.email),
            _ContactLine(icon: Icons.phone_outlined, value: user.phone),
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
  final List<({String id, RequestEntity request})> requests;
  final List<({String id, RequestEntity request})> active;
  final List<({String id, RequestEntity request})> completed;

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
  final List<({String id, RequestEntity request})> docs;

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
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                                  doc.request.requestCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(adminLabel(doc.request.serviceType)),
                              ),
                              DataCell(
                                Text(_date(doc.request.preferredDateTime)),
                              ),
                              DataCell(
                                _StatusBadge(
                                  doc.request.status.toStoredValue(),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
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

class _ActivityPlaceholder extends ConsumerWidget {
  const _ActivityPlaceholder({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      StreamBuilder<List<({String id, AuditLogEntity log})>>(
        stream: ref.watch(watchAuditLogsProvider).call(),
        builder: (context, snapshot) {
          final docs = (snapshot.data ?? const []).where((doc) {
            final data = doc.log;
            return data.actorUserId == userId || data.targetId == userId;
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
              final data = docs[index].log;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.history, size: 18),
                ),
                title: Text(adminLabel('${data.action}')),
                subtitle: Text('${data.targetType} · ${data.targetId}'),
                trailing: Text(_dateTime(data.timestamp)),
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
