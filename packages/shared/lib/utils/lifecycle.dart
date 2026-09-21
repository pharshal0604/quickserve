import 'package:shared/constants/constants.dart';
import 'package:shared/utils/errors.dart';

/// Returns whether [from] can transition to [to].
bool canTransition(String from, String to) {
  return switch (from) {
    StatusNames.created =>
      to == StatusNames.assigned || to == StatusNames.cancelled,
    StatusNames.assigned =>
      to == StatusNames.accepted || to == StatusNames.cancelled,
    StatusNames.accepted =>
      to == StatusNames.inProgress || to == StatusNames.cancelled,
    StatusNames.inProgress =>
      to == StatusNames.completed || to == StatusNames.cancelled,
    StatusNames.completed || StatusNames.cancelled => false,
    _ => false,
  };
}

/// Returns whether a role may perform the requested lifecycle transition.
bool isValidTransitionForRole(String from, String to, String role) {
  if (!canTransition(from, to)) return false;

  if (role == RoleNames.customer) {
    return to == StatusNames.cancelled && isCancellableByCustomer(from);
  }
  if (role == RoleNames.agent) {
    return to != StatusNames.cancelled &&
        (from == StatusNames.assigned && to == StatusNames.accepted ||
            from == StatusNames.accepted && to == StatusNames.inProgress ||
            from == StatusNames.inProgress && to == StatusNames.completed);
  }
  if (role == RoleNames.admin) return true;
  return false;
}

/// Returns whether [status] is a terminal status.
bool isTerminalStatus(String status) {
  return status == StatusNames.completed || status == StatusNames.cancelled;
}

/// Returns whether a Customer may cancel from [status].
bool isCancellableByCustomer(String status) {
  return status == StatusNames.created || status == StatusNames.assigned;
}

/// Validates a transition for a role and throws a typed error when illegal.
void requireValidTransition(String from, String to, String role) {
  if (!isValidTransitionForRole(from, to, role)) {
    throw SharedLifecycleException(
      'Role $role cannot transition $from to $to.',
    );
  }
}
