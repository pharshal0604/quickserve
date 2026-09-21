import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import '../state/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_exceptions.dart';
import 'quickserve_widgets.dart';
import 'register_password_requirements.dart';

class RegisterScreen extends ConsumerStatefulWidget {
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
  final _confirmController = TextEditingController();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  bool _acceptedTerms = false;
  bool _isCreating = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasValidLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _nameValidator(String? value) {
    final result = shared.validateName(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _emailValidator(String? value) {
    final result = shared.validateEmail(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _phoneValidator(String? value) {
    final result = shared.validatePhone(value ?? '');
    return result.isValid ? null : result.reason;
  }

  String? _passwordValidator(String? value) {
    final result = shared.validatePassword(value ?? '');
    return result.isValid ? null : result.reason;
  }

  void _updateRequirements(String value) {
    setState(() {
      _hasValidLength = value.length >= 8 && value.length <= 128;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
      _hasDigit = RegExp(r'[0-9]').hasMatch(value);
    });
  }

  Future<void> _createAccount() async {
    if (!_acceptedTerms) {
      setState(
        () => _errorMessage =
            'Please accept the Terms of Service and Privacy Policy.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });
    ref.read(registrationInProgressProvider.notifier).start();
    final email = _emailController.text.trim();
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .register(email: email, password: _passwordController.text);
      final user = credential.user!;
      try {
        await ref
            .read(userRepositoryProvider)
            .createProfile(
              uid: user.uid,
              name: _nameController.text.trim(),
              email: email,
              phone: _phoneController.text.trim(),
            );
      } catch (error) {
        try {
          await user.delete();
        } catch (_) {
          try {
            await ref.read(authRepositoryProvider).signOut();
          } catch (_) {}
        }
        rethrow;
      }
      ref.read(registrationInProgressProvider.notifier).finish();
      if (mounted) setState(() => _isCreating = false);
    } catch (error) {
      ref.read(registrationInProgressProvider.notifier).finish();
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _errorMessage = error is AppException
            ? error.userMessage
            : 'We could not finish setting up your account.';
      });
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });
    ref.read(registrationInProgressProvider.notifier).start();
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      final user = credential?.user;
      if (user != null) {
        final repository = ref.read(userRepositoryProvider);
        final profile = await repository.getProfile(user.uid);
        if (profile == null) {
          await repository.createProfile(
            uid: user.uid,
            name: user.displayName ?? 'QuickServe customer',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
          );
        }
      }
      ref.read(registrationInProgressProvider.notifier).finish();
      if (mounted) setState(() => _isCreating = false);
    } catch (error) {
      ref.read(registrationInProgressProvider.notifier).finish();
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _errorMessage = error is AppException
            ? error.userMessage
            : 'Google sign-up was not completed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/splash'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const QuickServeBrandHeader(
                eyebrow: 'Join QuickServe',
                subtitle: 'Simple service help starts here.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: quickServeInputDecoration(
                          'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: _nameValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: quickServeInputDecoration(
                          'Email Address',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: quickServeInputDecoration(
                          'Phone Number',
                          icon: Icons.phone_outlined,
                          prefixText: '+91  ',
                        ),
                        validator: _phoneValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: quickServeInputDecoration(
                          'Password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
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
                        validator: _passwordValidator,
                        onChanged: (value) {
                          _updateRequirements(value);
                          if (_confirmKey.currentState?.value?.isNotEmpty ??
                              false) {
                            _confirmKey.currentState?.validate();
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              [
                                _hasValidLength,
                                _hasUppercase,
                                _hasLowercase,
                                _hasDigit,
                              ].where((item) => item).length /
                              4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PasswordRequirements(
                        hasValidLength: _hasValidLength,
                        hasUppercase: _hasUppercase,
                        hasLowercase: _hasLowercase,
                        hasDigit: _hasDigit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: _confirmKey,
                        controller: _confirmController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: quickServeInputDecoration(
                          'Confirm Password',
                          icon: Icons.lock_reset_outlined,
                          suffix: IconButton(
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
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                            activeColor: AppColors.primary,
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _isCreating ? null : _createAccount,
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign Up Now  →'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _RegisterDivider(),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _isCreating ? null : _registerWithGoogle,
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        label: const Text('Register with Google'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterDivider extends StatelessWidget {
  const _RegisterDivider();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'OR REGISTER WITH',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.mutedText, letterSpacing: 1),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
