/// A pure-Dart domain entity representing a request lifecycle record.
///
/// This entity contains no serialization logic — conversion to/from
/// persistence formats belongs in the data layer's `StatusHistory` model.
class StatusHistoryEntity {
  /// Creates a status history entity.
  const StatusHistoryEntity({
    required this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.changedAt,
    required this.note,
  });

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

  @override
  bool operator ==(Object other) {
    return other is StatusHistoryEntity &&
        other.fromStatus == fromStatus &&
        other.toStatus == toStatus &&
        other.changedBy == changedBy &&
        other.changedAt == changedAt &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(fromStatus, toStatus, changedBy, changedAt, note);
}
