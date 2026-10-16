import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/code_input.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _countdownTimer;
  Timer? _cooldownTimer;

  int _expirySeconds = 600; // 10 minutes
  int _cooldownSeconds = 60; // 60s cooldown

  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _cooldownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirySeconds <= 1) {
        timer.cancel();
        setState(() => _expirySeconds = 0);
      } else {
        setState(() => _expirySeconds--);
      }
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return 'your email';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return '$name***@$domain';
    }
    return '${name.substring(0, 2)}***@$domain';
  }

  Future<void> _handleCodeCompleted(String code) async {
    setState(() => _hasError = false);
    final success = await ref.read(authNotifierProvider.notifier).verifyEmail(code);

    if (success && mounted) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.hasSquad ?? false) {
        context.go('/home');
      } else {
        context.go('/onboarding/team');
      }
    } else if (mounted) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _handleResend() async {
    try {
      await ref.read(authNotifierProvider.notifier).resendVerificationCode();
      setState(() {
        _cooldownSeconds = 60;
        _expirySeconds = 600;
        _hasError = false;
      });
      _startTimers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new verification code has been sent.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend code. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isLoading = authState.status == AuthStatus.loading;
    final isExpired = _expirySeconds <= 0;

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: !isLoading
                ? () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/auth');
                  }
                : null,
            child: Text(
              'Sign out',
              style: AppTextStyles.label.copyWith(color: AppTokens.neonPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.space16),
              const Text('Check your email', style: AppTextStyles.title),
              const SizedBox(height: AppTokens.space8),
              Text(
                'We sent a six-digit code to ${_maskEmail(user?.email)}. It expires in 10 minutes.',
                style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: AppTokens.space32),

              // 6-digit CodeInput
              CodeInput(
                length: 6,
                enabled: !isLoading && !isExpired,
                hasError: _hasError,
                onCompleted: _handleCodeCompleted,
              ),
              const SizedBox(height: AppTokens.space24),

              // Expiry Countdown
              Center(
                child: Text(
                  isExpired
                      ? 'This code has expired.'
                      : 'The code expires in ${_formatTime(_expirySeconds)}.',
                  style: AppTextStyles.caption.copyWith(
                    color: isExpired ? AppTokens.statusOut : AppTokens.textDisabled,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space24),

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

              // Resend Code Button
              AppButton(
                label: _cooldownSeconds > 0
                    ? 'Resend in $_cooldownSeconds s'
                    : 'Resend code',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                onPressed: _cooldownSeconds == 0 && !isLoading ? _handleResend : null,
              ),
              const SizedBox(height: AppTokens.space16),
            ],
          ),
        ),
      ),
    );
  }
}
