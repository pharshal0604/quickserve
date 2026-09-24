import 'package:shared/shared.dart' as shared;

import '../repositories/request_repository_interface.dart';

/// Use case to watch the status history of a request.
class WatchHistory {
  /// Creates the usecase.
  const WatchHistory(this._repository);
  final RequestRepositoryInterface _repository;

  /// Executes the usecase.
  Stream<List<shared.StatusHistoryEntity>> call(String requestId) =>
      _repository.watchHistory(requestId);
}
