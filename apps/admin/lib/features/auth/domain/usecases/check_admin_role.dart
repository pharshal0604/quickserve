import '../repositories/auth_repository.dart';

class CheckAdminRole {
  final AuthRepository repository;
  CheckAdminRole(this.repository);
  Future<bool> call(String uid) => repository.checkAdminRole(uid);
}
