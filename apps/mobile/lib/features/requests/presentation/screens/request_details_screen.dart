import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';
import 'package:quickserve_mobile/core/error/app_exceptions.dart';
import 'package:quickserve_mobile/core/utils/app_snackbar.dart';

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

    if (widget.requestId.isEmpty ||
        RegExp(r'[^a-zA-Z0-9_-]').hasMatch(widget.requestId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: Text('Invalid request ID format.')),
      );
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text('Request Details'),
        ),
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
                  item.serviceType,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.lg),
                _RequestStatusTimeline(
                  currentStatus: item.status.toStoredValue(),
                  priority: item.priority.toStoredValue(),
                  history: history.valueOrNull ?? const [],
                ),
                const SizedBox(height: AppSpacing.lg),
                _BookingInformation(request: item),
                if (item.agentId != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AssignedTechnician(
                    name: item.agentName,
                    phone: item.agentPhone,
                    onTap: () => context.push(
                      Uri(
                        path: '/agents/${item.agentId!}',
                        queryParameters: {
                          if (item.agentName != null) 'name': item.agentName,
                          if (item.agentPhone != null) 'phone': item.agentPhone,
                        },
                      ).toString(),
                    ),
                  ),
                ],
                if (item.cancellationReason != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(
                    label: 'Cancellation reason',
                    value: item.cancellationReason!,
                  ),
                ],
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
                if (isCustomer &&
                    shared.isCancellableByCustomer(
                      item.status.toStoredValue(),
                    )) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: Theme.of(context).filledButtonTheme.style
                          ?.copyWith(
                            backgroundColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.error,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.onError,
                            ),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                      onPressed: _busy ? null : _cancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Request'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
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
    // Delay disposal until dialog animation finishes to prevent ANR freeze
    Future.delayed(
      const Duration(milliseconds: 300),
      () => controller.dispose(),
    );

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

    // Delay disposal until dialog animation finishes to prevent ANR freeze
    Future.delayed(
      const Duration(milliseconds: 300),
      () => controller.dispose(),
    );

    if (reason == null) {
      return;
    }
    if (!mounted) return;
    final normalizedReason = shared.sanitizeRequestText(reason);
    final reasonResult = shared.validateCancellationReason(normalizedReason);
    if (!reasonResult.isValid) {
      AppSnackBar.show(context, message: reasonResult.reason!);
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(requestRepositoryProvider)
          .cancelRequest(
            requestId: widget.requestId,
            reason: normalizedReason,
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
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(_requestProvider(widget.requestId));
      ref.invalidate(_historyProvider(widget.requestId));
    });
  }
}

final _requestProvider = StreamProvider.family<shared.Request?, String>((
  ref,
  requestId,
) {
  return ref.watch(requestRepositoryProvider).watchRequest(requestId);
});

final _historyProvider =
    StreamProvider.family<List<shared.StatusHistory>, String>((ref, requestId) {
      return ref.watch(requestRepositoryProvider).watchHistory(requestId);
    });

String _statusLabel(String value) {
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

Color _statusColor(String status) {
  if (status == shared.StatusNames.completed) {
    return AppColors.statusCompleted;
  }
  if (status == shared.StatusNames.cancelled) {
    return AppColors.statusCancelled;
  }
  if (status == shared.StatusNames.inProgress) {
    return AppColors.statusProgress;
  }
  if (status == shared.StatusNames.assigned) {
    return AppColors.statusAssigned;
  }
  if (status == shared.StatusNames.accepted) {
    return AppColors.statusAccepted;
  }
  return AppColors.statusCreated;
}

class _RequestStatusTimeline extends StatelessWidget {
  const _RequestStatusTimeline({
    required this.currentStatus,
    required this.priority,
    required this.history,
  });

  final String currentStatus;
  final String priority;
  final List<shared.StatusHistory> history;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        status: shared.StatusNames.created,
        label: 'Created',
        description: 'Request submitted by customer',
      ),
      (
        status: shared.StatusNames.assigned,
        label: 'Assigned',
        description: 'Technician assigned by admin',
      ),
      (
        status: shared.StatusNames.accepted,
        label: 'Accepted',
        description: 'Technician confirmed dispatch',
      ),
      (
        status: shared.StatusNames.inProgress,
        label: 'In Progress',
        description: 'Work is actively underway',
      ),
      (
        status: shared.StatusNames.completed,
        label: 'Completed',
        description: 'Job successfully resolved',
      ),
    ];
    final reached = {...history.map((entry) => entry.toStatus), currentStatus};
    final currentIndex = steps.indexWhere(
      (step) => step.status == currentStatus,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Status Timeline',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                StatusPill(
                  label: _statusLabel(currentStatus),
                  color: _statusColor(currentStatus),
                ),
                const SizedBox(width: AppSpacing.sm),
                Chip(
                  label: Text(_statusLabel(priority)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < steps.length; index++)
              _TimelineStep(
                label: steps[index].label,
                description: steps[index].description,
                status: steps[index].status,
                isCurrent: steps[index].status == currentStatus,
                isReached:
                    reached.contains(steps[index].status) ||
                    (currentIndex >= 0 && index <= currentIndex),
                isLast:
                    index == steps.length - 1 &&
                    currentStatus != shared.StatusNames.cancelled,
              ),
            if (currentStatus == shared.StatusNames.cancelled)
              _TimelineStep(
                label: 'Cancelled',
                description: 'Request was cancelled',
                status: shared.StatusNames.cancelled,
                isCurrent: true,
                isReached: true,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.description,
    required this.status,
    required this.isCurrent,
    required this.isReached,
    required this.isLast,
  });

  final String label;
  final String description;
  final String status;
  final bool isCurrent;
  final bool isReached;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? _statusColor(status)
        : isReached
        ? AppColors.success
        : AppColors.outline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReached
                        ? color
                        : Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isReached
                      ? Icon(
                          isCurrent ? Icons.radio_button_checked : Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isReached ? AppColors.success : AppColors.outline,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isReached
                                ? (isCurrent
                                      ? color
                                      : Theme.of(context).colorScheme.onSurface)
                                : AppColors.mutedText,
                            fontSize: 17,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isCurrent) StatusPill(label: 'ACTIVE', color: color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isReached
                          ? AppColors.mutedText
                          : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingInformation extends StatelessWidget {
  const _BookingInformation({required this.request});

  final shared.Request request;

  @override
  Widget build(BuildContext context) {
    final date = request.preferredDateTime;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Information',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoRow(
              icon: Icons.build_outlined,
              label: 'Service Type',
              value: request.serviceType,
            ),
            _InfoRow(
              icon: Icons.description_outlined,
              label: 'Description',
              value: request.description,
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Scheduled Date',
              value: MaterialLocalizations.of(context).formatFullDate(date),
            ),
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Scheduled Time',
              value: TimeOfDay.fromDateTime(date).format(context),
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Service Address',
              value: request.address,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mutedText, size: 27),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedTechnician extends StatelessWidget {
  const _AssignedTechnician({
    required this.name,
    required this.phone,
    required this.onTap,
  });

  final String? name;
  final String? phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : 'Technician contact unavailable';
    final hasSnapshot =
        (name?.trim().isNotEmpty ?? false) ||
        (phone?.trim().isNotEmpty ?? false);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Field Technician',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            _TechnicianIdentity(
              name: displayName,
              subtitle: hasSnapshot
                  ? 'Tap to view contact details'
                  : 'Contact details unavailable for this request',
              onTap: hasSnapshot ? onTap : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianIdentity extends StatelessWidget {
  const _TechnicianIdentity({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                color: AppColors.statusAssigned,
                size: 34,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'View contact details',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

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
