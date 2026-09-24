import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quickserve_mobile/config/routes/app_routes.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_shadows.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';

/// The pale branded header used by the authentication and onboarding pages.
class QuickServeBrandHeader extends StatelessWidget {
  const QuickServeBrandHeader({
    super.key,
    this.eyebrow = 'QuickServe',
    this.subtitle = 'Reliable help, right when you need it.',
    this.compact = false,
  });

  final String eyebrow;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        compact ? AppSpacing.lg : 36,
        AppSpacing.xl,
        compact ? AppSpacing.lg : 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: 0,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.gold.withValues(alpha: .75),
              size: 28,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(
              Icons.business_center_outlined,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .22),
              size: 28,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 52 : 64,
                  height: compact ? 52 : 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.raised,
                  ),
                  child: Icon(
                    Icons.home_repair_service_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -.5,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A consistent field style for the rounded reference screens.
InputDecoration quickServeInputDecoration(
  String label, {
  IconData? icon,
  Widget? suffix,
  String? prefixText,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    prefixText: prefixText,
    filled: true,
  );
}

/// Makes Android/system back from a root section return to the Home dashboard.
///
/// Root sections are reached through navigation-bar or profile navigation and
/// are intentionally not part of the nested detail back stack.
class HomeBackScope extends StatelessWidget {
  const HomeBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: child,
    );
  }
}

/// Bottom navigation shared by customer-facing screens.
class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final paths = [AppRoutes.home, AppRoutes.services, AppRoutes.requests, AppRoutes.profile];
        context.go(paths[index]);
      },
      indicatorColor: AppColors.mintSurface,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
