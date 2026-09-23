import '../repositories/auth_repository_interface.dart';

/// Use case to sign in with email and password.
class SignIn {
  /// Creates the usecase.
  const SignIn(this._repository);
  final AuthRepositoryInterface _repository;

  /// Executes the usecase.
  Future<String> call(String email, String password) =>
      _repository.signIn(email: email, password: password);
}
