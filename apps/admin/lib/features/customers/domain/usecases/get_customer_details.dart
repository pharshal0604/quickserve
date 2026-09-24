import '../repositories/customer_repository.dart';

import 'package:shared/entities/user_entity.dart';

class GetCustomerDetails {
  final CustomerRepository repository;
  GetCustomerDetails(this.repository);
  Future<({String id, UserEntity user})?> call(String customerId) =>
      repository.getCustomerDetails(customerId);
}
