import '../repositories/agent_repository.dart';

import 'package:shared/entities/user_entity.dart';

class WatchAgents {
  final AgentRepository repository;
  WatchAgents(this.repository);
  Stream<List<({String id, UserEntity user})>> call() =>
      repository.watchAgents();
}
