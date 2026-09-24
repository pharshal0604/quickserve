import 'package:shared/shared.dart' as shared;

import '../repositories/request_repository_interface.dart';

/// Parameters for creating a request.
class CreateRequestParams {
  const CreateRequestParams({
    required this.customerId,
    required this.serviceType,
    required this.description,
    required this.preferredDateTime,
    required this.address,
    required this.priority,
  });

  final String customerId;
  final String serviceType;
  final String description;
  final DateTime preferredDateTime;
  final String address;
  final shared.RequestPriority priority;
}

/// Use case to create a request.
class CreateRequest {
  /// Creates the usecase.
  const CreateRequest(this._repository);
  final RequestRepositoryInterface _repository;

  /// Executes the usecase.
  Future<String> call(CreateRequestParams params) => _repository.createRequest(
    customerId: params.customerId,
    serviceType: params.serviceType,
    description: params.description,
    preferredDateTime: params.preferredDateTime,
    address: params.address,
    priority: params.priority,
  );
}
