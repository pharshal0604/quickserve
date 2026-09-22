import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/core/error/app_exceptions.dart';
import 'package:quickserve_mobile/features/agent/presentation/widgets/agent_common/agent_bottom_nav.dart';
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickserve_mobile/config/theme/theme_provider.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            uid: auth.uid,
            name: _nameController.text,
            phone: _phoneController.text,
          );
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AppException
                ? error.userMessage
                : 'Profile could not be updated.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    if (profile.hasValue && profile.value != null && !_initialized) {
      _nameController.text = profile.value!.name;
      _phoneController.text = profile.value!.phone;
      // We schedule the _initialized flag to be set to true so we don't mutate state during build,
      // but Dart is single-threaded so simply assigning it here is fine since it's just a local variable.
      _initialized = true;
    }

    return profile.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('Could not load your profile.')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found.')),
          );
        }
        final authUser = ref.watch(authStateProvider).value;
        if (user.role == shared.UserRole.agent) {
          return _AgentProfileView(
            user: user,
            authUser: authUser,
            editing: _editing,
            saving: _saving,
            phoneController: _phoneController,
            onToggleEditing: () => setState(() => _editing = !_editing),
            onSave: _saveProfile,
            onSettings: () => context.push('/settings'),
            onSignOut: () => ref.read(authRepositoryProvider).signOut(),
            onUnavailable: _showUnavailable,
          );
        }
        return _CustomerProfileView(
          user: user,
          authUser: authUser,
          editing: _editing,
          saving: _saving,
          nameController: _nameController,
          phoneController: _phoneController,
          onToggleEditing: () => setState(() => _editing = !_editing),
          onSave: _saveProfile,
          onSignOut: () => ref.read(authRepositoryProvider).signOut(),
          onNotifications: () => context.push('/notifications'),
          onSettings: () => context.push('/settings'),
          onUnavailable: _showUnavailable,
        );
      },
    );
  }

  void _showUnavailable(String feature) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feature),
        content: Text(
          '$feature is not part of the current Firebase data model, so no fake records were added.',
        ),
        actions: const [CloseButton()],
      ),
    );
  }
}

class _AgentProfileView extends ConsumerWidget {
  const _AgentProfileView({
    required this.user,
    required this.authUser,
    required this.editing,
    required this.saving,
    required this.phoneController,
    required this.onToggleEditing,
    required this.onSave,
    required this.onSettings,
    required this.onSignOut,
    required this.onUnavailable,
  });

  final shared.User user;
  final fb.User? authUser;
  final bool editing;
  final bool saving;
  final TextEditingController phoneController;
  final VoidCallback onToggleEditing;
  final VoidCallback onSave;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final void Function(String feature) onUnavailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = authUser?.photoURL;
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'App settings',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 3),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          // ── Avatar ─────────────────────────────────────────────
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.mintSurface,
                  backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          initial.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: -3,
                  bottom: 1,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Name & role ─────────────────────────────────────────
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 10),
          Center(
            child: _StatusLabel(label: 'Active', icon: Icons.verified_outlined),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onToggleEditing,
            child: Text(editing ? 'Cancel' : 'Edit Profile'),
          ),
          if (editing) ...[
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: quickServeInputDecoration('Phone Number'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: saving ? null : onSave,
              child: Text(saving ? 'Saving...' : 'Save changes'),
            ),
          ],
          const SizedBox(height: 20),
          _CustomerRow(
            icon: Icons.lock_outline_rounded,
            title: 'Security Settings',
            onTap: () => context.push('/security-settings'),
          ),
          _CustomerRow(
            icon: Icons.phone_android_outlined,
            title: 'Authorized Devices',
            onTap: () => context.push('/authorized-devices'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SharedProfileSettings(),
          ),
          const Divider(),
          _CustomerRow(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            color: Theme.of(context).colorScheme.error,
            onTap: onSignOut,
          ),
          const SizedBox(height: 16),
          Text(
            'QUICKSERVE MOBILE · ${user.role.toStoredValue().toUpperCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 8,
              letterSpacing: .8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _lineColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CustomerProfileView extends ConsumerWidget {
  const _CustomerProfileView({
    required this.user,
    required this.authUser,
    required this.editing,
    required this.saving,
    required this.nameController,
    required this.phoneController,
    required this.onToggleEditing,
    required this.onSave,
    required this.onSignOut,
    required this.onNotifications,
    required this.onSettings,
    required this.onUnavailable,
  });

  final shared.User user;
  final fb.User? authUser;
  final bool editing;
  final bool saving;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onToggleEditing;
  final VoidCallback onSave;
  final VoidCallback onSignOut;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final void Function(String feature) onUnavailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoUrl = authUser?.photoURL;
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0];

    return HomeBackScope(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text('Profile'),
          actions: [
            IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.mintSurface,
                backgroundImage: photoUrl == null || photoUrl.isEmpty
                    ? null
                    : NetworkImage(photoUrl),
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        initial.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onToggleEditing,
              child: Text(editing ? 'Cancel' : 'Edit Profile'),
            ),
            if (editing) ...[
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: quickServeInputDecoration('Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: quickServeInputDecoration('Phone Number'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Saving...' : 'Save changes'),
              ),
            ],
            const SizedBox(height: 20),
            _CustomerRow(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: onNotifications,
            ),
            _CustomerRow(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () => context.push('/saved-addresses'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: _SharedProfileSettings(),
            ),
            const Divider(),
            _CustomerRow(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              onTap: onSignOut,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedProfileSettings extends ConsumerWidget {
  const _SharedProfileSettings();

  Future<void> _launchPrivacyPolicy() async {
    final url = Uri.parse('https://quickserve.com/privacy');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchSupport() async {
    final url = Uri.parse('https://quickserve.com/support');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Dark Theme', style: TextStyle(fontSize: 14)),
          secondary: Icon(
            Icons.dark_mode_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          value: isDark,
          onChanged: (val) =>
              ref.read(themeModeProvider.notifier).toggleTheme(),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          title: const Text('Privacy Policy', style: TextStyle(fontSize: 14)),
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: _launchPrivacyPolicy,
        ),
        ListTile(
          title: const Text('Help & Support', style: TextStyle(fontSize: 14)),
          leading: Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: _launchSupport,
        ),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

Color _lineColor(BuildContext context) {
  return Theme.of(context).colorScheme.outline;
}
