import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';
import '../utils/app_exceptions.dart';
import '../utils/app_snackbar.dart';

/// Displays a request, its history, and role-appropriate lifecycle actions.
class RequestDetailsScreen extends ConsumerStatefulWidget {
  /// Creates the details screen.
  const RequestDetailsScreen({super.key, required this.requestId});

  /// The Firestore request document ID.
  final String requestId;

  @override
  ConsumerState<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(_requestProvider(widget.requestId));
    final profile = ref.watch(userProfileProvider).value;
    final isAgent = profile?.role.toStoredValue() == shared.RoleNames.agent;
    final isCustomer =
        profile?.role.toStoredValue() == shared.RoleNames.customer;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: request.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const _Message('Could not load this request.'),
        data: (item) {
          if (item == null) {
            return const _Message('This request is unavailable.');
          }
          final history = ref.watch(_historyProvider(widget.requestId));
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
              if (item.agentId != null)
                _DetailRow(label: 'Assigned Agent', value: item.agentId!),
              if (item.cancellationReason != null)
                _DetailRow(
                  label: 'Cancellation reason',
                  value: item.cancellationReason!,
                ),
              if (isAgent) ...[
                const SizedBox(height: AppSpacing.lg),
                _AgentActions(
                  request: item,
                  busy: _busy,
                  onAccept: () => _runAgentAction(
                    () => ref
                        .read(agentRepositoryProvider)
                        .acceptAssignedRequest(
                          requestId: widget.requestId,
                          agentId: _currentUserId,
                        ),
                  ),
                  onStart: () => _runAgentAction(
                    () => ref
                        .read(agentRepositoryProvider)
                        .startRequest(
                          requestId: widget.requestId,
                          agentId: _currentUserId,
                        ),
                  ),
                  onComplete: () => _completeRequest(widget.requestId),
                ),
              ],
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
                          final transition = entry.fromStatus == null
                              ? entry.toStatus
                              : '${entry.fromStatus} → ${entry.toStatus}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.radio_button_checked),
                            title: Text(transition),
                            subtitle: Text(entry.note ?? 'Status updated.'),
                          );
                        }).toList(),
                      ),
              ),
              if (isCustomer &&
                  shared.isCancellableByCustomer(
                    item.status.toStoredValue(),
                  )) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _cancel,
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

  String get _currentUserId => ref.read(authStateProvider).value!.uid;

  Future<void> _runAgentAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _refreshDetails();
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Request status updated.');
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.userMessage
          : 'The request could not be updated.';
      AppSnackBar.show(context, message: message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeRequest(String requestId) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete request'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Completion note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep in progress'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || note == null) return;
    await _runAgentAction(
      () => ref
          .read(agentRepositoryProvider)
          .completeRequest(
            requestId: requestId,
            agentId: _currentUserId,
            note: note,
          ),
    );
  }

  Future<void> _cancel() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel request?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
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
    if (!mounted || reason == null || reason.isEmpty) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(requestRepositoryProvider)
          .cancelRequest(
            requestId: widget.requestId,
            reason: reason,
            customerId: user.uid,
          );
      _refreshDetails();
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Request cancelled.');
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.userMessage
          : 'The request could not be cancelled.';
      AppSnackBar.show(context, message: message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refreshDetails() {
    ref.invalidate(_requestProvider(widget.requestId));
    ref.invalidate(_historyProvider(widget.requestId));
  }
}

final _requestProvider = FutureProvider.family<shared.Request?, String>((
  ref,
  requestId,
) {
  return ref.watch(requestRepositoryProvider).getRequest(requestId);
});

final _historyProvider =
    StreamProvider.family<List<shared.StatusHistory>, String>((ref, requestId) {
      return ref.watch(requestRepositoryProvider).watchHistory(requestId);
    });

class _AgentActions extends StatelessWidget {
  const _AgentActions({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onStart,
    required this.onComplete,
  });

  final shared.Request request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final status = request.status.toStoredValue();
    if (status == shared.StatusNames.assigned) {
      return FilledButton.icon(
        onPressed: busy ? null : onAccept,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Accept request'),
      );
    }
    if (status == shared.StatusNames.accepted) {
      return FilledButton.icon(
        onPressed: busy ? null : onStart,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start work'),
      );
    }
    if (status == shared.StatusNames.inProgress) {
      return FilledButton.icon(
        onPressed: busy ? null : onComplete,
        icon: const Icon(Icons.task_alt),
        label: const Text('Complete request'),
      );
    }
    if (shared.isTerminalStatus(status)) {
      return Text(
        'This request is ${status == shared.StatusNames.completed ? 'completed' : 'cancelled'}.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return const SizedBox.shrink();
  }
}

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
