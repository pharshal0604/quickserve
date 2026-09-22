import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart' as shared;

import 'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:quickserve_mobile/config/theme/app_colors.dart';
import 'package:quickserve_mobile/config/theme/app_spacing.dart';
import 'package:quickserve_mobile/core/error/app_exceptions.dart';
import 'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.isAgentLogin = false});

  final bool isAgentLogin;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String get _accountType => widget.isAgentLogin ? 'Agent' : 'User';

  shared.UserRole get _expectedRole =>
      widget.isAgentLogin ? shared.UserRole.agent : shared.UserRole.customer;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final result = shared.validateEmail(value ?? '');
    return result.isValid ? null : result.reason;
  }

  Future<void> _validateSignedInRole(String uid) async {
    final profile = await ref.read(userRepositoryProvider).getProfile(uid);
    if (profile?.role != _expectedRole) {
      await ref.read(authRepositoryProvider).signOut();
      throw AuthException(
        'wrong_role',
        'This account is not registered as a $_accountType account.',
      );
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'missing_user',
          'We could not load your account.',
        );
      }
      await _validateSignedInRole(user.uid);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is AppException
            ? error.userMessage
            : 'We could not sign you in. Please try again.';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      final user = credential?.user;
      if (user != null) {
        final repository = ref.read(userRepositoryProvider);
        final profile = await repository.getProfile(user.uid);
        if (profile == null) {
          if (widget.isAgentLogin) {
            throw const AuthException(
              'missing_agent_profile',
              'This Google account is not registered as a QuickServe agent.',
            );
          }
          await repository.createProfile(
            uid: user.uid,
            name: user.displayName ?? 'QuickServe customer',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
          );
        }
        await _validateSignedInRole(user.uid);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is AppException
            ? error.userMessage
            : 'Google sign-in was not completed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: const BackButton()),
              QuickServeBrandHeader(
                eyebrow: 'QuickServe',
                subtitle: widget.isAgentLogin
                    ? 'Sign in to manage assigned service requests.'
                    : 'Sign in to manage your service requests.',
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  width > 600 ? width * .18 : AppSpacing.xl,
                  AppSpacing.xl,
                  width > 600 ? width * .18 : AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$_accountType Login',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isAgentLogin
                            ? 'Access requests assigned to you.'
                            : 'Sign in to manage your service requests',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: quickServeInputDecoration(
                          'Email Address',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        decoration: quickServeInputDecoration(
                          'Password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null,
                        onFieldSubmitted: (_) => _isLoading ? null : _signIn(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          const Text('Remember me'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/password-reset'),
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ErrorBanner(message: _errorMessage!),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                              )
                            : Text('Sign In as $_accountType'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _DividerLabel(label: 'OR CONTINUE WITH'),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const _GoogleMark(),
                        label: const Text('Continue with Google'),
                      ),
                      if (!widget.isAgentLogin) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(color: AppColors.mutedText),
                              ),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                child: const Text('Create Account'),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.mutedText, letterSpacing: 1),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: Center(
      child: Text(
        'G',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.googleBlue,
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  );
}
