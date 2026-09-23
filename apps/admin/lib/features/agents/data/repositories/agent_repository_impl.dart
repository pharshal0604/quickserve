import '../../domain/repositories/agent_repository.dart';
import '../data_sources/agent_remote_data_source.dart';
import 'package:shared/models/user.dart';
import 'package:shared/entities/user_entity.dart';

class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource remoteDataSource;

  AgentRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<({String id, UserEntity user})>> watchAgents() {
    return remoteDataSource.watchAgents().map((snapshot) {
      return snapshot.docs.map((doc) => (id: doc.id, user: User.fromMap(doc.data() as Map<String, dynamic>).toEntity())).toList();
    });
  }

  @override
  Future<({String id, UserEntity user})?> getAgentDetails(String agentId) async {
    final doc = await remoteDataSource.getAgentDetails(agentId);
    if (!doc.exists || doc.data() == null) return null;
    return (id: doc.id, user: User.fromMap(doc.data() as Map<String, dynamic>).toEntity());
  }

  @override
  Future<void> updateAgentSchedule(String agentId, Map<String, dynamic> schedule) {
    return remoteDataSource.updateAgentSchedule(agentId, schedule);
  }

  @override
  Future<void> createDummyAgent(UserEntity agent) {
    final model = User.fromEntity(agent);
    return remoteDataSource.createDummyAgent(model.toMap());
  }
}
