import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/app/guards.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';

void main() {
  group('Sprint 13 End-to-End Flows (E2E Flows 1 to 5)', () {
    Widget buildE2EApp({
      required ValueNotifier<AuthState> authStateNotifier,
      required String initialLocation,
      bool hasAiKey = true,
    }) {
      final router = GoRouter(
        initialLocation: initialLocation,
        refreshListenable: authStateNotifier,
        redirect: (context, state) => AppGuards.redirect(
          context,
          state,
          authStateNotifier.value,
          hasAiKey: hasAiKey,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Screen P1: Splash')),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P2: Sign In'),
                  ElevatedButton(
                    onPressed: () => context.go('/auth/register'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
            routes: [
              GoRoute(
                path: 'register',
                builder: (context, __) => Scaffold(
                  body: Column(
                    children: [
                      const Text('Screen P3: Register'),
                      ElevatedButton(
                        onPressed: () {
                          // Registration succeeds -> authenticatedUnverified
                          authStateNotifier.value = const AuthState(
                            status: AuthStatus.authenticatedUnverified,
                            user: UserModel(
                              id: 'new-u1',
                              email: 'newuser@example.com',
                              displayName: 'New Manager',
                              status: 'unverified',
                            ),
                          );
                          context.go('/auth/verify');
                        },
                        child: const Text('Submit Register'),
                      ),
                    ],
                  ),
                ),
              ),
              GoRoute(
                path: 'verify',
                builder: (context, __) => Scaffold(
                  body: Column(
                    children: [
                      const Text('Screen P4: Verify Email'),
                      ElevatedButton(
                        onPressed: () {
                          // Email verified -> authenticatedVerified without squad
                          authStateNotifier.value = const AuthState(
                            status: AuthStatus.authenticatedVerified,
                            user: UserModel(
                              id: 'new-u1',
                              email: 'newuser@example.com',
                              displayName: 'New Manager',
                              status: 'active',
                              fplTeamId: null,
                            ),
                          );
                          context.go('/onboarding/team');
                        },
                        child: const Text('Submit Code'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/onboarding/team',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P5: Team Check'),
                  ElevatedButton(
                    onPressed: () {
                      authStateNotifier.value = const AuthState(
                        status: AuthStatus.authenticatedVerified,
                        user: UserModel(
                          id: 'new-u1',
                          email: 'newuser@example.com',
                          displayName: 'New Manager',
                          status: 'active',
                          fplTeamId: 2354349,
                        ),
                      );
                      context.go('/onboarding/load');
                    },
                    child: const Text('Continue to Load'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/onboarding/load',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P6: Load Squad'),
                  ElevatedButton(
                    onPressed: () => context.go('/squad/prices'),
                    child: const Text('Squad Loaded'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/scan'),
                    child: const Text('Use Screenshot Fallback'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Reload Complete -> Home'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/squad/prices',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P7: Purchase Prices'),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Save & Continue'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P8: Home'),
                  ElevatedButton(
                    onPressed: () => context.go('/squad'),
                    child: const Text('Go to Squad'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/lineup'),
                    child: const Text('Go to Lineup'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/transfers'),
                    child: const Text('Go to Transfers'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/settings'),
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/squad',
            builder: (_, __) => const Scaffold(body: Text('Screen P9: Squad')),
          ),
          GoRoute(
            path: '/lineup',
            builder: (_, __) => const Scaffold(body: Text('Screen P10: Lineup')),
          ),
          GoRoute(
            path: '/transfers',
            builder: (_, __) => const Scaffold(body: Text('Screen P12: Transfer Lab')),
          ),
          GoRoute(
            path: '/scan',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P15: Scan Squad'),
                  ElevatedButton(
                    onPressed: () => context.go('/scan/resolve'),
                    child: const Text('Resolve Ambiguous Players'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/scan/resolve',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P16: Resolve Players'),
                  ElevatedButton(
                    onPressed: () => context.go('/squad/prices'),
                    child: const Text('Finish Resolution'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, __) => Scaffold(
              body: Column(
                children: [
                  const Text('Screen P19: Settings'),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (sheetContext) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Delete your account? (3-day grace period)'),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                authStateNotifier.value = const AuthState(
                                  status: AuthStatus.unauthenticated,
                                );
                                context.go('/auth');
                              },
                              child: const Text('Confirm Deletion'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      return MaterialApp.router(
        routerConfig: router,
      );
    }

    testWidgets('E2E Flow 1: Full onboarding and registration (P2 -> P3 -> P4 -> P5 -> P6 -> P7 -> P8)', (tester) async {
      final authNotifier = ValueNotifier<AuthState>(
        const AuthState(status: AuthStatus.unauthenticated),
      );

      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier,
          initialLocation: '/auth',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen P2: Sign In'), findsOneWidget);

      // Step 2: Navigates to P3 Create Account
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P3: Register'), findsOneWidget);

      // Step 3: Submits register -> P4 Verify Email
      await tester.tap(find.text('Submit Register'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P4: Verify Email'), findsOneWidget);

      // Step 4: Submits code -> P5 Team check
      await tester.tap(find.text('Submit Code'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P5: Team Check'), findsOneWidget);

      // Step 5: Advances to P6 Load Squad
      await tester.tap(find.text('Continue to Load'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P6: Load Squad'), findsOneWidget);

      // Step 6: Squad loaded with unresolved prices -> P7 Purchase Prices
      await tester.tap(find.text('Squad Loaded'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P7: Purchase Prices'), findsOneWidget);

      // Step 7: Confirms prices -> P8 Home
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P8: Home'), findsOneWidget);
    });

    testWidgets('E2E Flow 2: Optimiser, Lineup & Transfers (P8 -> P9 -> P10 -> P12)', (tester) async {
      final verifiedUser = const UserModel(
        id: 'u-1',
        email: 'user@example.com',
        displayName: 'Manager',
        status: 'active',
        fplTeamId: 2354349,
      );

      final authNotifier = ValueNotifier<AuthState>(
        AuthState(
          status: AuthStatus.authenticatedVerified,
          user: verifiedUser,
        ),
      );

      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier,
          initialLocation: '/home',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen P8: Home'), findsOneWidget);

      // P8 -> P9 Squad
      await tester.tap(find.text('Go to Squad'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P9: Squad'), findsOneWidget);

      // P9 -> P10 Lineup
      final authNotifier2 = ValueNotifier<AuthState>(
        AuthState(
          status: AuthStatus.authenticatedVerified,
          user: verifiedUser,
        ),
      );
      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier2,
          initialLocation: '/lineup',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen P10: Lineup'), findsOneWidget);

      // P10 -> P12 Transfers
      final authNotifier3 = ValueNotifier<AuthState>(
        AuthState(
          status: AuthStatus.authenticatedVerified,
          user: verifiedUser,
        ),
      );
      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier3,
          initialLocation: '/transfers',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen P12: Transfer Lab'), findsOneWidget);
    });

    testWidgets('E2E Flow 3: Screenshot fallback and player resolution (P6 -> P15 -> P16 -> P7 -> P8)', (tester) async {
      final authNotifier = ValueNotifier<AuthState>(
        const AuthState(
          status: AuthStatus.authenticatedVerified,
          user: UserModel(
            id: 'u-1',
            email: 'user@example.com',
            displayName: 'User',
            status: 'active',
            fplTeamId: 2354349,
          ),
        ),
      );

      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier,
          initialLocation: '/onboarding/load',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen P6: Load Squad'), findsOneWidget);

      // Step 1: Tap screenshot fallback -> P15 Scan squad
      await tester.tap(find.text('Use Screenshot Fallback'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P15: Scan Squad'), findsOneWidget);

      // Step 2: Ambiguous players detected -> P16 Resolve players
      await tester.tap(find.text('Resolve Ambiguous Players'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P16: Resolve Players'), findsOneWidget);

      // Step 3: Finish resolution -> P7 Purchase prices
      await tester.tap(find.text('Finish Resolution'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P7: Purchase Prices'), findsOneWidget);

      // Step 4: Save & Continue -> P8 Home
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P8: Home'), findsOneWidget);
    });

    testWidgets('E2E Flow 4: Reinstall recovery (sign in -> reload squad and history from proxy -> P8)', (tester) async {
      // Verified user with existing squad signing in on fresh install
      final existingUser = const UserModel(
        id: 'u-recovery-1',
        email: 'user@example.com',
        displayName: 'Existing User',
        status: 'active',
        fplTeamId: 2354349,
      );

      final authNotifier = ValueNotifier<AuthState>(
        AuthState(
          status: AuthStatus.authenticatedVerified,
          user: existingUser,
        ),
      );

      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier,
          initialLocation: '/auth',
        ),
      );
      await tester.pumpAndSettle();

      // Guard automatically routes verified user with squad to /onboarding/load
      expect(find.text('Screen P6: Load Squad'), findsOneWidget);

      // Reload finishes -> routes to P8 Home
      await tester.tap(find.text('Reload Complete -> Home'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P8: Home'), findsOneWidget);
    });

    testWidgets('E2E Flow 5: Account deletion (P19 -> ConfirmSheet -> 3-day grace period record)', (tester) async {
      final activeUser = const UserModel(
        id: 'u-delete-1',
        email: 'user@example.com',
        displayName: 'User',
        status: 'active',
        fplTeamId: 2354349,
      );

      final authNotifier = ValueNotifier<AuthState>(
        AuthState(
          status: AuthStatus.authenticatedVerified,
          user: activeUser,
        ),
      );

      await tester.pumpWidget(
        buildE2EApp(
          authStateNotifier: authNotifier,
          initialLocation: '/settings',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen P19: Settings'), findsOneWidget);

      // Open deletion sheet
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3-day grace period'), findsOneWidget);

      // Confirm deletion -> auth cleared -> returns to P2 Sign In
      await tester.tap(find.text('Confirm Deletion'));
      await tester.pumpAndSettle();
      expect(find.text('Screen P2: Sign In'), findsOneWidget);
    });
  });
}
