import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({required this.user, super.key});
  final User user;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool busy = false;
  String? message;

  Future<void> resend() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.user.sendEmailVerification();
      if (mounted) setState(() => message = 'Verification email sent.');
    } on FirebaseAuthException {
      if (mounted) {
        setState(
          () => message = 'Unable to send a verification email right now.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkAgain() async {
    setState(() => busy = true);
    await widget.user.reload();
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Verify ${widget.user.email ?? 'your email address'} before entering the Admin Portal.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (message != null)
                  Text(
                    message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : checkAgain,
                  child: const Text('I have verified my email'),
                ),
                TextButton(
                  onPressed: busy ? null : resend,
                  child: const Text('Resend verification email'),
                ),
                TextButton(
                  onPressed: FirebaseAuth.instance.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
