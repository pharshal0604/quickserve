import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Activity
import 'features/activity/data/data_sources/activity_remote_data_source.dart';
import 'features/activity/data/repositories/activity_repository_impl.dart';
import 'features/activity/domain/repositories/activity_repository.dart';
import 'features/activity/domain/usecases/watch_audit_logs.dart';
import 'features/activity/domain/usecases/watch_users.dart';

// Agents
import 'features/agents/data/data_sources/agent_remote_data_source.dart';
import 'features/agents/data/repositories/agent_repository_impl.dart';
import 'features/agents/domain/repositories/agent_repository.dart';
import 'features/agents/domain/usecases/create_dummy_agent.dart';
import 'features/agents/domain/usecases/get_agent_details.dart';
import 'features/agents/domain/usecases/update_agent_schedule.dart';
import 'features/agents/domain/usecases/watch_agents.dart';

// Auth
import 'features/auth/data/data_sources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_admin_role.dart';
import 'features/auth/domain/usecases/send_password_reset.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';

// Customers
import 'features/customers/data/data_sources/customer_remote_data_source.dart';
import 'features/customers/data/repositories/customer_repository_impl.dart';
import 'features/customers/domain/repositories/customer_repository.dart';
import 'features/customers/domain/usecases/get_customer_details.dart';
import 'features/customers/domain/usecases/watch_customers.dart';

// Requests
import 'features/requests/data/data_sources/request_remote_data_source.dart';
import 'features/requests/data/repositories/request_repository_impl.dart';
import 'features/requests/domain/repositories/request_repository.dart';
import 'features/requests/domain/usecases/assign_request.dart';
import 'features/requests/domain/usecases/update_request_status.dart';
import 'features/requests/domain/usecases/watch_request_history.dart';
import 'features/requests/domain/usecases/watch_requests.dart';

// Services
import 'features/services/data/data_sources/service_remote_data_source.dart';
import 'features/services/data/repositories/service_repository_impl.dart';
import 'features/services/domain/repositories/service_repository.dart';
import 'features/services/domain/usecases/create_service.dart';
import 'features/services/domain/usecases/update_service.dart';
import 'features/services/domain/usecases/watch_services.dart';

// Core Firebase Providers
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Activity
final activityRemoteDataSourceProvider = Provider<ActivityRemoteDataSource>((ref) {
  return ActivityRemoteDataSourceImpl();
});
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(ref.read(activityRemoteDataSourceProvider));
});
final watchAuditLogsProvider = Provider<WatchAuditLogs>((ref) {
  return WatchAuditLogs(ref.read(activityRepositoryProvider));
});
final watchUsersProvider = Provider<WatchUsers>((ref) {
  return WatchUsers(ref.read(activityRepositoryProvider));
});

// Agents
final agentRemoteDataSourceProvider = Provider<AgentRemoteDataSource>((ref) {
  return AgentRemoteDataSourceImpl();
});
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepositoryImpl(ref.read(agentRemoteDataSourceProvider));
});
final createDummyAgentProvider = Provider<CreateDummyAgent>((ref) {
  return CreateDummyAgent(ref.read(agentRepositoryProvider));
});
final getAgentDetailsProvider = Provider<GetAgentDetails>((ref) {
  return GetAgentDetails(ref.read(agentRepositoryProvider));
});
final updateAgentScheduleProvider = Provider<UpdateAgentSchedule>((ref) {
  return UpdateAgentSchedule(ref.read(agentRepositoryProvider));
});
final watchAgentsProvider = Provider<WatchAgents>((ref) {
  return WatchAgents(ref.read(agentRepositoryProvider));
});

// Auth
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});
final checkAdminRoleProvider = Provider<CheckAdminRole>((ref) {
  return CheckAdminRole(ref.read(authRepositoryProvider));
});
final sendPasswordResetProvider = Provider<SendPasswordReset>((ref) {
  return SendPasswordReset(ref.read(authRepositoryProvider));
});
final signInProvider = Provider<SignIn>((ref) {
  return SignIn(ref.read(authRepositoryProvider));
});
final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.read(authRepositoryProvider));
});

// Customers
final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSourceImpl();
});
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.read(customerRemoteDataSourceProvider));
});
final getCustomerDetailsProvider = Provider<GetCustomerDetails>((ref) {
  return GetCustomerDetails(ref.read(customerRepositoryProvider));
});
final watchCustomersProvider = Provider<WatchCustomers>((ref) {
  return WatchCustomers(ref.read(customerRepositoryProvider));
});

// Requests
final requestRemoteDataSourceProvider = Provider<RequestRemoteDataSource>((ref) {
  return RequestRemoteDataSourceImpl();
});
final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepositoryImpl(ref.read(requestRemoteDataSourceProvider));
});
final assignRequestProvider = Provider<AssignRequest>((ref) {
  return AssignRequest(ref.read(requestRepositoryProvider));
});
final updateRequestStatusProvider = Provider<UpdateRequestStatus>((ref) {
  return UpdateRequestStatus(ref.read(requestRepositoryProvider));
});
final watchRequestHistoryProvider = Provider<WatchRequestHistory>((ref) {
  return WatchRequestHistory(ref.read(requestRepositoryProvider));
});
final watchRequestsProvider = Provider<WatchRequests>((ref) {
  return WatchRequests(ref.read(requestRepositoryProvider));
});

// Services
final serviceRemoteDataSourceProvider = Provider<ServiceRemoteDataSource>((ref) {
  return ServiceRemoteDataSourceImpl();
});
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(ref.read(serviceRemoteDataSourceProvider));
});
final createServiceProvider = Provider<CreateService>((ref) {
  return CreateService(ref.read(serviceRepositoryProvider));
});
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.read(serviceRepositoryProvider));
});
final watchServicesProvider = Provider<WatchServices>((ref) {
  return WatchServices(ref.read(serviceRepositoryProvider));
});
