import 'dart:async';

import '../repositories/auth_repository_interface.dart';

/// Use case to watch the authentication state.
class WatchAuthState {
  /// Creates the usecase.
  const WatchAuthState(this._repository);
  final AuthRepositoryInterface _repository;

  /// Executes the usecase.
  Stream<String?> call() => _repository.authStateChanges();
}
