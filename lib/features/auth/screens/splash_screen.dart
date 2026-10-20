import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showProgress = false;
  Timer? _progressTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Show progress indicator after 500 ms per P1 spec
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
    _progressTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'FPL Lens',
                style: AppTextStyles.display,
              ),
            ),
            const SizedBox(height: AppTokens.space24),
            SizedBox(
              height: 2.0,
              width: 120.0,
              child: _showProgress
                  ? const LinearProgressIndicator(
                      backgroundColor: AppTokens.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTokens.goldPrimary),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
