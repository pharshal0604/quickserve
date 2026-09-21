import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/core/error/app_exceptions.dart';
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
  bool _seeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      if (mounted) {
        setState(() {
          _saving = false;
          _editing = false;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load your profile.')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profile not found.'));
          }
          if (!_seeded) {
            _nameController.text = user.name;
            _phoneController.text = user.phone;
            _seeded = true;
          }
          final authUser = ref.watch(authStateProvider).value;
          final photoUrl = authUser?.photoURL;
          final initial = user.name.trim().isEmpty
              ? '?'
              : user.name.trim()[0].toUpperCase();
          final roleLabel = user.role.toStoredValue().replaceFirstMapped(
            RegExp(r'^.'),
            (match) => match.group(0)!.toUpperCase(),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
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
                          initial,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 3),
              Center(
                child: Text(
                  user.email,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: OutlinedButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: Text(_editing ? 'Cancel' : 'Edit Profile'),
                ),
              ),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _nameController,
                  decoration: quickServeInputDecoration(
                    'Full Name',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: quickServeInputDecoration(
                    'Phone Number',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _AccountCard(roleLabel: roleLabel, email: user.email),
              const SizedBox(height: AppSpacing.xl),
              const _ProfileSectionLabel('ACCOUNT MANAGEMENT'),
              _ProfileRow(
                icon: Icons.history_rounded,
                title: 'Service History',
                subtitle: 'View past and current requests',
                onTap: () => context.go('/requests'),
              ),
              _ProfileRow(
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                subtitle: 'Address book is not enabled yet',
                onTap: () => _showUnavailable('Saved addresses'),
              ),
              _ProfileRow(
                icon: Icons.credit_card_outlined,
                title: 'Payment Methods',
                subtitle: 'Payments are not part of the current flow',
                onTap: () => _showUnavailable('Payment methods'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ProfileSectionLabel('PREFERENCES'),
              _ProfileRow(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: 'Manage request alerts',
                onTap: () => context.go('/notifications'),
                trailing: const StatusPill(label: '•', color: AppColors.gold),
              ),
              _ProfileRow(
                icon: Icons.phone_android_outlined,
                title: 'App Settings',
                subtitle: 'Theme, language, and display',
                onTap: () => context.go('/settings'),
              ),
              _ProfileRow(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your data and security',
                onTap: () => context.go('/settings'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ProfileSectionLabel('SUPPORT'),
              _ProfileRow(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                subtitle: 'FAQs and customer support',
                onTap: _showSupport,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileRow(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'End your current session',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => ref.read(authRepositoryProvider).signOut(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Center(
                child: Text(
                  'QuickServe Mobile',
                  style: TextStyle(color: AppColors.outline, fontSize: 11),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUnavailable(String feature) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feature),
        content: Text(
          '$feature are not part of the current Firebase data model, so no fake records were added.',
        ),
        actions: const [CloseButton()],
      ),
    );
  }

  void _showSupport() {
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Help Center'),
        content: Text(
          'For help with a request, open its details page and share the request ID with support.',
        ),
        actions: [CloseButton()],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.roleLabel, required this.email});
  final String roleLabel;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22075B3E),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICKSERVE ACCOUNT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.titleColor,
    this.iconColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.mutedText,
                ),
          ],
        ),
      ),
    );
  }
}
