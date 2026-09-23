import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CustomerRemoteDataSource {
  Stream<QuerySnapshot> watchCustomers();
  Future<DocumentSnapshot> getCustomerDetails(String customerId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> watchCustomers() {
    return firestore.collection('users').where('role', isEqualTo: 'customer').limit(200).snapshots();
  }

  @override
  Future<DocumentSnapshot> getCustomerDetails(String customerId) {
    return firestore.collection('users').doc(customerId).get();
  }
}
