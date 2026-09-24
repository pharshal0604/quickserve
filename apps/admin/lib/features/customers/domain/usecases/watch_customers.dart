import '../repositories/customer_repository.dart';

import 'package:shared/entities/user_entity.dart';

class WatchCustomers {
  final CustomerRepository repository;
  WatchCustomers(this.repository);
  Stream<List<({String id, UserEntity user})>> call() =>
      repository.watchCustomers();
}
