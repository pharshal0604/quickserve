import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickserve_admin/injection_container.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class AgentDetailsScreen extends ConsumerWidget {
  const AgentDetailsScreen({required this.agentId, this.onBack, super.key});

  final String agentId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<({String id, UserEntity user})?>(
      future: ref.watch(getAgentDetailsProvider).call(agentId),
      builder: (context, agentSnapshot) {
        if (agentSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userEntity = agentSnapshot.data?.user;
        if (userEntity == null) {
          return const Scaffold(body: Center(child: Text('Agent not found')));
        }
        final data = {
          'name': userEntity.name,
          'email': userEntity.email,
          'phone': userEntity.phone,
          'role': userEntity.role.name,
          'location': userEntity.office,
          'schedule': userEntity.schedule,
        };
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back to agents',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Agent profile'),
            actions: [
              OutlinedButton.icon(
                onPressed: () async {
                  final email = data['email'];
                  final phone = data['phone'];
                  if (email != null && email.isNotEmpty) {
                    final uri = Uri.parse('mailto:$email');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  } else if (phone != null && phone.isNotEmpty) {
                    final uri = Uri.parse('sms:$phone');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No contact info available.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.mail_outline, size: 17),
                label: const Text('Message'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  final controller = TextEditingController(
                    text: data['schedule'] ?? '',
                  );
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Update Schedule'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Mon-Fri 9AM-5PM',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ref.read(updateAgentScheduleProvider).call(
                              agentId,
                              {'schedule': controller.text},
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Schedule updated'),
                                ),
                              );
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 17),
                label: const Text('Update schedule'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: StreamBuilder<List<({String id, RequestEntity request})>>(
            stream: ref.watch(watchRequestsProvider).call(),
            builder: (context, snapshot) {
              final requests = (snapshot.data ?? const [])
                  .where((doc) => doc.request.agentId == agentId)
                  .toList();
              final completed = requests
                  .where(
                    (doc) =>
                        doc.request.status.toStoredValue() ==
                        StatusNames.completed,
                  )
                  .length;
              final active = requests
                  .where(
                    (doc) => ![
                      StatusNames.completed,
                      StatusNames.cancelled,
                    ].contains(doc.request.status.toStoredValue()),
                  )
                  .length;
              final successRate = requests.isEmpty
                  ? 0
                  : ((completed / requests.length) * 100).round();
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _ProfileHeader(data: data),
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
                              children: [
                                chart,
                                const SizedBox(height: 16),
                                workload,
                              ],
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
                              children: [
                                skills,
                                const SizedBox(height: 16),
                                history,
                              ],
                            );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data});
  final Map<String, dynamic> data;

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
                gridColor: Theme.of(context).colorScheme.outlineVariant,
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
              _legend(Theme.of(context).colorScheme.tertiary, 'Active $active'),
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
  const _TrendPainter({required this.color, required this.gridColor});
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor.withValues(alpha: .45)
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
      oldDelegate.color != color || oldDelegate.gridColor != gridColor;
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
                color: Theme.of(context).colorScheme.tertiaryContainer,
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
  final List<({String id, RequestEntity request})> requests;

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
          for (final reqItem in requests)
            Builder(
              builder: (context) {
                final status = reqItem.request.status.toStoredValue();
                final statusColor = adminStatusColor(context, status);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(adminStatusIcon(status), color: statusColor),
                  title: Text(' · '),
                  subtitle: Text(
                    adminLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
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
class _DeleteAgentDialog extends StatefulWidget {
  final String agentId;
  const _DeleteAgentDialog({required this.agentId});

  @override
  State<_DeleteAgentDialog> createState() => _DeleteAgentDialogState();
}

class _DeleteAgentDialogState extends State<_DeleteAgentDialog> {
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _delete() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter admin password');
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null || adminUser.email == null) {
        throw Exception("No admin logged in");
      }
      
      final cred = EmailAuthProvider.credential(
        email: adminUser.email!,
        password: password,
      );
      
      await adminUser.reauthenticateWithCredential(cred);

      // Deleting the document revokes all role-based permissions immediately
      await FirebaseFirestore.instance.collection('users').doc(widget.agentId).delete();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = (e.code == 'wrong-password' || e.code == 'invalid-credential') 
            ? 'Incorrect password' 
            : e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Agent', style: TextStyle(color: Colors.red)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this agent? This action cannot be undone.'),
            const SizedBox(height: 16),
            const Text('Please enter admin password to confirm:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Admin Password',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _loading ? null : _delete,
          child: _loading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Delete Agent'),
        ),
      ],
    );
  }
}

