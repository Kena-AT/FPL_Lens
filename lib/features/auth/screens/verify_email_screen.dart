import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/code_input.dart';
import '../../../core/widgets/glass_container.dart';
import '../providers/auth_provider.dart';

/// Verify Email screen (/auth/verify) per Visual Redesign Design Document §8.4 & Sprint R3.
///
/// Features lock icon, title, email subtitle, 6-digit code boxes inside a glass card,
/// resend countdown, and sign-out option.
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
  String _enteredCode = '';

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
        if (mounted) setState(() => _expirySeconds = 0);
      } else {
        if (mounted) setState(() => _expirySeconds--);
      }
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
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
    setState(() {
      _hasError = false;
      _enteredCode = code;
    });

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
      if (mounted) {
        setState(() {
          _cooldownSeconds = 60;
          _hasError = false;
        });
        _startTimers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We sent a new code.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend code. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final user = authState.user;
    final maskedEmail = _maskEmail(user?.email);

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
              constraints: const BoxConstraints(maxWidth: 420.0),
              child: Column(
                children: [
                  // Lock icon in accent per §8.4
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: colors.accent,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),

                  // Title & Subtitle per §8.4 and §9.1
                  Text(
                    'Check your email',
                    style: AppTextStyles.title.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    'We sent a six-digit code to $maskedEmail.',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space24),

                  // Glass card holding CodeBoxes
                  GlassContainer(
                    blur: 20.0,
                    borderRadius: BorderRadius.circular(AppTokens.radiusModal),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space16,
                      vertical: AppTokens.space24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Six CodeBoxes (C16)
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: CodeInput(
                              onCompleted: _handleCodeCompleted,
                              hasError: _hasError,
                              enabled: !isLoading && _expirySeconds > 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),

                        // Timer text
                        Center(
                          child: Text(
                            _expirySeconds > 0
                                ? 'Code expires in ${_formatTime(_expirySeconds)}'
                                : 'Code expired. Tap Resend Code for a new one.',
                            style: AppTextStyles.caption.copyWith(
                              color: _expirySeconds > 0 ? colors.textDisabled : colors.statusError,
                            ),
                          ),
                        ),

                        // Error message
                        if (_hasError || authState.errorMessage != null) ...[
                          const SizedBox(height: AppTokens.space12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              authState.errorMessage ?? "That code isn't right. Check the email and try again.",
                              style: AppTextStyles.label.copyWith(
                                color: colors.statusError,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppTokens.space24),

                        // Verify button (C1)
                        AppButton(
                          label: 'Verify Code',
                          onPressed: _enteredCode.length == 6 && !isLoading && _expirySeconds > 0
                              ? () => _handleCodeCompleted(_enteredCode)
                              : null,
                          isLoading: isLoading,
                        ),

                        const SizedBox(height: AppTokens.space12),

                        // Resend Code (C2)
                        AppButton(
                          label: _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend Code',
                          variant: AppButtonVariant.secondary,
                          onPressed: _cooldownSeconds == 0 && !isLoading ? _handleResend : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTokens.space24),

                  // Sign out link (C4)
                  TextButton(
                    onPressed: !isLoading
                        ? () async {
                            await ref.read(authNotifierProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/auth');
                            }
                          }
                        : null,
                    child: Text(
                      'Sign out',
                      style: AppTextStyles.body.copyWith(
                        color: colors.textSecondary,
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
