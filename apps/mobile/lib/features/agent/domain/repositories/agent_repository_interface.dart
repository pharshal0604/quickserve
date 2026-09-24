import 'package:shared/shared.dart' as shared;

/// Abstract repository interface for agent operations.
abstract class AgentRepositoryInterface {
  /// Streams requests assigned to an agent.
  Stream<List<({String id, shared.RequestEntity request})>> watchAssignedRequests(String agentId);

  /// Accepts an assigned request.
  Future<void> acceptAssignedRequest({
    required String requestId,
    required String agentId,
  });

  /// Starts work on a request.
  Future<void> startRequest({
    required String requestId,
    required String agentId,
  });

  /// Completes an in-progress request.
  Future<void> completeRequest({
    required String requestId,
    required String agentId,
    String note,
  });
}
