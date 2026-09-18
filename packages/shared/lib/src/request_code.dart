import 'constants.dart';
import 'errors.dart';

/// A parsed QuickServe request code.
class ParsedRequestCode {
  /// Creates a parsed request code with its [year] and [sequence].
  const ParsedRequestCode({required this.year, required this.sequence});

  /// The four-digit request-code year.
  final int year;

  /// The non-negative request sequence.
  final int sequence;

  @override
  bool operator ==(Object other) {
    return other is ParsedRequestCode &&
        other.year == year &&
        other.sequence == sequence;
  }

  @override
  int get hashCode => Object.hash(year, sequence);
}

/// Formats a request code as `REQ-YYYY-000123`.
String formatRequestCode(int year, int sequence) {
  if (year < 1000 || year > 9999) {
    throw SharedValidationException('Year must contain exactly four digits.');
  }
  if (sequence < 0 || sequence > 999999) {
    throw SharedValidationException(
      'Sequence must be between 0 and 999999.',
    );
  }
  return '${RequestCodeConstants.prefix}$year-${sequence.toString().padLeft(6, '0')}';
}

/// Parses a valid request code into its year and sequence components.
ParsedRequestCode parseRequestCode(String code) {
  final match = RegExp(r'^REQ-([0-9]{4})-([0-9]{6})$').firstMatch(code);
  if (match == null) {
    throw SharedParseException(
      'Request code must match REQ-YYYY-000123.',
    );
  }
  return ParsedRequestCode(
    year: int.parse(match.group(1)!),
    sequence: int.parse(match.group(2)!),
  );
}

/// Returns whether [code] matches the QuickServe request-code format.
bool isValidRequestCode(String code) {
  return RegExp(r'^REQ-[0-9]{4}-[0-9]{6}$').hasMatch(code);
}
