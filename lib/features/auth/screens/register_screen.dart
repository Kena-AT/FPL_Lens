import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/team_id_field.dart';
import '../providers/auth_provider.dart';

/// Register screen (/auth/register) per Visual Redesign Design Document §8.3 & Sprint R3.
///
/// Features solid app bar, centered glass form card, email, display name, team ID,
/// password, terms checkbox, and register button.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _teamIdController = TextEditingController();

  int? _resolvedTeamId;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _displayNameController.addListener(() => setState(() {}));
    _teamIdController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();
    final parsedTeamId = _resolvedTeamId ?? int.tryParse(_teamIdController.text.trim());

    final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    final passwordValid = password.length >= 8;
    final nameValid = displayName.length >= 2 && displayName.length <= 32;
    final teamIdValid = parsedTeamId != null && parsedTeamId > 0;

    return emailValid && passwordValid && nameValid && teamIdValid && _termsAccepted;
  }

  Future<void> _handleRegister() async {
    final teamId = _resolvedTeamId ?? int.tryParse(_teamIdController.text.trim());
    if (!_isFormValid || teamId == null) return;

    final success = await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          fplTeamId: teamId,
        );

    if (success && mounted) {
      context.go('/auth/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    final email = _emailController.text.trim();
    final emailError = email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)
        ? 'Enter a valid email address.'
        : null;

    final password = _passwordController.text;
    final passwordError = password.isNotEmpty && password.length < 8
        ? 'Use at least 8 characters.'
        : null;

    final displayName = _displayNameController.text.trim();
    final nameError = displayName.isNotEmpty && (displayName.length < 2 || displayName.length > 32)
        ? 'Use 2 to 32 characters.'
        : null;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        title: Text(
          'Create account',
          style: AppTextStyles.title.copyWith(color: colors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go('/auth'),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420.0),
              child: GlassContainer(
                blur: 20.0,
                borderRadius: BorderRadius.circular(AppTokens.radiusModal),
                padding: const EdgeInsets.all(AppTokens.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    AppTextField(
                      label: 'Email',
                      hint: 'name@example.com',
                      controller: _emailController,
                      type: AppTextFieldType.email,
                      error: emailError,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppTokens.space16),

                    // Display Name
                    AppTextField(
                      label: 'Display name',
                      hint: 'Your name or handle',
                      controller: _displayNameController,
                      type: AppTextFieldType.standard,
                      error: nameError,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppTokens.space16),

                    // FPL Team ID
                    TeamIdField(
                      controller: _teamIdController,
                      onResolved: (id) => setState(() => _resolvedTeamId = id),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppTokens.space16),

                    // Password
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      type: AppTextFieldType.password,
                      error: passwordError,
                      helper: 'Must be at least 8 characters',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppTokens.space16),

                    // Terms checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: colors.accent,
                          checkColor: colors.accentOn,
                          onChanged: !isLoading
                              ? (val) => setState(() => _termsAccepted = val ?? false)
                              : null,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: !isLoading
                                ? () => setState(() => _termsAccepted = !_termsAccepted)
                                : null,
                            child: Text(
                              'I agree to the Terms and Privacy Policy',
                              style: AppTextStyles.label.copyWith(
                                color: colors.textSecondary,
                                fontSize: 13.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space24),

                    // Register button (C1)
                    AppButton(
                      label: 'Register',
                      onPressed: _isFormValid && !isLoading ? _handleRegister : null,
                      isLoading: isLoading,
                    ),

                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: AppTokens.space12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          authState.errorMessage!,
                          style: AppTextStyles.label.copyWith(
                            color: colors.statusError,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTokens.space16),

                    // Already have an account link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.body.copyWith(
                            color: colors.textSecondary,
                            fontSize: 13.0,
                          ),
                        ),
                        TextButton(
                          onPressed: !isLoading ? () => context.go('/auth') : null,
                          child: Text(
                            'Sign In',
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
            ),
          ),
        ),
      ),
    );
  }
}
