import '../repositories/agent_repository_interface.dart';
import 'accept_request.dart'; // Reuse AgentRequestParams

/// Use case to start a request.
class StartRequest {
  /// Creates the usecase.
  const StartRequest(this._repository);
  final AgentRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(AgentRequestParams params) => _repository.startRequest(
        requestId: params.requestId,
        agentId: params.agentId,
      );
}
