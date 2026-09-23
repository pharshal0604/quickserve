import 'package:shared/entities/status_history_entity.dart';
import 'package:shared/utils/model_helpers.dart';

/// An append-only request lifecycle record.
class StatusHistory {
  /// Creates a status-history record.
  const StatusHistory({
    required this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.changedAt,
    required this.note,
  });

  /// Parses a status-history record from Firestore field names.
  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      fromStatus: readNullable<String>(map, 'fromStatus'),
      toStatus: readRequired<String>(map, 'toStatus'),
      changedBy: readRequired<String>(map, 'changedBy'),
      changedAt: readDateTime(map, 'changedAt'),
      note: readNullable<String>(map, 'note'),
    );
  }

  /// The previous status, or null for the initial record.
  final String? fromStatus;

  /// The new status.
  final String toStatus;

  /// The user who caused the transition.
  final String changedBy;

  /// The transition timestamp.
  final DateTime changedAt;

  /// An optional transition note.
  final String? note;

  /// Converts this history record to Firestore field names and values.
  Map<String, dynamic> toMap() => {
    'fromStatus': fromStatus,
    'toStatus': toStatus,
    'changedBy': changedBy,
    'changedAt': changedAt,
    'note': note,
  };

  @override
  bool operator ==(Object other) {
    return other is StatusHistory &&
        other.fromStatus == fromStatus &&
        other.toStatus == toStatus &&
        other.changedBy == changedBy &&
        other.changedAt == changedAt &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(fromStatus, toStatus, changedBy, changedAt, note);

  /// Converts this model to a pure-Dart domain entity.
  StatusHistoryEntity toEntity() => StatusHistoryEntity(
    fromStatus: fromStatus,
    toStatus: toStatus,
    changedBy: changedBy,
    changedAt: changedAt,
    note: note,
  );

  /// Creates this model from a pure-Dart domain entity.
  factory StatusHistory.fromEntity(StatusHistoryEntity entity) => StatusHistory(
    fromStatus: entity.fromStatus,
    toStatus: entity.toStatus,
    changedBy: entity.changedBy,
    changedAt: entity.changedAt,
    note: entity.note,
  );
}
