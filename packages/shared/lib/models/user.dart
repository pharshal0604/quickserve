import 'package:shared/entities/user_entity.dart';
import 'package:shared/constants/enums.dart';
import 'package:shared/utils/model_helpers.dart';

/// A QuickServe user profile stored in `users/{uid}`.
class User {
  /// Creates a user profile.
  const User({
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

  /// Parses a user profile from Firestore field names.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      role: UserRole.fromStoredValue(readRequired<String>(map, 'role')),
      name: readRequired<String>(map, 'name'),
      email: readRequired<String>(map, 'email'),
      phone: readRequired<String>(map, 'phone'),
      createdAt: readDateTime(map, 'createdAt'),
      updatedAt: readDateTime(map, 'updatedAt'),
      addresses: List<String>.from(map['addresses'] ?? []),
      office: map['office'] as String?,
      schedule: map['schedule'] as String?,
    );
  }

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

  /// Converts this profile to Firestore field names and values.
  Map<String, dynamic> toMap() => {
    'role': role.toStoredValue(),
    'name': name,
    'email': email,
    'phone': phone,
    'addresses': addresses,
    if (office != null) 'office': office,
    if (schedule != null) 'schedule': schedule,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  bool operator ==(Object other) {
    return other is User &&
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
  int get hashCode =>
      Object.hash(role, name, email, phone, office, schedule, createdAt, updatedAt);

  /// Converts this model to a pure-Dart domain entity.
  UserEntity toEntity() => UserEntity(
    role: role,
    name: name,
    email: email,
    phone: phone,
    createdAt: createdAt,
    updatedAt: updatedAt,
    addresses: addresses,
    office: office,
    schedule: schedule,
  );

  /// Creates this model from a pure-Dart domain entity.
  factory User.fromEntity(UserEntity entity) => User(
    role: entity.role,
    name: entity.name,
    email: entity.email,
    phone: entity.phone,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    addresses: entity.addresses,
    office: entity.office,
    schedule: entity.schedule,
  );
}
