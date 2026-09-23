import '../repositories/auth_repository_interface.dart';

/// Use case to register with email and password.
class Register {
  /// Creates the usecase.
  const Register(this._repository);
  final AuthRepositoryInterface _repository;

  /// Executes the usecase.
  Future<String> call(String email, String password) =>
      _repository.register(email: email, password: password);
}
