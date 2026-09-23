import '../../domain/repositories/request_repository.dart';
import '../data_sources/request_remote_data_source.dart';
import 'package:shared/models/request.dart';
import 'package:shared/models/status_history.dart';
import 'package:shared/entities/request_entity.dart';
import 'package:shared/entities/status_history_entity.dart';

class RequestRepositoryImpl implements RequestRepository {
  final RequestRemoteDataSource remoteDataSource;

  RequestRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<({String id, RequestEntity request})>> watchRequests() {
    return remoteDataSource.watchRequests().map((snapshot) {
      return snapshot.docs.map((doc) => (id: doc.id, request: Request.fromMap(doc.data() as Map<String, dynamic>).toEntity())).toList();
    });
  }

  @override
  Stream<List<({String id, StatusHistoryEntity history})>> watchRequestHistory(String requestId) {
    return remoteDataSource.watchRequestHistory(requestId).map((snapshot) {
      return snapshot.docs.map((doc) => (id: doc.id, history: StatusHistory.fromMap(doc.data() as Map<String, dynamic>).toEntity())).toList();
    });
  }

  @override
  Future<void> assignRequest(String requestId, String agentId) {
    return remoteDataSource.assignRequest(requestId, agentId);
  }

  @override
  Future<void> updateRequestStatus(String requestId, String status, {String? note}) {
    return remoteDataSource.updateRequestStatus(requestId, status, note: note);
  }
}
