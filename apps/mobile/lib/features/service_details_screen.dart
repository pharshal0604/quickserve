import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'quickserve_widgets.dart';

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({super.key, required this.service});
  final shared.Service service;

  IconData get _icon {
    final value = service.name.toLowerCase();
    if (value.contains('ac') || value.contains('air')) return Icons.ac_unit;
    if (value.contains('plumb')) return Icons.plumbing_outlined;
    if (value.contains('electric')) return Icons.electrical_services_outlined;
    if (value.contains('clean')) return Icons.cleaning_services_outlined;
    return Icons.home_repair_service_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        centerTitle: true,
        title: const Text('Service Details'),
        actions: [
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                Center(child: Icon(_icon, color: AppColors.primary, size: 92)),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: .9),
                    child: const Icon(
                      Icons.favorite_border,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Active service',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  service.description,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _FactCard(
                        icon: Icons.verified_outlined,
                        title: 'Available',
                        value: 'Active in catalog',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _FactCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Request flow',
                        value: 'Track in app',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'About this service'),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose this service to tell QuickServe what you need, select a preferred time, and share the service address. Your request status will remain visible in My Requests.',
                  style: TextStyle(color: AppColors.mutedText, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/requests/create', extra: service.name),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book Service Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
