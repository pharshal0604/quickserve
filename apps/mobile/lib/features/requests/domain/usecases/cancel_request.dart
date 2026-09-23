import '../repositories/request_repository_interface.dart';

/// Parameters for cancelling a request.
class CancelRequestParams {
  const CancelRequestParams({
    required this.requestId,
    required this.reason,
    required this.userId,
  });

  final String requestId;
  final String reason;
  final String userId;
}

/// Use case to cancel a request.
class CancelRequest {
  /// Creates the usecase.
  const CancelRequest(this._repository);
  final RequestRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(CancelRequestParams params) => _repository.cancelRequest(
        requestId: params.requestId,
        reason: params.reason,
        userId: params.userId,
      );
}
