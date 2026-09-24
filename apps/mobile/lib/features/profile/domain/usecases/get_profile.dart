import 'package:shared/shared.dart' as shared;

import '../repositories/user_repository_interface.dart';

/// Use case to get a user profile.
class GetProfile {
  /// Creates the usecase.
  const GetProfile(this._repository);
  final UserRepositoryInterface _repository;

  /// Executes the usecase.
  Future<shared.UserEntity?> call(String uid) => _repository.getProfile(uid);
}
