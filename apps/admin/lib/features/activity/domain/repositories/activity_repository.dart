import 'package:shared/entities/audit_log_entity.dart';
import 'package:shared/entities/user_entity.dart';

abstract class ActivityRepository {
  Stream<List<({String id, AuditLogEntity log})>> watchAuditLogs();
  Stream<List<({String id, UserEntity user})>> watchUsers();
}
