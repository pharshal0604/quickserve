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

  /// The reason for failure, or null when the value is valid.
  final String? reason;
}

ValidationResult _required(String value, String field) {
  if (value.trim().isEmpty) {
    return ValidationResult.invalid('$field must not be empty.');
  }
  return const ValidationResult.valid();
}

/// Removes surrounding whitespace and common control characters from user text.
String sanitizeRequestText(String value) {
  return value
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Validates a person's name using letters and spaces only.
ValidationResult validateName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return const ValidationResult.invalid('Name is required.');
  }
  if (trimmed.length < 2) {
    return const ValidationResult.invalid(
      'Name must be at least 2 characters.',
    );
  }
  if (trimmed.length > 50) {
    return const ValidationResult.invalid(
      'Name must be 50 characters or fewer.',
    );
  }
  if (!RegExp(r'^[A-Za-z ]+$').hasMatch(trimmed)) {
    return const ValidationResult.invalid(
      'Name can only contain letters and spaces.',
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

/// Validates a phone number with exactly ten digits.
ValidationResult validatePhone(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return const ValidationResult.invalid('Phone number is required.');
  }
  if (!RegExp(r'^[0-9]{10}$').hasMatch(trimmed)) {
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return const ValidationResult.invalid(
        'Phone number must contain only digits.',
      );
    }
    return const ValidationResult.invalid(
      'Phone number must be exactly 10 digits.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a password with length and character requirements.
ValidationResult validatePassword(String value) {
  if (value.isEmpty) {
    return const ValidationResult.invalid('Password is required.');
  }
  if (value.length < 8) {
    return const ValidationResult.invalid(
      'Password must be at least 8 characters.',
    );
  }
  if (value.length > 128) {
    return const ValidationResult.invalid(
      'Password must be 128 characters or fewer.',
    );
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return const ValidationResult.invalid(
      'Password must include at least one uppercase letter.',
    );
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return const ValidationResult.invalid(
      'Password must include at least one lowercase letter.',
    );
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return const ValidationResult.invalid(
      'Password must include at least one digit.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates that a password confirmation matches the original password.
ValidationResult validateConfirmPassword(String value, String original) {
  if (value.isEmpty) {
    return const ValidationResult.invalid('Please confirm your password.');
  }
  if (value != original) {
    return const ValidationResult.invalid('Passwords do not match.');
  }
  return const ValidationResult.valid();
}

/// Validates a request description after sanitization: 10–1000 characters.
ValidationResult validateDescription(String value) {
  final normalized = sanitizeRequestText(value);
  if (normalized.isEmpty) {
    return const ValidationResult.invalid('Description is required.');
  }
  if (normalized.length < 10 || normalized.length > 1000) {
    return const ValidationResult.invalid(
      'Description must be between 10 and 1000 characters.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a request address after sanitization: 10–200 characters.
ValidationResult validateAddress(String value) {
  final normalized = sanitizeRequestText(value);
  if (normalized.isEmpty) {
    return const ValidationResult.invalid('Address is required.');
  }
  if (normalized.length < 10 || normalized.length > 200) {
    return const ValidationResult.invalid(
      'Address must be between 10 and 200 characters.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a preferred service time within the supported one-year window.
ValidationResult validatePreferredDateTime(DateTime value, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (!value.isAfter(current)) {
    return const ValidationResult.invalid(
      'Preferred date and time must be in the future.',
    );
  }
  if (value.isAfter(current.add(const Duration(days: 365)))) {
    return const ValidationResult.invalid(
      'Preferred date and time must be within one year.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a cancellation reason after sanitization: 5–500 characters.
ValidationResult validateCancellationReason(String value) {
  final normalized = sanitizeRequestText(value);
  if (normalized.length < 5 || normalized.length > 500) {
    return const ValidationResult.invalid(
      'Cancellation reason must be between 5 and 500 characters.',
    );
  }
  return const ValidationResult.valid();
}

/// Validates a selected service reference before the catalog lookup.
ValidationResult validateServiceType(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return const ValidationResult.invalid('Service is required.');
  }
  if (!ServiceNames.values.contains(normalized)) {
    return const ValidationResult.invalid(
      'Service must be AC servicing, Plumbing, Electrical, or Cleaning.',
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
