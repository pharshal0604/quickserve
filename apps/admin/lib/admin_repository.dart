import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/shared.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRequests() =>
      firestore.collection(CollectionNames.requests).limit(200).snapshots();

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
  }) => _mutateRequest(
    requestId: requestId,
    status: StatusNames.assigned,
    agentId: agentId,
    action: AuditEvent.requestAssigned.toStoredValue(),
    note: 'Assigned by administrator',
  );

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

  Future<void> _mutateRequest({
    required String requestId,
    required String status,
    required String action,
    String? note,
    String? agentId,
  }) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin session is not signed in.');
    final requestRef = firestore
        .collection(CollectionNames.requests)
        .doc(requestId);
    final historyRef = requestRef
        .collection(CollectionNames.statusHistory)
        .doc();
    final auditRef = firestore.collection(CollectionNames.auditLogs).doc();
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);
      if (!snapshot.exists) throw StateError('Request no longer exists.');
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
      if (agentId != null) changes['agentId'] = agentId;
      transaction.update(requestRef, changes);
      transaction.set(historyRef, {
        'fromStatus': oldStatus,
        'toStatus': status,
        'changedBy': uid,
        'changedAt': FieldValue.serverTimestamp(),
        'note': note ?? '',
      });
      transaction.set(auditRef, {
        'actorUserId': uid,
        'actorRole': RoleNames.admin,
        'action': action,
        'targetType': 'request',
        'targetId': requestId,
        'oldValue': {
          'status': oldStatus,
          if (agentId != null) 'agentId': data['agentId'],
        },
        'newValue': {'status': status, 'agentId': ?agentId},
        'result': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
