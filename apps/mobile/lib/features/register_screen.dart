import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_spacing.dart';
import 'register_password_requirements.dart';
import '../utils/app_exceptions.dart';

/// Provides the QuickServe customer registration screen.
class RegisterScreen extends ConsumerStatefulWidget {
  /// Creates the registration screen.
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  String? _errorMessage;
  bool _isCreating = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasValidLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final result = shared.validateName(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _validateEmail(String? value) {
    final result = shared.validateEmail(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _validatePhone(String? value) {
    final result = shared.validatePhone(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _validatePassword(String? value) {
    final result = shared.validatePassword(value ?? '');
    return result.isValid ? null : result.reason;
  }

  void _updatePasswordRequirements(String value) {
    setState(() {
      _hasValidLength = value.length >= 8 && value.length <= 128;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
      _hasDigit = RegExp(r'[0-9]').hasMatch(value);
    });
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isCreating = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    ref.read(registrationInProgressProvider.notifier).start();

    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password);
      final uid = credential.user!.uid;

      try {
        await ref
            .read(userRepositoryProvider)
            .createProfile(uid: uid, name: name, email: email, phone: phone);
      } catch (error) {
        try {
          await credential.user?.delete();
        } catch (_) {
          try {
            await ref.read(authRepositoryProvider).signOut();
          } catch (_) {}
        }
        ref.read(registrationInProgressProvider.notifier).finish();
        if (!mounted) return;
        setState(() {
          _isCreating = false;
          _errorMessage = error is AppException ? error.userMessage : 'We could not finish setting up your account. Please try again.';
        });
        return;
      }

      ref.read(registrationInProgressProvider.notifier).finish();
      if (!mounted) return;
      setState(() => _isCreating = false);
    } catch (error) {
      ref.read(registrationInProgressProvider.notifier).finish();
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _errorMessage = error is AppException
            ? error.userMessage
            : 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                    TextFormField(
                      controller: _nameController,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                      onChanged: (value) {
                        _updatePasswordRequirements(value);
                        if (_confirmKey.currentState?.value?.isNotEmpty ??
                            false) {
                          _confirmKey.currentState?.validate();
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.md,
                      ),
                      child: PasswordRequirements(
                        hasValidLength: _hasValidLength,
                        hasUppercase: _hasUppercase,
                        hasLowercase: _hasLowercase,
                        hasDigit: _hasDigit,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      key: _confirmKey,
                      obscureText: _obscureConfirmPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final result = shared.validateConfirmPassword(
                          value ?? '',
                          _passwordController.text,
                        );
                        return result.isValid ? null : result.reason;
                      },
                      onFieldSubmitted: (_) =>
                          _isCreating ? null : _createAccount(),
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
                      onPressed: _isCreating ? null : _createAccount,
                      child: _isCreating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('I already have an account'),
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
