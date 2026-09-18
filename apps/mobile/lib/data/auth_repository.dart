import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../utils/firebase_error_mapper.dart';

/// Provides Firebase Authentication operations for the mobile app.
final class AuthRepository {
  /// Creates an authentication repository.
  const AuthRepository();

  /// Streams Firebase Authentication session changes.
  Stream<fb.User?> authStateChanges() {
    return fb.FirebaseAuth.instance.authStateChanges();
  }

  /// Signs in with the required [email] and [password].
  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  /// Registers an account with the required [email] and [password].
  Future<fb.UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  /// Signs out the current Firebase Authentication session.
  Future<void> signOut() async {
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  /// Requests a password-reset email for [email].
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (error) {
      throw mapAuthError(error);
    }
  }
}
