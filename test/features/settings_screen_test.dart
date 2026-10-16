import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/widgets/confirm_sheet.dart';
import 'package:fpl_lens/core/widgets/disclosure_notice.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/settings/screens/settings_screen.dart';

void main() {
  Widget wrapSettings({required AuthNotifier notifier}) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/auth', builder: (_, __) => const Text('Screen: Auth')),
      ],
    );

    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('P19 SettingsScreen', () {
    testWidgets('Displays account information, preferences, and verbatim disclaimer', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      final notifier = AuthNotifier(
        repository: container.read(authRepositoryProvider),
        secureStore: container.read(secureStoreProvider),
      )..state = const AuthState(
          status: AuthStatus.authenticatedVerified,
          user: UserModel(
            id: 'user-456',
            email: 'manager@example.com',
            displayName: 'Top Manager',
            fplTeamId: 888888,
            status: 'active',
          ),
        );

      await tester.pumpWidget(wrapSettings(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('ma***@example.com'), findsOneWidget);
      expect(find.text('888888'), findsOneWidget);
      expect(find.byType(DisclosureNotice), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('Tapping Delete account opens confirmation sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      final notifier = AuthNotifier(
        repository: container.read(authRepositoryProvider),
        secureStore: container.read(secureStoreProvider),
      )..state = const AuthState(
          status: AuthStatus.authenticatedVerified,
          user: UserModel(
            id: 'user-456',
            email: 'manager@example.com',
            displayName: 'Top Manager',
            status: 'active',
          ),
        );

      await tester.pumpWidget(wrapSettings(notifier: notifier));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Delete account'));
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      // Confirm sheet appears with 3-day deletion copy
      expect(find.byType(ConfirmSheet), findsOneWidget);
      expect(
        find.textContaining('3-day grace period'),
        findsOneWidget,
      );
    });
  });
}
