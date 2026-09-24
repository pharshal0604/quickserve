import 'package:shared/shared.dart' as shared;

import '../repositories/user_repository_interface.dart';

/// Parameters for creating a profile.
class CreateProfileParams {
  const CreateProfileParams({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final shared.UserRole role;
}

/// Use case to create a profile.
class CreateProfile {
  /// Creates the usecase.
  const CreateProfile(this._repository);
  final UserRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(CreateProfileParams params) => _repository.createProfile(
    uid: params.uid,
    name: params.name,
    email: params.email,
    phone: params.phone,
    role: params.role,
  );
}
