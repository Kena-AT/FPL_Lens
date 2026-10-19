import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/team_id_field.dart';
import '../providers/auth_provider.dart';

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
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Create account', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.space8),
              Text(
                'We need your FPL team ID to load your squad.',
                style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: AppTokens.space24),

              // 1. Email
              AppTextField(
                label: 'Email',
                hint: 'name@example.com',
                controller: _emailController,
                type: AppTextFieldType.email,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppTokens.space16),

              // 2. Password
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                type: AppTextFieldType.password,
                helper: _passwordController.text.isEmpty
                    ? 'At least 8 characters.'
                    : (_passwordController.text.length < 8
                        ? '${_passwordController.text.length}/8 characters (at least 8 required)'
                        : 'Password length requirement met (${_passwordController.text.length} characters)'),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppTokens.space16),

              // 3. Display name
              AppTextField(
                label: 'Display name',
                hint: 'Manager Name',
                controller: _displayNameController,
                helper: 'Use 2 to 32 characters.',
                maxLength: 32,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppTokens.space16),

              // 4. Team ID
              TeamIdField(
                controller: _teamIdController,
                enabled: !isLoading,
                onResolved: (id) => setState(() => _resolvedTeamId = id),
              ),
              const SizedBox(height: AppTokens.space16),

              // 5. Terms & Privacy Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    activeColor: AppTokens.goldPrimary,
                    checkColor: AppTokens.bgBase,
                    onChanged: isLoading
                        ? null
                        : (val) => setState(() => _termsAccepted = val ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => setState(() => _termsAccepted = !_termsAccepted),
                      child: Text(
                        'I agree to the Terms and Privacy Policy',
                        style: AppTextStyles.body.copyWith(fontSize: 14.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space16),

              if (authState.errorMessage != null) ...[
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

              // 6. Submit Button
              AppButton(
                label: 'Create account',
                onPressed: _isFormValid && !isLoading ? _handleRegister : null,
                isLoading: isLoading,
              ),
              const SizedBox(height: AppTokens.space12),

              // 7. Already have an account
              AppButton(
                label: 'Already have an account? Sign in',
                variant: AppButtonVariant.tertiary,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: AppTokens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
