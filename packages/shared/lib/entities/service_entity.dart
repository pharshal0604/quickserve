/// A pure-Dart domain entity representing a QuickServe service catalog entry.
///
/// This entity contains no serialization logic — conversion to/from
/// persistence formats belongs in the data layer's `Service` model.
class ServiceEntity {
  /// Creates a service entity.
  const ServiceEntity({
    required this.name,
    required this.description,
    required this.active,
    required this.createdAt,
  });

  /// The service name.
  final String name;

  /// The service description.
  final String description;

  /// Whether the service is active in the catalog.
  final bool active;

  /// The service creation timestamp.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return other is ServiceEntity &&
        other.name == name &&
        other.description == description &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(name, description, active, createdAt);
}
