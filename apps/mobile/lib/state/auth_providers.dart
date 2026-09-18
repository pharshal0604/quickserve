import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart' as shared;

import '../data/auth_repository.dart';
import '../data/user_repository.dart';

/// Provides the Firebase Authentication repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// Provides the read-only user-profile repository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return const UserRepository();
});

/// Streams the current Firebase Authentication user.
final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Resolves the shared profile for the current Firebase Authentication user.
final userProfileProvider = FutureProvider<shared.User?>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (authState.isLoading) {
    return Completer<shared.User?>().future;
  }

  if (authState.hasError) {
    Error.throwWithStackTrace(
      authState.error!,
      authState.stackTrace ?? StackTrace.current,
    );
  }

  final user = authState.value;
  if (user == null) return null;

  return ref.watch(userRepositoryProvider).getProfile(user.uid);
});
