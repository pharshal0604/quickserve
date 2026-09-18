import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home_screen.dart';
import '../features/login_screen.dart';
import '../features/splash_screen.dart';
import '../state/auth_providers.dart';

final class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<fb.User?>>(authStateProvider, (_, _) {
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
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final path = state.uri.path;

      if (authState.isLoading) {
        return path == '/splash' ? null : '/splash';
      }

      if (authState.hasError) {
        return path == '/login' ? null : '/login';
      }

      final user = authState.value;
      if (user == null) {
        return path == '/login' ? null : '/login';
      }

      if (path == '/splash' || path == '/login') return '/home';
      return null;
    },
  );
});
