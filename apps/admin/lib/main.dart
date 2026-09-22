import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';

import 'config/theme/admin_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/requests/presentation/screens/requests_screen.dart';
import 'features/customers/presentation/screens/customers_screen.dart';
import 'features/agents/presentation/screens/agents_screen.dart';
import 'features/agents/presentation/screens/agent_details_screen.dart';
import 'features/services/presentation/screens/services_screen.dart';
import 'features/activity/presentation/screens/activity_screen.dart';
import 'features/activity/presentation/screens/notifications_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

import 'package:quickserve_admin/config/firebase/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuickServeAdminApp());
}

class QuickServeAdminApp extends StatefulWidget {
  const QuickServeAdminApp({super.key});

  @override
  State<QuickServeAdminApp> createState() => _QuickServeAdminAppState();
}

class _QuickServeAdminAppState extends State<QuickServeAdminApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickServe Admin',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AdminTheme.light(),
      darkTheme: AdminTheme.dark(),
      home: AuthGate(
        adminBuilder: (user) => AdminShell(
          user: user,
          onThemeChanged: (value) => setState(() => darkMode = value),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({
    required this.user,
    required this.onThemeChanged,
    super.key,
  });
  final User user;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  final repository = AdminRepository();
  String? selectedAgentId;
  Map<String, dynamic>? selectedAgentData;
  final titles = const [
    'Dashboard',
    'Requests',
    'Customers',
    'Agents',
    'Services',
    'Activity',
    'Notifications',
    'Settings',
  ];

  void _clearSelectedAgent() {
    if (selectedAgentId == null && selectedAgentData == null) return;
    setState(() {
      selectedAgentId = null;
      selectedAgentData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(repository: repository),
      RequestsScreen(repository: repository),
      CustomersScreen(repository: repository),
      if (selectedAgentId != null && selectedAgentData != null)
        AgentDetailsScreen(
          repository: repository,
          userId: selectedAgentId!,
          data: selectedAgentData!,
          onBack: _clearSelectedAgent,
        )
      else
        AgentsScreen(
          repository: repository,
          onAgentSelected: (selection) => setState(() {
            selectedAgentId = selection.userId;
            selectedAgentData = selection.data;
          }),
        ),
      ServicesScreen(repository: repository),
      ActivityScreen(repository: repository),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AdminTheme.ink,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.business_center_outlined,
                color: AdminTheme.sidebarText,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QuickServe',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'ADMIN PORTAL',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle light/dark theme',
            onPressed: () => widget.onThemeChanged(
              Theme.of(context).brightness == Brightness.light,
            ),
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          _AdminSidebar(
            selectedIndex: index,
            onSelected: (value) => setState(() {
              index = value;
              selectedAgentId = null;
              selectedAgentData = null;
            }),
            onLogout: FirebaseAuth.instance.signOut,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[index]),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final entries = <({String label, IconData icon, int index})>[
      (label: 'Dashboard', icon: Icons.dashboard_outlined, index: 0),
      (label: 'Requests', icon: Icons.assignment_outlined, index: 1),
      (label: 'Customers', icon: Icons.people_outline, index: 2),
      (label: 'Agents', icon: Icons.engineering_outlined, index: 3),
      (label: 'Services', icon: Icons.home_repair_service_outlined, index: 4),
      (label: 'Audit & Activity', icon: Icons.history, index: 5),
      (label: 'Notifications', icon: Icons.notifications_none, index: 6),
      (label: 'Settings', icon: Icons.settings_outlined, index: 7),
    ];
    return Container(
      width: 220,
      color: AdminTheme.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _SidebarLabel('MAIN'),
          _sidebarItem(entries[0]),
          const SizedBox(height: 16),
          const _SidebarLabel('OPERATIONS'),
          for (final entry in entries.skip(1).take(4)) _sidebarItem(entry),
          const SizedBox(height: 16),
          const _SidebarLabel('SYSTEM'),
          for (final entry in entries.skip(5)) _sidebarItem(entry),
          const Spacer(),
          const Divider(color: AdminTheme.sidebarDivider),
          _sidebarItem((
            label: 'Logout',
            icon: Icons.logout,
            index: -1,
          ), logout: true),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    ({String label, IconData icon, int index}) entry, {
    bool logout = false,
  }) {
    final selected = entry.index == selectedIndex;
    return _SidebarItem(
      entry: entry,
      selected: selected,
      logout: logout,
      onTap: logout ? onLogout : () => onSelected(entry.index),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.entry,
    required this.selected,
    required this.logout,
    required this.onTap,
  });

  final ({String label, IconData icon, int index}) entry;
  final bool selected;
  final bool logout;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? AdminTheme.ink
        : hovered
        ? AdminTheme.ink.withValues(alpha: .78)
        : Colors.transparent;
    final foreground = widget.logout
        ? AdminTheme.sidebarLogout
        : hovered || widget.selected
        ? AdminTheme.sidebarText
        : AdminTheme.sidebarMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
              boxShadow: hovered && !widget.selected
                  ? const [
                      BoxShadow(
                        color: AdminTheme.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(widget.entry.icon, size: 17, color: foreground),
                const SizedBox(width: 10),
                Text(
                  widget.entry.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: widget.selected || hovered
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AdminTheme.sidebarLabel,
        fontSize: 9,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
