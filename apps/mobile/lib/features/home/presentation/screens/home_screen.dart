import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Retry profile'),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: FilledButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                child: const Text('Sign out'),
              ),
            );
          }
          return user.role == shared.UserRole.agent
              ? _AgentDashboard(name: user.name)
              : _CustomerDashboard(name: user.name);
        },
      ),
    );
  }
}

class _CustomerDashboard extends ConsumerWidget {
  const _CustomerDashboard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final services = ref.watch(_homeServicesProvider);
    final requests = authUser == null
        ? null
        : ref.watch(_homeRequestsProvider(authUser.uid));
    final active = requests?.valueOrNull
        ?.where(
          (item) =>
              !shared.isTerminalStatus(item.request.status.toStoredValue()),
        )
        .toList(growable: false);
    final firstName = name.trim().split(' ').first;
    final photoUrl = authUser?.photoURL;

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
      body: SafeArea(
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
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                    backgroundImage: photoUrl == null || photoUrl.isEmpty
                        ? null
                        : NetworkImage(photoUrl),
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                            firstName.isEmpty
                                ? '?'
                                : firstName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: () => context.go('/services'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.mutedText),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Browse services',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Service categories',
              action: 'View all',
              onTap: () => context.go('/services'),
            ),
            const SizedBox(height: AppSpacing.sm),
            services.when(
              loading: () => const SizedBox(
                height: 110,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => SizedBox(
                height: 110,
                child: Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_homeServicesProvider),
                    child: const Text('Retry services'),
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const SizedBox(
                      height: 110,
                      child: Center(child: Text('No active services yet.')),
                    )
                  : SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) => _ServiceCategory(
                          service: items[index],
                          onTap: () => context.push(
                            '/services/detail',
                            extra: items[index],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (services.valueOrNull != null &&
                services.valueOrNull!.isNotEmpty)
              _FeaturedServiceCard(
                service: services.valueOrNull!.first,
                onTap: () => context.push(
                  '/services/detail',
                  extra: services.valueOrNull!.first,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            _ActiveRequestsSection(
              items: active ?? const [],
              isLoading: requests?.isLoading ?? false,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/requests/create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Request'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.go('/requests'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View my requests'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCategory extends StatelessWidget {
  const _ServiceCategory({required this.service, required this.onTap});
  final shared.Service service;
  final VoidCallback onTap;

  IconData get icon {
    final value = service.name.toLowerCase();
    if (value.contains('ac') || value.contains('air')) return Icons.ac_unit;
    if (value.contains('plumb')) return Icons.plumbing_outlined;
    if (value.contains('electric')) return Icons.electrical_services_outlined;
    if (value.contains('clean')) return Icons.cleaning_services_outlined;
    return Icons.home_repair_service_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 94,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.mintSurface,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 7),
            Text(
              service.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedServiceCard extends StatelessWidget {
  const _FeaturedServiceCard({required this.service, required this.onTap});
  final shared.Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.home_repair_service_rounded,
              color: AppColors.gold,
              size: 46,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available service',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ActiveRequestsSection extends StatelessWidget {
  const _ActiveRequestsSection({required this.items, required this.isLoading});
  final List<({String id, shared.Request request})> items;
  final bool isLoading;

  Color _statusColor(String status) {
    if (status == shared.StatusNames.inProgress) {
      return AppColors.statusProgress;
    }
    if (status == shared.StatusNames.assigned) return AppColors.statusAssigned;
    if (status == shared.StatusNames.accepted) return AppColors.statusAccepted;
    return AppColors.statusCreated;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active Request',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            StatusPill(
              label: '${items.length} Ongoing',
              color: items.isEmpty ? AppColors.mutedText : AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.mintSurface,
                child: Icon(Icons.bolt_outlined, color: AppColors.primary),
              ),
              title: const Text('No active requests'),
              subtitle: const Text('Your new requests will appear here.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/requests/create'),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: ListTile(
                  onTap: () => context.push('/requests/${item.id}'),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.mintSurface,
                    child: Icon(Icons.bolt_outlined, color: AppColors.primary),
                  ),
                  title: Text(
                    item.request.serviceType,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${item.request.requestCode} · ${item.request.address}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StatusPill(
                    label: item.request.status.toStoredValue(),
                    color: _statusColor(item.request.status.toStoredValue()),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AgentDashboard extends ConsumerWidget {
  const _AgentDashboard({required this.name});
  final String name;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    final requests = auth == null
        ? null
        : ref.watch(_agentHomeRequestsProvider(auth.uid));
    final items =
        requests?.valueOrNull ??
        const <({String id, shared.Request request})>[];
    final active = items
        .where(
          (item) =>
              !shared.isTerminalStatus(item.request.status.toStoredValue()),
        )
        .length;
    final completed = items
        .where(
          (item) =>
              item.request.status.toStoredValue() ==
              shared.StatusNames.completed,
        )
        .length;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agent dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                      Text(
                        'Welcome back, $name',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                _Metric(
                  label: 'Assigned',
                  value: '${items.length}',
                  icon: Icons.assignment_outlined,
                ),
                const SizedBox(width: AppSpacing.sm),
                _Metric(
                  label: 'Active',
                  value: '$active',
                  icon: Icons.timelapse,
                ),
                const SizedBox(width: AppSpacing.sm),
                _Metric(
                  label: 'Completed',
                  value: '$completed',
                  icon: Icons.task_alt,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Assigned requests'),
            if (requests?.isLoading ?? false)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              const Text(
                'No assigned requests yet.',
                style: TextStyle(color: AppColors.mutedText),
              )
            else
              ...items
                  .take(5)
                  .map(
                    (item) => Card(
                      child: ListTile(
                        onTap: () => context.push('/requests/${item.id}'),
                        leading: const Icon(
                          Icons.assignment_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(item.request.serviceType),
                        subtitle: Text(
                          '${item.request.requestCode} · ${item.request.status.toStoredValue()}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push('/agent/requests'),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('View all assigned requests'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

final _homeServicesProvider = StreamProvider<List<shared.Service>>((ref) {
  return ref.watch(serviceRepositoryProvider).watchActiveServices();
});

final _homeRequestsProvider =
    StreamProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, uid) =>
          ref.watch(requestRepositoryProvider).watchCustomerRequests(uid),
    );

final _agentHomeRequestsProvider =
    FutureProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, uid) =>
          ref.watch(agentRepositoryProvider).watchAssignedRequests(uid).first,
    );
