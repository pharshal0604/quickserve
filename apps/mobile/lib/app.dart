import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickserve_mobile/config/routes/app_router.dart';
import 'package:quickserve_mobile/config/theme/app_theme.dart';

/// The root application widget for QuickServe mobile.
class QuickServeApp extends ConsumerWidget {
  /// Creates the root application widget.
  const QuickServeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'QuickServe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.5,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
