/// Base class for safe application exceptions.
sealed class AppException implements Exception {
  /// Creates an application exception.
  const AppException(this.code, this.userMessage);

  /// A stable internal error code.
  final String code;

  /// A safe message suitable for displaying to the user.
  final String userMessage;

  @override
  String toString() => '$runtimeType(code: $code)';
}

/// An authentication-related application exception.
final class AuthException extends AppException {
  /// Creates an authentication exception.
  const AuthException(super.code, super.userMessage);
}

/// A user-profile repository application exception.
final class UserRepositoryException extends AppException {
  /// Creates a user repository exception.
  const UserRepositoryException(super.code, super.userMessage);
}

/// A request or service repository application exception.
class RequestRepositoryException extends AppException {
  /// Creates a request repository exception.
  const RequestRepositoryException(super.code, super.userMessage);
}

/// A service-catalog repository application exception.
final class ServiceRepositoryException extends RequestRepositoryException {
  /// Creates a service repository exception.
  const ServiceRepositoryException(super.code, super.userMessage);
}
