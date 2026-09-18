import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

import '../utils/app_exceptions.dart';

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
      final snapshot = await _requests.doc(requestId).get();
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
      final now = DateTime.now();
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
          'serviceType': serviceType.trim(),
          'description': description.trim(),
          'preferredDateTime': preferredDateTime,
          'address': address.trim(),
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
      final requestRef = _requests.doc(requestId);
      final historyRef = requestRef
          .collection(shared.CollectionNames.statusHistory)
          .doc();
      final auditRef = FirebaseFirestore.instance
          .collection(shared.CollectionNames.auditLogs)
          .doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
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

        transaction.update(requestRef, {
          'status': shared.StatusNames.cancelled,
          'updatedAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason.trim(),
        });
        transaction.set(historyRef, {
          'fromStatus': request.status.toStoredValue(),
          'toStatus': shared.StatusNames.cancelled,
          'changedBy': customerId,
          'changedAt': FieldValue.serverTimestamp(),
          'note': reason.trim(),
        });
        transaction.set(auditRef, {
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
      });
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
