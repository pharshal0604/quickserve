import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/core/error/app_exceptions.dart';
import 'package:quickserve_mobile/core/error/firebase_error_mapper.dart';

/// Reads QuickServe user profiles from Firestore.
final class UserRepository {
  /// Creates a user-profile repository.
  const UserRepository();

  /// Loads the profile for [uid], or returns null when it does not exist.
  Future<shared.User?> getProfile(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      return snapshot.exists ? shared.User.fromMap(snapshot.data()!) : null;
    } catch (error) {
      throw mapUserRepoError(error);
    }
  }

  /// Creates a customer profile for [uid].
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'customer',
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapUserRepoError(error);
    }
  }

  /// Updates the editable customer profile fields for [uid].
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    try {
      final nameResult = shared.validateName(name.trim());
      final phoneResult = shared.validatePhone(phone.trim());
      if (!nameResult.isValid) {
        throw UserRepositoryException(
          'invalid-name',
          nameResult.reason ?? 'Enter a valid name.',
        );
      }
      if (!phoneResult.isValid) {
        throw UserRepositoryException(
          'invalid-phone',
          phoneResult.reason ?? 'Enter a valid phone number.',
        );
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error is UserRepositoryException) rethrow;
      throw mapUserRepoError(error);
    }
  }
}
