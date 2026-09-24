import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';

/// Streams all requests assigned to the current agent.
final agentRequestsProvider =
    StreamProvider<List<({String id, shared.Request request})>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(agentRepositoryProvider).watchAssignedRequests(uid);
});

/// Computes metrics for the agent dashboard.
final agentMetricsProvider = Provider(
  (ref) {
    final requests = ref.watch(agentRequestsProvider).valueOrNull ?? [];
    
    final pending = requests
        .where((item) => item.request.status == shared.RequestStatus.assigned)
        .length;
    final active = requests
        .where(
          (item) =>
              item.request.status == shared.RequestStatus.accepted ||
              item.request.status == shared.RequestStatus.inProgress,
        )
        .length;
    final completed = requests
        .where((item) => item.request.status == shared.RequestStatus.completed)
        .length;
    final cancelled = requests
        .where((item) => item.request.status == shared.RequestStatus.cancelled)
        .length;
        
    final resolved = completed + cancelled;
    final efficiency = resolved == 0 ? 1.0 : completed / resolved;
    
    return (
      pending: pending,
      active: active,
      completed: completed,
      cancelled: cancelled,
      efficiency: efficiency,
    );
  },
);

final agentUpcomingRequestsProvider = Provider(
  (ref) {
    final requests = ref.watch(agentRequestsProvider).valueOrNull ?? [];
    
    final upcoming = requests
        .where(
          (item) =>
              item.request.status != shared.RequestStatus.completed &&
              item.request.status != shared.RequestStatus.cancelled,
        )
        .toList()
      ..sort(
        (a, b) => a.request.preferredDateTime.compareTo(
          b.request.preferredDateTime,
        ),
      );
      
    return upcoming;
  },
);
