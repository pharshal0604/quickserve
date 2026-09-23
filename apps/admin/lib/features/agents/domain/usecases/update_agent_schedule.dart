import '../repositories/agent_repository.dart';

class UpdateAgentSchedule {
  final AgentRepository repository;
  UpdateAgentSchedule(this.repository);
  Future<void> call(String agentId, Map<String, dynamic> schedule) => repository.updateAgentSchedule(agentId, schedule);
}
