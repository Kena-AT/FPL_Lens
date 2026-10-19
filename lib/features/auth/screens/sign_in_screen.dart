import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/disclosure_notice.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return email.isNotEmpty && emailRegex.hasMatch(email) && password.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final success = await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.isEmailVerified ?? false) {
        if (user?.hasSquad ?? false) {
          context.go('/home');
        } else {
          context.go('/onboarding/team');
        }
      } else {
        context.go('/auth/verify');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Scaffold for Google Sign-In button
    // In emulator / real device with Google Play Services, invokes GoogleSignIn().signIn()
    // For now, if mock or token provided:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In initiated...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isLocked = authState.status == AuthStatus.locked;
    final isFormValid = _isFormValid && !isLoading && !isLocked;

    String? lockoutText;
    if (isLocked && authState.lockoutSeconds != null) {
      final minutes = (authState.lockoutSeconds! / 60).ceil();
      lockoutText = "Too many attempts. Try again in $minutes minutes.";
    }

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTokens.space48),
                      // 1. Wordmark & Tagline
                      const Center(
                        child: Text(
                          'FPL Lens',
                          style: AppTextStyles.title,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Center(
                        child: Text(
                          'Your FPL squad, calculated on your phone.',
                          style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space32),

                      // 2. Form Fields
                      AppTextField(
                        label: 'Email',
                        hint: 'name@example.com',
                        controller: _emailController,
                        type: AppTextFieldType.email,
                        enabled: !isLoading && !isLocked,
                      ),
                      const SizedBox(height: AppTokens.space16),
                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        type: AppTextFieldType.password,
                        enabled: !isLoading && !isLocked,
                      ),
                      const SizedBox(height: AppTokens.space8),

                      // 3. Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: !isLoading && !isLocked
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Password reset instructions sent.")),
                                  );
                                }
                              : null,
                          child: Text(
                            'Forgot password?',
                            style: AppTextStyles.label.copyWith(color: AppTokens.neonPrimary),
                          ),
                        ),
                      ),

                      // Error or Lockout Banner
                      if (lockoutText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTokens.space12),
                          decoration: BoxDecoration(
                            color: AppTokens.statusOut.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                            border: Border.all(color: AppTokens.statusOut),
                          ),
                          child: Text(
                            lockoutText,
                            style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                      ] else if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTokens.space12),
                          decoration: BoxDecoration(
                            color: AppTokens.statusOut.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                            border: Border.all(color: AppTokens.statusOut),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                      ],

                      // 4. Sign in primary button
                      AppButton(
                        label: 'Sign in',
                        onPressed: isFormValid ? _handleSignIn : null,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppTokens.space16),

                      // 5. Divider with "or"
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
                            child: Text(
                              'or',
                              style: AppTextStyles.caption.copyWith(color: AppTokens.textDisabled),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space16),

                      // 6. Continue with Google
                      AppButton(
                        label: 'Continue with Google',
                        variant: AppButtonVariant.secondary,
                        onPressed: !isLoading && !isLocked ? _handleGoogleSignIn : null,
                        leading: const Icon(Icons.account_circle, size: 20.0, color: AppTokens.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.space12),

                      // 7. Create account tertiary
                      AppButton(
                        label: 'Create account',
                        variant: AppButtonVariant.tertiary,
                        onPressed: () => context.push('/auth/register'),
                      ),

                      const Spacer(),
                      const SizedBox(height: AppTokens.space16),

                      // 8. Disclaimer Notice
                      const DisclosureNotice(),
                      const SizedBox(height: AppTokens.space16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
