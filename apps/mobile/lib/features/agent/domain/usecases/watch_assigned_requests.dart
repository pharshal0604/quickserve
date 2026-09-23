import 'package:shared/shared.dart' as shared;
import '../repositories/agent_repository_interface.dart';

/// Use case to watch assigned requests for an agent.
class WatchAssignedRequests {
  /// Creates the usecase.
  const WatchAssignedRequests(this._repository);
  final AgentRepositoryInterface _repository;

  /// Executes the usecase.
  Stream<List<({String id, shared.RequestEntity request})>> call(String agentId) =>
      _repository.watchAssignedRequests(agentId);
}
