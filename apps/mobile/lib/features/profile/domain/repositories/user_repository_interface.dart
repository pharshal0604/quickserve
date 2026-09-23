import 'package:shared/shared.dart' as shared;

/// Abstract repository interface for user profile operations.
abstract class UserRepositoryInterface {
  /// Gets the profile of a user.
  Future<shared.UserEntity?> getProfile(String uid);

  /// Creates a profile for a user.
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required shared.UserRole role,
  });

  /// Updates the profile of a user.
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
  });

  /// Adds an address for a user.
  Future<void> addAddress({
    required String uid,
    required String address,
  });

  /// Removes an address from a user's profile.
  Future<void> removeAddress({
    required String uid,
    required String address,
  });
}
