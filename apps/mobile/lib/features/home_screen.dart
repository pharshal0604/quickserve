import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            shared.UserRole.customer => _GreetingView(
              text: 'Hello, ${user.name} (customer)',
            ),
            shared.UserRole.agent => _GreetingView(
              text: 'Hello, ${user.name} (agent)',
            ),
            shared.UserRole.admin => _AdminView(onSignOut: () => _signOut(ref)),
          };
        },
      ),
    );
  }
}

class _GreetingView extends StatelessWidget {
  const _GreetingView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
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
