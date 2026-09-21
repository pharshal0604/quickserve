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
  String? agentId;
  String? status;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    agentId = widget.data['agentId'] as String?;
    status = widget.data['status'] as String? ?? StatusNames.created;
  }

  @override
  Widget build(BuildContext context) {
    final code = '${widget.data['requestCode'] ?? widget.requestId}';
    final statusValue = status ?? StatusNames.created;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            Flexible(
              child: Text('Request $code', overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            _StatusChip(statusValue),
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width > 700)
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: const Text('Export invoice'),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: saving ? null : _showStatusPicker,
            icon: const Icon(Icons.sync_alt, size: 17),
            label: const Text('Update status'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(
            padding: const EdgeInsets.all(24),
            child: constraints.maxWidth >= 1050
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _mainColumn(context, theme, statusValue),
                      ),
                      const SizedBox(width: 18),
                      Expanded(flex: 3, child: _sideColumn(context, theme)),
                    ],
                  )
                : _mainColumn(context, theme, statusValue),
          );
          return SingleChildScrollView(child: content);
        },
      ),
    );
  }

  Widget _mainColumn(
    BuildContext context,
    ThemeData theme,
    String statusValue,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _RequestHero(data: widget.data, status: statusValue),
      const SizedBox(height: 18),
      _TimelineCard(repository: widget.repository, requestId: widget.requestId),
      const SizedBox(height: 18),
      _AssignmentCard(
        repository: widget.repository,
        agentId: agentId,
        status: statusValue,
        saving: saving,
        error: error,
        onAgentChanged: (value) => setState(() {
          agentId = value;
          if (value != null && status == StatusNames.created) {
            status = StatusNames.assigned;
          }
        }),
        onStatusChanged: (value) => setState(() => status = value),
        onSave: _save,
      ),
    ],
  );

  Widget _sideColumn(BuildContext context, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ProfileCard(
        title: 'Customer information',
        userId: widget.data['customerId'] as String?,
        repository: widget.repository,
        icon: Icons.person_outline,
      ),
      const SizedBox(height: 18),
      _ProfileCard(
        title: 'Assigned service agent',
        userId: agentId,
        repository: widget.repository,
        icon: Icons.engineering_outlined,
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QuickServe guaranteed',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'This service is protected under the QuickServe operational quality policy.',
              ),
              const SizedBox(height: 10),
              const Text(
                'Verification records are maintained for assigned agents.',
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _showStatusPicker() async {
    final currentStatus = status ?? StatusNames.created;
    final nextStatuses = [
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
            for (final value in nextStatuses)
              ListTile(
                leading: Icon(
                  adminStatusIcon(value),
                  color: adminStatusColor(context, value),
                ),
                title: Text(
                  adminLabel(value),
                  style: TextStyle(
                    color: adminStatusColor(context, value),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: value == currentStatus
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (next != null) setState(() => status = next);
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final oldAgent = widget.data['agentId'] as String?;
      final oldStatus = widget.data['status'] as String? ?? StatusNames.created;
      var currentStatus = oldStatus;
      if (agentId != oldAgent && agentId != null) {
        if (oldStatus != StatusNames.created) {
          throw StateError(
            'The assigned agent cannot be changed after the request is assigned.',
          );
        }
        await widget.repository.assignRequest(
          requestId: widget.requestId,
          agentId: agentId!,
        );
        currentStatus = StatusNames.assigned;
      }
      final targetStatus = status ?? currentStatus;
      if (targetStatus != currentStatus) {
        await widget.repository.updateStatus(
          requestId: widget.requestId,
          status: targetStatus,
          note: 'Updated by administrator',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _RequestHero extends StatelessWidget {
  const _RequestHero({required this.data, required this.status});
  final Map<String, dynamic> data;
  final String status;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? data['attachmentUrl'];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = SizedBox(
            width: constraints.maxWidth > 600 ? 230 : double.infinity,
            height: constraints.maxWidth > 600 ? 205 : 150,
            child: imageUrl is String && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.home_repair_service_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          );
          final details = Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['serviceType'] ?? 'Service request'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 17),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${data['address'] ?? 'Address not provided'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Customer instructions',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('${data['description'] ?? 'No instructions provided.'}'),
                const SizedBox(height: 14),
                Chip(
                  label: Text(
                    '${adminLabel('${data['priority'] ?? 'medium'}')} priority',
                  ),
                ),
              ],
            ),
          );
          return constraints.maxWidth > 600
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Request timeline',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View full history'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repository.watchHistory(requestId),
            builder: (context, historySnapshot) {
              final history = historySnapshot.data?.docs ?? const [];
              if (history.isEmpty) {
                return const Text('No status history recorded yet.');
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: repository.watchUsers(),
                builder: (context, usersSnapshot) {
                  final usersById = {
                    for (final doc in usersSnapshot.data?.docs ?? const [])
                      doc.id: doc.data(),
                  };
                  return Column(
                    children: [
                      for (final doc in history)
                        _TimelineEntry(
                          data: doc.data(),
                          actor: adminUserLabel(
                            usersById[doc.data()['changedBy']],
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Add internal note'),
          ),
        ],
      ),
    ),
  );
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.data, required this.actor});

  final Map<String, dynamic> data;
  final String actor;

  @override
  Widget build(BuildContext context) {
    final fromStatus = data['fromStatus'] as String?;
    final toStatus = '${data['toStatus'] ?? 'unknown'}';
    final transition = fromStatus == null || fromStatus.isEmpty
        ? adminLabel(toStatus)
        : '${adminLabel(fromStatus)} → ${adminLabel(toStatus)}';
    final note = '${data['note'] ?? ''}'.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: adminStatusColor(
          context,
          toStatus,
        ).withValues(alpha: .18),
        foregroundColor: adminStatusColor(context, toStatus),
        child: Icon(adminStatusIcon(toStatus), size: 18),
      ),
      title: Text(
        transition,
        style: TextStyle(
          color: adminStatusColor(context, toStatus),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${note.isEmpty ? 'Status updated' : note} · $actor\n'
        '${_timestamp(data['changedAt'])}',
      ),
      isThreeLine: true,
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.repository,
    required this.agentId,
    required this.status,
    required this.saving,
    required this.error,
    required this.onAgentChanged,
    required this.onStatusChanged,
    required this.onSave,
  });
  final AdminRepository repository;
  final String? agentId;
  final String status;
  final bool saving;
  final String? error;
  final ValueChanged<String?> onAgentChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final availableStatuses = <String>[
      status,
      ...StatusNames.values.where(
        (value) => value != status && canTransition(status, value),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignment and status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: repository.watchUsers(role: RoleNames.agent),
              builder: (context, snapshot) {
                final items = <DropdownMenuItem<String?>>[
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Unassigned'),
                  ),
                  ...?snapshot.data?.docs.map(
                    (doc) => DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        '${doc.data()['name'] ?? doc.id} · ${doc.data()['email'] ?? ''}',
                      ),
                    ),
                  ),
                ];
                return DropdownButtonFormField<String?>(
                  initialValue: agentId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned agent',
                  ),
                  items: items,
                  onChanged: saving || status != StatusNames.created
                      ? null
                      : onAgentChanged,
                );
              },
            ),
            if (status != StatusNames.created)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Agent assignment is locked after the request is assigned. Update the lifecycle status using the valid next step.',
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: availableStatuses
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        adminLabel(value),
                        style: TextStyle(
                          color: adminStatusColor(context, value),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: saving ? null : onStatusChanged,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Saving…' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.userId,
    required this.repository,
    required this.icon,
  });
  final String title;
  final String? userId;
  final AdminRepository repository;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: userId == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const Text('No profile assigned.'),
              ],
            )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: repository.firestore
                  .collection(CollectionNames.users)
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(child: Icon(icon, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${data['name'] ?? userId}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _profileLine(
                      Icons.mail_outline,
                      '${data['email'] ?? 'No email'}',
                    ),
                    _profileLine(
                      Icons.phone_outlined,
                      '${data['phone'] ?? 'No phone'}',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('View complete profile'),
                    ),
                  ],
                );
              },
            ),
    ),
  );

  Widget _profileLine(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      adminLabel(status),
      style: TextStyle(
        color: adminStatusColor(context, status),
        fontWeight: FontWeight.w600,
      ),
    ),
    visualDensity: VisualDensity.compact,
    backgroundColor: adminStatusColor(context, status).withValues(alpha: .18),
    side: BorderSide.none,
  );
}

String _timestamp(dynamic value) => value is Timestamp
    ? value.toDate().toLocal().toString().split('.').first
    : '${value ?? '—'}';
