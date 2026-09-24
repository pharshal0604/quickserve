import '../repositories/agent_repository_interface.dart';

/// Parameters for agent request operations.
class AgentRequestParams {
  const AgentRequestParams({required this.requestId, required this.agentId});

  final String requestId;
  final String agentId;
}

/// Use case to accept an assigned request.
class AcceptRequest {
  /// Creates the usecase.
  const AcceptRequest(this._repository);
  final AgentRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(AgentRequestParams params) =>
      _repository.acceptAssignedRequest(
        requestId: params.requestId,
        agentId: params.agentId,
      );
}
