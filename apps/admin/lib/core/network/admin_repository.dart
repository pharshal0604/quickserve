import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/shared.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRequests() => firestore
      .collection(CollectionNames.requests)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots();

  Future<void> sendPasswordReset(String email) {
    return auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchServices() => firestore
      .collection(CollectionNames.services)
      .orderBy('name')
      .limit(100)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers({String? role}) {
    Query<Map<String, dynamic>> query = firestore
        .collection(CollectionNames.users)
        .limit(200);
    if (role != null) query = query.where('role', isEqualTo: role);
    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAuditLogs() => firestore
      .collection(CollectionNames.auditLogs)
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchHistory(String requestId) =>
      firestore
          .collection(CollectionNames.requests)
          .doc(requestId)
          .collection(CollectionNames.statusHistory)
          .orderBy('changedAt', descending: true)
          .limit(50)
          .snapshots();




  Future<void> assignRequest({
    required String requestId,
    required String agentId,
  }) async {
    await _mutateRequest(
      requestId: requestId,
      status: StatusNames.assigned,
      agentId: agentId,
      action: AuditEvent.requestAssigned.toStoredValue(),
      note: 'Assigned by administrator',
    );
    
    // Trigger the Render custom backend
    try {
      final doc = await firestore.collection(CollectionNames.requests).doc(requestId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final customerId = data['customerId'];
        final agentName = data['agentName'];
        if (customerId != null && agentName != null) {
          // Live Render custom backend URL
          final url = Uri.parse('https://quickserve-backend-w98w.onrender.com/api/notify-assignment');
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'customerId': customerId, 'agentName': agentName}),
          ).timeout(const Duration(seconds: 3));
        }
      }
    } catch (_) {}
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
    String? note,
  }) => _mutateRequest(
    requestId: requestId,
    status: status,
    action: AuditEvent.requestUpdated.toStoredValue(),
    note: note,
  );

  Future<void> updateAgentSchedule({
    required String agentId,
    required String schedule,
  }) async {
    await firestore.collection(CollectionNames.users).doc(agentId).update({
      'schedule': schedule.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _mutateRequest({
    required String requestId,
    required String status,
    required String action,
    String? note,
    String? agentId,
  }) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin session is not signed in.');
    final normalizedNote = note == null ? null : sanitizeRequestText(note);
    if (normalizedNote != null && normalizedNote.length > 500) {
      throw ArgumentError('Notes must be 500 characters or fewer.');
    }
    final requestRef = firestore
        .collection(CollectionNames.requests)
        .doc(requestId);
    final agentRef = agentId == null
        ? null
        : firestore.collection(CollectionNames.users).doc(agentId);
    final historyRef = requestRef
        .collection(CollectionNames.statusHistory)
        .doc();
    final auditRef = firestore.collection(CollectionNames.auditLogs).doc();
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);
      final agentSnapshot = agentRef == null
          ? null
          : await transaction.get(agentRef);
      if (!snapshot.exists) throw StateError('Request no longer exists.');
      if (agentId != null &&
          (agentSnapshot == null ||
              !agentSnapshot.exists ||
              agentSnapshot.data()?['role'] != RoleNames.agent)) {
        throw StateError('The selected user is not an active service agent.');
      }
      final data = snapshot.data()!;
      final oldStatus = data['status'] as String?;
      if (oldStatus == null || !StatusNames.values.contains(status)) {
        throw StateError('The request has an invalid lifecycle status.');
      }
      if (!canTransition(oldStatus, status)) {
        throw StateError('Cannot change $oldStatus to $status.');
      }
      final changes = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == StatusNames.cancelled) {
        final cancellationReason = normalizedNote?.isNotEmpty == true
            ? normalizedNote!
            : 'Cancelled by administrator';
        if (!validateCancellationReason(cancellationReason).isValid) {
          throw ArgumentError('Cancellation reason is invalid.');
        }
        changes['cancellationReason'] = cancellationReason;
      }
      if (agentId != null) {
        final agentData = agentSnapshot!.data()!;
        final agentName = agentData['name'];
        final agentPhone = agentData['phone'];
        if (agentName is! String || agentPhone is! String) {
          throw StateError(
            'The selected agent profile is missing contact details.',
          );
        }
        changes['agentId'] = agentId;
        changes['agentName'] = agentName.trim();
        changes['agentPhone'] = agentPhone.trim();
      }
      transaction.update(requestRef, changes);
      transaction.set(historyRef, {
        'fromStatus': oldStatus,
        'toStatus': status,
        'changedBy': uid,
        'changedAt': FieldValue.serverTimestamp(),
        'note': normalizedNote ?? '',
      });
      transaction.set(auditRef, {
        'actorUserId': uid,
        'actorRole': RoleNames.admin,
        'action': action,
        'targetType': 'request',
        'targetId': requestId,
        'oldValue': {
          'status': oldStatus,
          'agentId': ?(agentId != null ? data['agentId'] : null),
        },
        'newValue': {'status': status, 'agentId': ?agentId},
        'result': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
