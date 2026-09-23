import 'dart:async';

/// Abstract repository interface for authentication.
abstract class AuthRepositoryInterface {
  /// Stream of authentication state changes, returning the user UID or null.
  Stream<String?> authStateChanges();

  /// Signs in with email and password, returning the user UID.
  Future<String> signIn({required String email, required String password});

  /// Registers with email and password, returning the user UID.
  Future<String> register({required String email, required String password});

  /// Signs out the current user.
  Future<void> signOut();

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email);
}
