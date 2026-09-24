import 'package:shared/entities/request_entity.dart';
import 'package:shared/entities/status_history_entity.dart';

abstract class RequestRepository {
  Stream<List<({String id, RequestEntity request})>> watchRequests();
  Stream<List<({String id, StatusHistoryEntity history})>> watchRequestHistory(
    String requestId,
  );
  Future<void> assignRequest(String requestId, String agentId);
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? note,
  });
}
