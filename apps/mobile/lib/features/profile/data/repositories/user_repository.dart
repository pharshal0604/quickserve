import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/core/error/app_exceptions.dart';
import 'package:quickserve_mobile/core/error/firebase_error_mapper.dart';
import '../../domain/repositories/user_repository_interface.dart';

/// Reads QuickServe user profiles from Firestore.
final class UserRepository implements UserRepositoryInterface {
  /// Creates a user-profile repository.
  const UserRepository();

  /// Loads the profile for [uid], or returns null when it does not exist.
  @override
  Future<shared.UserEntity?> getProfile(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      return snapshot.exists ? shared.User.fromMap(snapshot.data()!).toEntity() : null;
    } catch (error) {
      throw mapUserRepoError(error);
    }
  }

  /// Creates a customer profile for [uid].
  @override
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required shared.UserRole role,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role.name,
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
  @override
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) {
        final nameResult = shared.validateName(name.trim());
        if (!nameResult.isValid) {
          throw UserRepositoryException(
            'invalid-name',
            nameResult.reason ?? 'Enter a valid name.',
          );
        }
        updates['name'] = name.trim();
      }

      if (phone != null) {
        final phoneResult = shared.validatePhone(phone.trim());
        if (!phoneResult.isValid) {
          throw UserRepositoryException(
            'invalid-phone',
            phoneResult.reason ?? 'Enter a valid phone number.',
          );
        }
        updates['phone'] = phone.trim();
      }

      if (updates.length > 1) { // more than just updatedAt
        await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
      }
    } catch (error) {
      if (error is UserRepositoryException) rethrow;
      throw mapUserRepoError(error);
    }
  }

  /// Updates the saved addresses for [uid].
  Future<void> updateAddresses(String uid, List<String> addresses) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'addresses': addresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapUserRepoError(error);
    }
  }
  
  @override
  Future<void> addAddress({
    required String uid,
    required String address,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'addresses': FieldValue.arrayUnion([address]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapUserRepoError(error);
    }
  }

  @override
  Future<void> removeAddress({
    required String uid,
    required String address,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'addresses': FieldValue.arrayRemove([address]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapUserRepoError(error);
    }
  }

  /// Updates the editable agent profile fields for [uid].
  Future<void> updateAgentProfile({
    required String uid,
    required String email,
    required String phone,
    String? office,
  }) async {
    try {
      final phoneResult = shared.validatePhone(phone.trim());
      if (!phoneResult.isValid) {
        throw UserRepositoryException(
          'invalid-phone',
          phoneResult.reason ?? 'Enter a valid phone number.',
        );
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        if (office != null) 'office': office.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (error is UserRepositoryException) rethrow;
      throw mapUserRepoError(error);
    }
  }
}
