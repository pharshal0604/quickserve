import 'package:shared/entities/service_entity.dart';

abstract class ServiceRepository {
  Stream<List<({String id, ServiceEntity service})>> watchServices();
  Future<String> createService(String name, String description, bool active);
  Future<void> updateService(String serviceId, String name, String description, bool active);
}
