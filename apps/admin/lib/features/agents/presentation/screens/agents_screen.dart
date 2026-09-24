import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../../customers/presentation/screens/people_screen.dart';
import 'agent_details_screen.dart';

import 'package:quickserve_admin/injection_container.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({this.onAgentSelected, super.key});

  final ValueChanged<({String userId, UserEntity user})>? onAgentSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
    children: [
      PeopleScreen(
        role: RoleNames.agent,
        onDetails: onAgentSelected,
        detailsBuilder: (context, userId, user) =>
            AgentDetailsScreen(agentId: userId),
      ),
      Positioned(
        top: 24,
        right: 24,
        child: FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Create Dummy Agent'),
          onPressed: () async {
            await ref
                .read(createDummyAgentProvider)
                .call(
                  UserEntity(
                    role: UserRole.agent,
                    name: 'Test Agent',
                    email: 'agent@example.com',
                    phone: '123-456-7890',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dummy agent created')),
              );
            }
          },
        ),
      ),
    ],
  );
}
