import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/features/agent/presentation/widgets/agent_common/agent_bottom_nav.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';

class AgentRequestsScreen extends ConsumerStatefulWidget {
  const AgentRequestsScreen({super.key});

  @override
  ConsumerState<AgentRequestsScreen> createState() =>
      _AgentRequestsScreenState();
}

class _AgentRequestsScreenState extends ConsumerState<AgentRequestsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'all';
  bool _sortByPriority = true;
  String? _busyRequestId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    final requests = ref.watch(_assignedRequestsProvider(user.uid));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: const AgentBottomNav(currentIndex: 1),
        body: SafeArea(
          child: requests.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(_assignedRequestsProvider(user.uid)),
                child: const Text('Retry requests'),
              ),
            ),
            data: (items) => _AssignedRequestsBody(
              items: _filteredItems(items),
              totalCount: items.length,
              controller: _searchController,
              filter: _filter,
              sortByPriority: _sortByPriority,
              busyRequestId: _busyRequestId,
              onSearchChanged: (_) => setState(() {}),
              onFilterChanged: (value) => setState(() => _filter = value),
              onSortChanged: () =>
                  setState(() => _sortByPriority = !_sortByPriority),
              onOpen: (item) => context.push('/requests/${item.id}'),
              onAction: (item) => _performAction(item, user.uid),
            ),
          ),
        ),
      ),
    );
  }

  List<({String id, shared.Request request})> _filteredItems(
    List<({String id, shared.Request request})> items,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final result = items.where((item) {
      final status = item.request.status.toStoredValue();
      final matchesFilter = switch (_filter) {
        'assigned' => status == shared.StatusNames.assigned,
        'accepted' => status == shared.StatusNames.accepted,
        'active' =>
          status == shared.StatusNames.accepted ||
              status == shared.StatusNames.inProgress,
        _ => true,
      };
      final searchable =
          '${item.request.requestCode} ${item.request.serviceType} ${item.request.address}'
              .toLowerCase();
      return matchesFilter && (query.isEmpty || searchable.contains(query));
    }).toList();

    if (_sortByPriority) {
      result.sort(
        (a, b) =>
            _priority(a.request.priority)
                .compareTo(_priority(b.request.priority)),
      );
    }
    return result;
  }

  int _priority(shared.RequestPriority value) => switch (value) {
    shared.RequestPriority.high => 0,
    shared.RequestPriority.medium => 1,
    shared.RequestPriority.low => 2,
  };

  Future<void> _performAction(
    ({String id, shared.Request request}) item,
    String agentId,
  ) async {
    final status = item.request.status.toStoredValue();
    if (status == shared.StatusNames.inProgress ||
        shared.isTerminalStatus(status)) {
      context.push('/requests/${item.id}');
      return;
    }

    setState(() => _busyRequestId = item.id);
    try {
      final repository = ref.read(agentRepositoryProvider);
      if (status == shared.StatusNames.assigned) {
        await repository.acceptAssignedRequest(
          requestId: item.id,
          agentId: agentId,
        );
      } else if (status == shared.StatusNames.accepted) {
        await repository.startRequest(requestId: item.id, agentId: agentId);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  String _errorMessage(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

class _AssignedRequestsBody extends StatelessWidget {
  const _AssignedRequestsBody({
    required this.items,
    required this.totalCount,
    required this.controller,
    required this.filter,
    required this.sortByPriority,
    required this.busyRequestId,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onOpen,
    required this.onAction,
  });

  final List<({String id, shared.Request request})> items;
  final int totalCount;
  final TextEditingController controller;
  final String filter;
  final bool sortByPriority;
  final String? busyRequestId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSortChanged;
  final ValueChanged<({String id, shared.Request request})> onOpen;
  final ValueChanged<({String id, shared.Request request})> onAction;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {},
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
      children: [
        Text(
          'Assigned Tasks',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Manage your assigned and active work.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search by ID, name or service...',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          ),
        ),
        const SizedBox(height: 8),
        _FilterPills(selected: filter, onSelected: onFilterChanged),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              ' $totalCount - REQUESTS ',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .5),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onSortChanged,
              icon: Icon(
                sortByPriority ? Icons.filter_alt : Icons.swap_vert,
                size: 13,
              ),
              label: Text(sortByPriority ? 'Sort By Priority' : 'Sort By Date'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No requests match this view.')),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RequestCard(
                item: item,
                busy: busyRequestId == item.id,
                onOpen: () => onOpen(item),
                onAction: () => onAction(item),
              ),
            ),
        const SizedBox(height: 18),
        Center(
          child: TextButton.icon(
            onPressed: null,
            icon: const SizedBox.shrink(),
            label: Text(
              'Load More Requests',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _Pill(
          label: 'All Tasks',
          value: 'all',
          selected: selected == 'all',
          onTap: onSelected,
        ),
        _Pill(
          label: 'Assigned',
          value: 'assigned',
          selected: selected == 'assigned',
          onTap: onSelected,
        ),
        _Pill(
          label: 'Accepted',
          value: 'accepted',
          selected: selected == 'accepted',
          onTap: onSelected,
        ),
        _Pill(
          label: 'Active',
          value: 'active',
          selected: selected == 'active',
          onTap: onSelected,
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.item,
    required this.busy,
    required this.onOpen,
    required this.onAction,
  });
  final ({String id, shared.Request request}) item;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final status = request.status.toStoredValue();
    final statusColor = _statusColor(status);
    final actionLabel = switch (status) {
      shared.StatusNames.assigned => 'Accept Request',
      shared.StatusNames.accepted => 'Start Work',
      _ => '',
    };
    final activeAction =
        status == shared.StatusNames.assigned ||
        status == shared.StatusNames.accepted;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requestCode,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.serviceType,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              _RequestMeta(
                icon: Icons.person_outline,
                value: request.customerId.isEmpty
                    ? 'Customer unavailable'
                    : request.customerId,
              ),
              _RequestMeta(
                icon: Icons.location_on_outlined,
                value: request.address,
                secondary: true,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _RequestMetaInline(
                    icon: Icons.calendar_today_outlined,
                    value: _date(request.preferredDateTime),
                  ),
                  const SizedBox(width: 16),
                  _RequestMetaInline(
                    icon: Icons.access_time,
                    value: _time(request.preferredDateTime),
                  ),
                ],
              ),
              if (activeAction) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : onAction,
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(actionLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) => switch (status) {
    shared.StatusNames.inProgress => AppColors.statusProgress,
    shared.StatusNames.accepted => AppColors.success,
    shared.StatusNames.assigned => AppColors.warning,
    shared.StatusNames.completed => AppColors.success,
    _ => AppColors.mutedText,
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          _label(status),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  static String _label(String value) => value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _RequestMeta extends StatelessWidget {
  const _RequestMeta({
    required this.icon,
    required this.value,
    this.secondary = false,
  });
  final IconData icon;
  final String value;
  final bool secondary;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: secondary ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: secondary ? 9 : 10,
              color: secondary
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequestMetaInline extends StatelessWidget {
  const _RequestMetaInline({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 8),
      Text(
        value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
      ),
    ],
  );
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _time(DateTime value) {
  final hour = value.hour == 0 || value.hour == 12 ? 12 : value.hour % 12;
  return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}

final _assignedRequestsProvider =
    StreamProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, agentId) =>
          ref.watch(agentRepositoryProvider).watchAssignedRequests(agentId),
    );
