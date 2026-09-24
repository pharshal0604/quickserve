import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/core/error/app_exceptions.dart';

/// Provides assigned-request reads and Agent lifecycle transitions.
final class AgentRepository {
  /// Creates an Agent repository.
  const AgentRepository();

  CollectionReference<Map<String, dynamic>> get _requests =>
      FirebaseFirestore.instance.collection(shared.CollectionNames.requests);

  /// Streams requests assigned to [agentId].
  Stream<List<({String id, shared.Request request})>> watchAssignedRequests(
    String agentId,
  ) {
    return _requests
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => (id: doc.id, request: shared.Request.fromMap(doc.data())),
          )
          .toList();
    });
  }

  /// Accepts a request assigned to [agentId].
  Future<void> acceptAssignedRequest({
    required String requestId,
    required String agentId,
  }) {
    return _transition(
      requestId: requestId,
      agentId: agentId,
      expectedStatus: shared.StatusNames.assigned,
      nextStatus: shared.StatusNames.accepted,
      note: 'Agent accepted request.',
    );
  }

  /// Starts work on an accepted request assigned to [agentId].
  Future<void> startRequest({
    required String requestId,
    required String agentId,
  }) {
    return _transition(
      requestId: requestId,
      agentId: agentId,
      expectedStatus: shared.StatusNames.accepted,
      nextStatus: shared.StatusNames.inProgress,
      note: 'Agent started work.',
    );
  }

  /// Completes an in-progress request assigned to [agentId].
  Future<void> completeRequest({
    required String requestId,
    required String agentId,
    String note = '',
  }) {
    final trimmedNote = note.trim();
    if (trimmedNote.length > 500) {
      throw const RequestRepositoryException(
        'invalid-note',
        'Completion notes must be 500 characters or fewer.',
      );
    }
    return _transition(
      requestId: requestId,
      agentId: agentId,
      expectedStatus: shared.StatusNames.inProgress,
      nextStatus: shared.StatusNames.completed,
      note: trimmedNote.isEmpty ? 'Agent completed request.' : trimmedNote,
    );
  }

  Future<void> _transition({
    required String requestId,
    required String agentId,
    required String expectedStatus,
    required String nextStatus,
    required String note,
  }) async {
    final requestRef = _requests.doc(requestId);
    final historyRef = requestRef
        .collection(shared.CollectionNames.statusHistory)
        .doc();

    try {
      final txnRequest = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) {
          throw const RequestRepositoryException(
            'not-found',
            'The request was not found.',
          );
        }

        final request = shared.Request.fromMap(snapshot.data()!);
        if (request.agentId != agentId) {
          throw const RequestRepositoryException(
            'not-assigned',
            'This request is not assigned to you.',
          );
        }
        if (request.status.toStoredValue() != expectedStatus) {
          throw const RequestRepositoryException(
            'stale-transition',
            'This request changed. Refresh it before trying again.',
          );
        }

        try {
          shared.requireValidTransition(
            expectedStatus,
            nextStatus,
            shared.RoleNames.agent,
          );
        } on shared.SharedLifecycleException {
          throw const RequestRepositoryException(
            'invalid-transition',
            'This request cannot move to that status.',
          );
        }

        transaction.update(requestRef, {
          'status': nextStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(historyRef, {
          'fromStatus': expectedStatus,
          'toStatus': nextStatus,
          'changedBy': agentId,
          'changedAt': FieldValue.serverTimestamp(),
          'note': note,
        });

        // Return request data for the notification (avoids a second read).
        return request;
      });

      // Trigger notification via backend — fire-and-forget.
      _sendNotification(
        requestId: requestId,
        status: nextStatus,
        agentId: agentId,
        customerId: txnRequest.customerId,
        agentName: txnRequest.agentName,
        serviceName: txnRequest.serviceType,
      );
    } catch (error) {
      if (error is RequestRepositoryException) rethrow;
      if (error is FirebaseException) {
        final message = switch (error.code) {
          'permission-denied' =>
            'You are not authorized to update this request.',
          'unavailable' || 'deadline-exceeded' =>
            'The service is temporarily unavailable. Please try again.',
          'not-found' => 'The requested record was not found.',
          _ => 'The request could not be updated. Please try again.',
        };
        throw RequestRepositoryException(error.code, message);
      }
      throw const RequestRepositoryException(
        'request-operation-failed',
        'The request could not be updated. Please try again.',
      );
    }
  }

  /// Sends a push notification via the backend. Fire-and-forget.
  static void _sendNotification({
    required String requestId,
    required String status,
    required String agentId,
    required String? customerId,
    required String? agentName,
    required String? serviceName,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;

      const backendUrl = String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'https://quickserve-backend-w98w.onrender.com',
      );

      await http.post(
        Uri.parse('$backendUrl/api/notify-status-change'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'requestId': requestId,
          'status': status,
          'agentId': agentId,
          'customerId': customerId,
          'agentName': agentName,
          'serviceName': serviceName,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }
}
