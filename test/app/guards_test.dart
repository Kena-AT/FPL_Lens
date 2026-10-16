import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/app/guards.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';

void main() {
  group('AppGuards.redirect', () {
    Widget buildRouterApp({
      required AuthState authState,
      required String initialLocation,
    }) {
      final router = GoRouter(
        initialLocation: initialLocation,
        redirect: (context, state) => AppGuards.redirect(context, state, authState),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('Screen: Splash')),
          GoRoute(path: '/auth', builder: (_, __) => const Text('Screen: Auth')),
          GoRoute(path: '/auth/register', builder: (_, __) => const Text('Screen: Register')),
          GoRoute(path: '/auth/verify', builder: (_, __) => const Text('Screen: Verify')),
          GoRoute(path: '/onboarding/team', builder: (_, __) => const Text('Screen: TeamCheck')),
          GoRoute(path: '/home', builder: (_, __) => const Text('Screen: Home')),
        ],
      );

      return MaterialApp.router(
        routerConfig: router,
      );
    }

    testWidgets('Splash screen stays on / without redirect', (tester) async {
      await tester.pumpWidget(
        buildRouterApp(
          authState: const AuthState(status: AuthStatus.unauthenticated),
          initialLocation: '/',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen: Splash'), findsOneWidget);
    });

    testWidgets('Unauthenticated user is redirected to /auth from /home', (tester) async {
      await tester.pumpWidget(
        buildRouterApp(
          authState: const AuthState(status: AuthStatus.unauthenticated),
          initialLocation: '/home',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen: Auth'), findsOneWidget);
    });

    testWidgets('Unauthenticated user can access /auth and /auth/register', (tester) async {
      await tester.pumpWidget(
        buildRouterApp(
          authState: const AuthState(status: AuthStatus.unauthenticated),
          initialLocation: '/auth/register',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen: Register'), findsOneWidget);
    });

    testWidgets('Authenticated unverified user is redirected to /auth/verify', (tester) async {
      await tester.pumpWidget(
        buildRouterApp(
          authState: const AuthState(
            status: AuthStatus.authenticatedUnverified,
            user: UserModel(
              id: 'user-1',
              email: 'test@example.com',
              displayName: 'Test',
              status: 'unverified',
            ),
          ),
          initialLocation: '/home',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen: Verify'), findsOneWidget);
    });

    testWidgets('Authenticated verified user without squad is redirected to /onboarding/team', (tester) async {
      await tester.pumpWidget(
        buildRouterApp(
          authState: const AuthState(
            status: AuthStatus.authenticatedVerified,
            user: UserModel(
              id: 'user-1',
              email: 'test@example.com',
              displayName: 'Test',
              status: 'active',
              fplTeamId: null,
            ),
          ),
          initialLocation: '/auth',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen: TeamCheck'), findsOneWidget);
    });

    testWidgets('Authenticated verified user with squad reaches /home', (tester) async {
      await tester.pumpWidget(
        buildRouterApp(
          authState: const AuthState(
            status: AuthStatus.authenticatedVerified,
            user: UserModel(
              id: 'user-1',
              email: 'test@example.com',
              displayName: 'Test',
              status: 'active',
              fplTeamId: 123456,
            ),
          ),
          initialLocation: '/home',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen: Home'), findsOneWidget);
    });
  });
}
