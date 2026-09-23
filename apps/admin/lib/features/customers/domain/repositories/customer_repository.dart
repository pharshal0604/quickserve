import 'package:shared/entities/user_entity.dart';

abstract class CustomerRepository {
  Stream<List<({String id, UserEntity user})>> watchCustomers();
  Future<({String id, UserEntity user})?> getCustomerDetails(String customerId);
}
