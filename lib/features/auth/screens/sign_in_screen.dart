import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/disclosure_notice.dart';
import '../../../core/widgets/glass_container.dart';
import '../providers/auth_provider.dart';

/// Sign In screen (/auth) per Visual Redesign Design Document §8.2 & Sprint R3.
///
/// Features centered glass form card, email/password fields, official Google Sign-in button,
/// lockout banner, and verbatim legal non-affiliation disclaimer.
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
          context.go('/onboarding/load', extra: user!.fplTeamId);
        } else {
          context.go('/onboarding/team');
        }
      } else {
        context.go('/auth/verify');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In initiated...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isLocked = authState.status == AuthStatus.locked;
    final isFormValid = _isFormValid && !isLoading && !isLocked;

    String? lockoutText;
    if (isLocked) {
      if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) {
        lockoutText = authState.errorMessage;
      } else if (authState.lockoutSeconds != null) {
        final m = authState.lockoutSeconds! ~/ 60;
        final s = authState.lockoutSeconds! % 60;
        final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        lockoutText = "Too many attempts. Try again in $timeStr.";
      }
    }

    final inlineError = lockoutText ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Above card: Wordmark and Subtitle per §8.2
                  Text(
                    'FPL Lens',
                    style: AppTextStyles.display.copyWith(
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    'Deterministic Fantasy Premier League Intelligence',
                    style: AppTextStyles.subtitle.copyWith(
                      color: colors.textSecondary,
                      fontSize: 14.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space24),

                  // 2. Centered Glass Card per §8.2
                  GlassContainer(
                    blur: 20.0,
                    borderRadius: BorderRadius.circular(AppTokens.radiusModal),
                    padding: const EdgeInsets.all(AppTokens.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Lockout Banner inside card if active
                        if (isLocked && lockoutText != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppTokens.space12),
                            decoration: BoxDecoration(
                              color: colors.statusWarn.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusBase),
                              border: Border.all(color: colors.statusWarn),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, color: colors.statusWarn, size: 20),
                                const SizedBox(width: AppTokens.space8),
                                Expanded(
                                  child: Text(
                                    lockoutText,
                                    style: AppTextStyles.label.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.space16),
                        ],

                        // Email Field
                        AppTextField(
                          label: 'Email',
                          hint: 'name@example.com',
                          controller: _emailController,
                          type: AppTextFieldType.email,
                          enabled: !isLoading && !isLocked,
                        ),
                        const SizedBox(height: AppTokens.space16),

                        // Password Field
                        AppTextField(
                          label: 'Password',
                          controller: _passwordController,
                          type: AppTextFieldType.password,
                          enabled: !isLoading && !isLocked,
                        ),
                        const SizedBox(height: AppTokens.space8),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: !isLoading && !isLocked
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset instructions sent.'),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(
                              'Forgot password?',
                              style: AppTextStyles.label.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.space8),

                        // Sign in primary button (C1)
                        AppButton(
                          label: 'Sign in',
                          onPressed: isFormValid ? _handleSignIn : null,
                          isLoading: isLoading,
                        ),

                        // Inline error message
                        if (inlineError != null && !isLocked) ...[
                          const SizedBox(height: AppTokens.space12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              inlineError,
                              style: AppTextStyles.label.copyWith(
                                color: colors.statusError,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppTokens.space16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: colors.borderSubtle)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
                              child: Text(
                                'or',
                                style: AppTextStyles.caption.copyWith(color: colors.textDisabled),
                              ),
                            ),
                            Expanded(child: Divider(color: colors.borderSubtle)),
                          ],
                        ),

                        const SizedBox(height: AppTokens.space16),

                        // Google Sign In (C2)
                        AppButton(
                          label: 'Continue with Google',
                          variant: AppButtonVariant.secondary,
                          leading: const Icon(Icons.g_mobiledata_rounded, size: 28),
                          onPressed: !isLoading && !isLocked ? _handleGoogleSignIn : null,
                        ),

                        const SizedBox(height: AppTokens.space16),

                        // Sign up link (C4)
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTextStyles.body.copyWith(
                                color: colors.textSecondary,
                                fontSize: 13.0,
                              ),
                            ),
                            TextButton(
                              onPressed: !isLoading ? () => context.go('/auth/register') : null,
                              child: Text(
                                'Sign Up',
                                style: AppTextStyles.body.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTokens.space24),

                  // 3. Verbatim Non-affiliation Disclaimer below card (§9.7)
                  const DisclosureNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
