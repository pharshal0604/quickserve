import 'package:shared/shared.dart' as shared;
import '../repositories/service_repository_interface.dart';

/// Use case to get all services.
class GetServices {
  /// Creates the usecase.
  const GetServices(this._repository);
  final ServiceRepositoryInterface _repository;

  /// Executes the usecase.
  Future<List<shared.ServiceEntity>> call() => _repository.getServices();
}
