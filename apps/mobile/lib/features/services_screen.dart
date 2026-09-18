import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';

/// Displays active QuickServe services.
class ServicesScreen extends ConsumerWidget {
  /// Creates the Services screen.
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(_servicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: services.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _MessageState(
          message: 'Could not load services.',
          action: TextButton(
            onPressed: () => ref.invalidate(_servicesProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _MessageState(
              message: 'No active services are available.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final service = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  title: Text(service.name),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(service.description),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () =>
                      context.push('/requests/create', extra: service.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _servicesProvider = FutureProvider<List<shared.Service>>((ref) {
  return ref.watch(serviceRepositoryProvider).getServices();
});

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            ?action,
          ],
        ),
      ),
    );
  }
}
