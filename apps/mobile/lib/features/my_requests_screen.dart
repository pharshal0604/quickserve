import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';

/// Lists requests owned by the signed-in Customer.
class MyRequestsScreen extends ConsumerWidget {
  /// Creates the screen.
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }
    final requests = ref.watch(_customerRequestsProvider(user.uid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(_customerRequestsProvider(user.uid)),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _RequestMessage(
          message: 'Could not load your requests.',
          action: TextButton(
            onPressed: () =>
                ref.invalidate(_customerRequestsProvider(user.uid)),
            child: const Text('Retry'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _RequestMessage(
              message: 'You have not created any requests yet.',
              action: FilledButton(
                onPressed: () => context.push('/requests/create'),
                child: const Text('Create Request'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final request = item.request;
              return Card(
                child: ListTile(
                  title: Text(request.requestCode),
                  subtitle: Text(
                    '${request.serviceType}\n${request.status.toStoredValue()} · ${request.priority.toStoredValue()}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/requests/${item.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _customerRequestsProvider =
    FutureProvider.family<List<({String id, shared.Request request})>, String>((
      ref,
      uid,
    ) async {
      await ref.watch(authStateProvider.future);
      return ref
          .watch(requestRepositoryProvider)
          .watchCustomerRequests(uid)
          .first;
    });

class _RequestMessage extends StatelessWidget {
  const _RequestMessage({required this.message, this.action});

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
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
