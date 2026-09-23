import 'package:shared/shared.dart' as shared;

/// Abstract repository interface for services.
abstract class ServiceRepositoryInterface {
  /// Gets all services.
  Future<List<shared.ServiceEntity>> getServices();

  /// Streams all active services.
  Stream<List<shared.ServiceEntity>> watchActiveServices();
}
