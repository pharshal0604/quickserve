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
}
