import '../repositories/auth_repository_interface.dart';

/// Use case to sign out.
class SignOut {
  /// Creates the usecase.
  const SignOut(this._repository);
  final AuthRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call() => _repository.signOut();
}
