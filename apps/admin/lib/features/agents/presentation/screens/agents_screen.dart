import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../admin_repository.dart';
import '../../../customers/presentation/screens/people_screen.dart';
import 'agent_details_screen.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({required this.repository, super.key});
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) => PeopleScreen(
    repository: repository,
    role: RoleNames.agent,
    detailsBuilder: (context, userId, data) =>
        AgentDetailsScreen(repository: repository, userId: userId, data: data),
  );
}
