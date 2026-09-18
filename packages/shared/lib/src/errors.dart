/// Base exception for errors raised by the QuickServe shared domain package.
class SharedException implements Exception {
  /// Creates a shared exception with a human-readable [message].
  const SharedException(this.message, {this.cause});

  /// The human-readable explanation of the error.
  final String message;

  /// The optional underlying cause.
  final Object? cause;

  @override
  String toString() => message;
}

/// Indicates invalid input or a failed domain validation.
class SharedValidationException extends SharedException {
  /// Creates a validation exception with a human-readable [message].
  const SharedValidationException(super.message, {super.cause});
}

/// Indicates that a stored value or serialized map could not be parsed.
class SharedParseException extends SharedException {
  /// Creates a parse exception with a human-readable [message].
  const SharedParseException(super.message, {super.cause});
}

/// Indicates that an attempted request lifecycle transition is illegal.
class SharedLifecycleException extends SharedException {
  /// Creates a lifecycle exception with a human-readable [message].
  const SharedLifecycleException(super.message, {super.cause});
}
