import '../../domain/repositories/customer_repository.dart';
import '../data_sources/customer_remote_data_source.dart';

import 'package:shared/models/user.dart';
import 'package:shared/entities/user_entity.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<({String id, UserEntity user})>> watchCustomers() {
    return remoteDataSource.watchCustomers().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => (
              id: doc.id,
              user: User.fromMap(doc.data() as Map<String, dynamic>).toEntity(),
            ),
          )
          .toList();
    });
  }

  @override
  Future<({String id, UserEntity user})?> getCustomerDetails(
    String customerId,
  ) async {
    final doc = await remoteDataSource.getCustomerDetails(customerId);
    if (!doc.exists || doc.data() == null) return null;
    return (
      id: doc.id,
      user: User.fromMap(doc.data() as Map<String, dynamic>).toEntity(),
    );
  }
}
