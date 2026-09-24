import '../repositories/agent_repository.dart';

import 'package:shared/entities/user_entity.dart';

class GetAgentDetails {
  final AgentRepository repository;
  GetAgentDetails(this.repository);
  Future<({String id, UserEntity user})?> call(String agentId) =>
      repository.getAgentDetails(agentId);
}
