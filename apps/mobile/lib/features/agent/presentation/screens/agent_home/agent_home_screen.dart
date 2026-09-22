import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/features/agent/presentation/widgets/agent_common/agent_bottom_nav.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

/// Agent dashboard with quick access, metrics, and upcoming assigned work.
class AgentHomeScreen extends ConsumerWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).value;

    if (authUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final requests = ref.watch(_agentRequestsProvider(authUser.uid));
    return profile.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Retry profile'),
          ),
        ),
      ),
      data: (user) {
        if (user == null || user.role != shared.UserRole.agent) {
          return const Scaffold(
            body: Center(child: Text('Agent profile not found.')),
          );
        }
        return _AgentHomeContent(agentName: user.name, requests: requests);
      },
    );
  }
}

class _AgentHomeContent extends StatelessWidget {
  const _AgentHomeContent({required this.agentName, required this.requests});

  final String agentName;
  final AsyncValue<List<({String id, shared.Request request})>> requests;

  @override
  Widget build(BuildContext context) {
    final items = requests.valueOrNull ?? const [];
    final pending = items
        .where((item) => item.request.status == shared.RequestStatus.assigned)
        .length;
    final active = items
        .where(
          (item) =>
              item.request.status == shared.RequestStatus.accepted ||
              item.request.status == shared.RequestStatus.inProgress,
        )
        .length;
    final completed = items
        .where((item) => item.request.status == shared.RequestStatus.completed)
        .length;
    final upcoming =
        items
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const AgentBottomNav(currentIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/agent/requests'),
        tooltip: 'View tasks',
        child: const Icon(Icons.navigation_outlined),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          agentName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(28),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.mintSurface,
                      child: Text(
                        _initials(agentName),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  _MetricCard(
                    label: 'Pending',
                    value: '$pending',
                    caption: 'Needs action',
                    icon: Icons.assignment_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                    label: 'Active',
                    value: '$active',
                    caption: 'On site',
                    icon: Icons.schedule_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                    label: 'Done',
                    value: '$completed',
                    caption: 'This month',
                    icon: Icons.task_alt,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _PerformanceCard(),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: 'Quick Access'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickAction(
                    label: 'Schedule',
                    icon: Icons.calendar_month_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => context.go('/agent/requests'),
                  ),
                  _QuickAction(
                    label: 'Messages',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: colorScheme.secondary,
                    onTap: () => context.push('/notifications'),
                  ),
                  _QuickAction(
                    label: 'Inventory',
                    icon: Icons.apps_outlined,
                    color: AppColors.warning,
                    onTap: () => _showComingSoon(context, 'Inventory'),
                  ),
                  _QuickAction(
                    label: 'Map View',
                    icon: Icons.navigation_outlined,
                    color: AppColors.success,
                    onTap: () => _showComingSoon(context, 'Map view'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Upcoming Tasks',
                action: 'View All â†’',
                onTap: () => context.go('/agent/requests'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (requests.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (requests.hasError)
                const _EmptyState(
                  message: 'Assigned tasks could not be loaded.',
                )
              else if (upcoming.isEmpty)
                const _EmptyState(message: 'No upcoming tasks yet.')
              else
                ...upcoming
                    .take(3)
                    .map((item) => _UpcomingTaskCard(item: item)),
              const SizedBox(height: AppSpacing.lg),
              _AvailabilityCard(
                onTap: () => _showComingSoon(context, 'Availability'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available in the agent tools.')),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '↗ Performance Efficiency',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '88%',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(value: .88, minHeight: 7),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your completion rate is 5% higher than last week. Great job!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTaskCard extends StatelessWidget {
  const _UpcomingTaskCard({required this.item});

  final ({String id, shared.Request request}) item;

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final status = request.status.toStoredValue();
    final statusColor = shared.QuickServeStatusColors.forStatus(status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => context.push('/requests/${item.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.mintSurface,
          child: Icon(Icons.navigation_outlined, color: statusColor),
        ),
        title: Text(
          request.serviceType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${_timeLabel(request.preferredDateTime)} · ${request.address}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusPill(label: _statusLabel(status), color: statusColor),
      ),
    );
  }

  static String _timeLabel(DateTime value) {
    final hour = value.hour == 0 || value.hour == 12 ? 12 : value.hour % 12;
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${value.minute.toString().padLeft(2, '0')} $period';
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

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.mintSurface,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: const Icon(Icons.check),
        ),
        title: Text(
          'Ready for your next shift?',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Keep your availability up to date for new requests.',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

final _agentRequestsProvider =
    StreamProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, uid) =>
          ref.watch(agentRepositoryProvider).watchAssignedRequests(uid),
    );
