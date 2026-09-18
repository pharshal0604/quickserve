import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' as shared;

/// Reads requests assigned to the signed-in Agent.
final class AgentRepository {
  const AgentRepository();

  Stream<List<({String id, shared.Request request})>> watchAssignedRequests(
    String agentId,
  ) {
    return FirebaseFirestore.instance
        .collection(shared.CollectionNames.requests)
        .where('agentId', isEqualTo: agentId)
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
}
