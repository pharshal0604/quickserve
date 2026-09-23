import '../../domain/repositories/activity_repository.dart';
import '../data_sources/activity_remote_data_source.dart';
import 'package:shared/models/audit_log.dart';
import 'package:shared/models/user.dart';
import 'package:shared/entities/audit_log_entity.dart';
import 'package:shared/entities/user_entity.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;

  ActivityRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<({String id, AuditLogEntity log})>> watchAuditLogs() {
    return remoteDataSource.watchAuditLogs().map((snapshot) {
      return snapshot.docs.map((doc) => (id: doc.id, log: AuditLog.fromMap(doc.data() as Map<String, dynamic>).toEntity())).toList();
    });
  }

  @override
  Stream<List<({String id, UserEntity user})>> watchUsers() {
    return remoteDataSource.watchUsers().map((snapshot) {
      return snapshot.docs.map((doc) => (id: doc.id, user: User.fromMap(doc.data() as Map<String, dynamic>).toEntity())).toList();
    });
  }
}
