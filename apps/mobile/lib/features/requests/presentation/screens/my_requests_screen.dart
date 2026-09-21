import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
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
    if (status == shared.StatusNames.accepted) return AppColors.statusAccepted;
    return AppColors.statusCreated;
  }

  List<Widget> _filterChips() {
    return [
      'All',
      'Active',
      'created',
      'assigned',
      'accepted',
      'in_progress',
      'completed',
      'cancelled',
    ].map<Widget>((
      filter,
    ) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(filter[0].toUpperCase() + filter.substring(1)),
          selected: _filter == filter,
          onSelected: (_) => setState(() => _filter = filter),
        ),
      );
    }).toList();
  }

  Widget _requestCard(
    BuildContext context,
    ({String id, shared.Request request}) item,
  ) {
    final request = item.request;
    final status = request.status.toStoredValue();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/requests/${item.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.serviceType,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusPill(label: status, color: _statusColor(status)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  request.requestCode,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 6),
                Text(
                  request.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        request.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      MaterialLocalizations.of(context)
                          .formatShortDate(request.preferredDateTime.toDate()),
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                    const Spacer(),
                    Text(
                      request.priority.toStoredValue(),
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }
    final requests = ref.watch(_customerRequestsProvider(user.uid));
    return HomeBackScope(
      child: Scaffold(
        bottomNavigationBar: const CustomerBottomNav(currentIndex: 2),
      body: SafeArea(
        child: requests.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () =>
                  ref.invalidate(_customerRequestsProvider(user.uid)),
              child: const Text('Retry requests'),
            ),
          ),
          data: (items) {
            final query = _searchController.text.toLowerCase();
            final filtered = items.where((item) {
              final status = item.request.status.toStoredValue();
              final matchesQuery =
                  query.isEmpty ||
                  item.request.requestCode.toLowerCase().contains(query) ||
                  item.request.serviceType.toLowerCase().contains(query);
              final matchesFilter =
                  _filter == 'All' ||
                  (_filter == 'Active'
                      ? !shared.isTerminalStatus(status)
                      : status == _filter.toLowerCase());
              return matchesQuery && matchesFilter;
            }).toList();
            final activeCount = items
                .where((item) =>
                    !shared.isTerminalStatus(item.request.status.toStoredValue()))
                .length;
            final completedCount = items
                .where((item) =>
                    item.request.status.toStoredValue() ==
                    shared.StatusNames.completed)
                .length;
            final cancelledCount = items
                .where((item) =>
                    item.request.status.toStoredValue() ==
                    shared.StatusNames.cancelled)
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  'My Requests',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Track every request from creation to completion.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _RequestMetric(
                        label: 'Total',
                        value: '${items.length}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RequestMetric(
                        label: 'Active',
                        value: '$activeCount',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RequestMetric(
                        label: 'Done',
                        value: '$completedCount',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RequestMetric(
                        label: 'Cancelled',
                        value: '$cancelledCount',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: quickServeInputDecoration(
                    'Search by service or ID',
                    icon: Icons.search,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filterChips(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (filtered.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        const Text('No matching requests.'),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context.push('/requests/create'),
                          child: const Text('Create a request'),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((item) => _requestCard(context, item)),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _RequestMetric extends StatelessWidget {
  const _RequestMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

final _customerRequestsProvider =
    StreamProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, uid) => ref.watch(requestRepositoryProvider).watchCustomerRequests(uid),
    );
