import '../../domain/repositories/service_repository.dart';
import '../data_sources/service_remote_data_source.dart';

import 'package:shared/models/service.dart';
import 'package:shared/entities/service_entity.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<({String id, ServiceEntity service})>> watchServices() {
    return remoteDataSource.watchServices().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => (
              id: doc.id,
              service: Service.fromMap(doc.data() as Map<String, dynamic>)
                  .toEntity(),
            ),
          )
          .toList();
    });
  }

  @override
  Future<String> createService(String name, String description, bool active) {
    return remoteDataSource.createService({
      'name': name,
      'description': description,
      'isActive': active,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateService(
    String serviceId,
    String name,
    String description,
    bool active,
  ) {
    return remoteDataSource.updateService(serviceId, {
      'name': name,
      'description': description,
      'isActive': active,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
