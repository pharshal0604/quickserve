import '../repositories/service_repository.dart';

import 'package:shared/entities/service_entity.dart';

class WatchServices {
  final ServiceRepository repository;
  WatchServices(this.repository);
  Stream<List<({String id, ServiceEntity service})>> call() =>
      repository.watchServices();
}
