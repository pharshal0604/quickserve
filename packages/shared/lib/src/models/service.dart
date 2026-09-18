import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_helpers.dart';

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
      createdAt: readRequired<Timestamp>(map, 'createdAt'),
    );
  }

  /// The service name.
  final String name;

  /// The service description.
  final String description;

  /// Whether the service is active in the catalog.
  final bool active;

  /// The service creation timestamp.
  final Timestamp createdAt;

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
}
