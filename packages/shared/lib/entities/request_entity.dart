import 'package:shared/constants/enums.dart';

/// A pure-Dart domain entity representing a QuickServe service request.
///
/// This entity contains no serialization logic — conversion to/from
/// persistence formats belongs in the data layer's `Request` model.
class RequestEntity {
  /// Creates a request entity.
  const RequestEntity({
    required this.requestCode,
    required this.customerId,
    required this.agentId,
    required this.agentName,
    required this.agentPhone,
    required this.serviceType,
    required this.description,
    required this.preferredDateTime,
    required this.address,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.cancellationReason,
  });

  /// The public request identifier.
  final String requestCode;

  /// The owning Customer ID.
  final String customerId;

  /// The assigned Agent ID, or null before assignment.
  final String? agentId;

  /// The assigned technician name captured at assignment time.
  final String? agentName;

  /// The assigned technician phone captured at assignment time.
  final String? agentPhone;

  /// The selected service type.
  final String serviceType;

  /// The customer's request description.
  final String description;

  /// The customer's preferred service timestamp.
  final DateTime preferredDateTime;

  /// The service address.
  final String address;

  /// The request priority.
  final RequestPriority priority;

  /// The current lifecycle status.
  final RequestStatus status;

  /// The request creation timestamp.
  final DateTime createdAt;

  /// The request last-update timestamp.
  final DateTime updatedAt;

  /// The cancellation reason, or null when not cancelled.
  final String? cancellationReason;

  @override
  bool operator ==(Object other) {
    return other is RequestEntity &&
        other.requestCode == requestCode &&
        other.customerId == customerId &&
        other.agentId == agentId &&
        other.agentName == agentName &&
        other.agentPhone == agentPhone &&
        other.serviceType == serviceType &&
        other.description == description &&
        other.preferredDateTime == preferredDateTime &&
        other.address == address &&
        other.priority == priority &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.cancellationReason == cancellationReason;
  }

  @override
  int get hashCode => Object.hash(
    requestCode,
    customerId,
    agentId,
    agentName,
    agentPhone,
    serviceType,
    description,
    preferredDateTime,
    address,
    priority,
    status,
    createdAt,
    updatedAt,
    cancellationReason,
  );
}
