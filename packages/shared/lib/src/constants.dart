/// Firestore collection and subcollection names used by QuickServe.
abstract final class CollectionNames {
  /// The user profile collection.
  static const users = 'users';

  /// The service catalog collection.
  static const services = 'services';

  /// The service request collection.
  static const requests = 'requests';

  /// The request status-history subcollection.
  static const statusHistory = 'status_history';

  /// The audit log collection.
  static const auditLogs = 'audit_logs';

  /// The yearly request counter collection.
  static const counters = 'counters';
}

/// Fixed stored role values.
abstract final class RoleNames {
  /// Customer role.
  static const customer = 'customer';

  /// Agent role.
  static const agent = 'agent';

  /// Admin role.
  static const admin = 'admin';

  /// All supported role values.
  static const values = <String>[customer, agent, admin];
}

/// Fixed stored request-status values.
abstract final class StatusNames {
  /// Newly created request.
  static const created = 'created';

  /// Request assigned to an Agent.
  static const assigned = 'assigned';

  /// Assigned Agent accepted the request.
  static const accepted = 'accepted';

  /// Work is in progress.
  static const inProgress = 'in_progress';

  /// Work is complete.
  static const completed = 'completed';

  /// Request was cancelled.
  static const cancelled = 'cancelled';

  /// All supported request-status values.
  static const values = <String>[
    created,
    assigned,
    accepted,
    inProgress,
    completed,
    cancelled,
  ];
}

/// Fixed service catalog values.
abstract final class ServiceNames {
  /// Air-conditioning servicing.
  static const acServicing = 'AC servicing';

  /// Plumbing work.
  static const plumbing = 'Plumbing';

  /// Electrical work.
  static const electrical = 'Electrical';

  /// Cleaning work.
  static const cleaning = 'Cleaning';

  /// All supported service names.
  static const values = <String>[acServicing, plumbing, electrical, cleaning];
}

/// Fixed stored priority values.
abstract final class PriorityNames {
  /// Low priority.
  static const low = 'low';

  /// Medium priority.
  static const medium = 'medium';

  /// High priority.
  static const high = 'high';

  /// All supported priority values.
  static const values = <String>[low, medium, high];
}

/// Fixed audit and activity event names.
abstract final class EventNames {
  /// Successful login event.
  static const loginSuccess = 'LOGIN_SUCCESS';

  /// Request-created event.
  static const requestCreated = 'REQUEST_CREATED';

  /// Request-assignment event.
  static const requestAssigned = 'REQUEST_ASSIGNED';

  /// Request-update event.
  static const requestUpdated = 'REQUEST_UPDATED';

  /// Authorization-failure event.
  static const authorizationFailed = 'AUTHORIZATION_FAILED';

  /// Database-error event.
  static const databaseError = 'DATABASE_ERROR';

  /// All supported event names.
  static const values = <String>[
    loginSuccess,
    requestCreated,
    requestAssigned,
    requestUpdated,
    authorizationFailed,
    databaseError,
  ];
}

/// Constants for the public request-code format `REQ-YYYY-000123`.
abstract final class RequestCodeConstants {
  /// The request-code prefix.
  static const prefix = 'REQ-';

  /// Number of digits in the year component.
  static const yearLength = 4;

  /// Number of digits in the sequence component.
  static const sequenceLength = 6;
}
