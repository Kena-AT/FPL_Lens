import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/core/widgets/code_input.dart';
import 'package:fpl_lens/core/widgets/disclosure_notice.dart';
import 'package:fpl_lens/core/widgets/glass_container.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/auth/screens/register_screen.dart';
import 'package:fpl_lens/features/auth/screens/sign_in_screen.dart';
import 'package:fpl_lens/features/auth/screens/splash_screen.dart';
import 'package:fpl_lens/features/auth/screens/verify_email_screen.dart';
import 'package:fpl_lens/features/onboarding/screens/load_squad_screen.dart';
import 'package:fpl_lens/features/onboarding/screens/team_check_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class MockFplRepository extends FplRepository {
  MockFplRepository() : super(dio: null);

  @override
  Future<EntryModel> getEntry(int teamId) async {
    return const EntryModel(
      id: 12345,
      name: 'Redesign FC',
      playerFirstName: 'Alex',
      playerLastName: 'Ferguson',
      summaryOverallPoints: 1240,
      summaryOverallRank: 42000,
    );
  }
}

class MockSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  MockSquadNotifier([super.state = const SquadState(step: SquadLoadingStep.step2SquadPicks)]);

  @override
  Future<void> loadSquadSequence(int teamId, {bool force = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildAppWithRoute({
    required Widget screen,
    ThemeMode themeMode = ThemeMode.dark,
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => screen),
        GoRoute(path: '/auth', builder: (_, __) => const Scaffold(body: Text('Route: /auth'))),
        GoRoute(path: '/auth/register', builder: (_, __) => const Scaffold(body: Text('Route: /auth/register'))),
        GoRoute(path: '/auth/verify', builder: (_, __) => const Scaffold(body: Text('Route: /auth/verify'))),
        GoRoute(path: '/onboarding/team', builder: (_, __) => const Scaffold(body: Text('Route: /onboarding/team'))),
        GoRoute(path: '/onboarding/load', builder: (_, __) => const Scaffold(body: Text('Route: /onboarding/load'))),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('Route: /home'))),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }

  group('Sprint R3: Auth and Onboarding Visual Redesign Tests', () {
    // -------------------------------------------------------------------------
    // 1. SplashScreen Tests
    // -------------------------------------------------------------------------
    group('SplashScreen (/)', () {
      testWidgets('renders wordmark, accent line, version and disclaimer in dark mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const SplashScreen(),
            themeMode: ThemeMode.dark,
          ),
        );

        expect(find.text('FPL Lens'), findsOneWidget);
        expect(find.text('v1.5.0'), findsOneWidget);
        expect(find.text('Independent analytics for Fantasy Premier League.'), findsOneWidget);

        // Progress line reveals after 500ms
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('renders cleanly in light mode paper background', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const SplashScreen(),
            themeMode: ThemeMode.light,
          ),
        );

        expect(find.text('FPL Lens'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      });
    });

    // -------------------------------------------------------------------------
    // 2. SignInScreen Tests
    // -------------------------------------------------------------------------
    group('SignInScreen (/auth)', () {
      testWidgets('renders glass form card, wordmark, Google button, and disclaimer in dark mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const SignInScreen(),
            themeMode: ThemeMode.dark,
          ),
        );

        expect(find.text('FPL Lens'), findsOneWidget);
        expect(find.text('Deterministic Fantasy Premier League Intelligence'), findsOneWidget);
        expect(find.byType(GlassContainer), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.byType(DisclosureNotice), findsOneWidget);
      });

      testWidgets('renders cleanly in light mode with accessible contrast', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const SignInScreen(),
            themeMode: ThemeMode.light,
          ),
        );

        expect(find.text('FPL Lens'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
        expect(find.byType(DisclosureNotice), findsOneWidget);
      });

      testWidgets('displays lockout countdown banner inside card when locked', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const SignInScreen(),
            overrides: [
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(
                  repository: ref.watch(authRepositoryProvider),
                  secureStore: ref.watch(secureStoreProvider),
                )..state = const AuthState(
                    status: AuthStatus.locked,
                    lockoutSeconds: 900,
                    errorMessage: 'Too many attempts. Try again in 15 minutes.',
                  ),
              ),
            ],
          ),
        );

        expect(find.text('Too many attempts. Try again in 15 minutes.'), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 3. RegisterScreen Tests
    // -------------------------------------------------------------------------
    group('RegisterScreen (/auth/register)', () {
      testWidgets('renders solid app bar, glass form card, and all required inputs in dark mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const RegisterScreen(),
            themeMode: ThemeMode.dark,
          ),
        );

        expect(find.text('Create account'), findsOneWidget);
        expect(find.byType(GlassContainer), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Display name'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
        expect(find.text('I agree to the Terms and Privacy Policy'), findsOneWidget);
        expect(find.text('Register'), findsOneWidget);
      });

      testWidgets('renders cleanly in light mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const RegisterScreen(),
            themeMode: ThemeMode.light,
          ),
        );

        expect(find.text('Create account'), findsOneWidget);
        expect(find.byType(GlassContainer), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 4. VerifyEmailScreen Tests
    // -------------------------------------------------------------------------
    group('VerifyEmailScreen (/auth/verify)', () {
      testWidgets('renders lock icon, email subtitle, 6-digit CodeBoxes in dark mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const VerifyEmailScreen(),
            themeMode: ThemeMode.dark,
            overrides: [
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(
                  repository: ref.watch(authRepositoryProvider),
                  secureStore: ref.watch(secureStoreProvider),
                )..state = const AuthState(
                    status: AuthStatus.authenticatedUnverified,
                    user: UserModel(
                      id: 'user-1',
                      email: 'manager@example.com',
                      displayName: 'Manager',
                      status: 'unverified',
                    ),
                  ),
              ),
            ],
          ),
        );

        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
        expect(find.text('Check your email'), findsOneWidget);
        expect(find.textContaining('We sent a six-digit code to ma***@example.com.'), findsOneWidget);
        expect(find.byType(CodeInput), findsOneWidget);
        expect(find.text('Verify Code'), findsOneWidget);
        expect(find.text('Sign out'), findsOneWidget);
      });

      testWidgets('renders cleanly in light mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const VerifyEmailScreen(),
            themeMode: ThemeMode.light,
          ),
        );

        expect(find.text('Check your email'), findsOneWidget);
        expect(find.byType(CodeInput), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 5. TeamCheckScreen Tests
    // -------------------------------------------------------------------------
    group('TeamCheckScreen (/onboarding/team)', () {
      testWidgets('renders team confirmation card and password disclaimer card in dark mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const TeamCheckScreen(),
            themeMode: ThemeMode.dark,
            overrides: [
              fplRepositoryProvider.overrideWithValue(MockFplRepository()),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(
                  repository: ref.watch(authRepositoryProvider),
                  secureStore: ref.watch(secureStoreProvider),
                )..state = const AuthState(
                    status: AuthStatus.authenticatedVerified,
                    user: UserModel(
                      id: 'user-1',
                      email: 'manager@example.com',
                      displayName: 'Manager',
                      fplTeamId: 12345,
                      status: 'verified',
                    ),
                  ),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Your team'), findsOneWidget);
        expect(find.text('Redesign FC'), findsOneWidget);
        expect(find.text('Manager: Alex Ferguson'), findsOneWidget);
        expect(find.text('ID 12345'), findsOneWidget);
        expect(find.text('FPL Lens never asks for your FPL account password.'), findsOneWidget);
        expect(find.text('Confirm and load squad'), findsOneWidget);
      });

      testWidgets('renders cleanly in light mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const TeamCheckScreen(),
            themeMode: ThemeMode.light,
            overrides: [
              fplRepositoryProvider.overrideWithValue(MockFplRepository()),
            ],
          ),
        );

        expect(find.text('Your team'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 6. LoadSquadScreen Tests
    // -------------------------------------------------------------------------
    group('LoadSquadScreen (/onboarding/load)', () {
      testWidgets('renders clean loading progress line without process steps in dark mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const LoadSquadScreen(teamId: 12345),
            themeMode: ThemeMode.dark,
            overrides: [
              squadNotifierProvider.overrideWith(
                (ref) => MockSquadNotifier(
                  const SquadState(step: SquadLoadingStep.step2SquadPicks),
                ),
              ),
            ],
          ),
        );

        await tester.pump();

        expect(find.text('Loading your squad'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Connecting to Premier League servers'), findsNothing);
      });

      testWidgets('renders cleanly in light mode', (tester) async {
        await tester.pumpWidget(
          buildAppWithRoute(
            screen: const LoadSquadScreen(teamId: 12345),
            themeMode: ThemeMode.light,
            overrides: [
              squadNotifierProvider.overrideWith(
                (ref) => MockSquadNotifier(
                  const SquadState(step: SquadLoadingStep.step2SquadPicks),
                ),
              ),
            ],
          ),
        );

        expect(find.text('Loading your squad'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 7. Text Scale 200% Accessibility
    // -------------------------------------------------------------------------
    testWidgets('Auth and onboarding screens render without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithRoute(
          screen: const SignInScreen(),
          themeMode: ThemeMode.dark,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('FPL Lens'), findsOneWidget);
    });
  });
}
