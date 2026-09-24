import '../repositories/activity_repository.dart';

import 'package:shared/entities/user_entity.dart';

class WatchUsers {
  final ActivityRepository repository;
  WatchUsers(this.repository);
  Stream<List<({String id, UserEntity user})>> call() =>
      repository.watchUsers();
}
