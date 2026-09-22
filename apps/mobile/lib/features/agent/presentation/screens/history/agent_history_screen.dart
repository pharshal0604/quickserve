import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/features/agent/presentation/widgets/agent_common/agent_bottom_nav.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

/// Completed and cancelled work for the signed-in agent.
class AgentHistoryScreen extends ConsumerStatefulWidget {
  const AgentHistoryScreen({super.key});

  @override
  ConsumerState<AgentHistoryScreen> createState() => _AgentHistoryScreenState();
}

class _AgentHistoryScreenState extends ConsumerState<AgentHistoryScreen> {
  String _query = '';
  bool _completedOnly = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final requests = ref.watch(_agentHistoryRequestsProvider(uid));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Request History',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: SizedBox(
                height: 38,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, customer, or service...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    // Fill, borders, and focus colors come from inputDecorationTheme.
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _HistoryFilterChip(
                    label: 'All',
                    selected: !_completedOnly,
                    onTap: () => setState(() => _completedOnly = false),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _HistoryFilterChip(
                    label: 'Completed',
                    selected: _completedOnly,
                    onTap: () => setState(() => _completedOnly = true),
                  ),
                  const Spacer(),
                  _HistoryFilterChip(
                    label: 'Options',
                    icon: Icons.filter_alt_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: requests.when(
                loading: () => const _ArchiveLoading(),
                error: (_, _) =>
                    const Center(child: Text('History could not be loaded.')),
                data: (items) {
                  final query = _query.trim().toLowerCase();
                  final history = items.where((item) {
                    final status = item.request.status;
                    if (status != shared.RequestStatus.completed &&
                        status != shared.RequestStatus.cancelled) {
                      return false;
                    }
                    if (_completedOnly &&
                        status != shared.RequestStatus.completed) {
                      return false;
                    }
                    if (query.isEmpty) return true;
                    final request = item.request;
                    return item.id.toLowerCase().contains(query) ||
                        request.requestCode.toLowerCase().contains(query) ||
                        request.serviceType.toLowerCase().contains(query) ||
                        request.address.toLowerCase().contains(query);
                  }).toList();

                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'No archived requests yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final request = item.request;
                      final status = request.status.toStoredValue();
                      return Card(
                        child: ListTile(
                          onTap: () => context.push('/requests/${item.id}'),
                          leading: Icon(
                            request.status == shared.RequestStatus.completed
                                ? Icons.task_alt
                                : Icons.cancel_outlined,
                            color: shared.QuickServeStatusColors.forStatus(
                              status,
                            ),
                          ),
                          title: Text(
                            request.serviceType,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${request.requestCode} Â· ${request.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: StatusPill(
                            label: _statusLabel(status),
                            color: shared.QuickServeStatusColors.forStatus(
                              status,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 2),
    );
  }

  static String _statusLabel(String value) {
    return value
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }
}

class _ArchiveLoading extends StatelessWidget {
  const _ArchiveLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Retrieving archive...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    this.icon,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = selected
        ? Theme.of(context).colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foreground = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: foreground),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _agentHistoryRequestsProvider =
    StreamProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, uid) =>
          ref.watch(agentRepositoryProvider).watchAssignedRequests(uid),
    );
