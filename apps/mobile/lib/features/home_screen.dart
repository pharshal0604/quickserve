import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';

/// Displays the role-aware QuickServe home stub.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  Future<void> _signOut(WidgetRef ref) {
    return ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickServe'),
        actions: [
          IconButton(
            onPressed: () => _signOut(ref),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ProfileErrorView(
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            return _MissingProfileView(onSignOut: () => _signOut(ref));
          }

          return switch (user.role) {
            shared.UserRole.customer => _CustomerHomeView(name: user.name),
            shared.UserRole.agent => _AgentHomeView(name: user.name),
            shared.UserRole.admin => _AdminView(onSignOut: () => _signOut(ref)),
          };
        },
      ),
    );
  }
}

class _CustomerHomeView extends StatelessWidget {
  const _CustomerHomeView({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Hello, $name', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        const Text('What service do you need today?'),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => context.push('/requests/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create Request'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.push('/services'),
          icon: const Icon(Icons.home_repair_service_outlined),
          label: const Text('Browse Services'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.push('/requests'),
          icon: const Icon(Icons.list_alt_outlined),
          label: const Text('My Requests'),
        ),
      ],
    );
  }
}

class _AgentHomeView extends StatelessWidget {
  const _AgentHomeView({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Hello, $name', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        const Text('Review the requests assigned to you.'),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => context.push('/agent/requests'),
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Assigned Requests'),
        ),
      ],
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load your profile.'),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MissingProfileView extends StatelessWidget {
  const _MissingProfileView({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your account profile is not available. Please contact support.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Admin accounts use the web portal.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}
