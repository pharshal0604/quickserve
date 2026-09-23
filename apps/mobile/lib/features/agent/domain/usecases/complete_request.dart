import '../repositories/agent_repository_interface.dart';
import 'accept_request.dart'; // Reuse AgentRequestParams

/// Use case to complete a request.
class CompleteRequest {
  /// Creates the usecase.
  const CompleteRequest(this._repository);
  final AgentRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(AgentRequestParams params) => _repository.completeRequest(
        requestId: params.requestId,
        agentId: params.agentId,
      );
}
