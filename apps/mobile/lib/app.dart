import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickserve_mobile/config/routes/app_router.dart';
import 'package:quickserve_mobile/config/theme/app_theme.dart';
import 'package:quickserve_mobile/config/theme/theme_provider.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/core/services/push_notification_service.dart';

/// Global key to show SnackBars across the app
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The root application widget for QuickServe mobile.
class QuickServeApp extends ConsumerWidget {
  /// Creates the root application widget.
  const QuickServeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize FCM token only AFTER profile is successfully loaded/created
    // This prevents a Firestore offline-cache race condition where FCM writes
    // create a malformed local document before the registration flow finishes.
    ref.listen(userProfileProvider, (previous, next) {
      final profile = next.value;
      final user = ref.read(authStateProvider).value;
      if (profile != null && user != null) {
        ref.read(pushNotificationServiceProvider).initialize(user.uid);
      }
    });

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'QuickServe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.5,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
