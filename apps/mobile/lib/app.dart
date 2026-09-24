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
    // Initialize or remove FCM token based on auth state
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(pushNotificationServiceProvider).initialize(user.uid);
      } else if (previous?.value != null) {
        ref
            .read(pushNotificationServiceProvider)
            .removeToken(previous!.value!.uid);
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
