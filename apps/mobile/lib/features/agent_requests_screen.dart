import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';

/// Shows requests assigned to the signed-in Agent.
class AgentRequestsScreen extends ConsumerWidget {
  const AgentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }
    final requests = ref.watch(_assignedRequestsProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Requests')),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load assigned requests.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No assigned requests yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final request = item.request;
                  return Card(
                    child: ListTile(
                      title: Text(request.requestCode),
                      subtitle: Text(
                        '${request.serviceType}\n${request.status.toStoredValue()} · ${request.priority.toStoredValue()}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/requests/${item.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

final _assignedRequestsProvider =
    FutureProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, agentId) async => ref
          .watch(agentRepositoryProvider)
          .watchAssignedRequests(agentId)
          .first,
    );
