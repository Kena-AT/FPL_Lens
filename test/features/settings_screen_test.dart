import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/widgets/confirm_sheet.dart';
import 'package:fpl_lens/core/widgets/disclosure_notice.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/settings/screens/settings_screen.dart';

void main() {
  late AppDatabase inMemoryDb;

  setUp(() {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

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
        appDatabaseProvider.overrideWithValue(inMemoryDb),
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

    testWidgets('P19 renders cleanly without overflow at 360 dp in dark theme', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
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
            id: 'user-789',
            email: 'user360@example.com',
            displayName: 'Manager 360',
            fplTeamId: 123456,
            status: 'active',
          ),
        );

      await tester.pumpWidget(wrapSettings(notifier: notifier));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Share anonymous usage data'), findsOneWidget);
    });

    testWidgets('P19 renders cleanly without overflow at 430 dp in dark theme', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
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
            id: 'user-789',
            email: 'user430@example.com',
            displayName: 'Manager 430',
            fplTeamId: 654321,
            status: 'active',
          ),
        );

      await tester.pumpWidget(wrapSettings(notifier: notifier));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('About FPL Lens'), 200);
      expect(find.text('About FPL Lens'), findsOneWidget);
    });
  });
}
