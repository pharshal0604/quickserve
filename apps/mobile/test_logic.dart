import 'package:shared/shared.dart' as shared;

void main() {
  bool emailVerified = false;
  var role = shared.UserRole.agent;
  
  bool isAdmin = role == shared.UserRole.admin;
  
  if (!emailVerified && !isAdmin) {
    print("Blocked! Redirecting to verify-email");
  } else {
    print("Allowed!");
  }
}
