import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';
import '../utils/app_exceptions.dart';

/// Provides the QuickServe email/password login screen.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  String? _emailErrorMessage;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final result = shared.validateEmail(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isSigningIn = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is AuthException
            ? error.userMessage
            : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final emailResult = shared.validateEmail(_emailController.text.trim());
    if (!emailResult.isValid) {
      setState(() => _emailErrorMessage = emailResult.reason);
      return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());
    } catch (_) {
      // The same safe message is shown whether or not the email exists.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('If that email exists, a reset link has been sent.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'QuickServe',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        errorText: _emailErrorMessage,
                      ),
                      validator: _validateEmail,
                      onChanged: (_) {
                        if (_emailErrorMessage != null) {
                          setState(() => _emailErrorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _isSigningIn ? null : _signIn(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _isSigningIn ? null : _signIn,
                      child: _isSigningIn
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _sendPasswordReset,
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
