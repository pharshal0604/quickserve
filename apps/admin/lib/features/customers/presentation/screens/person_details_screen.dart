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
      title: Text(
        '${role == RoleNames.customer ? 'Customer' : 'Agent'} profile',
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(adminInitial(data['name'])),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['name'] ?? userId}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${data['email'] ?? 'No email'} · ${data['phone'] ?? 'No phone'}',
                          ),
                          const SizedBox(height: 6),
                          Chip(label: Text('${data['status'] ?? 'active'}')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard('All requests', requests.length),
                _SummaryCard('Active', active.length),
                _SummaryCard('Completed', completed.length),
              ],
            ),
            const SizedBox(height: 16),
            _RequestSection(title: 'Active requests', docs: active),
            const SizedBox(height: 16),
            _RequestSection(
              title: 'Completed request history',
              docs: completed,
            ),
          ],
        );
      },
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.title, required this.docs});
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (docs.isEmpty) const Text('No requests in this section.'),
          for (final doc in docs)
            Builder(
              builder: (context) {
                final status = '${doc.data()['status'] ?? 'unknown'}';
                final statusColor = adminStatusColor(context, status);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(adminStatusIcon(status), color: statusColor),
                  title: Text(
                    '${doc.data()['requestCode'] ?? doc.id} · ${doc.data()['serviceType'] ?? 'Service'}',
                  ),
                  subtitle: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${doc.data()['address'] ?? 'No address'} · ',
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
                );
              },
            ),
        ],
      ),
    ),
  );
}
