import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../customers/presentation/screens/people_screen.dart';
import 'agent_details_screen.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({this.onAgentSelected, super.key});

  final ValueChanged<({String userId, UserEntity user})>? onAgentSelected;

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      PeopleScreen(
        role: RoleNames.agent,
        onDetails: widget.onAgentSelected,
        detailsBuilder: (context, userId, user) =>
            AgentDetailsScreen(agentId: userId),
      ),
      Positioned(
        top: 24,
        right: 24,
        child: FilledButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Add Agent'),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const _AddAgentDialog(),
            );
          },
        ),
      ),
    ],
  );
}

class _AddAgentDialog extends StatefulWidget {
  const _AddAgentDialog();

  @override
  State<_AddAgentDialog> createState() => _AddAgentDialogState();
}

class _AddAgentDialogState extends State<_AddAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      // 0. Check for duplicate phone number in Firestore BEFORE creating Auth account
      final phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already registered.')),
          );
          setState(() => _loading = false);
        }
        return; // Abort creation
      }

      // 1. Create a temporary FirebaseApp with a unique name to prevent collisions
      final tempApp = await Firebase.initializeApp(
        name: 'AgentCreationApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      try {
        final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
        final cred = await tempAuth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordCtrl.text,
        );

        final uid = cred.user!.uid;

        // 2. Save profile using the default Firebase app instance
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'role': RoleNames.agent,
            'name': _nameCtrl.text.trim(),
            'email': email,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Rollback: if database fails, delete the orphaned auth user
          await cred.user!.delete();
          rethrow;
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agent created successfully')),
          );
        }
      } finally {
        await tempApp.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Agent'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) {
                  final result = validateName(v ?? '');
                  return result.isValid ? null : result.reason;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final result = validateEmail(v ?? '');
                  return result.isValid ? null : result.reason;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number (10 digits)'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final result = validatePhone(v ?? '');
                  return result.isValid ? null : result.reason;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Initial Password'),
                obscureText: true,
                validator: (v) {
                  final result = validatePassword(v ?? '');
                  return result.isValid ? null : result.reason;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create Agent'),
        ),
      ],
    );
  }
}
