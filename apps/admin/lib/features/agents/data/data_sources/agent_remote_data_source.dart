import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AgentRemoteDataSource {
  Stream<QuerySnapshot> watchAgents();
  Future<DocumentSnapshot> getAgentDetails(String agentId);
  Future<void> updateAgentSchedule(String agentId, Map<String, dynamic> schedule);
  Future<void> createDummyAgent(Map<String, dynamic> agentData);
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> watchAgents() {
    return firestore.collection('users').where('role', isEqualTo: 'agent').limit(200).snapshots();
  }

  @override
  Future<DocumentSnapshot> getAgentDetails(String agentId) {
    return firestore.collection('users').doc(agentId).get();
  }

  @override
  Future<void> updateAgentSchedule(String agentId, Map<String, dynamic> schedule) async {
    await firestore.collection('users').doc(agentId).update({'schedule': schedule});
  }

  @override
  Future<void> createDummyAgent(Map<String, dynamic> agentData) async {
    await firestore.collection('users').add(agentData);
  }
}
