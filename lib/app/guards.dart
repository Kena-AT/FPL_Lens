import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';

abstract final class AppGuards {
  static String? redirect(
    BuildContext context,
    GoRouterState state,
    AuthState authState, {
    bool hasAiKey = false,
  }) {
    final location = state.uri.path;

    final isSplash = location == '/';
    final isAuth = location == '/auth';
    final isRegister = location == '/auth/register';
    final isVerify = location == '/auth/verify';

    // While on splash screen, splash screen handles its own routing after timeout
    if (isSplash) return null;

    // 1. Unauthenticated users:
    if (authState.status == AuthStatus.unauthenticated ||
        authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.locked) {
      if (isAuth || isRegister) return null;
      return '/auth';
    }

    // 2. Authenticated but unverified users:
    if (authState.status == AuthStatus.authenticatedUnverified) {
      if (isVerify) return null;
      return '/auth/verify';
    }

    // 3. Authenticated and verified users:
    if (authState.status == AuthStatus.authenticatedVerified) {
      final hasSquad = authState.user?.hasSquad ?? false;
      if (isAuth || isRegister || isVerify) {
        return hasSquad ? '/onboarding/load' : '/onboarding/team';
      }

      // 6. AI key: /scan with no stored key goes to /settings/ai?next=/scan per §B6
      if (location == '/scan' && !hasAiKey) {
        return '/settings/ai?next=/scan';
      }

      final isOnboarding = location.startsWith('/onboarding');
      final isSettings = location.startsWith('/settings');
      final isScan = location.startsWith('/scan');
      if (!hasSquad && !isOnboarding && !isSettings && !isScan) {
        return '/onboarding/team';
      }
    }

    return null;
  }
}
