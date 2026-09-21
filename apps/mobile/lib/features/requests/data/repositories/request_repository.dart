import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/core/error/app_exceptions.dart';

/// Provides Customer request operations against the existing Firestore model.
final class RequestRepository {
  /// Creates a request repository.
  const RequestRepository();

  CollectionReference<Map<String, dynamic>> get _requests =>
      FirebaseFirestore.instance.collection(shared.CollectionNames.requests);

  /// Streams requests owned by [customerId], newest first.
  Stream<List<({String id, shared.Request request})>> watchCustomerRequests(
    String customerId,
  ) {
    return _requests
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    (id: doc.id, request: shared.Request.fromMap(doc.data())),
              )
              .toList(growable: false),
        );
  }

  /// Loads a request by document ID.
  Future<shared.Request?> getRequest(String requestId) async {
    try {
      final snapshot = await _requests.doc(requestId).get(
        const GetOptions(source: Source.server),
      );
      return snapshot.exists ? shared.Request.fromMap(snapshot.data()!) : null;
    } catch (error) {
      throw _mapError(error, 'Could not load this request.');
    }
  }

  /// Streams the append-only history for [requestId].
  Stream<List<shared.StatusHistory>> watchHistory(String requestId) {
    return _requests
        .doc(requestId)
        .collection(shared.CollectionNames.statusHistory)
        .orderBy('changedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => shared.StatusHistory.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  /// Creates a request, allocates its yearly code, and writes initial history.
  Future<String> createRequest({
    required String customerId,
    required String serviceType,
    required String description,
    required Timestamp preferredDateTime,
    required String address,
    required shared.RequestPriority priority,
  }) async {
    try {
      final normalizedService = serviceType.trim();
      final normalizedDescription = shared.sanitizeRequestText(description);
      final normalizedAddress = shared.sanitizeRequestText(address);
      final serviceResult = shared.validateServiceType(normalizedService);
      final descriptionResult = shared.validateDescription(
        normalizedDescription,
      );
      final addressResult = shared.validateAddress(normalizedAddress);
      final preferredResult = shared.validatePreferredDateTime(
        preferredDateTime.toDate(),
      );
      for (final result in [
        serviceResult,
        descriptionResult,
        addressResult,
        preferredResult,
      ]) {
        if (!result.isValid) {
          throw RequestRepositoryException(
            'validation-failed',
            result.reason ?? 'Request details are invalid.',
          );
        }
      }
      final serviceId = shared.ServiceNames.documentIdFor(normalizedService);
      final activeService = await FirebaseFirestore.instance
          .collection(shared.CollectionNames.services)
          .doc(serviceId)
          .get();
      final serviceData = activeService.data();
      if (!activeService.exists ||
          serviceData?['name'] != normalizedService ||
          serviceData?['active'] != true) {
        throw const RequestRepositoryException(
          'service-unavailable',
          'That service is no longer available. Please choose another service.',
        );
      }

      final now = DateTime.now().toUtc();
      final year = now.year;
      final counterRef = FirebaseFirestore.instance
          .collection(shared.CollectionNames.counters)
          .doc('$year');
      final requestRef = _requests.doc();
      final historyRef = requestRef
          .collection(shared.CollectionNames.statusHistory)
          .doc();
      final auditRef = FirebaseFirestore.instance
          .collection(shared.CollectionNames.auditLogs)
          .doc();

      late String requestCode;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterRef);
        final current = counterSnapshot.exists
            ? shared.Counter.fromMap(counterSnapshot.data()!).lastRequestNumber
            : 0;
        final next = current + 1;
        requestCode = shared.formatRequestCode(year, next);

        transaction.set(counterRef, {'lastRequestNumber': next});
        transaction.set(requestRef, {
          'requestCode': requestCode,
          'customerId': customerId,
          'agentId': null,
          'serviceType': normalizedService,
          'description': normalizedDescription,
          'preferredDateTime': Timestamp.fromDate(
            preferredDateTime.toDate().toUtc(),
          ),
          'address': normalizedAddress,
          'priority': priority.toStoredValue(),
          'status': shared.StatusNames.created,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'cancellationReason': null,
        });
        transaction.set(historyRef, {
          'fromStatus': null,
          'toStatus': shared.StatusNames.created,
          'changedBy': customerId,
          'changedAt': FieldValue.serverTimestamp(),
          'note': 'Request created.',
        });
        transaction.set(auditRef, {
          'actorUserId': customerId,
          'actorRole': shared.RoleNames.customer,
          'action': shared.EventNames.requestCreated,
          'targetType': 'request',
          'targetId': requestRef.id,
          'oldValue': <String, dynamic>{},
          'newValue': <String, dynamic>{
            'status': shared.StatusNames.created,
            'requestCode': requestCode,
          },
          'result': 'success',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      return requestRef.id;
    } catch (error) {
      throw _mapError(error, 'Could not create the request. Please try again.');
    }
  }

  /// Cancels an eligible customer-owned request with [reason].
  Future<void> cancelRequest({
    required String requestId,
    required String reason,
    required String customerId,
  }) async {
    try {
      final normalizedReason = shared.sanitizeRequestText(reason);
      final reasonResult = shared.validateCancellationReason(normalizedReason);
      if (!reasonResult.isValid) {
        throw RequestRepositoryException(
          'validation-failed',
          reasonResult.reason ?? 'Cancellation reason is invalid.',
        );
      }
      final requestRef = _requests.doc(requestId);
      final historyRef = requestRef
          .collection(shared.CollectionNames.statusHistory)
          .doc();
      final auditRef = FirebaseFirestore.instance
          .collection(shared.CollectionNames.auditLogs)
          .doc();

      final snapshot = await requestRef.get(
        const GetOptions(source: Source.server),
      );
      if (!snapshot.exists) {
        throw const RequestRepositoryException(
          'not-found',
          'The request was not found.',
        );
      }
      final request = shared.Request.fromMap(snapshot.data()!);
      if (request.customerId != customerId ||
          !shared.isCancellableByCustomer(request.status.toStoredValue())) {
        throw const RequestRepositoryException(
          'not-eligible',
          'This request cannot be cancelled at its current status.',
        );
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.update(requestRef, {
        'status': shared.StatusNames.cancelled,
        'updatedAt': FieldValue.serverTimestamp(),
        'cancellationReason': normalizedReason,
      });
      batch.set(historyRef, {
        'fromStatus': request.status.toStoredValue(),
        'toStatus': shared.StatusNames.cancelled,
        'changedBy': customerId,
        'changedAt': FieldValue.serverTimestamp(),
        'note': normalizedReason,
      });
      batch.set(auditRef, {
        'actorUserId': customerId,
        'actorRole': shared.RoleNames.customer,
        'action': shared.EventNames.requestUpdated,
        'targetType': 'request',
        'targetId': requestRef.id,
        'oldValue': <String, dynamic>{
          'status': request.status.toStoredValue(),
        },
        'newValue': <String, dynamic>{'status': shared.StatusNames.cancelled},
        'result': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (error) {
      throw _mapError(error, 'Could not cancel the request. Please try again.');
    }
  }
}

RequestRepositoryException _mapError(Object error, String message) {
  if (error is RequestRepositoryException) return error;
  if (error is FirebaseException) {
    final safeMessage = switch (error.code) {
      'permission-denied' => 'You are not authorized to perform this action.',
      'unavailable' || 'deadline-exceeded' =>
        'The service is temporarily unavailable. Please try again.',
      'not-found' => 'The requested record was not found.',
      _ => message,
    };
    return RequestRepositoryException(error.code, safeMessage);
  }
  return RequestRepositoryException('request-operation-failed', message);
}
