import '../repositories/user_repository_interface.dart';

/// Parameters for updating a profile.
class UpdateProfileParams {
  const UpdateProfileParams({required this.uid, this.name, this.phone});

  final String uid;
  final String? name;
  final String? phone;
}

/// Use case to update a profile.
class UpdateProfile {
  /// Creates the usecase.
  const UpdateProfile(this._repository);
  final UserRepositoryInterface _repository;

  /// Executes the usecase.
  Future<void> call(UpdateProfileParams params) => _repository.updateProfile(
    uid: params.uid,
    name: params.name,
    phone: params.phone,
  );
}
