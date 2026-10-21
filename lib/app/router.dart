import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/home/screens/home_shell_screen.dart';
import '../features/onboarding/screens/load_squad_screen.dart';
import '../features/onboarding/screens/team_check_screen.dart';
import '../features/lineup/screens/heatmap_screen.dart';
import '../features/player/screens/player_detail_screen.dart';
import '../features/settings/screens/notifications_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/squad/screens/purchase_prices_screen.dart';
import 'guards.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      return AppGuards.redirect(context, state, authState);
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'verify',
            name: 'verify',
            builder: (context, state) => const VerifyEmailScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/team',
        name: 'teamCheck',
        builder: (context, state) => const TeamCheckScreen(),
      ),
      GoRoute(
        path: '/onboarding/load',
        name: 'loadSquad',
        builder: (context, state) {
          final teamId = (state.extra as int?) ?? 0;
          return LoadSquadScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/squad/prices',
        name: 'purchasePrices',
        builder: (context, state) => const PurchasePricesScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeShellScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/squad',
        name: 'squad',
        builder: (context, state) => const HomeShellScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/lineup',
        name: 'lineup',
        builder: (context, state) => const HomeShellScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/transfers',
        name: 'transfers',
        builder: (context, state) => const HomeShellScreen(initialIndex: 3),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/player/:fplId',
        name: 'playerDetail',
        builder: (context, state) {
          final fplId = int.tryParse(state.pathParameters['fplId'] ?? '') ?? 0;
          final gw = int.tryParse(state.uri.queryParameters['gw'] ?? '');
          return PlayerDetailScreen(fplId: fplId, gameweek: gw);
        },
      ),
      GoRoute(
        path: '/heatmap',
        name: 'heatmap',
        builder: (context, state) => const HeatmapScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});
