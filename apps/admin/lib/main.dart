import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide User;

import 'admin_repository.dart';
import 'firebase/emulator_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, authEmulatorPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      emulatorHost,
      firestoreEmulatorPort,
    );
  }
  runApp(const QuickServeAdminApp());
}

class QuickServeAdminApp extends StatelessWidget {
  const QuickServeAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'QuickServe Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff145c72)),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, authSnapshot) {
      if (authSnapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingPage();
      }
      final user = authSnapshot.data;
      if (user == null) return const LoginScreen();
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection(CollectionNames.users)
            .doc(user.uid)
            .get(),
        builder: (context, profileSnapshot) {
          if (!profileSnapshot.hasData) return const _LoadingPage();
          final role = profileSnapshot.data!.data()?['role'];
          if (role != RoleNames.admin) return const _AccessDeniedPage();
          return AdminShell(user: user);
        },
      );
    },
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Unable to sign in.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'QuickServe Admin',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Sign in with an administrator account.'),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  onSubmitted: (_) => submit(),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(busy ? 'Signing in…' : 'Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminShell extends StatefulWidget {
  const AdminShell({required this.user, super.key});
  final User user;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  final repository = AdminRepository();
  final titles = const ['Dashboard', 'Requests', 'Users', 'Activity'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(repository: repository),
      RequestsPage(repository: repository),
      UsersPage(repository: repository),
      ActivityPage(repository: repository),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('QuickServe · ${titles[index]}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(widget.user.email ?? '')),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Requests'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: Text('Activity'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[index]),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.repository, super.key});
  final AdminRepository repository;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repository.watchRequests(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final counts = {
            for (final status in StatusNames.values)
              status: docs.where((d) => d.data()['status'] == status).length,
          };
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Operations overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.hasError
                    ? 'Unable to load requests: ${snapshot.error}'
                    : 'Live request totals from the latest 200 records.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard('Total', docs.length, Icons.all_inbox),
                  for (final status in StatusNames.values)
                    _MetricCard(
                      _statusLabel(status),
                      counts[status] ?? 0,
                      _statusIcon(status),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin controls',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use Requests to assign eligible Agents, advance valid lifecycle states, and inspect customer, service, notes, and status history.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestsPage extends StatefulWidget {
  const RequestsPage({required this.repository, super.key});
  final AdminRepository repository;
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  String search = '';
  String status = 'all';
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: widget.repository.watchRequests(),
    builder: (context, snapshot) {
      final all = snapshot.data?.docs ?? const [];
      final docs =
          all.where((doc) {
            final d = doc.data();
            final needle = search.toLowerCase();
            final matchesSearch =
                needle.isEmpty ||
                [
                  d['requestCode'],
                  d['description'],
                  d['serviceType'],
                  d['address'],
                ].join(' ').toLowerCase().contains(needle);
            return matchesSearch && (status == 'all' || d['status'] == status);
          }).toList()..sort(
            (a, b) =>
                ((b.data()['updatedAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0)
                    .compareTo(
                      (a.data()['updatedAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0,
                    ),
          );
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => search = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText:
                          'Search code, service, address, or description',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: status,
                  items: ['all', ...StatusNames.values]
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s == 'all' ? 'All statuses' : _statusLabel(s),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => status = value ?? 'all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: snapshot.hasError
                  ? Center(
                      child: Text('Unable to load requests: ${snapshot.error}'),
                    )
                  : Card(
                      child: ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _requestTile(context, docs[index]),
                      ),
                    ),
            ),
          ],
        ),
      );
    },
  );

  Widget _requestTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final current = d['status'] as String? ?? 'unknown';
    return ListTile(
      leading: CircleAvatar(child: Icon(_statusIcon(current))),
      title: Text(
        '${d['requestCode'] ?? doc.id} · ${d['serviceType'] ?? 'Service'}',
      ),
      subtitle: Text('${d['description'] ?? ''}\n${d['address'] ?? ''}'),
      isThreeLine: true,
      trailing: Chip(label: Text(_statusLabel(current))),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) =>
            RequestDialog(repository: widget.repository, id: doc.id, data: d),
      ),
    );
  }
}

class RequestDialog extends StatefulWidget {
  const RequestDialog({
    required this.repository,
    required this.id,
    required this.data,
    super.key,
  });
  final AdminRepository repository;
  final String id;
  final Map<String, dynamic> data;
  @override
  State<RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<RequestDialog> {
  String? selectedAgent;
  String? selectedStatus;
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) {
    final current = widget.data['status'] as String? ?? 'created';
    selectedStatus ??= current;
    selectedAgent ??= widget.data['agentId'] as String?;
    return AlertDialog(
      title: Text(widget.data['requestCode'] as String? ?? widget.id),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail('Service', widget.data['serviceType']),
              _detail('Description', widget.data['description']),
              _detail('Address', widget.data['address']),
              _detail('Priority', widget.data['priority']),
              _detail('Customer ID', widget.data['customerId']),
              _detail('Current status', _statusLabel(current)),
              const Divider(),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.repository.watchUsers(role: RoleNames.agent),
                builder: (context, snapshot) => DropdownButtonFormField<String>(
                  initialValue: selectedAgent,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Agent',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
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
                  ],
                  onChanged: (value) => setState(() => selectedAgent = value),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Next status'),
                items: StatusNames.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedStatus = value),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Save changes'),
        ),
      ],
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text('$label: ${value ?? '—'}'),
  );
  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final current = widget.data['status'] as String? ?? 'created';
      if (selectedAgent != widget.data['agentId'] && selectedAgent != null) {
        await widget.repository.assignRequest(
          requestId: widget.id,
          agentId: selectedAgent!,
        );
      }
      if (selectedStatus != current &&
          !(selectedAgent != widget.data['agentId'] &&
              selectedStatus == StatusNames.assigned)) {
        await widget.repository.updateStatus(
          requestId: widget.id,
          status: selectedStatus!,
          note: 'Updated by administrator',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({required this.repository, super.key});
  final AdminRepository repository;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repository.watchUsers(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Customer and Agent records',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Phone')),
                  ],
                  rows: docs.map((doc) {
                    final d = doc.data();
                    return DataRow(
                      cells: [
                        DataCell(Text('${d['name'] ?? '—'}')),
                        DataCell(Text('${d['email'] ?? '—'}')),
                        DataCell(Text('${d['role'] ?? '—'}')),
                        DataCell(Text('${d['phone'] ?? '—'}')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      );
}

class ActivityPage extends StatelessWidget {
  const ActivityPage({required this.repository, super.key});
  final AdminRepository repository;
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: repository.watchAuditLogs(),
    builder: (context, snapshot) {
      final docs = snapshot.data?.docs ?? const [];
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Activity and audit log',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = docs[i].data();
                return ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(
                    '${d['action'] ?? 'EVENT'} · ${d['targetId'] ?? ''}',
                  ),
                  subtitle: Text(
                    'Actor ${d['actorUserId'] ?? '—'} · ${d['result'] ?? '—'}',
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Administrator access required'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: FirebaseAuth.instance.signOut,
                child: Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _statusLabel(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
IconData _statusIcon(String value) => switch (value) {
  StatusNames.created => Icons.fiber_new,
  StatusNames.assigned => Icons.person_add_alt_1,
  StatusNames.accepted => Icons.thumb_up_alt_outlined,
  StatusNames.inProgress => Icons.sync,
  StatusNames.completed => Icons.check_circle_outline,
  StatusNames.cancelled => Icons.cancel_outlined,
  _ => Icons.help_outline,
};
