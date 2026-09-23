import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart' hide User;

import '../../../main.dart';
import '../../../injection_container.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/email_verification_page.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/requests/presentation/screens/requests_screen.dart';
import '../../features/requests/presentation/screens/request_details_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/customers/presentation/screens/person_details_screen.dart';
import '../../features/agents/presentation/screens/agents_screen.dart';
import '../../features/agents/presentation/screens/agent_details_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/activity/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

final userProfileProvider = StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, uid) {
  return ref.read(firebaseFirestoreProvider).collection(CollectionNames.users).doc(uid).snapshots();
});

class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Administrator access required'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(firebaseAuthProvider).signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      
      final isLoggingIn = state.uri.path == '/login';
      final isVerifying = state.uri.path == '/verify-email';
//       final isDenied = state.uri.path == '/access-denied';
      
      if (authState.isLoading) return null;

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (!user.emailVerified) {
        return isVerifying ? null : '/verify-email';
      }

      // We cannot await inside sync redirect easily without a Listenable,
      // but we will handle the admin check via a route or shell.
      // Wait, let's just let the access-denied check happen at the shell level 
      // or we can use the provider.

      if (isLoggingIn || isVerifying) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final user = ref.read(firebaseAuthProvider).currentUser!;
          return EmailVerificationPage(user: user);
        },
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final user = ref.read(firebaseAuthProvider).currentUser;
          if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          
          final profileAsync = ref.watch(userProfileProvider(user.uid));
          return profileAsync.when(
            data: (profile) {
              final role = profile.data()?['role'];
              if (role != RoleNames.admin) {
                return const AccessDeniedScreen();
              }
              // Wait, AdminShell might not need user, we'll see
              return AdminShell(
                navigationShell: navigationShell,
              );
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, _) => const Scaffold(body: Center(child: Text('Error loading profile'))),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) => const RequestsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => RequestDetailsScreen(requestId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PersonDetailsScreen(customerId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agents',
                builder: (context, state) => const AgentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => AgentDetailsScreen(agentId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                builder: (context, state) => const ServicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const ActivityScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
