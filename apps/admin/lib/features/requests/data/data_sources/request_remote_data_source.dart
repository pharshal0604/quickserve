import 'package:cloud_firestore/cloud_firestore.dart';

abstract class RequestRemoteDataSource {
  Stream<QuerySnapshot> watchRequests();
  Stream<QuerySnapshot> watchRequestHistory(String requestId);
  Future<void> assignRequest(String requestId, String agentId);
  Future<void> updateRequestStatus(String requestId, String status, {String? note});
}

class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> watchRequests() {
    return firestore.collection('requests').orderBy('createdAt', descending: true).limit(200).snapshots();
  }

  @override
  Stream<QuerySnapshot> watchRequestHistory(String requestId) {
    return firestore.collection('requests').doc(requestId).collection('statusHistory').orderBy('timestamp', descending: true).snapshots();
  }

  @override
  Future<void> assignRequest(String requestId, String agentId) async {
    final agentDoc = await firestore.collection('users').doc(agentId).get();
    final agentData = agentDoc.data();
    final updateData = {
      'agentId': agentId,
      'agentName': agentData?['displayName'] ?? agentData?['email'] ?? 'Assigned Agent',
      'agentPhone': agentData?['phone'],
      'status': 'assigned', // It also updates status in UI, might as well make sure it's updated in DB if needed, but let's just do name/phone
    };
    await firestore.collection('requests').doc(requestId).update(updateData);
  }

  @override
  Future<void> updateRequestStatus(String requestId, String status, {String? note}) async {
    final data = <String, dynamic>{'status': status};
    if (note != null) data['note'] = note;
    await firestore.collection('requests').doc(requestId).update(data);
  }
}
