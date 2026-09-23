import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ServiceRemoteDataSource {
  Stream<QuerySnapshot> watchServices();
  Future<String> createService(Map<String, dynamic> data);
  Future<void> updateService(String serviceId, Map<String, dynamic> data);
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> watchServices() {
    return firestore.collection('services').orderBy('name').limit(100).snapshots();
  }

  @override
  Future<String> createService(Map<String, dynamic> data) async {
    final doc = await firestore.collection('services').add(data);
    return doc.id;
  }

  @override
  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    await firestore.collection('services').doc(serviceId).update(data);
  }
}
