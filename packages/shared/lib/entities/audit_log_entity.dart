import 'package:shared/constants/enums.dart';

/// A pure-Dart domain entity representing an audit log record.
///
/// This entity contains no serialization logic — conversion to/from
/// persistence formats belongs in the data layer's `AuditLog` model.
class AuditLogEntity {
  /// Creates an audit log entity.
  const AuditLogEntity({
    required this.actorUserId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.oldValue,
    required this.newValue,
    required this.result,
    required this.timestamp,
  });

  /// The user who performed the action.
  final String actorUserId;

  /// The actor's stored role.
  final UserRole actorRole;

  /// The fixed event action.
  final AuditEvent action;

  /// The type of target affected by the event.
  final String targetType;

  /// The identifier of the affected target.
  final String targetId;

  /// The safe old values associated with the event.
  final Map<String, dynamic> oldValue;

  /// The safe new values associated with the event.
  final Map<String, dynamic> newValue;

  /// The operation result, such as success, denied, or failure.
  final String result;

  /// The event timestamp.
  final DateTime timestamp;

  @override
  bool operator ==(Object other) {
    return other is AuditLogEntity &&
        other.actorUserId == actorUserId &&
        other.actorRole == actorRole &&
        other.action == action &&
        other.targetType == targetType &&
        other.targetId == targetId &&
        other.result == result &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
    actorUserId,
    actorRole,
    action,
    targetType,
    targetId,
    result,
    timestamp,
  );
}
