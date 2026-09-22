import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

import '../../../requests/presentation/screens/request_details_screen.dart';
import '../../../requests/presentation/screens/requests_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.repository, super.key});

  final AdminRepository repository;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: repository.watchRequests(),
    builder: (context, snapshot) {
      final docs = snapshot.data?.docs ?? const [];
      final counts = <String, int>{
        for (final status in StatusNames.values)
          status: docs.where((doc) => doc.data()['status'] == status).length,
      };
      final recent = [...docs]
        ..sort((a, b) => _updatedAt(b).compareTo(_updatedAt(a)));
      final critical = recent
          .where((doc) {
            final data = doc.data();
            final active = ![
              StatusNames.completed,
              StatusNames.cancelled,
            ].contains(data['status']);
            return active &&
                (data['priority'] == PriorityNames.high ||
                    (data['status'] == StatusNames.created &&
                        data['agentId'] == null));
          })
          .take(4)
          .toList();
      final active = docs
          .where(
            (doc) => ![
              StatusNames.completed,
              StatusNames.cancelled,
            ].contains(doc.data()['status']),
          )
          .toList();
      final completed = docs
          .where((doc) => doc.data()['status'] == StatusNames.completed)
          .toList();

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
                      'Dashboard Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitor requests, agents, and service operations.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Total requests',
                value: docs.length,
                icon: Icons.assignment_outlined,
                onTap: () => _showMetricDetails(
                  context,
                  title: 'Total requests',
                  description: 'All service requests currently recorded.',
                  docs: docs,
                  repository: repository,
                ),
              ),
              _Metric(
                label: 'Active requests',
                value: active.length,
                icon: Icons.timelapse_outlined,
                onTap: () => _showMetricDetails(
                  context,
                  title: 'Active requests',
                  description: 'Requests that are not completed or cancelled.',
                  docs: active,
                  repository: repository,
                ),
              ),
              _Metric(
                label: 'Completed',
                value: completed.length,
                icon: Icons.check_circle_outline,
                onTap: () => _showMetricDetails(
                  context,
                  title: 'Completed requests',
                  description: 'Requests that reached the completed status.',
                  docs: completed,
                  repository: repository,
                ),
              ),
              _Metric(
                label: 'Critical alerts',
                value: critical.length,
                icon: Icons.warning_amber_outlined,
                onTap: () => _showMetricDetails(
                  context,
                  title: 'Critical alerts',
                  description: 'High-priority active requests or requests waiting for assignment.',
                  docs: critical,
                  repository: repository,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = _StatusChart(counts: counts, total: docs.length);
              final alerts = _CriticalAlerts(
                docs: critical,
                repository: repository,
              );
              return constraints.maxWidth >= 900
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: chart),
                        const SizedBox(width: 16),
                        Expanded(child: alerts),
                      ],
                    )
                  : Column(
                      children: [chart, const SizedBox(height: 16), alerts],
                    );
            },
          ),
          const SizedBox(height: 20),
          _RecentRequests(
            docs: recent.take(6).toList(),
            repository: repository,
          ),
          if (snapshot.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Unable to load live requests: ${snapshot.error}'),
            ),
        ],
      );
    },
  );

  static DateTime _updatedAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()['updatedAt'];
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}

void _showMetricDetails(
  BuildContext context, {
  required String title,
  required String description,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  required AdminRepository repository,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => _MetricDetailsDialog(
      title: title,
      description: description,
      docs: docs,
      repository: repository,
    ),
  );
}

class _MetricDetailsDialog extends StatelessWidget {
  const _MetricDetailsDialog({
    required this.title,
    required this.description,
    required this.docs,
    required this.repository,
  });

  final String title;
  final String description;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(description),
            const SizedBox(height: 6),
            Text(
              '${docs.length} matching record${docs.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No matching request data is available.'),
              )
            else
              SizedBox(
                height: 390,
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final status = '${data['status'] ?? 'unknown'}';
                    final statusColor = adminStatusColor(context, status);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Icon(
                        adminStatusIcon(status),
                        color: statusColor,
                      ),
                      title: Text(
                        '${data['requestCode'] ?? doc.id} · ${data['serviceType'] ?? 'Service'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${adminLabel(status)} · ${data['address'] ?? 'Address not provided'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _openRequest(context, repository, doc);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: .18),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.counts, required this.total});
  final Map<String, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Live distribution across the service lifecycle',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _DoughnutPainter(
                    values: [
                      for (final status in StatusNames.values)
                        counts[status] ?? 0,
                    ],
                    colors: [
                      for (final status in StatusNames.values)
                        adminStatusColor(context, status),
                    ],
                    emptyColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text('Requests'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final status in StatusNames.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: adminStatusColor(context, status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adminLabel(status),
                                style: TextStyle(
                                  color: adminStatusColor(context, status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${counts[status] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DoughnutPainter extends CustomPainter {
  const _DoughnutPainter({
    required this.values,
    required this.colors,
    required this.emptyColor,
  });
  final List<int> values;
  final List<Color> colors;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(
      0,
      (runningTotal, value) => runningTotal + value,
    );
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.butt;
    if (total == 0) {
      paint.color = emptyColor.withValues(alpha: .45);
      canvas.drawArc(rect.deflate(16), 0, math.pi * 2, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = math.pi * 2 * values[index] / total;
      if (sweep <= 0) continue;
      paint.color = colors[index];
      canvas.drawArc(rect.deflate(16), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.emptyColor != emptyColor;
}

class _RecentRequests extends StatelessWidget {
  const _RecentRequests({required this.docs, required this.repository});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.watchUsers(role: RoleNames.customer),
      builder: (context, usersSnapshot) {
        final usersById = {
          for (final doc in usersSnapshot.data?.docs ?? const [])
            doc.id: doc.data(),
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent service requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestsScreen(repository: repository),
                        ),
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (docs.isEmpty) const Text('No requests are available.'),
                for (final doc in docs)
                  Builder(
                    builder: (context) {
                      final status = '${doc.data()['status'] ?? 'unknown'}';
                      final statusColor = adminStatusColor(context, status);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          adminStatusIcon(status),
                          color: statusColor,
                        ),
                        title: Text(
                          '${doc.data()['requestCode'] ?? doc.id} · ${doc.data()['serviceType'] ?? 'Service'}',
                        ),
                        subtitle: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${adminUserLabel(usersById[doc.data()['customerId']])} · ',
                              ),
                              TextSpan(
                                text: adminLabel(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openRequest(context, repository, doc),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CriticalAlerts extends StatelessWidget {
  const _CriticalAlerts({required this.docs, required this.repository});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Critical alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${docs.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (docs.isEmpty) const Text('No critical alerts right now.'),
          for (final doc in docs)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: Text(
                '${doc.data()['requestCode'] ?? doc.id} · ${doc.data()['priority'] ?? 'Unassigned'}',
              ),
              subtitle: Text(
                doc.data()['status'] == StatusNames.created
                    ? 'Waiting for agent assignment'
                    : 'High-priority request',
              ),
              onTap: () => _openRequest(context, repository, doc),
            ),
        ],
      ),
    ),
  );
}

void _openRequest(
  BuildContext context,
  AdminRepository repository,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RequestDetailsScreen(
        repository: repository,
        requestId: doc.id,
        data: doc.data(),
      ),
    ),
  );
}
