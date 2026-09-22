import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';

class EditAgentProfileScreen extends ConsumerStatefulWidget {
  const EditAgentProfileScreen({super.key});

  @override
  ConsumerState<EditAgentProfileScreen> createState() =>
      _EditAgentProfileScreenState();
}

class _EditAgentProfileScreenState
    extends ConsumerState<EditAgentProfileScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _officeController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;

    setState(() => _saving = true);

    try {
      final newEmail = _emailController.text.trim();

      // Update Firebase Auth Email if it changed
      if (newEmail != auth.email && newEmail.isNotEmpty) {
        await auth.verifyBeforeUpdateEmail(newEmail);
      }

      // Update Firestore
      await ref
          .read(userRepositoryProvider)
          .updateAgentProfile(
            uid: auth.uid,
            email: newEmail,
            phone: _phoneController.text,
            office: _officeController.text,
          );

      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } on fb.FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication error')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    if (profile.hasValue && profile.value != null && !_initialized) {
      _emailController.text = profile.value!.email;
      _phoneController.text = profile.value!.phone;
      _officeController.text = profile.value!.office ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profile not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _officeController,
                decoration: const InputDecoration(
                  labelText: 'Regional Office',
                  hintText: 'e.g. North District Office',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 32),
              if (_saving)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Changes'),
                ),
            ],
          );
        },
      ),
    );
  }
}
