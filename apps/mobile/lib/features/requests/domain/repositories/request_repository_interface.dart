import 'package:shared/shared.dart' as shared;

/// Abstract repository interface for requests.
abstract class RequestRepositoryInterface {
  /// Creates a new request and returns its ID.
  Future<String> createRequest({
    required String customerId,
    required String serviceType,
    required String description,
    required DateTime preferredDateTime,
    required String address,
    required shared.RequestPriority priority,
  });

  /// Streams requests owned by a customer.
  Stream<List<({String id, shared.RequestEntity request})>>
  watchCustomerRequests(String customerId);

  /// Streams a single request by its ID.
  Stream<shared.RequestEntity?> watchRequest(String requestId);

  /// Streams the status history for a request.
  Stream<List<shared.StatusHistoryEntity>> watchHistory(String requestId);

  /// Cancels a request.
  Future<void> cancelRequest({
    required String requestId,
    required String reason,
    required String userId,
  });
}
