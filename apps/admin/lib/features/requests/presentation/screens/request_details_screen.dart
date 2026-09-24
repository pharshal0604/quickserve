import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/shared/admin_formatters.dart';
import 'package:quickserve_admin/injection_container.dart';

class RequestDetailsScreen extends ConsumerStatefulWidget {
  const RequestDetailsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> {
  String? status;
  String? agentId;
  bool saving = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<({String id, RequestEntity request})>>(
      stream: ref.watch(watchRequestsProvider).call(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final docIndex = snapshot.data!.indexWhere(
          (doc) => doc.id == widget.requestId,
        );
        if (docIndex == -1) {
          return const Scaffold(body: Center(child: Text('Request not found')));
        }

        final doc = snapshot.data![docIndex];
        final request = doc.request;
        final String currentStatus = status ?? request.status.toStoredValue();
        final currentAgentId = agentId ?? request.agentId;

        final code = request.requestCode;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: _RequestHeader(
              code: code,
              status: currentStatus,
              request: request,
              onBack: () => Navigator.of(context).pop(),
              onStatusTap: () => _showStatusPicker(currentStatus),
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Request actions',
                onSelected: (value) {
                  if (value == 'status') _showStatusPicker(currentStatus);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'status', child: Text('Update status')),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: constraints.maxWidth >= 980
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _mainColumn(context, request)),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 330,
                          child: _sideColumn(
                            context,
                            request,
                            currentStatus,
                            currentAgentId,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _mainColumn(context, request),
                        const SizedBox(height: 16),
                        _sideColumn(
                          context,
                          request,
                          currentStatus,
                          currentAgentId,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _mainColumn(BuildContext context, RequestEntity request) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ServiceOverviewCard(request: request),
      const SizedBox(height: 16),
      _TimelineCard(requestId: widget.requestId),
    ],
  );

  Widget _sideColumn(
    BuildContext context,
    RequestEntity request,
    String currentStatus,
    String? currentAgentId,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _CustomerInformationCard(userId: request.customerId),
      const SizedBox(height: 16),
      _AgentInformationCard(
        userId: currentAgentId,
        assignedAt: request.updatedAt,
        enabled: currentStatus == StatusNames.created && !saving,
        onReassign: () => _showAgentPicker(currentStatus),
        onContact: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent contact actions are not connected yet.'),
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 12),
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );

  Future<void> _showStatusPicker(String currentStatus) async {
    final options = [
      currentStatus,
      ...StatusNames.values.where(
        (value) =>
            value != currentStatus && canTransition(currentStatus, value),
      ),
    ];
    final next = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Update request status')),
            for (final value in options)
              ListTile(
                leading: Icon(
                  adminStatusIcon(value),
                  color: adminStatusColor(context, value),
                ),
                title: Text(adminLabel(value)),
                trailing: value == currentStatus
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (next != null && mounted) {
      await ref.read(updateRequestStatusProvider).call(widget.requestId, next);
      if (mounted) setState(() => status = next);
    }
  }

  Future<void> _showAgentPicker(String currentStatus) async {
    if (currentStatus != StatusNames.created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Agent assignment is locked after the request is assigned.',
          ),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.65,
          child: StreamBuilder<List<({String id, UserEntity user})>>(
            stream: ref.watch(watchAgentsProvider).call(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading agents',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              final agents = snapshot.data ?? [];
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Assign Service Agent',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  if (agents.isEmpty)
                    const Expanded(
                      child: Center(child: Text('No service agents found.')),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: agents.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = agents[index];
                          final user = doc.user;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              child: Text(adminInitial(user.name)),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              user.phone,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            onTap: () => Navigator.pop(context, doc.id),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      agentId = selected;
      saving = true;
      error = null;
    });
    try {
      await ref.read(assignRequestProvider).call(widget.requestId, selected);
      if (mounted) setState(() => status = StatusNames.assigned);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({
    required this.code,
    required this.status,
    required this.request,
    required this.onBack,
    required this.onStatusTap,
  });

  final String code;
  final String status;
  final RequestEntity request;
  final VoidCallback onBack;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
      ),
      Text(
        'Request $code',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(width: 10),
      _StatusBadge(status, compact: true),
      const SizedBox(width: 14),
      Flexible(
        child: Text(
          'Placed on ${_date(request.createdAt)} · ${_time(request.preferredDateTime)}',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _ServiceOverviewCard extends StatelessWidget {
  const _ServiceOverviewCard({required this.request});
  final RequestEntity request;

  @override
  Widget build(BuildContext context) {
    const String? imageUrl = null; // No imageUrl in RequestEntity
    final priority = request.priority.name;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = SizedBox(
            width: constraints.maxWidth >= 620 ? 150 : double.infinity,
            height: constraints.maxWidth >= 620 ? 140 : 170,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_repair_service_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        _PriorityBadge(priority),
                      ],
                    ),
                  ),
          );
          final details = Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.serviceType,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Category: ${adminLabel(request.serviceType)}'),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: request.address,
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.notes_outlined,
                  label: 'Customer instructions',
                  value: request.description,
                ),
              ],
            ),
          );
          return constraints.maxWidth >= 620
              ? Row(
                  children: [
                    image,
                    Expanded(child: details),
                  ],
                )
              : Column(children: [image, details]);
        },
      ),
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Timeline',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'A chronological view of status updates and communications.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Full History'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<({String id, StatusHistoryEntity history})>>(
            stream: ref.watch(watchRequestHistoryProvider).call(requestId),
            builder: (context, historySnapshot) {
              final history = historySnapshot.data;
              if ((history ?? []).isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No status history recorded yet.'),
                );
              }
              return StreamBuilder<List<({String id, UserEntity user})>>(
                stream: ref.watch(watchUsersProvider).call(),
                builder: (context, usersSnapshot) {
                  final users = <String, UserEntity>{
                    for (final doc in usersSnapshot.data ?? [])
                      doc.id: doc.user,
                  };
                  return Column(
                    children: [
                      for (
                        var index = 0;
                        index < (history ?? []).length;
                        index++
                      )
                        _TimelineRow(
                          historyEntity: (history ?? [])[index].history,
                          actor: users[(history ?? [])[index].history.changedBy]
                              ?.name,
                          isLast: index == (history ?? []).length - 1,
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Add Internal Note'),
          ),
        ],
      ),
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.historyEntity,
    required this.actor,
    required this.isLast,
  });
  final StatusHistoryEntity historyEntity;
  final String? actor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final toStatus = historyEntity.toStatus;
    final fromStatus = historyEntity.fromStatus;
    final title = fromStatus == null || fromStatus.isEmpty
        ? adminLabel(toStatus)
        : '${adminLabel(fromStatus)} → ${adminLabel(toStatus)}';
    final color = adminStatusColor(context, toStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    adminStatusIcon(toStatus),
                    size: 13,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 42,
                    color: Theme.of(context).dividerColor,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 3,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _timestamp(historyEntity.changedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  historyEntity.note ?? 'Status updated',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'ACTION BY: $actor',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerInformationCard extends ConsumerWidget {
  const _CustomerInformationCard({required this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _UserInformationCard(
    userId: userId,
    title: 'Customer Information',
    icon: Icons.person_outline,
    roleLabel: 'Customer',
    actionLabel: 'View Complete Profile',
    isCustomer: true,
  );
}

class _AgentInformationCard extends ConsumerWidget {
  const _AgentInformationCard({
    required this.userId,
    required this.assignedAt,
    required this.enabled,
    required this.onReassign,
    required this.onContact,
  });
  final String? userId;
  final DateTime? assignedAt;
  final bool enabled;
  final VoidCallback onReassign;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: userId == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Service Agent',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('No service agent assigned.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: enabled ? onReassign : null,
                  child: const Text('Assign Service Agent'),
                ),
              ],
            )
          : FutureBuilder<({String id, UserEntity user})?>(
              future: ref.watch(getAgentDetailsProvider).call(userId!),
              builder: (context, snapshot) {
                final user = snapshot.data?.user;
                final name = user?.name ?? userId!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Assigned Service Agent',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Text(adminInitial(name)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: _RoleBadge(label: 'Service Agent'),
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(
                      icon: Icons.mail_outline,
                      label: 'Email address',
                      value: user?.email ?? 'No email',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: user?.phone ?? 'No phone',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.calendar_today_outlined,
                      label: 'Assigned on',
                      value: _date(assignedAt),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onContact,
                      icon: const Icon(Icons.phone_outlined, size: 15),
                      label: const Text('Contact Agent'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: enabled ? onReassign : null,
                      child: const Text('Reassign Agent'),
                    ),
                  ],
                );
              },
            ),
    ),
  );
}

class _UserInformationCard extends ConsumerWidget {
  const _UserInformationCard({
    required this.userId,
    required this.title,
    required this.icon,
    required this.roleLabel,
    required this.actionLabel,
    this.isCustomer = true,
  });
  final String? userId;
  final String title;
  final IconData icon;
  final String roleLabel;
  final String actionLabel;
  final bool isCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: userId == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('No profile assigned.'),
              ],
            )
          : FutureBuilder<({String id, UserEntity user})?>(
              future: isCustomer
                  ? ref.watch(getCustomerDetailsProvider).call(userId!)
                  : ref.watch(getAgentDetailsProvider).call(userId!),
              builder: (context, snapshot) {
                final user = snapshot.data?.user;
                final name = user?.name ?? userId!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Text(adminInitial(name)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RoleBadge(label: roleLabel),
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(
                      icon: Icons.mail_outline,
                      label: 'Email address',
                      value: user?.email ?? 'No email',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: user?.phone ?? 'No phone',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member since',
                      value: _date(user?.createdAt),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(onPressed: null, child: Text(actionLabel)),
                  ],
                );
              },
            ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 15,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 2),
            Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onTertiaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge(this.priority);
  final String priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = priority == 'high' ? scheme.error : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${adminLabel(priority)} priority'.toUpperCase(),
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status, {this.compact = false});
  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = adminStatusColor(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        adminLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : 12,
        ),
      ),
    );
  }
}

String _date(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    return '${_month(date.month)} ${date.day}, ${date.year}';
  }
  return '—';
}

String _time(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
  return 'Time not scheduled';
}

String _timestamp(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate().toLocal();
    return '${_month(date.month)} ${date.day}, ${date.year} · ${_time(value)}';
  }
  return '—';
}

String _month(int value) => const [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][value];
