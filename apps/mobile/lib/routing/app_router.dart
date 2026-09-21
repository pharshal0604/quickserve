import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../features/agent_requests_screen.dart';
import '../features/create_request_screen.dart';
import '../features/home_screen.dart';
import '../features/login_screen.dart';
import '../features/my_requests_screen.dart';
import '../features/notifications_screen.dart';
import '../features/profile_screen.dart';
import '../features/request_details_screen.dart';
import '../features/settings_screen.dart';
import '../features/services_screen.dart';
import '../features/password_reset_screen.dart';
import '../features/register_screen.dart';
import '../features/request_success_screen.dart';
import '../features/service_details_screen.dart';
import '../features/splash_screen.dart';
import '../state/auth_providers.dart';

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
        builder: (context, state) =>
            ServiceDetailsScreen(service: state.extra as shared.Service),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: '/requests/create',
        builder: (context, state) =>
            CreateRequestScreen(initialService: state.extra as String?),
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
        const publicPaths = {'/login', '/register', '/password-reset'};
        return publicPaths.contains(path) ? null : '/login';
      }

      if (registering && path == '/register') return null;

      const authPaths = {'/splash', '/login', '/register', '/password-reset'};
      if (authPaths.contains(path)) return '/home';
      return null;
    },
  );
});
