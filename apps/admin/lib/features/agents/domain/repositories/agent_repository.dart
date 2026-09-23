import 'package:shared/entities/user_entity.dart';

abstract class AgentRepository {
  Stream<List<({String id, UserEntity user})>> watchAgents();
  Future<({String id, UserEntity user})?> getAgentDetails(String agentId);
  Future<void> updateAgentSchedule(String agentId, Map<String, dynamic> schedule);
  Future<void> createDummyAgent(UserEntity agent);
}
