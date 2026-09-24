import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/features/agent/presentation/providers/agent_providers.dart';
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

    final requests = ref.watch(agentRequestsProvider);
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
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search by ID, customer, or service...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    // Fill, borders, and focus colors come from inputDecorationTheme.
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
                      separatorBuilder: (_, _) =>
                          SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final request = item.request;
                        final status = request.status.toStoredValue();
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => context.push('/requests/${item.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        request.status ==
                                                shared.RequestStatus.completed
                                            ? Icons.task_alt
                                            : Icons.cancel_outlined,
                                        color:
                                            shared
                                                .QuickServeStatusColors.forStatus(
                                              status,
                                            ),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          request.serviceType,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      StatusPill(
                                        label: _statusLabel(status),
                                        color:
                                            shared
                                                .QuickServeStatusColors.forStatus(
                                              status,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          request.address,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.tag,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        request.requestCode,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
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
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

