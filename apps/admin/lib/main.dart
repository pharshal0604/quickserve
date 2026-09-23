import 'package:quickserve_admin/config/routes/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme/admin_theme.dart';

import 'package:quickserve_admin/config/firebase/firebase_options.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: QuickServeAdminApp()));
}

final darkModeProvider = StateProvider<bool>((ref) => false);
final textScaleProvider = StateProvider<double>((ref) => 1.0);

class QuickServeAdminApp extends ConsumerWidget {
  const QuickServeAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final darkMode = ref.watch(darkModeProvider);
    final textScale = ref.watch(textScaleProvider);

    return MaterialApp.router(
      title: 'QuickServe Admin',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AdminTheme.light(),
      darkTheme: AdminTheme.dark(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Row(
        children: [
          _AdminSidebar(
            selectedIndex: navigationShell.currentIndex,
            onSelected: (value) => navigationShell.goBranch(value),
            onLogout: FirebaseAuth.instance.signOut,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
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
      (label: 'Settings', icon: Icons.settings_outlined, index: 6),
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
