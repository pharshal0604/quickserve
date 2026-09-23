abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<bool> checkAdminRole(String uid);
}
