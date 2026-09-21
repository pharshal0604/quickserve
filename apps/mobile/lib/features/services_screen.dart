import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'quickserve_widgets.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});
  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _icon(String name) {
    final value = name.toLowerCase();
    if (value.contains('ac') || value.contains('air')) return Icons.ac_unit;
    if (value.contains('plumb')) return Icons.plumbing_outlined;
    if (value.contains('electric')) return Icons.electrical_services_outlined;
    if (value.contains('clean')) return Icons.cleaning_services_outlined;
    return Icons.home_repair_service_outlined;
  }

  List<Widget> _filterChips() {
    return ['All', 'AC', 'Plumbing', 'Electrical', 'Cleaning'].map<Widget>((
      filter,
    ) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(filter),
          selected: _filter == filter,
          onSelected: (_) => setState(() => _filter = filter),
        ),
      );
    }).toList();
  }

  Widget _serviceCard(BuildContext context, shared.Service service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          leading: CircleAvatar(
            backgroundColor: AppColors.mintSurface,
            child: Icon(_icon(service.name), color: AppColors.primary),
          ),
          title: Text(
            service.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/services/detail', extra: service),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(_servicesProvider);
    return Scaffold(
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
      body: SafeArea(
        child: services.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(_servicesProvider),
              child: const Text('Retry services'),
            ),
          ),
          data: (items) {
            final query = _searchController.text.trim().toLowerCase();
            final filtered = items.where((service) {
              final matchesQuery =
                  query.isEmpty ||
                  service.name.toLowerCase().contains(query) ||
                  service.description.toLowerCase().contains(query);
              final matchesFilter =
                  _filter == 'All' ||
                  service.name.toLowerCase().contains(_filter.toLowerCase());
              return matchesQuery && matchesFilter;
            }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  'Find Services',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Browse services',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Find the right professional for your home.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: quickServeInputDecoration(
                    'Search services',
                    icon: Icons.search,
                    suffix: const Icon(Icons.tune_rounded),
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
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: Text('No matching services found.')),
                  )
                else
                  ...filtered.map((service) => _serviceCard(context, service)),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _servicesProvider = FutureProvider<List<shared.Service>>(
  (ref) => ref.watch(serviceRepositoryProvider).getServices(),
);
