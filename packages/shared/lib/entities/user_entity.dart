import 'package:shared/constants/enums.dart';

/// A pure-Dart domain entity representing a QuickServe user profile.
///
/// This entity contains no serialization logic — conversion to/from
/// persistence formats belongs in the data layer's `User` model.
class UserEntity {
  /// Creates a user entity.
  const UserEntity({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.addresses = const [],
    this.office,
    this.schedule,
  });

  /// The user's stored role.
  final UserRole role;

  /// The user's display name.
  final String name;

  /// The user's email address.
  final String email;

  /// The user's phone number.
  final String phone;

  /// The customer's saved addresses.
  final List<String> addresses;

  /// The agent's regional office.
  final String? office;

  /// The agent's working schedule.
  final String? schedule;

  /// The profile creation timestamp.
  final DateTime createdAt;

  /// The profile last-update timestamp.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is UserEntity &&
        other.role == role &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.office == office &&
        other.schedule == schedule &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    role,
    name,
    email,
    phone,
    office,
    schedule,
    createdAt,
    updatedAt,
  );
}
