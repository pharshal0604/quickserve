import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';

import '../../../customers/presentation/screens/people_screen.dart';
import 'agent_details_screen.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({required this.repository, this.onAgentSelected, super.key});
  final AdminRepository repository;
  final ValueChanged<({String userId, Map<String, dynamic> data})>?
  onAgentSelected;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          PeopleScreen(
            repository: repository,
            role: RoleNames.agent,
            onDetails: onAgentSelected,
            detailsBuilder: (context, userId, data) => AgentDetailsScreen(
                repository: repository, userId: userId, data: data),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Dummy Agent'),
              onPressed: () async {
                final id = 'dummy_agent_${DateTime.now().millisecondsSinceEpoch}';
                await repository.firestore.collection('users').doc(id).set({
                  'role': RoleNames.agent,
                  'name': 'Test Agent',
                  'email': 'agent@example.com',
                  'phone': '555-0199',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dummy agent created!')),
                  );
                }
              },
            ),
          ),
        ],
      );
}
