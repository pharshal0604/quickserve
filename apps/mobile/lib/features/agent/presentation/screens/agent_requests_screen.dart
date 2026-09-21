import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

class AgentRequestsScreen extends ConsumerStatefulWidget {
  const AgentRequestsScreen({super.key});
  @override
  ConsumerState<AgentRequestsScreen> createState() =>
      _AgentRequestsScreenState();
}

class _AgentRequestsScreenState extends ConsumerState<AgentRequestsScreen> {
  final _searchController = TextEditingController();
  bool _history = false;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _color(String status) {
    if (status == shared.StatusNames.completed) {
      return AppColors.statusCompleted;
    }
    if (status == shared.StatusNames.cancelled) {
      return AppColors.statusCancelled;
    }
    if (status == shared.StatusNames.inProgress) {
      return AppColors.statusProgress;
    }
    if (status == shared.StatusNames.assigned) return AppColors.statusAssigned;
    return AppColors.statusAccepted;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }
    final requests = ref.watch(_assignedRequestsProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Requests')),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () =>
                ref.invalidate(_assignedRequestsProvider(user.uid)),
            child: const Text('Retry requests'),
          ),
        ),
        data: (items) {
          final query = _searchController.text.toLowerCase();
          final filtered = items.where((item) {
            final status = item.request.status.toStoredValue();
            final historyMatch = _history
                ? shared.isTerminalStatus(status)
                : !shared.isTerminalStatus(status);
            return historyMatch &&
                (query.isEmpty ||
                    item.request.requestCode.toLowerCase().contains(query) ||
                    item.request.serviceType.toLowerCase().contains(query));
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                'Manage your queue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Accept, start, and complete assigned work from one place.',
                style: TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: quickServeInputDecoration(
                  'Search requests',
                  icon: Icons.search,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Active')),
                  ButtonSegment(value: true, label: Text('History')),
                ],
                selected: {_history},
                onSelectionChanged: (selection) =>
                    setState(() => _history = selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                const Text(
                  'No requests in this view.',
                  style: TextStyle(color: AppColors.mutedText),
                )
              else
                ...filtered.map((item) {
                  final request = item.request;
                  final status = request.status.toStoredValue();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Card(
                      child: ListTile(
                        onTap: () => context.push('/requests/${item.id}'),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.mintSurface,
                          child: Icon(
                            Icons.assignment_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          request.serviceType,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${request.requestCode}\n${request.address}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: StatusPill(
                          label: status,
                          color: _color(status),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

final _assignedRequestsProvider =
    FutureProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, agentId) => ref
          .watch(agentRepositoryProvider)
          .watchAssignedRequests(agentId)
          .first,
    );
