import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';
import 'package:quickserve_admin/shared/admin_formatters.dart';

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({
    required this.repository,
    required this.requestId,
    required this.data,
    super.key,
  });

  final AdminRepository repository;
  final String requestId;
  final Map<String, dynamic> data;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late String status;
  String? agentId;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    status = widget.data['status'] as String? ?? StatusNames.created;
    agentId = widget.data['agentId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final code = '${widget.data['requestCode'] ?? widget.requestId}';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: _RequestHeader(
          code: code,
          status: status,
          data: widget.data,
          onBack: () => Navigator.of(context).pop(),
          onStatusTap: _showStatusPicker,
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Request actions',
            onSelected: (value) {
              if (value == 'status') _showStatusPicker();
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
                    Expanded(flex: 7, child: _mainColumn(context)),
                    const SizedBox(width: 16),
                    SizedBox(width: 330, child: _sideColumn(context)),
                  ],
                )
              : Column(
                  children: [
                    _mainColumn(context),
                    const SizedBox(height: 16),
                    _sideColumn(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _mainColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ServiceOverviewCard(data: widget.data),
      const SizedBox(height: 16),
      _TimelineCard(repository: widget.repository, requestId: widget.requestId),
    ],
  );

  Widget _sideColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _CustomerInformationCard(
        repository: widget.repository,
        userId: widget.data['customerId'] as String?,
      ),
      const SizedBox(height: 16),
      _AgentInformationCard(
        repository: widget.repository,
        userId: agentId,
        assignedAt: widget.data['updatedAt'],
        enabled: status == StatusNames.created && !saving,
        onReassign: _showAgentPicker,
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

  Future<void> _showStatusPicker() async {
    final options = [
      status,
      ...StatusNames.values.where(
        (value) => value != status && canTransition(status, value),
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
                trailing: value == status ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (next != null && mounted) {
      await widget.repository.updateStatus(requestId: widget.requestId, status: next);
      if (mounted) setState(() => status = next);
    }
  }

  Future<void> _showAgentPicker() async {
    if (status != StatusNames.created) {
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
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.repository.watchUsers(role: RoleNames.agent),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading agents', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                );
              }
              final agents = snapshot.data?.docs ?? const [];
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Assign Service Agent',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  if (agents.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No service agents found.'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: agents.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = agents[index];
                          final data = doc.data();
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              child: Text(adminInitial(data['name'])),
                            ),
                            title: Text(
                              '${data['name'] ?? doc.id}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${data['phone'] ?? data['email'] ?? 'No contact'}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      await widget.repository.assignRequest(
        requestId: widget.requestId,
        agentId: selected,
      );
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
    required this.data,
    required this.onBack,
    required this.onStatusTap,
  });

  final String code;
  final String status;
  final Map<String, dynamic> data;
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
          'Placed on ${_date(data['createdAt'])} · ${_time(data['preferredDateTime'])}',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _ServiceOverviewCard extends StatelessWidget {
  const _ServiceOverviewCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? data['attachmentUrl'];
    final priority = '${data['priority'] ?? 'medium'}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = SizedBox(
            width: constraints.maxWidth >= 620 ? 150 : double.infinity,
            height: constraints.maxWidth >= 620 ? 140 : 170,
            child: imageUrl is String && imageUrl.isNotEmpty
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
                  '${data['serviceType'] ?? 'Service request'}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${adminLabel('${data['serviceType'] ?? 'service'}')}',
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: '${data['address'] ?? 'Address not provided'}',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.notes_outlined,
                  label: 'Customer instructions',
                  value:
                      '${data['description'] ?? 'No instructions provided.'}',
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

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.repository, required this.requestId});
  final AdminRepository repository;
  final String requestId;

  @override
  Widget build(BuildContext context) => Card(
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
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repository.watchHistory(requestId),
            builder: (context, historySnapshot) {
              final history = historySnapshot.data?.docs ?? const [];
              if (history.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No status history recorded yet.'),
                );
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: repository.watchUsers(),
                builder: (context, usersSnapshot) {
                  final users = <String, Map<String, dynamic>>{
                    for (final doc in usersSnapshot.data?.docs ?? const [])
                      doc.id: doc.data(),
                  };
                  return Column(
                    children: [
                      for (var index = 0; index < history.length; index++)
                        _TimelineRow(
                          data: history[index].data(),
                          actor: adminUserLabel(
                            users[history[index].data()['changedBy']],
                          ),
                          isLast: index == history.length - 1,
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
    required this.data,
    required this.actor,
    required this.isLast,
  });
  final Map<String, dynamic> data;
  final String actor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final toStatus = '${data['toStatus'] ?? 'unknown'}';
    final fromStatus = data['fromStatus'] as String?;
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
                      _timestamp(data['changedAt']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${data['note'] ?? 'Status updated'}',
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

class _CustomerInformationCard extends StatelessWidget {
  const _CustomerInformationCard({
    required this.repository,
    required this.userId,
  });
  final AdminRepository repository;
  final String? userId;

  @override
  Widget build(BuildContext context) => _UserInformationCard(
    repository: repository,
    userId: userId,
    title: 'Customer Information',
    icon: Icons.person_outline,
    roleLabel: 'Customer',
    actionLabel: 'View Complete Profile',
  );
}

class _AgentInformationCard extends StatefulWidget {
  const _AgentInformationCard({
    required this.repository,
    required this.userId,
    required this.assignedAt,
    required this.enabled,
    required this.onReassign,
    required this.onContact,
  });
  final AdminRepository repository;
  final String? userId;
  final dynamic assignedAt;
  final bool enabled;
  final VoidCallback onReassign;
  final VoidCallback onContact;

  @override
  State<_AgentInformationCard> createState() => _AgentInformationCardState();
}

class _AgentInformationCardState extends State<_AgentInformationCard> {
  late Future<DocumentSnapshot<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(_AgentInformationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _future = _fetch();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>? _fetch() {
    if (widget.userId == null) return null;
    return widget.repository.firestore
        .collection(CollectionNames.users)
        .doc(widget.userId)
        .get();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: widget.userId == null
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
                  onPressed: widget.enabled ? widget.onReassign : null,
                  child: const Text('Assign Service Agent'),
                ),
              ],
            )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                final name = '${data['name'] ?? widget.userId}';
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
                      value: '${data['email'] ?? 'No email'}',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: '${data['phone'] ?? 'No phone'}',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.calendar_today_outlined,
                      label: 'Assigned on',
                      value: _date(widget.assignedAt),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: widget.onContact,
                      icon: const Icon(Icons.phone_outlined, size: 15),
                      label: const Text('Contact Agent'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.enabled ? widget.onReassign : null,
                      child: const Text('Reassign Agent'),
                    ),
                  ],
                );
              },
            ),
    ),
  );
}

class _UserInformationCard extends StatefulWidget {
  const _UserInformationCard({
    required this.repository,
    required this.userId,
    required this.title,
    required this.icon,
    required this.roleLabel,
    required this.actionLabel,
  });
  final AdminRepository repository;
  final String? userId;
  final String title;
  final IconData icon;
  final String roleLabel;
  final String actionLabel;

  @override
  State<_UserInformationCard> createState() => _UserInformationCardState();
}

class _UserInformationCardState extends State<_UserInformationCard> {
  late Future<DocumentSnapshot<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(_UserInformationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _future = _fetch();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>? _fetch() {
    if (widget.userId == null) return null;
    return widget.repository.firestore
        .collection(CollectionNames.users)
        .doc(widget.userId)
        .get();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: widget.userId == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('No profile assigned.'),
              ],
            )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                final name = '${data['name'] ?? widget.userId}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.title,
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
                      child: _RoleBadge(label: widget.roleLabel),
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(
                      icon: Icons.mail_outline,
                      label: 'Email address',
                      value: '${data['email'] ?? 'No email'}',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: '${data['phone'] ?? 'No phone'}',
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member since',
                      value: _date(data['createdAt']),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(onPressed: null, child: Text(widget.actionLabel)),
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
