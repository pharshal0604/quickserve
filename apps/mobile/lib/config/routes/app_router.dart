import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'app_routes.dart';

import 'package:quickserve_mobile/features/agent/presentation/screens/agent_shell_screen.dart';
import 'package:quickserve_mobile/features/agent/presentation/screens/agent_home/agent_home_screen.dart';
import 'package:quickserve_mobile/features/agent/presentation/screens/assigned_requests/assigned_requests_screen.dart';
import 'package:quickserve_mobile/features/agent/presentation/screens/history/agent_history_screen.dart';
import 'package:quickserve_mobile/features/requests/presentation/screens/create_request_screen.dart';
import 'package:quickserve_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:quickserve_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:quickserve_mobile/features/requests/presentation/screens/my_requests_screen.dart';
import 'package:quickserve_mobile/features/profile/presentation/screens/agent_profile_screen.dart';
import 'package:quickserve_mobile/features/profile/presentation/screens/notifications_screen.dart';
import 'package:quickserve_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:quickserve_mobile/features/profile/presentation/screens/saved_addresses_screen.dart';

import 'package:quickserve_mobile/features/profile/presentation/screens/settings_screen.dart';
import 'package:quickserve_mobile/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:quickserve_mobile/features/profile/presentation/screens/authorized_devices_screen.dart';
import 'package:quickserve_mobile/features/requests/presentation/screens/request_details_screen.dart';
import 'package:quickserve_mobile/features/services/presentation/screens/services_screen.dart';
import 'package:quickserve_mobile/features/auth/presentation/screens/password_reset_screen.dart';
import 'package:quickserve_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:quickserve_mobile/features/requests/presentation/screens/request_success_screen.dart';
import 'package:quickserve_mobile/features/services/presentation/screens/service_details_screen.dart';
import 'package:quickserve_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';

final class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<fb.User?>>(authStateProvider, (_, _) {
      notifyListeners();
    });
    ref.listen<bool>(registrationInProgressProvider, (_, _) {
      notifyListeners();
    });
    ref.listen<AsyncValue<shared.User?>>(userProfileProvider, (_, _) {
      notifyListeners();
    });
    ref.onDispose(dispose);
  }
}

/// Provides the application router for the Phase 5a authentication flow.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.agentLogin,
        builder: (context, state) => const LoginScreen(isAgentLogin: true),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (context, state) => ServiceDetailsScreen(
          service: shared.Service(
            name: state.uri.queryParameters['name'] ?? '',
            description: state.uri.queryParameters['desc'] ?? '',
            active: true,
            createdAt: DateTime.now(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedAddresses,
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: AppRoutes.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.authorizedDevices,
        builder: (context, state) => const AuthorizedDevicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.requests,
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRequest,
        builder: (context, state) => CreateRequestScreen(
          initialService: state.uri.queryParameters['service'],
        ),
      ),
      GoRoute(
        path: '/request-success/:requestId',
        builder: (context, state) =>
            RequestSuccessScreen(requestId: state.pathParameters['requestId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AgentShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/home',
                builder: (context, state) => const AgentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/requests',
                builder: (context, state) => const AgentRequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/history',
                builder: (context, state) => const AgentHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/agents/:agentId',
        builder: (context, state) => AgentProfileScreen(
          agentId: state.pathParameters['agentId']!,
        ),
      ),
      GoRoute(
        path: '/requests/:requestId',
        builder: (context, state) =>
            RequestDetailsScreen(requestId: state.pathParameters['requestId']!),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final registering = ref.read(registrationInProgressProvider);
      final path = state.uri.path;

      if (authState.isLoading) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = authState.value;
      if (user == null) {
        return AppRoutes.publicPaths.contains(path) ? null : AppRoutes.splash;
      }

      if (registering && path == AppRoutes.register) return null;

      if (AppRoutes.publicPaths.contains(path)) return AppRoutes.home;

      final profileState = ref.read(userProfileProvider);
      
      // If we are authenticated but profile is still loading, wait on splash
      if (profileState.isLoading && !AppRoutes.publicPaths.contains(path) && path != AppRoutes.splash) {
        return AppRoutes.splash;
      }

      final userProfile = profileState.value;
      if (userProfile != null) {
        if (userProfile.role == shared.UserRole.agent) {
          if (path == AppRoutes.home) return '/a/home';
          if (path == AppRoutes.agentRequests) return '/a/requests';
          if (path == AppRoutes.agentHistory) return '/a/history';
          if (path == AppRoutes.profile) return '/a/profile';

          if (path.startsWith(AppRoutes.createRequest) ||
              path.startsWith(AppRoutes.services)) {
            return '/a/home';
          }
        } else if (userProfile.role == shared.UserRole.customer) {
          if (path.startsWith('/agent/') || path.startsWith('/a/')) {
            return AppRoutes.home;
          }
        }
      }

      return null;
    },
  );
});
