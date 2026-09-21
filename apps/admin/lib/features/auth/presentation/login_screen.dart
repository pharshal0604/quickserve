import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:quickserve_admin/core/network/admin_repository.dart';

import '../../../core/validators/auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool showPassword = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final value = email.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'Enter your email address first.');
      return;
    }
    try {
      await AdminRepository().sendPasswordReset(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent if the account exists.'),
        ),
      );
    } on FirebaseAuthException {
      if (mounted) {
        setState(() => error = 'Unable to send a reset email right now.');
      }
    }
  }

  Future<void> submit() async {
    final address = email.text.trim();
    final secret = password.text;
    final emailError = AdminAuthValidators.email(address);
    final passwordError = AdminAuthValidators.password(secret);
    if (emailError != null || passwordError != null) {
      setState(() => error = emailError ?? passwordError);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: address,
        password: secret,
      );
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'The email or password is incorrect.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Unable to sign in right now.',
      };
      setState(() => error = message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.code == 'popup-closed-by-user'
            ? 'Google sign-in was cancelled.'
            : 'Unable to sign in with Google right now.';
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff6f8f7),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final form = _loginForm(context);
        if (compact) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: form,
                ),
              ),
            ),
          );
        }
        return Row(
          children: [
            Expanded(flex: 5, child: _loginBrandPanel(context)),
            Expanded(
              flex: 4,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: form,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _loginBrandPanel(BuildContext context) => Container(
    color: const Color(0xff07120f),
    padding: const EdgeInsets.all(56),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xffb9f36b),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt, color: Color(0xff07120f), size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'QUICKSERVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 72),
        const Text(
          'Admin Portal',
          style: TextStyle(
            color: Color(0xffb9f36b),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Manage your platform\nwith precision.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Monitor requests, coordinate service agents, and keep every customer experience on track.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .68),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            _loginFeature(Icons.insights_outlined, 'Live operations'),
            const SizedBox(width: 24),
            _loginFeature(Icons.verified_user_outlined, 'Role-secured'),
          ],
        ),
      ],
    ),
  );

  Widget _loginFeature(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: const Color(0xffb9f36b), size: 18),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .72))),
    ],
  );

  Widget _loginForm(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Welcome back',
        style: TextStyle(
          color: Color(0xff12372d),
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Sign in to your administrator account.',
        style: TextStyle(
          color: Colors.black.withValues(alpha: .58),
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 36),
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email address',
          prefixIcon: Icon(Icons.mail_outline),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: password,
        obscureText: !showPassword,
        onSubmitted: (_) => submit(),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: showPassword ? 'Hide password' : 'Show password',
            onPressed: busy
                ? null
                : () => setState(() => showPassword = !showPassword),
            icon: Icon(
              showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: busy ? null : resetPassword,
          child: const Text('Forgot password?'),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(error!, style: const TextStyle(color: Color(0xffb3261e))),
      ],
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff12372d),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Signing in...' : 'Sign in'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: busy ? null : signInWithGoogle,
          icon: const _GoogleMark(),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff12372d),
            side: BorderSide(color: Colors.black.withValues(alpha: .16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Text(
        'Administrator access only',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black.withValues(alpha: .45),
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: Color(0xff4285f4),
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );
}
