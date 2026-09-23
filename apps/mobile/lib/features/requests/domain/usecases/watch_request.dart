import 'package:shared/shared.dart' as shared;
import '../repositories/request_repository_interface.dart';

/// Use case to watch a single request.
class WatchRequest {
  /// Creates the usecase.
  const WatchRequest(this._repository);
  final RequestRepositoryInterface _repository;

  /// Executes the usecase.
  Stream<shared.RequestEntity?> call(String requestId) =>
      _repository.watchRequest(requestId);
}
