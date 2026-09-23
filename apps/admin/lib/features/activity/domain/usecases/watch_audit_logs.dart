import '../repositories/activity_repository.dart';
import 'package:shared/entities/audit_log_entity.dart';

class WatchAuditLogs {
  final ActivityRepository repository;
  WatchAuditLogs(this.repository);
  Stream<List<({String id, AuditLogEntity log})>> call() => repository.watchAuditLogs();
}
