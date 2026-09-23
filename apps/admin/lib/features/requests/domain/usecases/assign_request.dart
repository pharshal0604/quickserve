import '../repositories/request_repository.dart';

class AssignRequest {
  final RequestRepository repository;
  AssignRequest(this.repository);
  Future<void> call(String requestId, String agentId) => repository.assignRequest(requestId, agentId);
}
