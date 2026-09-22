import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

/// The unauthenticated QuickServe welcome/onboarding page.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const QuickServeBrandHeader(
              eyebrow: 'QuickServe',
              subtitle: 'Reliable help, right when you need it.',
              compact: true,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Home help made simple',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Book trusted local professionals, follow every update, and get back to your day.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppColors.mutedText, height: 1.45),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('User Login'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/agent-login'),
                      icon: const Icon(Icons.engineering_outlined),
                      label: const Text('Agent Login'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'Fast. Clear. Dependable.',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.mutedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
