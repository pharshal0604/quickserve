import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/features/agent/presentation/screens/agent_home/agent_home_screen.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';
import 'package:quickserve_mobile/core/error/app_exceptions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Profile parsing error:\n${err is AppException ? err.userMessage : err}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry profile'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                child: const Text('Sign out'),
              ),
            ],
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
              ? const AgentHomeScreen()
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
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
                        itemBuilder: (context, index) {
                          final s = items[index];
                          return _ServiceCategory(
                            service: s,
                            onTap: () => context.push(
                              Uri(
                                path: '/services/detail',
                                queryParameters: {
                                  'name': s.name,
                                  'desc': s.description,
                                },
                              ).toString(),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),

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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.mintSurface,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 7),
            Text(
              service.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
              color: items.isEmpty
                  ? AppColors.mutedText
                  : Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.mintSurface,
                child: Icon(
                  Icons.bolt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.mintSurface,
                    child: Icon(
                      Icons.bolt_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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

final _homeServicesProvider = StreamProvider<List<shared.Service>>((ref) {
  return ref.watch(serviceRepositoryProvider).watchActiveServices();
});

final _homeRequestsProvider =
    StreamProvider.family<List<({String id, shared.Request request})>, String>(
      (ref, uid) =>
          ref.watch(requestRepositoryProvider).watchCustomerRequests(uid),
    );
