import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class AgentDetailsScreen extends StatelessWidget {
  const AgentDetailsScreen({
    required this.repository,
    required this.userId,
    required this.data,
    super.key,
  });

  final AdminRepository repository;
  final String userId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackButton(),
      title: const Text('Agent profile'),
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.mail_outline, size: 17),
          label: const Text('Message'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_month_outlined, size: 17),
          label: const Text('Update schedule'),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.watchRequests(),
      builder: (context, snapshot) {
        final requests = (snapshot.data?.docs ?? const [])
            .where((doc) => doc.data()['agentId'] == userId)
            .toList();
        final completed = requests
            .where((doc) => doc.data()['status'] == StatusNames.completed)
            .length;
        final active = requests
            .where(
              (doc) => ![
                StatusNames.completed,
                StatusNames.cancelled,
              ].contains(doc.data()['status']),
            )
            .length;
        final successRate = requests.isEmpty
            ? 0
            : ((completed / requests.length) * 100).round();
        final tenure = _tenure(data['createdAt']);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _ProfileHeader(data: data, tenure: tenure),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Kpi(
                  icon: Icons.work_outline,
                  label: 'Total jobs',
                  value: '${requests.length}',
                ),
                _Kpi(
                  icon: Icons.check_circle_outline,
                  label: 'Success rate',
                  value: '$successRate%',
                ),
                _Kpi(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Years tenure',
                  value: tenure,
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = _PerformanceCard(
                  completed: completed,
                  active: active,
                  total: requests.length,
                );
                final workload = _WorkloadCard(active: active);
                return constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: chart),
                          const SizedBox(width: 16),
                          Expanded(child: workload),
                        ],
                      )
                    : Column(
                        children: [chart, const SizedBox(height: 16), workload],
                      );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final skills = _SkillsCard(data: data);
                final history = _RecentJobs(
                  requests: requests.take(5).toList(),
                );
                return constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: skills),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: history),
                        ],
                      )
                    : Column(
                        children: [skills, const SizedBox(height: 16), history],
                      );
              },
            ),
          ],
        );
      },
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data, required this.tenure});
  final Map<String, dynamic> data;
  final String tenure;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              adminInitial(data['name']),
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['name'] ?? 'Service agent'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['specialization'] ?? 'Service professional'} · ${data['role'] ?? RoleNames.agent}',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('${data['status'] ?? 'active'}')),
                    Chip(label: Text('★ ${data['rating'] ?? '—'}')),
                  ],
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 650)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _detail(Icons.mail_outline, '${data['email'] ?? 'No email'}'),
                _detail(Icons.phone_outlined, '${data['phone'] ?? 'No phone'}'),
                _detail(
                  Icons.location_on_outlined,
                  '${data['location'] ?? 'Location not set'}',
                ),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _detail(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 15), const SizedBox(width: 7), Text(text)],
    ),
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.completed,
    required this.active,
    required this.total,
  });
  final int completed;
  final int active;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance trends',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Jobs completed and current workload metrics.'),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _TrendPainter(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(
                Theme.of(context).colorScheme.primary,
                'Completed $completed',
              ),
              const SizedBox(width: 18),
              _legend(Colors.amber, 'Active $active'),
              const Spacer(),
              Text(
                '$total total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _legend(Color color, String text) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(text),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(0, size.height * .72);
    for (var i = 1; i <= 6; i++) {
      final x = size.width * i / 6;
      final y = size.height * (.65 - math.sin(i * 1.2) * .16);
      path.lineTo(x, y);
    }
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WorkloadCard extends StatelessWidget {
  const _WorkloadCard({required this.active});
  final int active;

  @override
  Widget build(BuildContext context) {
    final capacity = math.min(active, 5);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current workload',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active tasks'),
                Text(
                  '$capacity / 5 cap',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: capacity / 5),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                active >= 5
                    ? 'High capacity reached. Avoid assigning new long-distance jobs.'
                    : 'Capacity available for new assignments.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final raw = data['skills'];
    final skills = raw is List && raw.isNotEmpty
        ? raw.map((item) => '$item').toList()
        : [
            'AC Maintenance',
            'Heating Repairs',
            'Ventilation Setup',
            'Smart Thermostats',
            'Duct Sealing',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills & specializations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final skill in skills) Chip(label: Text(skill))],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentJobs extends StatelessWidget {
  const _RecentJobs({required this.requests});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> requests;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent service requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty) const Text('No assigned requests yet.'),
          for (final request in requests)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                adminStatusIcon('${request.data()['status'] ?? ''}'),
              ),
              title: Text(
                '${request.data()['requestCode'] ?? request.id} · ${request.data()['serviceType'] ?? 'Service'}',
              ),
              subtitle: Text(
                adminLabel('${request.data()['status'] ?? 'unknown'}'),
              ),
            ),
        ],
      ),
    ),
  );
}

String _tenure(dynamic value) {
  if (value is! Timestamp) return '—';
  final days = DateTime.now().difference(value.toDate()).inDays;
  return '${(days / 365.25).toStringAsFixed(1)} yrs';
}
