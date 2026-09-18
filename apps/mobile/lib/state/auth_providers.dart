import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart' as shared;

import '../data/agent_repository.dart';
import '../data/auth_repository.dart';
import '../data/request_repository.dart';
import '../data/service_repository.dart';
import '../data/user_repository.dart';

/// Provides the Firebase Authentication repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// Provides the read-only user-profile repository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return const UserRepository();
});

/// Provides service-catalog operations.
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return const ServiceRepository();
});

/// Provides assigned-request reads for Agents.
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return const AgentRepository();
});

/// Provides request operations.
final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return const RequestRepository();
});

/// Streams the current Firebase Authentication user.
final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// True while a customer registration flow is in progress. The router
/// keeps the user on /register until this flips back to false.
final registrationInProgressProvider =
    NotifierProvider<RegistrationInProgressNotifier, bool>(
      RegistrationInProgressNotifier.new,
    );

/// Simple boolean notifier for the registration-in-progress flag.
class RegistrationInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks registration as started.
  void start() => state = true;

  /// Marks registration as finished (success or failure).
  void finish() => state = false;
}

/// Resolves the shared profile for the current Firebase Authentication user.
final userProfileProvider = FutureProvider<shared.User?>((ref) async {
  ref.watch(registrationInProgressProvider);
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
