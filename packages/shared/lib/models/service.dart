import 'package:shared/entities/service_entity.dart';
import 'package:shared/utils/model_helpers.dart';

/// A QuickServe service catalog entry stored in `services/{serviceId}`.
class Service {
  /// Creates a service catalog entry.
  const Service({
    required this.name,
    required this.description,
    required this.active,
    required this.createdAt,
  });

  /// Parses a service catalog entry from Firestore field names.
  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      name: readRequired<String>(map, 'name'),
      description: readRequired<String>(map, 'description'),
      active: readRequired<bool>(map, 'active'),
      createdAt: readDateTime(map, 'createdAt'),
    );
  }

  /// The service name.
  final String name;

  /// The service description.
  final String description;

  /// Whether the service is active in the catalog.
  final bool active;

  /// The service creation timestamp.
  final DateTime createdAt;

  /// Converts this service to Firestore field names and values.
  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'active': active,
    'createdAt': createdAt,
  };

  @override
  bool operator ==(Object other) {
    return other is Service &&
        other.name == name &&
        other.description == description &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(name, description, active, createdAt);

  /// Converts this model to a pure-Dart domain entity.
  ServiceEntity toEntity() => ServiceEntity(
    name: name,
    description: description,
    active: active,
    createdAt: createdAt,
  );

  /// Creates this model from a pure-Dart domain entity.
  factory Service.fromEntity(ServiceEntity entity) => Service(
    name: entity.name,
    description: entity.description,
    active: entity.active,
    createdAt: entity.createdAt,
  );
}
