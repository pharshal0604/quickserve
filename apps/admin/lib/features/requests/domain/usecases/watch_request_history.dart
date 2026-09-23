import '../repositories/request_repository.dart';
import 'package:shared/entities/status_history_entity.dart';

class WatchRequestHistory {
  final RequestRepository repository;
  WatchRequestHistory(this.repository);
  Stream<List<({String id, StatusHistoryEntity history})>> call(String requestId) => repository.watchRequestHistory(requestId);
}
