import 'package:shared/shared.dart' as shared;
import '../repositories/request_repository_interface.dart';

/// Use case to watch customer requests.
class WatchCustomerRequests {
  /// Creates the usecase.
  const WatchCustomerRequests(this._repository);
  final RequestRepositoryInterface _repository;

  /// Executes the usecase.
  Stream<List<({String id, shared.RequestEntity request})>> call(String customerId) =>
      _repository.watchCustomerRequests(customerId);
}
