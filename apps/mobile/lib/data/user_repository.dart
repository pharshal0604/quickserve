import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import '../utils/firebase_error_mapper.dart';

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
}
