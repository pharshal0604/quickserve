import '../repositories/service_repository.dart';

class UpdateService {
  final ServiceRepository repository;
  UpdateService(this.repository);
  Future<void> call(
    String serviceId,
    String name,
    String description,
    bool active,
  ) => repository.updateService(serviceId, name, description, active);
}
