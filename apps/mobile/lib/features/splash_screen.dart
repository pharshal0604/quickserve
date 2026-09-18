import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Displays the initial QuickServe authentication loading state.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text('QuickServe', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
