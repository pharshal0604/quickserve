import '../repositories/request_repository.dart';

class UpdateRequestStatus {
  final RequestRepository repository;
  UpdateRequestStatus(this.repository);
  Future<void> call(String requestId, String status, {String? note}) => repository.updateRequestStatus(requestId, status, note: note);
}
