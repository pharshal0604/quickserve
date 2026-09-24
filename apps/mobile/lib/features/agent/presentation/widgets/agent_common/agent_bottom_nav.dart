import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quickserve_mobile/config/routes/app_routes.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';

/// Root navigation for the agent experience.
class AgentBottomNav extends StatelessWidget {
  const AgentBottomNav({
    super.key,
    required this.currentIndex,
    this.showSelection = true,
  });

  final int currentIndex;
  final bool showSelection;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        const paths = [
          AppRoutes.home,
          AppRoutes.agentRequests,
          AppRoutes.agentHistory,
          AppRoutes.profile,
        ];
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
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
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
