import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';

import 'package:shared/shared.dart' as shared;
import 'package:go_router/go_router.dart';

/// An artificial delay screen to simulate "Loading data" after a successful login.
class PostLoginDelayScreen extends ConsumerStatefulWidget {
  const PostLoginDelayScreen({super.key});

  @override
  ConsumerState<PostLoginDelayScreen> createState() => _PostLoginDelayScreenState();
}

class _PostLoginDelayScreenState extends ConsumerState<PostLoginDelayScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for exactly 3 seconds to simulate data fetching/syncing, 
    // then release the router lock and navigate based on role.
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      ref.read(justLoggedInProvider.notifier).state = false;
      
      final profile = ref.read(userProfileProvider).value;
      if (profile != null && profile.role == shared.UserRole.agent) {
        context.go('/a/home');
      } else {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Loading your dashboard...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Syncing latest requests and data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
