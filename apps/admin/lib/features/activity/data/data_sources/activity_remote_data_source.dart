import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

abstract class ActivityRemoteDataSource {
  Stream<QuerySnapshot> watchAuditLogs();
  Stream<QuerySnapshot> watchUsers();
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> watchAuditLogs() {
    return firestore
        .collection(CollectionNames.auditLogs)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> watchUsers() {
    return firestore.collection(CollectionNames.users).limit(200).snapshots();
  }
}
