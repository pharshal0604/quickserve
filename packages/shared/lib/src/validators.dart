import 'constants.dart';

/// The result of a validation operation.
class ValidationResult {
  const ValidationResult._({required this.isValid, this.reason});

  /// Creates a successful validation result.
  const ValidationResult.valid() : this._(isValid: true);

  /// Creates a failed validation result with a [reason].
  const ValidationResult.invalid(String reason)
    : this._(isValid: false, reason: reason);

  /// Whether the input passed validation.
  final bool isValid;

  /// The reason for failure, or null when the input is valid.
  final String? reason;
}

ValidationResult _required(String value, String field) {
  if (value.trim().isEmpty) {
    return ValidationResult.invalid('$field must not be empty.');
  }
  return const ValidationResult.valid();
}

/// Validates a person's name: trimmed length must be 2–80 characters.
ValidationResult validateName(String value) {
  final required = _required(value, 'Name');
  if (!required.isValid) return required;
  final length = value.trim().length;
  if (length < 2 || length > 80) {
    return const ValidationResult.invalid(
      'Name must be between 2 and 80 characters.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates an email address using a practical standard email format.
ValidationResult validateEmail(String value) {
  final required = _required(value, 'Email');
  if (!required.isValid) return required;
  final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  return valid
      ? const ValidationResult.valid()
      : const ValidationResult.invalid('Email format is invalid.');
}

/// Validates a phone number with 8–15 digits and an optional leading plus.
ValidationResult validatePhone(String value) {
  final required = _required(value, 'Phone');
  if (!required.isValid) return required;
  final valid = RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value.trim());
  return valid
      ? const ValidationResult.valid()
      : const ValidationResult.invalid(
          'Phone must contain 8 to 15 digits and may start with +.',
        );
}

/// Validates a request description with a trimmed length of 1–2000 characters.
ValidationResult validateDescription(String value) {
  final required = _required(value, 'Description');
  if (!required.isValid) return required;
  final length = value.trim().length;
  if (length > 2000) {
    return const ValidationResult.invalid(
      'Description must not exceed 2000 characters.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a request address with a trimmed length of 5–300 characters.
ValidationResult validateAddress(String value) {
  final required = _required(value, 'Address');
  if (!required.isValid) return required;
  final length = value.trim().length;
  if (length < 5 || length > 300) {
    return const ValidationResult.invalid(
      'Address must be between 5 and 300 characters.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a stored priority value.
ValidationResult validatePriority(String value) {
  return PriorityNames.values.contains(value)
      ? const ValidationResult.valid()
      : const ValidationResult.invalid(
          'Priority must be low, medium, or high.',
        );
}

/// Validates a stored request-status value.
ValidationResult validateStatus(String value) {
  return StatusNames.values.contains(value)
      ? const ValidationResult.valid()
      : const ValidationResult.invalid(
          'Status is not a supported QuickServe status.',
        );
}

/// Validates a stored role value.
ValidationResult validateRole(String value) {
  return RoleNames.values.contains(value)
      ? const ValidationResult.valid()
      : const ValidationResult.invalid(
          'Role must be customer, agent, or admin.',
        );
}

/// Validates the public `REQ-YYYY-000123` request-code format.
ValidationResult validateRequestCode(String value) {
  final valid = RegExp(r'^REQ-[0-9]{4}-[0-9]{6}$').hasMatch(value);
  return valid
      ? const ValidationResult.valid()
      : const ValidationResult.invalid(
          'Request code must match REQ-YYYY-000123.',
        );
}
