import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shared/constants/enums.dart';
import 'package:shared/utils/model_helpers.dart';

/// A QuickServe service request stored in `requests/{requestId}`.
class Request {
  /// Creates a service request.
  const Request({
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

  /// Parses a request from Firestore field names.
  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      requestCode: readRequired<String>(map, 'requestCode'),
      customerId: readRequired<String>(map, 'customerId'),
      agentId: readNullable<String>(map, 'agentId'),
      agentName: readNullable<String>(map, 'agentName'),
      agentPhone: readNullable<String>(map, 'agentPhone'),
      serviceType: readRequired<String>(map, 'serviceType'),
      description: readRequired<String>(map, 'description'),
      preferredDateTime: readRequired<Timestamp>(map, 'preferredDateTime'),
      address: readRequired<String>(map, 'address'),
      priority: RequestPriority.fromStoredValue(
        readRequired<String>(map, 'priority'),
      ),
      status: RequestStatus.fromStoredValue(
        readRequired<String>(map, 'status'),
      ),
      createdAt: readRequired<Timestamp>(map, 'createdAt'),
      updatedAt: readRequired<Timestamp>(map, 'updatedAt'),
      cancellationReason: readNullable<String>(map, 'cancellationReason'),
    );
  }

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
  final Timestamp preferredDateTime;

  /// The service address.
  final String address;

  /// The request priority.
  final RequestPriority priority;

  /// The current lifecycle status.
  final RequestStatus status;

  /// The request creation timestamp.
  final Timestamp createdAt;

  /// The request last-update timestamp.
  final Timestamp updatedAt;

  /// The cancellation reason, or null when not cancelled.
  final String? cancellationReason;

  /// Converts this request to Firestore field names and values.
  Map<String, dynamic> toMap() => {
    'requestCode': requestCode,
    'customerId': customerId,
    'agentId': agentId,
    'agentName': agentName,
    'agentPhone': agentPhone,
    'serviceType': serviceType,
    'description': description,
    'preferredDateTime': preferredDateTime,
    'address': address,
    'priority': priority.toStoredValue(),
    'status': status.toStoredValue(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'cancellationReason': cancellationReason,
  };

  @override
  bool operator ==(Object other) {
    return other is Request &&
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
