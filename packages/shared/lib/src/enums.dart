import 'errors.dart';

/// A QuickServe account role.
enum UserRole {
  /// A customer who creates and tracks requests.
  customer,

  /// An Agent who manages assigned work.
  agent,

  /// An administrator who manages operations.
  admin;

  /// Returns the exact lowercase value stored in Firestore.
  String toStoredValue() => switch (this) {
    UserRole.customer => 'customer',
    UserRole.agent => 'agent',
    UserRole.admin => 'admin',
  };

  /// Parses an exact stored role value.
  static UserRole fromStoredValue(String value) {
    for (final role in UserRole.values) {
      if (role.toStoredValue() == value) return role;
    }
    throw SharedParseException('Invalid user role: $value');
  }
}

/// A QuickServe request lifecycle status.
enum RequestStatus {
  /// A request has been created but not assigned.
  created,

  /// An Agent has been assigned.
  assigned,

  /// The assigned Agent accepted the request.
  accepted,

  /// Work is in progress.
  inProgress,

  /// Work is complete.
  completed,

  /// The request was cancelled.
  cancelled;

  /// Returns the exact lowercase value stored in Firestore.
  String toStoredValue() => switch (this) {
    RequestStatus.created => 'created',
    RequestStatus.assigned => 'assigned',
    RequestStatus.accepted => 'accepted',
    RequestStatus.inProgress => 'in_progress',
    RequestStatus.completed => 'completed',
    RequestStatus.cancelled => 'cancelled',
  };

  /// Parses an exact stored request-status value.
  static RequestStatus fromStoredValue(String value) {
    for (final status in RequestStatus.values) {
      if (status.toStoredValue() == value) return status;
    }
    throw SharedParseException('Invalid request status: $value');
  }
}

/// A QuickServe request priority.
enum RequestPriority {
  /// Low priority.
  low,

  /// Medium priority.
  medium,

  /// High priority.
  high;

  /// Returns the exact lowercase value stored in Firestore.
  String toStoredValue() => switch (this) {
    RequestPriority.low => 'low',
    RequestPriority.medium => 'medium',
    RequestPriority.high => 'high',
  };

  /// Parses an exact stored priority value.
  static RequestPriority fromStoredValue(String value) {
    for (final priority in RequestPriority.values) {
      if (priority.toStoredValue() == value) return priority;
    }
    throw SharedParseException('Invalid request priority: $value');
  }
}

/// A fixed QuickServe audit event.
enum AuditEvent {
  /// A successful login.
  loginSuccess,

  /// A request was created.
  requestCreated,

  /// A request was assigned.
  requestAssigned,

  /// A request was updated.
  requestUpdated,

  /// An authorization attempt failed.
  authorizationFailed,

  /// A database operation failed.
  databaseError;

  /// Returns the exact uppercase value stored in Firestore.
  String toStoredValue() => switch (this) {
    AuditEvent.loginSuccess => 'LOGIN_SUCCESS',
    AuditEvent.requestCreated => 'REQUEST_CREATED',
    AuditEvent.requestAssigned => 'REQUEST_ASSIGNED',
    AuditEvent.requestUpdated => 'REQUEST_UPDATED',
    AuditEvent.authorizationFailed => 'AUTHORIZATION_FAILED',
    AuditEvent.databaseError => 'DATABASE_ERROR',
  };

  /// Parses an exact stored audit event value.
  static AuditEvent fromStoredValue(String value) {
    for (final event in AuditEvent.values) {
      if (event.toStoredValue() == value) return event;
    }
    throw SharedParseException('Invalid audit event: $value');
  }
}
