import '../repositories/agent_repository.dart';

import 'package:shared/entities/user_entity.dart';

class CreateDummyAgent {
  final AgentRepository repository;
  CreateDummyAgent(this.repository);
  Future<void> call(UserEntity agent) => repository.createDummyAgent(agent);
}
