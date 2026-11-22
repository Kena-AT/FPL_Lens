import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../providers/auth_provider.dart';

/// Splash screen (/) per Visual Redesign Design Document §8.1 & Sprint R3.
///
/// Features centered wordmark, 2dp accent underline, version and disclaimer,
/// with 400ms session transition.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  bool _showProgress = false;
  Timer? _progressTimer;
  Timer? _timeoutTimer;
  late AnimationController _lineController;
  late Animation<double> _lineWidthAnimation;

  @override
  void initState() {
    super.initState();

    _lineController = AnimationController(
      vsync: this,
      duration: AppTokens.motionReveal, // 280ms per §8.1
    );

    _lineWidthAnimation = Tween<double>(begin: 0.0, end: 120.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeOutCubic),
    );

    _lineController.forward();

    // Show progress indicator after 500 ms only if network verification is needed per §8.1
    _progressTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showProgress = true);
    });

    // Max wait on splash: 3 seconds
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        if (ref.read(authNotifierProvider).status == AuthStatus.loading) {
          ref.read(authNotifierProvider.notifier).resetToUnauthenticated();
        }
        _routeNext();
      }
    });

    // Check session
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authNotifierProvider.notifier).checkSession();
      if (mounted) {
        _routeNext();
      }
    });
  }

  void _routeNext() {
    if (!mounted) return;
    _timeoutTimer?.cancel();
    _progressTimer?.cancel();

    final currentStatus = ref.read(authNotifierProvider).status;
    if (currentStatus == AuthStatus.loading) {
      ref.read(authNotifierProvider.notifier).resetToUnauthenticated();
    }

    final authState = ref.read(authNotifierProvider);

    switch (authState.status) {
      case AuthStatus.authenticatedVerified:
        if (authState.user?.hasSquad ?? false) {
          context.go('/home');
        } else {
          context.go('/onboarding/team');
        }
        break;
      case AuthStatus.authenticatedUnverified:
        context.go('/auth/verify');
        break;
      case AuthStatus.unauthenticated:
      default:
        context.go('/auth');
        break;
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    _progressTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            // Centered Wordmark
            Semantics(
              header: true,
              child: Text(
                'FPL Lens',
                style: AppTextStyles.display.copyWith(
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space8),

            // 2dp accent line under wordmark (280ms animation per §8.1)
            AnimatedBuilder(
              animation: _lineWidthAnimation,
              builder: (context, _) => Container(
                height: 2.0,
                width: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
                    ? 120.0
                    : _lineWidthAnimation.value,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space24),

            // Progress indicator after 500ms
            SizedBox(
              height: 2.0,
              width: 120.0,
              child: _showProgress
                  ? LinearProgressIndicator(
                      value: (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ? 0.75 : null,
                      backgroundColor: colors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    )
                  : const SizedBox.shrink(),
            ),

            const Spacer(flex: 3),

            // Version and subtle non-affiliation note per §8.1
            Text(
              'v1.5.0',
              style: AppTextStyles.caption.copyWith(color: colors.textDisabled),
            ),
            const SizedBox(height: AppTokens.space4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space32),
              child: Text(
                'Independent analytics for Fantasy Premier League.',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textDisabled,
                  fontSize: 11.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTokens.space16),
          ],
        ),
      ),
    );
  }
}
