import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:quickserve_mobile/core/error/app_exceptions.dart';

/// Maps a Firebase Authentication error to a safe application exception.
AuthException mapAuthError(Object error) {
  if (error is fb.FirebaseAuthException) {
    final message = switch (error.code) {
      'user-not-found' => 'No account was found for that email.',
      'wrong-password' => 'The email or password is incorrect.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'A network error occurred. Check your connection and try again.',
      'email-already-in-use' => 'An account already uses that email.',
      'weak-password' => 'Choose a stronger password.',
      'operation-not-allowed' => 'This sign-in method is unavailable.',
      'invalid-credential' => 'The email or password is incorrect.',
      _ => 'Something went wrong. Please try again.',
    };
    return AuthException(error.code, message);
  }

  if (error is FirebaseException) {
    final message = switch (error.code) {
      'permission-denied' => 'You are not authorized to perform this action.',
      'unavailable' => 'The service is unavailable. Please try again.',
      'deadline-exceeded' => 'The request took too long. Please try again.',
      'not-found' => 'The requested record was not found.',
      'failed-precondition' => 'The operation cannot be completed right now.',
      _ => 'Something went wrong. Please try again.',
    };
    return AuthException(error.code, message);
  }

  return const AuthException(
    'unknown-auth-error',
    'Something went wrong. Please try again.',
  );
}

/// Maps a Firestore error to a safe user-profile repository exception.
UserRepositoryException mapUserRepoError(Object error) {
  if (error is FirebaseException) {
    final message = switch (error.code) {
      'permission-denied' => 'You are not authorized to load your profile.',
      'unavailable' => 'Your profile is temporarily unavailable.',
      'deadline-exceeded' => 'Loading your profile took too long.',
      'not-found' => 'Your profile was not found.',
      'failed-precondition' => 'Your profile cannot be loaded right now.',
      _ => 'Something went wrong. Please try again.',
    };
    return UserRepositoryException(error.code, message);
  }

  if (error.runtimeType.toString() == 'SharedParseException') {
    return UserRepositoryException('parse-error', error.toString());
  }

  return UserRepositoryException(
    'unknown-user-repository-error',
    'Something went wrong. Please try again. $error',
  );
}
