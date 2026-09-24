import '../repositories/request_repository.dart';

import 'package:shared/entities/request_entity.dart';

class WatchRequests {
  final RequestRepository repository;
  WatchRequests(this.repository);
  Stream<List<({String id, RequestEntity request})>> call() =>
      repository.watchRequests();
}
