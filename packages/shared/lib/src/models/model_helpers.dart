import '../errors.dart';

/// Reads a required typed field from a serialized model map.
T readRequired<T>(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is T) return value;
  throw SharedParseException('Field $field is missing or has the wrong type.');
}

/// Reads an optional typed field from a serialized model map.
T? readNullable<T>(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value == null) return null;
  if (value is T) return value;
  throw SharedParseException('Field $field has the wrong type.');
}

/// Reads a typed map field from a serialized model map.
Map<String, dynamic> readMap(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  throw SharedParseException('Field $field is missing or has the wrong type.');
}

/// Compares nested map and list values for structural equality.
bool deepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;

  if (left is Map && right is Map) {
    if (left.length != right.length) return false;

    for (final key in left.keys) {
      if (!right.containsKey(key) || !deepEquals(left[key], right[key])) {
        return false;
      }
    }

    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) return false;

    for (var index = 0; index < left.length; index++) {
      if (!deepEquals(left[index], right[index])) return false;
    }

    return true;
  }

  return left == right;
}

/// Creates a stable hash for nested map and list values.
int deepHash(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    return Object.hashAll(
      entries.map((entry) {
        return Object.hash(entry.key, deepHash(entry.value));
      }),
    );
  }

  if (value is List) return Object.hashAll(value.map(deepHash));
  return value.hashCode;
}
