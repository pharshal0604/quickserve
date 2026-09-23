import '../repositories/auth_repository_interface.dart';

/// Use case to send a password reset email.
class SendPasswordReset {
  /// Creates the usecase.
  const SendPasswordReset(this._repository);
  final AuthRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(String email) => _repository.sendPasswordResetEmail(email);
}
