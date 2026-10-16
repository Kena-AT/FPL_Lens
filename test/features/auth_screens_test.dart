import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/widgets/app_text_field.dart';
import 'package:fpl_lens/core/widgets/code_input.dart';
import 'package:fpl_lens/core/widgets/disclosure_notice.dart';
import 'package:fpl_lens/core/widgets/team_id_field.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/auth/screens/register_screen.dart';
import 'package:fpl_lens/features/auth/screens/sign_in_screen.dart';
import 'package:fpl_lens/features/auth/screens/splash_screen.dart';
import 'package:fpl_lens/features/auth/screens/verify_email_screen.dart';

void main() {
  Widget wrapWithScope(Widget child, {List<Override> overrides = const []}) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
        GoRoute(path: '/auth', builder: (_, __) => const Text('Screen: Auth')),
        GoRoute(path: '/home', builder: (_, __) => const Text('Screen: Home')),
        GoRoute(path: '/auth/verify', builder: (_, __) => const Text('Screen: Verify')),
        GoRoute(path: '/onboarding/team', builder: (_, __) => const Text('Screen: TeamCheck')),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  void setLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Authentication Screens', () {
    testWidgets('P1 SplashScreen displays wordmark and branding', (tester) async {
      await tester.pumpWidget(wrapWithScope(const SplashScreen()));

      expect(find.text('FPL Lens'), findsOneWidget);
      // Advances through timers
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('P2 SignInScreen renders form fields, buttons, and verbatim disclaimer', (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(wrapWithScope(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(find.text('FPL Lens'), findsOneWidget);
      expect(find.widgetWithText(AppTextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(AppTextField, 'Password'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(DisclosureNotice), findsOneWidget);
    });

    testWidgets('P2 SignInScreen shows lockout banner when locked', (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        wrapWithScope(
          const SignInScreen(),
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
      await tester.pumpAndSettle();

      expect(find.text('Too many attempts. Try again in 15 minutes.'), findsOneWidget);
    });

    testWidgets('P3 RegisterScreen renders all required fields and terms checkbox', (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(wrapWithScope(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsWidgets);
      expect(find.widgetWithText(AppTextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(AppTextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(AppTextField, 'Display name'), findsOneWidget);
      expect(find.byType(TeamIdField), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('I agree to the Terms and Privacy Policy'), findsOneWidget);
    });

    testWidgets('P4 VerifyEmailScreen renders 6-box input, resend button, and sign out', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(
          const VerifyEmailScreen(),
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(
                repository: ref.watch(authRepositoryProvider),
                secureStore: ref.watch(secureStoreProvider),
              )..state = const AuthState(
                  status: AuthStatus.authenticatedUnverified,
                  user: UserModel(
                    id: 'u-123',
                    email: 'kenakaye11@gmail.com',
                    displayName: 'Kena',
                    status: 'unverified',
                  ),
                ),
            ),
          ],
        ),
      );

      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('We sent a six-digit code to'), findsOneWidget);
      expect(find.byType(CodeInput), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
