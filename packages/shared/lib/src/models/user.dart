import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums.dart';
import 'model_helpers.dart';

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
  });

  /// Parses a user profile from Firestore field names.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      role: UserRole.fromStoredValue(readRequired<String>(map, 'role')),
      name: readRequired<String>(map, 'name'),
      email: readRequired<String>(map, 'email'),
      phone: readRequired<String>(map, 'phone'),
      createdAt: readRequired<Timestamp>(map, 'createdAt'),
      updatedAt: readRequired<Timestamp>(map, 'updatedAt'),
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

  /// The profile creation timestamp.
  final Timestamp createdAt;

  /// The profile last-update timestamp.
  final Timestamp updatedAt;

  /// Converts this profile to Firestore field names and values.
  Map<String, dynamic> toMap() => {
        'role': role.toStoredValue(),
        'name': name,
        'email': email,
        'phone': phone,
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
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        role,
        name,
        email,
        phone,
        createdAt,
        updatedAt,
      );
}
