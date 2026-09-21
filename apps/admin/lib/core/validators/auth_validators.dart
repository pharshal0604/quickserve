abstract final class AdminAuthValidators {
  static final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Enter your email address.';
    }
    if (!emailPattern.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) {
      return 'Enter your password.';
    }
    return null;
  }
}
