import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide User;

import 'email_verification_page.dart';
import 'login_screen.dart';

/// Routes an authenticated Firebase user into the Admin portal only when the
/// account is verified and its Firestore profile has the admin role.
class AuthGate extends StatelessWidget {
  const AuthGate({required this.adminBuilder, super.key});

  final Widget Function(User user) adminBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, authSnapshot) {
      if (authSnapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingPage();
      }

      final user = authSnapshot.data;
      if (user == null) return const LoginScreen();
      if (!user.emailVerified) return EmailVerificationPage(user: user);

      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection(CollectionNames.users)
            .doc(user.uid)
            .get(),
        builder: (context, profileSnapshot) {
          if (!profileSnapshot.hasData) return const _LoadingPage();

          final role = profileSnapshot.data!.data()?['role'];
          if (role != RoleNames.admin) return const _AccessDeniedPage();

          return adminBuilder(user);
        },
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
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
