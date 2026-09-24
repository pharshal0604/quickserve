import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:quickserve_mobile/core/error/firebase_error_mapper.dart';

/// Provides Firebase Authentication operations for the mobile app.
final class AuthRepository {
  const AuthRepository();

  Stream<fb.User?> authStateChanges() => fb.FirebaseAuth.instance.userChanges();

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

  /// Signs in with Google. Web uses Firebase's popup; Android/iOS uses the
  /// native Google account chooser provided by google_sign_in.
  Future<fb.UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = fb.GoogleAuthProvider();
        return await fb.FirebaseAuth.instance.signInWithPopup(provider);
      }
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final authentication = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );
      return await fb.FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await fb.FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  Future<void> reload() async {
    try {
      await fb.FirebaseAuth.instance.currentUser?.reload();
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await GoogleSignIn().signOut();
      await fb.FirebaseAuth.instance.signOut();
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (error) {
      throw mapAuthError(error);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }
      await user.updatePassword(newPassword);
    } catch (error) {
      throw mapAuthError(error);
    }
  }
}
