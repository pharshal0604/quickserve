import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class RequestRemoteDataSource {
  Stream<QuerySnapshot> watchRequests();
  Stream<QuerySnapshot> watchRequestHistory(String requestId);
  Future<void> assignRequest(String requestId, String agentId);
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? note,
  });
}

class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> watchRequests() {
    return firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> watchRequestHistory(String requestId) {
    return firestore
        .collection('requests')
        .doc(requestId)
        .collection('status_history')
        .orderBy('changedAt', descending: true)
        .snapshots();
  }

  @override
  Future<void> assignRequest(String requestId, String agentId) async {
    final agentDoc = await firestore.collection('users').doc(agentId).get();
    final agentData = agentDoc.data();
    
    final requestRef = firestore.collection('requests').doc(requestId);
    final requestDoc = await requestRef.get();
    final fromStatus = requestDoc.data()?['status'];
    
    final batch = firestore.batch();
    
    final updateData = {
      'agentId': agentId,
      'agentName':
          agentData?['name'] ?? agentData?['email'] ?? 'Assigned Agent',
      'agentPhone': agentData?['phone'],
      'status': 'assigned',
    };
    batch.update(requestRef, updateData);
    
    final historyRef = requestRef.collection('status_history').doc();
    batch.set(historyRef, {
      'fromStatus': fromStatus,
      'toStatus': 'assigned',
      'changedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      'changedAt': FieldValue.serverTimestamp(),
      'note': 'Assigned to ${agentData?['name'] ?? 'Agent'}',
    });
    
    await batch.commit();
  }

  @override
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? note,
  }) async {
    final requestRef = firestore.collection('requests').doc(requestId);
    final requestDoc = await requestRef.get();
    final fromStatus = requestDoc.data()?['status'];

    final batch = firestore.batch();
    
    final data = <String, dynamic>{'status': status};
    batch.update(requestRef, data);
    
    final historyRef = requestRef.collection('status_history').doc();
    batch.set(historyRef, {
      'fromStatus': fromStatus,
      'toStatus': status,
      'changedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      'changedAt': FieldValue.serverTimestamp(),
      'note': note,
    });
    
    await batch.commit();
  }
}
