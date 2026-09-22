import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

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
    ref.onDispose(dispose);
  }
}

/// Provides the application router for the Phase 5a authentication flow.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/agent-login',
        builder: (context, state) => const LoginScreen(isAgentLogin: true),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: '/services/detail',
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
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/saved-addresses',
        builder: (context, state) => const SavedAddressesScreen(),
      ),

      GoRoute(
        path: '/security-settings',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/authorized-devices',
        builder: (context, state) => const AuthorizedDevicesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: '/requests/create',
        builder: (context, state) => CreateRequestScreen(
          initialService: state.uri.queryParameters['service'],
        ),
      ),
      GoRoute(
        path: '/request-success/:requestId',
        builder: (context, state) =>
            RequestSuccessScreen(requestId: state.pathParameters['requestId']!),
      ),
      GoRoute(
        path: '/agent/requests',
        builder: (context, state) => const AgentRequestsScreen(),
      ),
      GoRoute(
        path: '/agent/history',
        builder: (context, state) => const AgentHistoryScreen(),
      ),
      GoRoute(
        path: '/agents/:agentId',
        builder: (context, state) => AgentProfileScreen(
          snapshot: AgentContactSnapshot(
            name: state.uri.queryParameters['name'],
            phone: state.uri.queryParameters['phone'],
          ),
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
        return path == '/splash' ? null : '/splash';
      }

      final user = authState.value;
      if (user == null) {
        const publicPaths = {
          '/splash',
          '/login',
          '/agent-login',
          '/register',
          '/password-reset',
        };
        return publicPaths.contains(path) ? null : '/splash';
      }

      if (registering && path == '/register') return null;

      const authPaths = {
        '/splash',
        '/login',
        '/agent-login',
        '/register',
        '/password-reset',
      };

      if (authPaths.contains(path)) return '/home';

      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile != null) {
        if (userProfile.role == shared.UserRole.agent) {
          if (path.startsWith('/create-request') ||
              path.startsWith('/services')) {
            return '/home';
          }
        } else if (userProfile.role == shared.UserRole.customer) {
          if (path.startsWith('/agent')) {
            return '/home';
          }
        }
      }

      return null;
    },
  );
});
