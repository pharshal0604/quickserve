import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/shared/admin_formatters.dart';
import 'package:quickserve_admin/injection_container.dart';

import '../../../requests/presentation/screens/request_details_screen.dart';
import '../../../requests/presentation/screens/requests_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => StreamBuilder<List<({String id, RequestEntity request})>>(
    stream: ref.watch(watchRequestsProvider).call(),
    builder: (context, snapshot) {
      final docs = snapshot.data ?? [];
      final counts = <String, int>{
        for (final status in StatusNames.values)
          status: docs.where((doc) => doc.request.status.toStoredValue() == status).length,
      };
      final recent = [...docs]
        ..sort((a, b) => b.request.updatedAt.compareTo(a.request.updatedAt));
      final critical = recent
          .where((doc) {
            final request = doc.request;
            final active = ![
              StatusNames.completed,
              StatusNames.cancelled,
            ].contains(request.status.toStoredValue());
            return active &&
                (request.priority.name == PriorityNames.high ||
                    (request.status.toStoredValue() == StatusNames.created &&
                        request.agentId == null));
          })
          .take(4)
          .toList();
      final active = docs
          .where(
            (doc) => ![
              StatusNames.completed,
              StatusNames.cancelled,
            ].contains(doc.request.status.toStoredValue()),
          )
          .toList();
      final completed = docs
          .where((doc) => doc.request.status.toStoredValue() == StatusNames.completed)
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatusChart(counts: counts, total: docs.length),
          const SizedBox(height: 20),
          _RecentRequests(docs: recent.take(6).toList()),
          if (snapshot.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Unable to load live requests: ${snapshot.error}'),
            ),
        ],
      );
    },
  );
}

void _showMetricDetails(
  BuildContext context, {
  required String title,
  required String description,
  required List<({String id, RequestEntity request})> docs,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => _MetricDetailsDialog(
      title: title,
      description: description,
      docs: docs,
    ),
  );
}

class _MetricDetailsDialog extends StatelessWidget {
  const _MetricDetailsDialog({
    required this.title,
    required this.description,
    required this.docs,
  });

  final String title;
  final String description;
  final List<({String id, RequestEntity request})> docs;

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
                    final request = doc.request;
                    final status = request.status.toStoredValue();
                    final statusColor = adminStatusColor(context, status);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Icon(
                        adminStatusIcon(status),
                        color: statusColor,
                      ),
                      title: Text(
                        '${request.requestCode} · ${request.serviceType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${adminLabel(status)} · ${request.address}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _openRequest(context, doc);
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
                              '${counts[status]}',
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

class _RecentRequests extends ConsumerWidget {
  const _RecentRequests({required this.docs});
  final List<({String id, RequestEntity request})> docs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<({String id, UserEntity user})>>(
      stream: ref.watch(watchCustomersProvider).call(),
      builder: (context, usersSnapshot) {
        final usersById = {
          for (final doc in usersSnapshot.data ?? const []) doc.id: doc.user,
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
                          builder: (_) => const RequestsScreen(),
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
                      final status = doc.request.status.toStoredValue();
                      final statusColor = adminStatusColor(context, status);
                      final customer = usersById[doc.request.customerId];
                      final customerName =
                          customer?.name ?? doc.request.customerId;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          adminStatusIcon(status),
                          color: statusColor,
                        ),
                        title: Text(
                          '${doc.request.requestCode} · ${doc.request.serviceType}',
                        ),
                        subtitle: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '$customerName · '),
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
                        onTap: () => _openRequest(context, doc),
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

void _openRequest(
  BuildContext context,
  ({String id, RequestEntity request}) doc,
) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => RequestDetailsScreen(requestId: doc.id)),
  );
}
