import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';

/// Displays a request and its append-only status history.
class RequestDetailsScreen extends ConsumerWidget {
  /// Creates the details screen.
  const RequestDetailsScreen({super.key, required this.requestId});

  /// The Firestore request document ID.
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(_requestProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: request.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _Message('Could not load this request.'),
        data: (item) {
          if (item == null) {
            return const _Message('This request is unavailable.');
          }
          final history = ref.watch(_historyProvider(requestId));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                item.requestCode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.serviceType,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  Chip(label: Text(item.status.toStoredValue())),
                  Chip(label: Text(item.priority.toStoredValue())),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              _DetailRow(label: 'Description', value: item.description),
              _DetailRow(label: 'Address', value: item.address),
              _DetailRow(
                label: 'Preferred date',
                value: MaterialLocalizations.of(context)
                    .formatFullDate(item.preferredDateTime.toDate()),
              ),
              if (item.cancellationReason != null)
                _DetailRow(
                  label: 'Cancellation reason',
                  value: item.cancellationReason!,
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Status history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              history.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) =>
                    const Text('History is unavailable.'),
                data: (items) => items.isEmpty
                    ? const Text('No history is available.')
                    : Column(
                        children: items.map((entry) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.radio_button_checked),
                            title: Text(entry.toStatus),
                            subtitle: Text(entry.note ?? 'Status updated.'),
                          );
                        }).toList(),
                      ),
              ),
              if (shared.isCancellableByCustomer(
                item.status.toStoredValue(),
              )) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => _cancel(context, ref, item),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel request'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    shared.Request request,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel request?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted || reason == null || reason.isEmpty) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    try {
      await ref
          .read(requestRepositoryProvider)
          .cancelRequest(
            requestId: requestId,
            reason: reason,
            customerId: user.uid,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request cancelled.')));
      ref.invalidate(_requestProvider(requestId));
      ref.invalidate(_historyProvider(requestId));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The request could not be cancelled.')),
      );
    }
  }
}

final _requestProvider = FutureProvider.family<shared.Request?, String>((
  ref,
  requestId,
) {
  return ref.watch(requestRepositoryProvider).getRequest(requestId);
});

final _historyProvider =
    FutureProvider.family<List<shared.StatusHistory>, String>((ref, requestId) {
      return ref.watch(requestRepositoryProvider).watchHistory(requestId).first;
    });

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(value),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}
