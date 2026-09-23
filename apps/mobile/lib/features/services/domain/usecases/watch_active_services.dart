import 'package:shared/shared.dart' as shared;
import '../repositories/service_repository_interface.dart';

/// Use case to watch active services.
class WatchActiveServices {
  /// Creates the usecase.
  const WatchActiveServices(this._repository);
  final ServiceRepositoryInterface _repository;

  /// Executes the usecase.
  Stream<List<shared.ServiceEntity>> call() =>
      _repository.watchActiveServices();
}
