import '../repositories/service_repository.dart';

class CreateService {
  final ServiceRepository repository;
  CreateService(this.repository);
  Future<String> call(String name, String description, bool active) =>
      repository.createService(name, description, active);
}
