import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shared/constants/enums.dart';
import 'package:shared/utils/model_helpers.dart';

/// An append-only QuickServe activity record.
class AuditLog {
  /// Creates an audit log record.
  const AuditLog({
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

  /// Parses an audit log record from Firestore field names.
  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      actorUserId: readRequired<String>(map, 'actorUserId'),
      actorRole: UserRole.fromStoredValue(
        readRequired<String>(map, 'actorRole'),
      ),
      action: AuditEvent.fromStoredValue(readRequired<String>(map, 'action')),
      targetType: readRequired<String>(map, 'targetType'),
      targetId: readRequired<String>(map, 'targetId'),
      oldValue: readMap(map, 'oldValue'),
      newValue: readMap(map, 'newValue'),
      result: readRequired<String>(map, 'result'),
      timestamp: readRequired<Timestamp>(map, 'timestamp'),
    );
  }

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
  final Timestamp timestamp;

  /// Converts this audit log to Firestore field names and values.
  Map<String, dynamic> toMap() => {
    'actorUserId': actorUserId,
    'actorRole': actorRole.toStoredValue(),
    'action': action.toStoredValue(),
    'targetType': targetType,
    'targetId': targetId,
    'oldValue': Map<String, dynamic>.from(oldValue),
    'newValue': Map<String, dynamic>.from(newValue),
    'result': result,
    'timestamp': timestamp,
  };

  @override
  bool operator ==(Object other) {
    return other is AuditLog &&
        other.actorUserId == actorUserId &&
        other.actorRole == actorRole &&
        other.action == action &&
        other.targetType == targetType &&
        other.targetId == targetId &&
        deepEquals(other.oldValue, oldValue) &&
        deepEquals(other.newValue, newValue) &&
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
    deepHash(oldValue),
    deepHash(newValue),
    result,
    timestamp,
  );
}
